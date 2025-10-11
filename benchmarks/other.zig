const std = @import("std");
const zbench = @import("zbench");
const uuid = @import("uuid");

const assert = std.debug.assert;
const testing = std.testing;

const kid = @import("kid");

pub fn BenchmarkUUIDV7GenerateOne(_: std.mem.Allocator) void {
    _ = uuid.v7.new();
}

pub fn BenchmarkUUIDV7Generate1000(_: std.mem.Allocator) void {
    for (0..1_000) |_| {
        _ = uuid.v7.new();
    }
}

pub fn BenchmarkUUIDV7Generate8192(_: std.mem.Allocator) void {
    for (0..8192) |_| {
        _ = uuid.v7.new();
    }
}

pub fn BenchmarkUUIDV7Generate10000(_: std.mem.Allocator) void {
    for (0..10_000) |_| {
        _ = uuid.v7.new();
    }
}

pub fn BenchmarkUUIDV7Generate100000(_: std.mem.Allocator) void {
    for (0..100_000) |_| {
        _ = uuid.v7.new();
    }
}

pub fn BenchmarkUUIDV7Generate1000000(_: std.mem.Allocator) void {
    for (0..1_000_000) |_| {
        _ = uuid.v7.new();
    }
}

pub fn BenchmarkUUIDV4GenerateOne(_: std.mem.Allocator) void {
    _ = uuid.v4.new();
}

pub fn BenchmarkUUIDV4Generate1000(_: std.mem.Allocator) void {
    for (0..1_000) |_| {
        _ = uuid.v4.new();
    }
}

pub fn BenchmarkUUIDV4Generate8192(_: std.mem.Allocator) void {
    for (0..8192) |_| {
        _ = uuid.v4.new();
    }
}

pub fn BenchmarkUUIDV4Generate10000(_: std.mem.Allocator) void {
    for (0..10_000) |_| {
        _ = uuid.v4.new();
    }
}

pub fn BenchmarkUUIDV4Generate100000(_: std.mem.Allocator) void {
    for (0..100_000) |_| {
        _ = uuid.v4.new();
    }
}

pub fn BenchmarkUUIDV4Generate1000000(_: std.mem.Allocator) void {
    for (0..1_000_000) |_| {
        _ = uuid.v4.new();
    }
}

test "uuid.v7 benchmarks" {
    var bench = zbench.Benchmark.init(std.testing.allocator, .{
        .iterations = 100,
    });
    defer bench.deinit();

    try bench.add("uuid.v7 1 ids", BenchmarkUUIDV7GenerateOne, .{});
    try bench.add("uuid.v7 1000 ids", BenchmarkUUIDV7Generate1000, .{});
    try bench.add("uuid.v7 8192 ids", BenchmarkUUIDV7Generate8192, .{});
    try bench.add("uuid.v7 10_000 ids", BenchmarkUUIDV7Generate10000, .{});
    try bench.add("uuid.v7 100_000 ids", BenchmarkUUIDV7Generate100000, .{});
    try bench.add("uuid.v7 1_000_000 ids", BenchmarkUUIDV7Generate1000000, .{ .iterations = 5 });

    var stderr = std.fs.File.stderr().writerStreaming(&.{});
    const writer = &stderr.interface;

    try writer.writeAll("\n");
    try writer.writeAll("|--------------------|\n");
    try writer.writeAll("| uuid.v7 Benchmarks |\n");
    try writer.writeAll("|--------------------|\n");
    try bench.run(writer);
}

test "uuid.v4 benchmarks" {
    var bench = zbench.Benchmark.init(std.testing.allocator, .{
        .iterations = 100,
    });
    defer bench.deinit();

    try bench.add("uuid.v4 1 ids", BenchmarkUUIDV4GenerateOne, .{});
    try bench.add("uuid.v4 1000 ids", BenchmarkUUIDV4Generate1000, .{});
    try bench.add("uuid.v4 8192 ids", BenchmarkUUIDV4Generate8192, .{});
    try bench.add("uuid.v4 10_000 ids", BenchmarkUUIDV4Generate10000, .{});
    try bench.add("uuid.v4 100_000 ids", BenchmarkUUIDV4Generate100000, .{});
    try bench.add("uuid.v4 1_000_000 ids", BenchmarkUUIDV4Generate1000000, .{ .iterations = 5 });

    var stderr = std.fs.File.stderr().writerStreaming(&.{});
    const writer = &stderr.interface;

    try writer.writeAll("\n");
    try writer.writeAll("|--------------------|\n");
    try writer.writeAll("| uuid.v4 Benchmarks |\n");
    try writer.writeAll("|--------------------|\n");
    try bench.run(writer);
}
