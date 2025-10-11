const std = @import("std");

const version = std.SemanticVersion{ .major = 0, .minor = 0, .patch = 3 };

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    // This is shamelessly taken from the `zbench` library's `build.zig` file. see [here](https://github.com/hendriknielaender/zBench/blob/b69a438f5a1a96d4dd0ea69e1dbcb73a209f76cd/build.zig)
    setupLibrary(b, target, optimize);
    setupTests(b, target, optimize);
    setupBenchmarks(b, target, optimize);
    // setupExamples(b, target, optimize);
}

fn setupLibrary(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const lib = b.addLibrary(.{
        .name = "kid",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/kid.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .version = version,
    });

    // Explicitly export the `kid` module so it can be imported by others
    _ = b.addModule("kid", .{
        .root_source_file = b.path("src/kid.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);
}

fn setupTests(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const lib_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

fn setupBenchmarks(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const bench_lib = b.addTest(.{
        .name = "bench",
        .root_module = b.createModule(.{
            .root_source_file = b.path("benchmarks/bench.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const kid_mod = b.addModule("kid", .{
        .root_source_file = b.path("src/kid.zig"),
        .target = target,
        .optimize = optimize,
    });

    const uuid_dep = b.dependency("uuid", .{
        .target = target,
        .optimize = optimize,
    });
    const uuid_mod = uuid_dep.module("uuid");

    const zbench_dep = b.dependency("zbench", .{
        .target = target,
        .optimize = optimize,
    });
    const zbench_mod = zbench_dep.module("zbench");

    bench_lib.root_module.addImport("kid", kid_mod);
    bench_lib.root_module.addImport("uuid", uuid_mod);
    bench_lib.root_module.addImport("zbench", zbench_mod);

    const run_bench_tests = b.addRunArtifact(bench_lib);
    const bench_test_step = b.step("bench", "Run benchmark tests");
    bench_test_step.dependOn(&run_bench_tests.step);
}
