const std = @import("std");
const testing = std.testing;

const kidv2 = @import("./kidv2.zig");

test "init/deinit" {
    const io = testing.io;

    try kidv2.init(io, 0, .{});
    defer kidv2.deinit(io);
}

test "generates sequential ids" {
    const io = testing.io;

    try kidv2.init(io, 1, .{});
    defer kidv2.deinit(io);

    const kidv2_0 = kidv2.generate(io);
    const kidv2_1 = kidv2.generate(io);

    const kidv2_0_decoded = kidv2.decode(kidv2_0);
    const kidv2_1_decoded = kidv2.decode(kidv2_1);

    try testing.expect(kidv2_0_decoded.timestamp_ms <= kidv2_1_decoded.timestamp_ms);

    if (kidv2_0_decoded.timestamp_ms == kidv2_1_decoded.timestamp_ms) {
        try testing.expectEqual(0, kidv2_0_decoded.counter);
        try testing.expectEqual(1, kidv2_1_decoded.counter);
    } else {
        try testing.expectEqual(0, kidv2_0_decoded.counter);
        try testing.expectEqual(0, kidv2_1_decoded.counter);
    }
    try testing.expect(kidv2_0_decoded.node_id == kidv2_1_decoded.node_id);
}

test "can generate 8192 ids per ms" {
    const allocator = testing.allocator;
    const io = testing.io;

    try kidv2.init(io, 2, .{});
    defer kidv2.deinit(io);

    const iters = 100_000;

    var ids = try std.ArrayList(u64).initCapacity(allocator, iters);
    defer ids.deinit(allocator);

    for (0..iters) |_| {
        const id = kidv2.generate(io);
        ids.appendAssumeCapacity(id);
    }

    // loop over all the ids
    var current_ts: u64 = 0;
    for (ids.items) |id| {
        const decoded = kidv2.decode(id);
        if (decoded.timestamp_ms > current_ts) current_ts = decoded.timestamp_ms;

        // ensure that all counters are less than the max of a 13 bit integer 8192
        try testing.expect(decoded.counter <= std.math.maxInt(u13));
    }

    try testing.expectEqual(iters, ids.items.len);
}

// const std = @import("std");
// const testing = std.testing;

// const kidv2 = @import("./kidv2.zig");

// test "init/deinit" {
//     const io = testing.io;

//     try kidv2.init(io, 0, .{});
//     defer kidv2.deinit();
// }

// test "generates sequential ids" {
//     const io = testing.io;

//     try kidv2.init(io, 1, .{});
//     defer kidv2.deinit();

//     const kidv2_0 = kidv2.generate();
//     const kidv2_1 = kidv2.generate();

//     const kidv2_0_decoded = kidv2.decode(kidv2_0);
//     const kidv2_1_decoded = kidv2.decode(kidv2_1);

//     try testing.expect(kidv2_0_decoded.timestamp_ms <= kidv2_1_decoded.timestamp_ms);

//     if (kidv2_0_decoded.timestamp_ms == kidv2_1_decoded.timestamp_ms) {
//         try testing.expectEqual(0, kidv2_0_decoded.counter);
//         try testing.expectEqual(1, kidv2_1_decoded.counter);
//     } else {
//         try testing.expectEqual(0, kidv2_0_decoded.counter);
//         try testing.expectEqual(0, kidv2_1_decoded.counter);
//     }
//     try testing.expect(kidv2_0_decoded.node_id == kidv2_1_decoded.node_id);
// }

// test "can generate 8192 ids per ms" {
//     const allocator = testing.allocator;
//     const io = testing.io;

//     try kidv2.init(io, 2, .{});
//     defer kidv2.deinit();

//     const iters = 100_000;

//     var ids = try std.ArrayList(u64).initCapacity(allocator, iters);
//     defer ids.deinit(allocator);

//     for (0..iters) |_| {
//         const id = kidv2.generate();
//         ids.appendAssumeCapacity(id);
//     }

//     // loop over all the ids
//     var current_ts: u64 = 0;
//     for (ids.items) |id| {
//         const decoded = kidv2.decode(id);
//         if (decoded.timestamp_ms > current_ts) current_ts = decoded.timestamp_ms;

//         // ensure that all counters are less than the max of a 13 bit integer 8192
//         try testing.expect(decoded.counter <= std.math.maxInt(u13));
//     }

//     try testing.expectEqual(iters, ids.items.len);
// }
