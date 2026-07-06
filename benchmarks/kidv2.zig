const std = @import("std");
const zbench = @import("zbench");

const assert = std.debug.assert;
const testing = std.testing;

const kidv2 = @import("kidv2");

pub const BenchmarkKIDv2Generate = struct {
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
            _ = kidv2.generate(self.io);
        }
    }
};

test "KIDv2 benchmarks" {
    var bench = zbench.Benchmark.init(std.testing.allocator, .{
        .iterations = 100,
    });
    defer bench.deinit();

    const io = testing.io;

    try kidv2.init(io, 10, .{});
    defer kidv2.deinit(
        io,
    );

    try bench.addParam("generate 1 ids", &BenchmarkKIDv2Generate.new(io, 1), .{});
    try bench.addParam("generate 1000 ids", &BenchmarkKIDv2Generate.new(io, 1_000), .{});
    try bench.addParam("generate 8192 ids", &BenchmarkKIDv2Generate.new(io, 8192), .{});
    try bench.addParam("generate 10_000 ids", &BenchmarkKIDv2Generate.new(io, 10_000), .{});
    try bench.addParam("generate 100_000 ids", &BenchmarkKIDv2Generate.new(io, 100_000), .{});
    try bench.addParam(
        "generate 1_000_000 ids",
        &BenchmarkKIDv2Generate.new(io, 1_000_000),
        .{ .iterations = 5 },
    );

    const stderr = std.Io.File.stderr();
    var stderr_writer = stderr.writerStreaming(io, &.{});
    const writer = &stderr_writer.interface;

    try writer.writeAll("\n");
    try writer.writeAll("|----------------|\n");
    try writer.writeAll("| KIDv2 Benchmarks |\n");
    try writer.writeAll("|----------------|\n");
    try bench.run(io, stderr);
}

// const std = @import("std");
// const zbench = @import("zbench");

// const assert = std.debug.assert;
// const testing = std.testing;

// const kidv2 = @import("kidv2");

// pub const BenchmarkKIDv2Generate = struct {
//     const Self = @This();
//     iters: usize = 1,
//     pub fn new(iters: usize) Self {
//         return Self{
//             .iters = iters,
//         };
//     }

//     pub fn run(self: *Self, _: std.mem.Allocator) void {
//         for (0..self.iters) |_| {
//             _ = kidv2.generate();
//         }
//     }
// };

// test "KIDv2 benchmarks" {
//     var bench = zbench.Benchmark.init(std.testing.allocator, .{
//         .iterations = 100,
//     });
//     defer bench.deinit();

//     const io = testing.io;

//     try kidv2.init(io, 100, .{});
//     defer kidv2.deinit();

//     try bench.addParam("generate 1 ids", &BenchmarkKIDv2Generate.new(1), .{});
//     try bench.addParam("generate 1000 ids", &BenchmarkKIDv2Generate.new(1_000), .{});
//     try bench.addParam("generate 8192 ids", &BenchmarkKIDv2Generate.new(8192), .{});
//     try bench.addParam("generate 10_000 ids", &BenchmarkKIDv2Generate.new(10_000), .{});
//     try bench.addParam("generate 100_000 ids", &BenchmarkKIDv2Generate.new(100_000), .{});
//     try bench.addParam(
//         "generate 1_000_000 ids",
//         &BenchmarkKIDv2Generate.new(1_000_000),
//         .{ .iterations = 5 },
//     );

//     const stderr = std.Io.File.stderr();
//     var stderr_writer = stderr.writerStreaming(io, &.{});
//     const writer = &stderr_writer.interface;

//     try writer.writeAll("\n");
//     try writer.writeAll("|----------------|\n");
//     try writer.writeAll("| KIDv2 Benchmarks |\n");
//     try writer.writeAll("|----------------|\n");
//     try bench.run(io, stderr);
// }
