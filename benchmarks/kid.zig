const std = @import("std");
const zbench = @import("zbench");

const assert = std.debug.assert;
const testing = std.testing;

const kid = @import("kid");

pub const BenchmarkKIDGenerate = struct {
    const Self = @This();
    io: std.Io,
    iters: usize = 1,
    pub fn new(io: std.Io, iters: usize) Self {
        return Self{
            .io = io,
            .iters = iters,
        };
    }

    pub fn run(self: *Self, _: std.mem.Allocator) void {
        for (0..self.iters) |_| {
            _ = kid.generate(self.io);
        }
    }
};

test "KID benchmarks" {
    var bench = zbench.Benchmark.init(std.testing.allocator, .{
        .iterations = 100,
    });
    defer bench.deinit();

    const io = testing.io;

    kid.configure(100, .{});

    try bench.addParam("generate 1 ids", &BenchmarkKIDGenerate.new(io, 1), .{});
    try bench.addParam("generate 1000 ids", &BenchmarkKIDGenerate.new(io, 1_000), .{});
    try bench.addParam("generate 8192 ids", &BenchmarkKIDGenerate.new(io, 8192), .{});
    try bench.addParam("generate 10_000 ids", &BenchmarkKIDGenerate.new(io, 10_000), .{});
    try bench.addParam("generate 100_000 ids", &BenchmarkKIDGenerate.new(io, 100_000), .{});
    try bench.addParam(
        "generate 1_000_000 ids",
        &BenchmarkKIDGenerate.new(io, 1_000_000),
        .{ .iterations = 5 },
    );

    const stderr = std.Io.File.stderr();
    var stderr_writer = stderr.writerStreaming(io, &.{});
    const writer = &stderr_writer.interface;

    try writer.writeAll("\n");
    try writer.writeAll("|----------------|\n");
    try writer.writeAll("| KID Benchmarks |\n");
    try writer.writeAll("|----------------|\n");
    try bench.run(io, stderr);
}
