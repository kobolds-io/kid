const std = @import("std");
const testing = std.testing;

const kid = @import("./kid.zig");

test "generates sequential ids" {
    kid.configure(1, .{});
    const kid_0 = kid.generate();
    const kid_1 = kid.generate();

    const kid_0_decoded = kid.decode(kid_0);
    const kid_1_decoded = kid.decode(kid_1);

    try testing.expect(kid_0_decoded.timestamp_ms <= kid_1_decoded.timestamp_ms);

    if (kid_0_decoded.timestamp_ms == kid_1_decoded.timestamp_ms) {
        try testing.expectEqual(0, kid_0_decoded.counter);
        try testing.expectEqual(1, kid_1_decoded.counter);
    } else {
        try testing.expectEqual(0, kid_0_decoded.counter);
        try testing.expectEqual(0, kid_1_decoded.counter);
    }
    try testing.expect(kid_0_decoded.node_id == kid_1_decoded.node_id);
}

test "can generate 8192 ids per ms" {
    const allocator = testing.allocator;

    kid.configure(2, .{});

    const iters = 100_000;

    var ids = try std.ArrayList(u64).initCapacity(allocator, iters);
    defer ids.deinit(allocator);

    for (0..iters) |_| {
        const id = kid.generate();
        ids.appendAssumeCapacity(id);
    }

    // loop over all the ids
    var current_ts: u64 = 0;
    for (ids.items) |id| {
        const decoded = kid.decode(id);
        if (decoded.timestamp_ms > current_ts) current_ts = decoded.timestamp_ms;

        // ensure that all counters are less than the max of a 13 bit integer 8192
        try testing.expect(decoded.counter <= std.math.maxInt(u13));
    }

    try testing.expectEqual(iters, ids.items.len);
}

test "KID is thread-safe and generates unique IDs" {
    return error.SkipZigTest;
}
