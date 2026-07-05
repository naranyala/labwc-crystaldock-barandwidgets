const std = @import("std");
pub fn main() !void {
    inline for (@typeInfo(std.process).Struct.decls) |decl| {
        std.debug.print("{s}\n", .{decl.name});
    }
}
