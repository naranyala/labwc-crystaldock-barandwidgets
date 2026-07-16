// launcher_test.zig — Unit tests for launcher panel grid math
//
// Tests the pure layout/hit-testing logic extracted from main_shell.zig
// without requiring Wayland or Blend2D dependencies.

const std = @import("std");

// ---- Constants matching main_shell.zig ----
const LAUNCHER_W: i32 = 520;
const LAUNCHER_H: i32 = 420;
const LAUNCHER_COLS: i32 = 2;
const LAUNCHER_ROW_H: i32 = 56;
const LAUNCHER_X: i32 = 24;
const LAUNCHER_PAD: i32 = 12;

// ---- Pure math functions (mirrors main_shell.zig) ----

fn launcherVisibleRows() i32 {
    const area = LAUNCHER_H - LAUNCHER_PAD * 2;
    return area / LAUNCHER_ROW_H;
}

/// Mirrors the hit-test logic from main_shell.zig launcherItemAt().
/// Returns the index of the item at (mx, my), or -1 if no hit.
fn launcherItemAt(mx: i32, my: i32, total_items: i32, scroll: i32) i32 {
    const rows = launcherVisibleRows();
    const start = @as(usize, @intCast(scroll)) * @as(usize, LAUNCHER_COLS);
    var col: i32 = 0;
    var row: i32 = 0;
    var idx: usize = start;
    while (col < LAUNCHER_COLS) : (col += 1) {
        row = 0;
        while (row < rows) : (row += 1) {
            if (@as(i32, @intCast(idx)) >= total_items) return -1;
            const y = LAUNCHER_PAD + row * LAUNCHER_ROW_H;
            if (my >= y and my < y + LAUNCHER_ROW_H - 4) {
                if (mx >= LAUNCHER_X + col * @divTrunc(LAUNCHER_W, 2) and
                    mx < LAUNCHER_X + col * @divTrunc(LAUNCHER_W, 2) + (@divTrunc(LAUNCHER_W, 2) - LAUNCHER_PAD))
                {
                    return @intCast(idx);
                }
            }
            idx += 1;
        }
    }
    return -1;
}

// ---- Visible rows tests ----

test "launcherVisibleRows — returns correct count" {
    const rows = launcherVisibleRows();
    // (420 - 24) / 56 = 396 / 56 = 7
    try std.testing.expectEqual(@as(i32, 7), rows);
}

test "launcherVisibleRows — positive" {
    try std.testing.expect(launcherVisibleRows() > 0);
}

// ---- Hit-test basic cases ----

