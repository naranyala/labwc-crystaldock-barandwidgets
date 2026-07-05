const std = @import("std");
pub fn main(args: [][:0]u8) !void {
    for (args) |arg| {
        std.debug.print("{s}\n", .{arg});
    }
}
