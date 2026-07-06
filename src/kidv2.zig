const std = @import("std");
const atomic = std.atomic;

pub const KIDOptions = struct {
    epoch_ms: u64 = DEFAULT_EPOCH_MS,
};

const DEFAULT_EPOCH_MS: u64 = 1735689600000; // Jan 1, 2025, in ms

/// Bit layout (64 bits total):
/// [ timestamp 40 bits ] | [ counter 13 bits ] | [ node_id 6 bits ] | [ thread_id 5 bits ]
///
/// - Timestamp: 40 bits, usable until ~2059 from custom epoch
/// - Counter:   13 bits, 8192 ids/ms/thread
/// - Node ID:   6 bits, 64 physical nodes
/// - Thread ID: 5 bits, 32 threads per node
///
/// Uniqueness holds per (node_id, thread_id) pair. Cross-thread ordering
/// within a node is NOT guaranteed -- only per-thread ordering and
/// per-node approximate time ordering hold.
const IdFields = packed struct {
    thread_id: u5 = 0,
    node_id: u6 = 0,
    counter: u13 = 0,
    timestamp: u40 = 0,
};

pub const Decoded = struct {
    timestamp_ms: u64,
    counter: u32,
    node_id: u8,
    thread_id: u8,
};

// --- module-level global config ---
var epoch_ms: u64 = DEFAULT_EPOCH_MS;
var node_id: u6 = 0;
var initialized: atomic.Value(bool) = atomic.Value(bool).init(false);
var init_once: std.Io.Mutex = .init;

// Assigns a unique thread slot [0, 32) the first time each thread calls
// generate(). This atomic op happens once per thread lifetime, not per ID.
var next_thread_slot: atomic.Value(u8) = atomic.Value(u8).init(0);

// --- per-thread state, no synchronization needed ---
threadlocal var tl_state: u64 = 0;
threadlocal var tl_thread_id: ?u5 = null;

/// Configure KID globally. Safe to call exactly once per process.
/// Calling it a second time is a programmer error and will return error.AlreadyInitialized.
pub fn init(io: std.Io, n_id: u6, options: KIDOptions) !void {
    init_once.lockUncancelable(io);
    defer init_once.unlock(io);

    if (initialized.load(.acquire)) return error.AlreadyInitialized;

    node_id = n_id;
    epoch_ms = options.epoch_ms;

    initialized.store(true, .release);
}

/// Reset global state. Call once at shutdown. Note this does not reset
/// per-thread state -- threads that already claimed a slot keep it if
/// init() is called again without process restart.
pub fn deinit(io: std.Io) void {
    init_once.lockUncancelable(io);
    defer init_once.unlock(io);

    initialized.store(false, .release);
    next_thread_slot.store(0, .monotonic);
}

fn currentThreadId() u5 {
    if (tl_thread_id) |id| return id;

    const slot = next_thread_slot.fetchAdd(1, .monotonic);
    // 5 bits => 32 max slots. Overflow is a configuration error: too many
    // ID-generating threads for the reserved bit width.
    if (slot >= 32) @panic("kid: exceeded max threads per node (32)");

    const id: u5 = @intCast(slot);
    tl_thread_id = id;
    return id;
}

/// Generate a new KID. Must be called after init() has been called once
/// globally. No cross-thread synchronization occurs on this path -- each
/// thread's state lives in thread-local storage.
pub fn generate(io: std.Io) u64 {
    std.debug.assert(initialized.load(.monotonic)); // catches missing init() in debug builds

    const t_id = currentThreadId();

    while (true) {
        const now = std.Io.Timestamp.now(io, .real);
        const now_ms: u64 = @intCast(now.toMilliseconds());
        const ts_delta = (now_ms -| epoch_ms) & ((1 << 40) - 1);
        const ts: u40 = @intCast(ts_delta);

        const old_fields: IdFields = @bitCast(tl_state);

        var new_fields = IdFields{
            .timestamp = ts,
            .counter = 0,
            .node_id = node_id,
            .thread_id = t_id,
        };

        if (ts < old_fields.timestamp) {
            // local clock regressed relative to this thread's last id;
            // hold at the last known timestamp rather than going backward
            new_fields.timestamp = old_fields.timestamp;
        }

        if (new_fields.timestamp == old_fields.timestamp) {
            new_fields.counter = old_fields.counter +% 1;

            if (new_fields.counter == 0) {
                // counter overflow: 8192 ids/ms exhausted on this thread.
                // Spin until the clock actually advances, bounded to 5ms.
                const spin_upper_bounds_ms = now_ms + 5;
                var later_ms: u64 = now_ms;
                var advanced = false;

                while (later_ms < spin_upper_bounds_ms) {
                    const later = std.Io.Timestamp.now(io, .real);
                    later_ms = @intCast(later.toMilliseconds());
                    const later_delta = (later_ms -| epoch_ms) & ((1 << 40) - 1);
                    const later_ts: u40 = @intCast(later_delta);

                    if (later_ts > old_fields.timestamp) {
                        new_fields.timestamp = later_ts;
                        new_fields.counter = 0;
                        advanced = true;
                        break;
                    }
                    std.atomic.spinLoopHint();
                }

                if (!advanced) @panic("kid: spin upper bounds breached, sustained 8192 ids/ms/thread contention");
            }
        }

        const new_bits: u64 = @bitCast(new_fields);
        tl_state = new_bits;
        return new_bits;
    }
}

