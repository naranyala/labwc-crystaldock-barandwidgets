const std = @import("std");
pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    var args = try init.args.toSlice(allocator);
    defer allocator.free(args);
    _ = init.io;
    for (args) |arg| {
        std.debug.print("{s}\n", .{arg});
    }
}
