const std = @import("std");
const zbench = @import("zbench");

test "prints system info" {
    var stderr = std.fs.File.stderr().writerStreaming(&.{});
    const writer = &stderr.interface;

    try writer.writeAll("--------------------------------------------------------\n");
    try writer.print("{f}", .{try zbench.getSystemInfo()});
    try writer.writeAll("--------------------------------------------------------\n");
}

comptime {
    _ = @import("kid.zig");
    _ = @import("other.zig");
}
