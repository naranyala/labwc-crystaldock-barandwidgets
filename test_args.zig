const std = @import("std");
pub fn main() !void {
    var args = try std.process.argsAlloc(std.heap.page_allocator);
    _ = args;
}
