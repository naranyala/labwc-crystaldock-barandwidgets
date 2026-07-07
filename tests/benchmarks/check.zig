const std = @import("std");

pub fn main() void {
    std.debug.print("std.time: {any}\n", .{@typeInfo(@TypeOf(std.time))});
}
