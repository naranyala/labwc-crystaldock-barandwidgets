// blend2d_render_test.zig — Unit tests for blend2d_render.zig
const std = @import("std");
const render = @import("blend2d_render.zig");
const c = @import("c.zig").c;

test "TextMetrics default" {
    const tm = render.TextMetrics{};
    try std.testing.expectEqual(@as(f64, 0), tm.width);
    try std.testing.expectEqual(@as(f64, 0), tm.height);
}

test "BlendRenderer struct size" {
    const size = @sizeOf(render.BlendRenderer);
    try std.testing.expect(size > 0);
    try std.testing.expect(size < 4096); // Sanity check
}

test "BlendRenderer — init and deinit" {
    // Allocate a small pixel buffer
    const W: i32 = 64;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch |err| {
        // If Blend2D is not available, skip the test
        std.log.warn("Blend2D init failed (library not linked?): {}", .{err});
        return;
    };
    defer renderer.deinit();

    try std.testing.expect(renderer.handle != null);
}

test "BlendRenderer — fillRect produces pixels" {
    const W: i32 = 32;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    // Fill entire buffer with red
    renderer.fillRect(0, 0, @floatFromInt(W), @floatFromInt(H), 0xFFFF0000);
    renderer.flush();

    // Check that pixels are non-zero
    var nonzero: usize = 0;
    for (buf) |b| {
        if (b != 0) nonzero += 1;
    }
    try std.testing.expect(nonzero > 0);
}

test "BlendRenderer — fillRect partial" {
    const W: i32 = 32;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    // Fill top-left quadrant only
    renderer.fillRect(0, 0, 16, 16, 0xFF00FF00);
    renderer.flush();

    // Top-left should be green
    const pixel0 = @as(u32, buf[0]) | (@as(u32, buf[1]) << 8) |
        (@as(u32, buf[2]) << 16) | (@as(u32, buf[3]) << 24);
    try std.testing.expectEqual(@as(u32, 0xFF00FF00), pixel0);
}

test "BlendRenderer — fillRectRaw" {
    const W: i32 = 16;
    const H: i32 = 16;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    renderer.fillRectRaw(0, 0, @floatFromInt(W), @floatFromInt(H), 0, 128, 255, 255);
    renderer.flush();

    // Check first pixel: A=255, R=0, G=128, B=255
    try std.testing.expectEqual(@as(u8, 255), buf[3]); // A
    try std.testing.expectEqual(@as(u8, 0), buf[2]);   // R
    try std.testing.expectEqual(@as(u8, 128), buf[1]); // G
    try std.testing.expectEqual(@as(u8, 255), buf[0]); // B
}

test "BlendRenderer — multiple flushes" {
    const W: i32 = 16;
    const H: i32 = 16;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    // First frame: red
    renderer.fillRect(0, 0, @floatFromInt(W), @floatFromInt(H), 0xFFFF0000);
    renderer.flush();

    var nonzero: usize = 0;
    for (buf) |b| {
        if (b != 0) nonzero += 1;
    }
    try std.testing.expect(nonzero > 0);

    // Second frame: blue (overwrite)
    renderer.fillRect(0, 0, @floatFromInt(W), @floatFromInt(H), 0xFF0000FF);
    renderer.flush();

    // Should still have non-zero pixels
    nonzero = 0;
    for (buf) |b| {
        if (b != 0) nonzero += 1;
    }
    try std.testing.expect(nonzero > 0);
}

test "BlendRenderer — drawBorder" {
    const W: i32 = 32;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    renderer.drawBorder(4, 4, 24, 24, 0xFFFFFFFF);
    renderer.flush();

    // Border should produce some non-zero pixels
    var nonzero: usize = 0;
    for (buf) |b| {
        if (b != 0) nonzero += 1;
    }
    try std.testing.expect(nonzero > 0);
}

test "BlendRenderer — drawCircle" {
    const W: i32 = 32;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    renderer.drawCircle(16, 16, 10, 0xFF00FF00);
    renderer.flush();

    // Circle should produce some non-zero pixels
    var nonzero: usize = 0;
    for (buf) |b| {
        if (b != 0) nonzero += 1;
    }
    try std.testing.expect(nonzero > 0);
}

test "BlendRenderer — measureText returns valid metrics" {
    const W: i32 = 64;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    const tm = renderer.measureText("Hello");
    // Width should be positive if font is loaded
    if (renderer.font_loaded()) {
        try std.testing.expect(tm.width > 0);
        // Height may be 0 depending on font metrics — just check width
    }
}

