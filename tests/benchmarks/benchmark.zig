const std = @import("std");

const c = @cImport({
    @cInclude("engine.h");
});

pub fn main() !void {
    var timer: std.time.Timer = try std.time.Timer.start();

    // Test A: Latency
    timer.reset();
    var i: usize = 0;
    while (i < 1_000_000) : (i += 1) {
        _ = c.latency_test();
    }
    const latency_ns = timer.read();
    std.debug.print("LATENCY_ZIG: {d}\n", .{latency_ns});

    // Test B: Throughput
    const len = 1_000_000;
    const allocator = std.heap.page_allocator;
    const data = try allocator.alloc(i32, len);
    for (data, 0..) |*item, idx| item.* = @intCast(idx);

    timer.reset();
    c.throughput_test(data.ptr, len);
    const throughput_ns = timer.read();
    std.debug.print("THROUGHPUT_ZIG: {d}\n", .{throughput_ns});
    allocator.free(data);

    // Test C: Iteration
    var val: i32 = 0;
    timer.reset();
    var j: usize = 0;
    while (j < 1_000_000) : (j += 1) {
        val = c.iteration_test(val);
    }
    _ = val; 
    const iteration_ns = timer.read();
    std.debug.print("ITERATION_ZIG: {d}\n", .{iteration_ns});
}
