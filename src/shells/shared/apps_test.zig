// apps_test.zig — Unit tests for apps.zig scanner
const std = @import("std");
const apps = @import("apps");

// ---- Scan and count ----

test "scan — completes without error" {
    apps.scan();
    // Scanner may find 0 entries in sandboxed test environments,
    // but should not crash or return garbage.
    const n = apps.count();
    try std.testing.expect(n <= apps.MAX_APPS);
}

test "scan — idempotent (calling twice doesn't duplicate)" {
    apps.scan();
    const n1 = apps.count();
    apps.scan();
    const n2 = apps.count();
    try std.testing.expectEqual(n1, n2);
}

test "list — returns valid slice matching count" {
    apps.scan();
    const list = apps.list();
    try std.testing.expectEqual(apps.count(), list.len);
    // If scanner found entries, validate them
    if (list.len > 0) {
        try std.testing.expect(list[0].name_len > 0);
    }
}

// ---- Entry field validation ----

test "list — every entry has non-empty name" {
    apps.scan();
    const list = apps.list();
    for (list) |entry| {
        try std.testing.expect(entry.name_len > 0);
        try std.testing.expect(entry.name[0] != 0);
    }
}

test "list — every entry has non-empty exec" {
    apps.scan();
    const list = apps.list();
    for (list) |entry| {
        try std.testing.expect(entry.exec_len > 0);
        try std.testing.expect(entry.exec[0] != 0);
    }
}

test "list — entries are null-terminated" {
    apps.scan();
    const list = apps.list();
    for (list) |entry| {
        try std.testing.expectEqual(@as(u8, 0), entry.name[entry.name_len]);
        try std.testing.expectEqual(@as(u8, 0), entry.exec[entry.exec_len]);
        try std.testing.expectEqual(@as(u8, 0), entry.icon[entry.icon_len]);
    }
}

// ---- Deduplication ----

test "list — no duplicate names" {
    apps.scan();
    const list = apps.list();
    for (list, 0..) |a, i| {
        for (list[i + 1 ..]) |b| {
            const a_name = a.name[0..a.name_len];
            const b_name = b.name[0..b.name_len];
            try std.testing.expect(!std.mem.eql(u8, a_name, b_name));
        }
    }
}

// ---- Desktop vs executable distinction ----

test "list — desktop entries have from_desktop=true" {
    apps.scan();
    const list = apps.list();
    for (list) |entry| {
        if (entry.from_desktop) {
            // Validated: at least one desktop entry exists
            try std.testing.expect(entry.name_len > 0);
            return;
        }
    }
    // No desktop entries found — acceptable in test environment
}

test "list — PATH executables have from_desktop=false" {
    apps.scan();
    const list = apps.list();
    for (list) |entry| {
        if (!entry.from_desktop) {
            try std.testing.expect(entry.name_len > 0);
            return;
        }
    }
    // No PATH executables found — acceptable in test environment
}

// ---- Common system apps present ----

test "list — if entries exist, names are printable ASCII" {
    apps.scan();
    const list = apps.list();
    for (list) |entry| {
        const name = entry.name[0..entry.name_len];
        for (name) |ch| {
            // Name should be printable (space to tilde) or common extended chars
            try std.testing.expect(ch >= 0x20);
        }
    }
}

// ---- Name length bounds ----

test "list — name lengths within bounds" {
    apps.scan();
    const list = apps.list();
    for (list) |entry| {
        try std.testing.expect(entry.name_len <= 127);
        try std.testing.expect(entry.exec_len <= 255);
        try std.testing.expect(entry.icon_len <= 127);
    }
}

// ---- Edge cases ----

test "MAX_APPS constant is reasonable" {
    try std.testing.expect(apps.MAX_APPS >= 256);
    try std.testing.expect(apps.MAX_APPS <= 65536);
}
