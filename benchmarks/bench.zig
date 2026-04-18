const std = @import("std");
const zbench = @import("zbench");

test "prints system info" {
    const io = std.testing.io;
    const stderr = std.Io.File.stderr();
    var stderr_writer = stderr.writerStreaming(io, &.{});
    const writer = &stderr_writer.interface;

    try writer.writeAll("--------------------------------------------------------\n");
    try writer.print("{f}", .{try zbench.getSystemInfo()});
    try writer.writeAll("--------------------------------------------------------\n");
}

comptime {
    _ = @import("kid.zig");
    _ = @import("other.zig");
}