test "launcherItemAt — first item (top-left)" {
    // Item 0 is at col=0, row=0
    const y = LAUNCHER_PAD + 0 * LAUNCHER_ROW_H + 10; // inside first row
    const x = LAUNCHER_X + 10; // inside first column
    const result = launcherItemAt(x, y, 100, 0);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "launcherItemAt — second item (col=0, row=1)" {
    // Items fill column-first: item 0 = col0,row0; item 1 = col0,row1
    const y = LAUNCHER_PAD + LAUNCHER_ROW_H + 10; // row 1
    const x = LAUNCHER_X + 10; // col 0
    const result = launcherItemAt(x, y, 100, 0);
    try std.testing.expectEqual(@as(i32, 1), result);
}

test "launcherItemAt — third item (col=0, row=2)" {
    // Item 2 = col0,row2
    const y = LAUNCHER_PAD + 2 * LAUNCHER_ROW_H + 10; // row 2
    const x = LAUNCHER_X + 10; // col 0
    const result = launcherItemAt(x, y, 100, 0);
    try std.testing.expectEqual(@as(i32, 2), result);
}

test "launcherItemAt — miss above grid" {
    const result = launcherItemAt(LAUNCHER_X + 10, 5, 100, 0); // y=5 is above LAUNCHER_PAD=12
    try std.testing.expectEqual(@as(i32, -1), result);
}

test "launcherItemAt — miss below grid" {
    const result = launcherItemAt(LAUNCHER_X + 10, LAUNCHER_H - 1, 100, 0);
    try std.testing.expectEqual(@as(i32, -1), result);
}

test "launcherItemAt — miss left of grid" {
    const result = launcherItemAt(5, LAUNCHER_PAD + 10, 100, 0); // x=5 is before LAUNCHER_X=24
    try std.testing.expectEqual(@as(i32, -1), result);
}

test "launcherItemAt — miss right of grid" {
    // Right column ends at LAUNCHER_X + LAUNCHER_W/2 + (LAUNCHER_W/2 - LAUNCHER_PAD)
    const right_edge = LAUNCHER_X + @divTrunc(LAUNCHER_W, 2) + (@divTrunc(LAUNCHER_W, 2) - LAUNCHER_PAD);
    const result = launcherItemAt(right_edge + 1, LAUNCHER_PAD + 10, 100, 0);
    try std.testing.expectEqual(@as(i32, -1), result);
}

// ---- Scroll tests ----

test "launcherItemAt — scroll shifts visible items" {
    const y_row0 = LAUNCHER_PAD + 10;
    const x_col0 = LAUNCHER_X + 10;

    // scroll=1 means start=1*2=2, so col=0,row=0 shows index 2
    const result = launcherItemAt(x_col0, y_row0, 100, 1);
    try std.testing.expectEqual(@as(i32, 2), result);
}

test "launcherItemAt — scroll=2 shows items starting at index 4" {
    const y_row0 = LAUNCHER_PAD + 10;
    const x_col0 = LAUNCHER_X + 10;
    // scroll=2 means start=2*2=4
    const result = launcherItemAt(x_col0, y_row0, 100, 2);
    try std.testing.expectEqual(@as(i32, 4), result);
}

test "launcherItemAt — scroll beyond items returns -1" {
    const y_row0 = LAUNCHER_PAD + 10;
    const x_col0 = LAUNCHER_X + 10;
    // scroll=100 means start at index 200, but only 10 items exist
    const result = launcherItemAt(x_col0, y_row0, 10, 100);
    try std.testing.expectEqual(@as(i32, -1), result);
}

// ---- Boundary tests ----

test "launcherItemAt — exact row boundary (top edge inclusive)" {
    const y = LAUNCHER_PAD; // exact top of first row
    const x = LAUNCHER_X + 10;
    const result = launcherItemAt(x, y, 100, 0);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "launcherItemAt — row boundary (bottom edge exclusive)" {
    // y = LAUNCHER_PAD + LAUNCHER_ROW_H - 4 is the last pixel in the row
    const y = LAUNCHER_PAD + LAUNCHER_ROW_H - 5; // still inside row
    const x = LAUNCHER_X + 10;
    const result = launcherItemAt(x, y, 100, 0);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "launcherItemAt — row boundary (just past bottom)" {
    // Row 0 covers y in [LAUNCHER_PAD, LAUNCHER_PAD + LAUNCHER_ROW_H - 4)
    // y = LAUNCHER_PAD + LAUNCHER_ROW_H is the start of row 1
    const y = LAUNCHER_PAD + LAUNCHER_ROW_H;
    const x = LAUNCHER_X + 10;
    const result = launcherItemAt(x, y, 100, 0);
    // col=0,row=1 = index 1 in column-first layout
    try std.testing.expectEqual(@as(i32, 1), result);
}

test "launcherItemAt — column boundary (left edge inclusive)" {
    const y = LAUNCHER_PAD + 10;
    const x = LAUNCHER_X; // exact left edge of col 0
    const result = launcherItemAt(x, y, 100, 0);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "launcherItemAt — column boundary between cols" {
    const y = LAUNCHER_PAD + 10;
    const mid = LAUNCHER_X + @divTrunc(LAUNCHER_W, 2); // start of col 1
    const result = launcherItemAt(mid, y, 100, 0);
    // col=1,row=0 = index 7 (col 0 has 7 rows: indices 0-6)
    try std.testing.expectEqual(@as(i32, 7), result);
}

// ---- Few items ----

test "launcherItemAt — single item only hits first cell" {
    const y = LAUNCHER_PAD + 10;
    const x = LAUNCHER_X + 10;
    const r0 = launcherItemAt(x, y, 1, 0);
    try std.testing.expectEqual(@as(i32, 0), r0);
    // Second cell (col=1) is past the single item
    const x2 = LAUNCHER_X + @divTrunc(LAUNCHER_W, 2) + 10;
    const r1 = launcherItemAt(x2, y, 1, 0);
    try std.testing.expectEqual(@as(i32, -1), r1);
}

test "launcherItemAt — zero items always returns -1" {
    const y = LAUNCHER_PAD + 10;
    const x = LAUNCHER_X + 10;
    const result = launcherItemAt(x, y, 0, 0);
    try std.testing.expectEqual(@as(i32, -1), result);
}

// ---- Constants sanity ----

test "launcher constants — positive dimensions" {
    try std.testing.expect(LAUNCHER_W > 0);
    try std.testing.expect(LAUNCHER_H > 0);
    try std.testing.expect(LAUNCHER_COLS > 0);
    try std.testing.expect(LAUNCHER_ROW_H > 0);
    try std.testing.expect(LAUNCHER_X >= 0);
    try std.testing.expect(LAUNCHER_PAD >= 0);
}

test "launcher constants — row height fits in panel" {
    try std.testing.expect(LAUNCHER_ROW_H <= LAUNCHER_H);
}

test "launcher constants — padding doesn't exceed dimensions" {
    try std.testing.expect(LAUNCHER_PAD * 2 < LAUNCHER_H);
    try std.testing.expect(LAUNCHER_X < @divTrunc(LAUNCHER_W, 2));
}
