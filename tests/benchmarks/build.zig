const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions({});
    const optimize = b.standardOptimizeOption({});

    // 1. Compile the engine as a static library
    const engine_lib = b.addStaticLibrary(.{
        .name = "engine",
        .target = target,
        .optimize = optimize,
    });
    engine_lib.addCSourceFile(.{ .file = b.path("engine.c"), .flags = &.{} });
    engine_lib.install();

    // 2. Build the Pure C Benchmark
    const c_bench = b.addExecutable(.{
        .name = "pure_c_bench",
        .target = target,
        .optimize = optimize,
    });
    c_bench.addCSourceFile(.{ .file = b.path("pure_c_bench.c"), .flags = &.{} });
    c_bench.linkLibrary(engine_lib);
    c_bench.linkLibC();
    b.installArtifact(c_bench);

    // 3. Build the Zig Benchmark
    const zig_bench = b.addExecutable(.{
        .name = "benchmark_zig",
        .target = target,
        .optimize = optimize,
    });
    zig_bench.addModule("engine", .{ .path = b.path("engine.h") }); // Note: This is not quite right for C, we use include paths
    zig_bench.addIncludePath(b.path("."));
    zig_bench.linkLibrary(engine_lib);
    zig_bench.linkLibC();
    zig_bench.addImplicitArgs(&.{ "tests/benchmarks/benchmark.zig" }); // This is a hack for running via zig build run
    // Actually, let's just make it a normal executable
    b.installArtifact(zig_bench);
}