pub fn decode(id: u64) Decoded {
    const fields: IdFields = @bitCast(id);
    return .{
        .timestamp_ms = @as(u64, fields.timestamp) + epoch_ms,
        .counter = fields.counter,
        .node_id = fields.node_id,
        .thread_id = fields.thread_id,
    };
}
// const std = @import("std");
// const atomic = std.atomic;

// pub const KIDOptions = struct {
//     epoch_ms: u64 = DEFAULT_EPOCH_MS,
// };

// const DEFAULT_EPOCH_MS: u64 = 1735689600000; // Jan 1, 2025, in ms

// const IdFields = packed struct {
//     node_id: u11 = 0,
//     counter: u13 = 0,
//     timestamp: u40 = 0,
// };

// const Decoded = struct {
//     timestamp_ms: u64,
//     counter: u32,
//     node_id: u16,
// };

// // --- module-level global state ---
// var epoch_ms: u64 = DEFAULT_EPOCH_MS;
// var node_id: u11 = 0;
// var state: atomic.Value(u64) = atomic.Value(u64).init(0);

// var cached_ms: atomic.Value(u64) = atomic.Value(u64).init(0);
// var ticker_running: atomic.Value(bool) = atomic.Value(bool).init(false);
// var ticker_thread: ?std.Thread = null;

// var init_once: std.Io.Mutex = .init;
// var initialized: atomic.Value(bool) = atomic.Value(bool).init(false);

// fn tickerLoop(io: std.Io) void {
//     while (ticker_running.load(.monotonic)) {
//         const now = std.Io.Timestamp.now(io, .real);
//         const now_ms: u64 = @intCast(now.toMilliseconds());
//         cached_ms.store(now_ms, .release);
//         std.Io.sleep(io, .fromMilliseconds(1), .real) catch |err| {
//             std.debug.print("{s} - could not sleep. continuing loop\n", .{@errorName(err)});
//             continue;
//         };
//     }
// }

// /// Configure KID globally. Safe to call exactly once per process.
// /// Calling it a second time is a programmer error and will return error.AlreadyInitialized.
// pub fn init(io: std.Io, n_id: u11, options: KIDOptions) !void {
//     init_once.lockUncancelable(io);
//     defer init_once.unlock(io);

//     if (initialized.load(.acquire)) return error.AlreadyInitialized;

//     node_id = n_id;
//     epoch_ms = options.epoch_ms;

//     // seed synchronously so generate() never reads a zero
//     const now = std.Io.Timestamp.now(io, .real);
//     cached_ms.store(@intCast(now.toMilliseconds()), .release);

//     ticker_running.store(true, .monotonic);
//     ticker_thread = try std.Thread.spawn(.{}, tickerLoop, .{io});

//     initialized.store(true, .release);
// }

// /// Stop the background clock thread. Call once at shutdown.
// pub fn deinit() void {
//     if (!initialized.load(.acquire)) return;

//     ticker_running.store(false, .monotonic);
//     if (ticker_thread) |t| t.join();
//     ticker_thread = null;

//     initialized.store(false, .release);
// }

// pub fn generate() u64 {
//     std.debug.assert(initialized.load(.monotonic)); // catches missing init() in debug builds

//     while (true) {
//         const now_ms = cached_ms.load(.acquire);
//         const ts_delta = (now_ms -| epoch_ms) & ((1 << 40) - 1);
//         const ts: u40 = @intCast(ts_delta);

//         const old = state.load(.acquire);
//         const old_fields: IdFields = @bitCast(old);

//         var new_fields = IdFields{
//             .timestamp = ts,
//             .counter = 0,
//             .node_id = node_id,
//         };

//         if (ts < old_fields.timestamp) {
//             new_fields.timestamp = old_fields.timestamp;
//         }

//         if (new_fields.timestamp == old_fields.timestamp) {
//             new_fields.counter = old_fields.counter +% 1;

//             if (new_fields.counter == 0) {
//                 var later_ms: u64 = now_ms;
//                 const spin_upper_bounds_ms = now_ms + 5;
//                 var advanced = false;

//                 while (later_ms < spin_upper_bounds_ms) {
//                     later_ms = cached_ms.load(.acquire);
//                     const later_delta = (later_ms -| epoch_ms) & ((1 << 40) - 1);
//                     const later_ts: u40 = @intCast(later_delta);

//                     if (later_ts > old_fields.timestamp) {
//                         new_fields.timestamp = later_ts;
//                         new_fields.counter = 0;
//                         advanced = true;
//                         break;
//                     }
//                     std.atomic.spinLoopHint();
//                 }

//                 if (!advanced) @panic("spin upper bounds breached");
//             }
//         }

//         const new_bits: u64 = @bitCast(new_fields);
//         if (state.cmpxchgWeak(old, new_bits, .acq_rel, .acquire) == null) {
//             return new_bits;
//         }
//     }
// }

// pub fn decode(id: u64) Decoded {
//     const fields: IdFields = @bitCast(id);
//     return .{
//         .timestamp_ms = @as(u64, fields.timestamp) + epoch_ms,
//         .counter = fields.counter,
//         .node_id = fields.node_id,
//     };
// }
