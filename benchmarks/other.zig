const std = @import("std");
const zbench = @import("zbench");
const uuid = @import("uuid");

const assert = std.debug.assert;
const testing = std.testing;

const kid = @import("kid");

pub const BenchmarkUUIDv7Generate = struct {
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
            _ = uuid.v7.new(self.io);
        }
    }
};

pub const BenchmarkUUIDv4Generate = struct {
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
            _ = uuid.v4.new(self.io);
        }
    }
};

test "uuid.v7 benchmarks" {
    var bench = zbench.Benchmark.init(std.testing.allocator, .{
        .iterations = 100,
    });
    defer bench.deinit();

    const io = testing.io;

    try bench.addParam("uuid.v7 1 ids", &BenchmarkUUIDv7Generate.new(io, 1), .{});
    try bench.addParam("uuid.v7 1000 ids", &BenchmarkUUIDv7Generate.new(io, 1_000), .{});
    try bench.addParam("uuid.v7 8192 ids", &BenchmarkUUIDv7Generate.new(io, 8192), .{});
    try bench.addParam("uuid.v7 10_000 ids", &BenchmarkUUIDv7Generate.new(io, 10_000), .{});
    try bench.addParam("uuid.v7 100_000 ids", &BenchmarkUUIDv7Generate.new(io, 100_000), .{});
    try bench.addParam(
        "uuid.v7 1_000_000 ids",
        &BenchmarkUUIDv7Generate.new(io, 1_000_000),
        .{ .iterations = 5 },
    );

    const stderr = std.Io.File.stderr();
    var stderr_writer = stderr.writerStreaming(io, &.{});
    const writer = &stderr_writer.interface;

    try writer.writeAll("\n");
    try writer.writeAll("|--------------------|\n");
    try writer.writeAll("| uuid.v7 Benchmarks |\n");
    try writer.writeAll("|--------------------|\n");
    try bench.run(io, stderr);
}

test "uuid.v4 benchmarks" {
    var bench = zbench.Benchmark.init(std.testing.allocator, .{
        .iterations = 100,
    });
    defer bench.deinit();

    const io = testing.io;

    try bench.addParam("uuid.v4 1 ids", &BenchmarkUUIDv4Generate.new(io, 1), .{});
    try bench.addParam("uuid.v4 1000 ids", &BenchmarkUUIDv4Generate.new(io, 1_000), .{});
    try bench.addParam("uuid.v4 8192 ids", &BenchmarkUUIDv4Generate.new(io, 8192), .{});
    try bench.addParam("uuid.v4 10_000 ids", &BenchmarkUUIDv4Generate.new(io, 10_000), .{});
    try bench.addParam("uuid.v4 100_000 ids", &BenchmarkUUIDv4Generate.new(io, 100_000), .{});
    try bench.addParam(
        "uuid.v4 1_000_000 ids",
        &BenchmarkUUIDv4Generate.new(io, 1_000_000),
        .{ .iterations = 5 },
    );

    const stderr = std.Io.File.stderr();
    var stderr_writer = stderr.writerStreaming(io, &.{});
    const writer = &stderr_writer.interface;

    try writer.writeAll("\n");
    try writer.writeAll("|--------------------|\n");
    try writer.writeAll("| uuid.v4 Benchmarks |\n");
    try writer.writeAll("|--------------------|\n");
    try bench.run(io, stderr);
}