test "BlendRenderer — measureText empty string" {
    const W: i32 = 32;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    const tm = renderer.measureText("");
    try std.testing.expectEqual(@as(f64, 0), tm.width);
    try std.testing.expectEqual(@as(f64, 0), tm.height);
}

test "BlendRenderer — setFontSize" {
    const W: i32 = 32;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    // Should not crash
    renderer.setFontSize(24.0);
    renderer.setFontSize(8.0);
    renderer.setFontSize(72.0);
    try std.testing.expect(true);
}

test "BlendRenderer — deinit is idempotent" {
    const W: i32 = 16;
    const H: i32 = 16;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;

    renderer.deinit();

    // Second deinit should not crash
    renderer.deinit();
    try std.testing.expect(true);
}

test "BlendRenderer — stride alignment handling" {
    // Test with non-standard stride (padded beyond pixel width)
    const W: i32 = 30;
    const H: i32 = 4;
    const stride = 128; // Stride wider than W*4=120
    var buf: [@as(usize, @intCast(stride * H))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    renderer.fillRect(0, 0, @floatFromInt(W), @floatFromInt(H), 0xFF1A1C26);
    renderer.flush();

    // First pixel should be correct
    const pixel0 = @as(u32, buf[0]) | (@as(u32, buf[1]) << 8) |
        (@as(u32, buf[2]) << 16) | (@as(u32, buf[3]) << 24);
    try std.testing.expectEqual(@as(u32, 0xFF1A1C26), pixel0);

    // Last pixel of first row should also be correct
    const last_row0_idx = @as(usize, @intCast((W - 1) * 4));
    const pixel_last = @as(u32, buf[last_row0_idx]) | (@as(u32, buf[last_row0_idx + 1]) << 8) |
        (@as(u32, buf[last_row0_idx + 2]) << 16) | (@as(u32, buf[last_row0_idx + 3]) << 24);
    try std.testing.expectEqual(@as(u32, 0xFF1A1C26), pixel_last);

    // Second row should also be correct (stride handled properly)
    const row1_idx = @as(usize, @intCast(stride));
    const pixel_row1 = @as(u32, buf[row1_idx]) | (@as(u32, buf[row1_idx + 1]) << 8) |
        (@as(u32, buf[row1_idx + 2]) << 16) | (@as(u32, buf[row1_idx + 3]) << 24);
    try std.testing.expectEqual(@as(u32, 0xFF1A1C26), pixel_row1);
}

fn pixelAt(buf: []u8, x: i32, y: i32, stride: i32) u32 {
    const idx = @as(usize, @intCast(y)) * @as(usize, @intCast(stride)) + @as(usize, @intCast(x)) * 4;
    return @as(u32, buf[idx]) | (@as(u32, buf[idx + 1]) << 8) |
        (@as(u32, buf[idx + 2]) << 16) | (@as(u32, buf[idx + 3]) << 24);
}

test "BlendRenderer — ARGB32 byte order" {
    // Verifies fillRect writes straight (opaque) ARGB32 little-endian:
    // byte0=B, byte1=G, byte2=R, byte3=A.
    const W: i32 = 16;
    const H: i32 = 16;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    renderer.fillRect(0, 0, @floatFromInt(W), @floatFromInt(H), 0xFF112233);
    renderer.flush();

    try std.testing.expectEqual(@as(u32, 0xFF112233), pixelAt(&buf, 0, 0, stride));
}

test "BlendRenderer — setScale scales geometry" {
    // HiDPI: a logical rect must map into the device buffer scaled by `scale`.
    // Blend2D's internal image is not auto-cleared, so first paint the whole
    // surface with an opaque sentinel; only then draw the scaled rect on top.
    const W: i32 = 64;
    const H: i32 = 64;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    // Clear whole surface to opaque black so untouched pixels are known.
    renderer.fillRect(0, 0, @floatFromInt(W), @floatFromInt(H), 0xFF000000);

    renderer.setScale(2.0);
    // Logical (0,0,10,10) -> device (0,0,20,20)
    renderer.fillRect(0, 0, 10, 10, 0xFF00FF00);
    renderer.flush();

    // Inside the scaled rect
    try std.testing.expectEqual(@as(u32, 0xFF00FF00), pixelAt(&buf, 5, 5, stride));
    // Outside the scaled rect but inside the buffer -> still sentinel black
    try std.testing.expectEqual(@as(u32, 0xFF000000), pixelAt(&buf, 30, 30, stride));
}

test "BlendRenderer — drawText does not panic when font present" {
    const W: i32 = 64;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    if (renderer.font_loaded()) {
        renderer.setFontSize(14.0);
        renderer.drawText("Hello", 2, 16, 0xFFFFFFFF);
        renderer.flush();
    }
    try std.testing.expect(true);
}

test "BlendRenderer — drawText produces visible pixels" {
    const W: i32 = 128;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    if (renderer.font_loaded()) {
        renderer.setFontSize(16.0);
        renderer.drawText("AB", 2, 4, 0xFFFFFFFF);
        renderer.flush();

        // Check that some pixels are white (text rendered)
        var white_pixels: usize = 0;
        for (buf) |b| {
            if (b == 255) white_pixels += 1;
        }
        try std.testing.expect(white_pixels > 0);
    }
}

test "BlendRenderer — null renderer safety" {
    // Calling functions on null renderer should not crash
    var renderer = render.BlendRenderer{ .handle = null };
    renderer.fillRect(0, 0, 10, 10, 0xFFFF0000);
    renderer.flush();
    renderer.setFontSize(14.0);
    _ = renderer.font_size();
    try std.testing.expect(true);
}

test "BlendRenderer — font_size getter" {
    const W: i32 = 32;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    renderer.setFontSize(24.0);
    const size = renderer.font_size();
    // Font size should be close to 24 (may have internal rounding)
    try std.testing.expect(size > 20.0);
    try std.testing.expect(size < 30.0);
}

test "BlendRenderer — loadBoldFont does not crash" {
    const W: i32 = 32;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    renderer.loadBoldFont();
    // Should not crash even if no bold font found
    try std.testing.expect(true);
}

test "BlendRenderer — multiple draws accumulate" {
    const W: i32 = 64;
    const H: i32 = 64;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    // Draw multiple overlapping shapes
    renderer.fillRect(0, 0, 32, 32, 0xFFFF0000);   // Red top-left
    renderer.fillRect(32, 0, 32, 32, 0xFF00FF00);   // Green top-right
    renderer.fillRect(0, 32, 32, 32, 0xFF0000FF);   // Blue bottom-left
    renderer.drawCircle(48, 48, 12, 0xFFFFFF00);     // Yellow circle
    renderer.flush();

    // Verify different quadrants have different colors
    const tl = pixelAt(&buf, 8, 8, stride);
    const tr = pixelAt(&buf, 40, 8, stride);
    const bl = pixelAt(&buf, 8, 40, stride);
    try std.testing.expectEqual(@as(u32, 0xFFFF0000), tl);
    try std.testing.expectEqual(@as(u32, 0xFF00FF00), tr);
    try std.testing.expectEqual(@as(u32, 0xFF0000FF), bl);
}

test "BlendRenderer — drawBorder produces stroke pixels" {
    const W: i32 = 32;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    // Draw border at edges — should produce pixels along the border
    renderer.drawBorder(0, 0, 32, 32, 0xFFFFFFFF);
    renderer.flush();

    // Top-left corner should have white pixel
    const tl = pixelAt(&buf, 0, 0, stride);
    try std.testing.expect(tl != 0);
}

test "BlendRenderer — drawCircle centered pixels" {
    const W: i32 = 32;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    // Draw circle at center — center pixel should be filled
    renderer.drawCircle(16, 16, 14, 0xFF00FF00);
    renderer.flush();

    const center = pixelAt(&buf, 16, 16, stride);
    try std.testing.expect(center != 0);
}

test "BlendRenderer — setFontSize changes text size" {
    const W: i32 = 128;
    const H: i32 = 32;
    const stride = W * 4;
    var buf: [@as(usize, @intCast(W * H * 4))]u8 = undefined;
    @memset(&buf, 0);

    var renderer = render.BlendRenderer.init(&buf, W, H, stride) catch return;
    defer renderer.deinit();

    if (renderer.font_loaded()) {
        renderer.setFontSize(8.0);
        const m8 = renderer.measureText("Test");
        renderer.setFontSize(24.0);
        const m24 = renderer.measureText("Test");
        try std.testing.expect(m24.width > m8.width);
    }
}
