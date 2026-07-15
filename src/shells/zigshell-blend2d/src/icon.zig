// icon.zig — Zig wrapper for C icon functions (icon.c)
const std = @import("std");
const c = @import("c.zig").c;

pub fn clearCache() void {
    c.icon_clear_cache();
}

pub fn load(app_id: [*:0]const u8, size: i32) ?c.BLImageCore {
    var img: c.BLImageCore = std.mem.zeroes(c.BLImageCore);
    if (c.icon_load(app_id, @intCast(size), @ptrCast(&img))) {
        return img;
    }
    return null;
}

pub fn fallback(app_id: [*:0]const u8, size: i32) c.BLImageCore {
    const p: ?*c.BLImageCore = @ptrCast(@alignCast(c.icon_fallback(app_id, @intCast(size))));
    if (p) |ptr| return ptr.*;
    return std.mem.zeroes(c.BLImageCore);
}
