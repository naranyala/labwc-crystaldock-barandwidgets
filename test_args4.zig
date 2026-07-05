const std = @import("std");
pub fn main(init: std.process.Init.Minimal) !void {
    var args = init.args.iterate();
    while (args.next()) |arg| {
        std.debug.print("{s}\n", .{arg});
    }
}
