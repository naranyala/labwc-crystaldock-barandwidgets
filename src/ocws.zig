const std = @import("std");
const process = std.process;

extern "c" fn printf(format: [*:0]const u8, ...) c_int;
extern "c" fn fprintf(file: ?*anyopaque, format: [*:0]const u8, ...) c_int;
extern "c" fn strcmp(s1: [*:0]const u8, s2: [*:0]const u8) c_int;
extern "c" fn fork() c_int;
extern "c" fn execvp(file: [*:0]const u8, argv: [*:null]const ?[*:0]const u8) c_int;
extern "c" fn execlp(file: [*:0]const u8, ...) c_int;
extern "c" fn waitpid(pid: c_int, status: *c_int, options: c_int) c_int;
extern "c" fn access(path: [*:0]const u8, mode: c_int) c_int;
extern "c" fn mkdir(path: [*:0]const u8, mode: c_uint) c_int;
extern "c" fn getenv(name: [*:0]const u8) ?[*:0]const u8;
extern "c" fn _exit(status: c_int) noreturn;

extern const stderr: ?*anyopaque;
const F_OK = 0;
const WNOHANG = 1;

fn WIFEXITED(status: c_int) bool {
    return (status & 0x7f) == 0;
}

fn WEXITSTATUS(status: c_int) c_int {
    return (status >> 8) & 0xff;
}

const VERSION = "0.1.0";

const Subcommand = struct {
    name: [*:0]const u8,
    description: [*:0]const u8,
    builtin: bool,
};

const subcommands = [_]Subcommand{
    .{ .name = "shot", .description = "Screenshot tool (grim + slurp)", .builtin = false },
    .{ .name = "clip", .description = "Clipboard manager (cliphist + fuzzel)", .builtin = false },
    .{ .name = "lock", .description = "Screen lock wrapper (swaylock)", .builtin = false },
    .{ .name = "sysmon", .description = "System metrics (CPU/mem/net/bat)", .builtin = false },
    .{ .name = "brightness", .description = "Smooth backlight control", .builtin = false },
    .{ .name = "volume", .description = "Smooth PulseAudio control", .builtin = false },
    .{ .name = "recorder", .description = "Screen recording (wf-recorder)", .builtin = false },
    .{ .name = "emit", .description = "Event Bus API for UI state", .builtin = false },
    .{ .name = "search", .description = "Web query search with fuzzel", .builtin = false },
    .{ .name = "kv", .description = "Key-value persistent store", .builtin = false },
    .{ .name = "color", .description = "Wallpaper palette extraction", .builtin = false },
    .{ .name = "ocr", .description = "Screen OCR (Tesseract)", .builtin = false },
    .{ .name = "notify", .description = "Native D-Bus notification daemon", .builtin = false },
    .{ .name = "wallpaper", .description = "Time-of-day wallpaper transitions", .builtin = false },
    .{ .name = "live-bg", .description = "Animated live background", .builtin = false },
    .{ .name = "osd-notify", .description = "Glassmorphic notification popup", .builtin = false },
    .{ .name = "hypertile", .description = "Dynamic tiling for labwc", .builtin = false },
    .{ .name = "settings", .description = "GTK3 settings GUI", .builtin = false },
    .{ .name = "help", .description = "Show this help message", .builtin = true },
};

fn eql(a: [*:0]const u8, b: [*:0]const u8) bool {
    return strcmp(a, b) == 0;
}

fn bufPrintZ(buf: []u8, comptime fmt: []const u8, args: anytype) [*:0]const u8 {
    return std.fmt.bufPrintZ(buf, fmt, args) catch unreachable;
}

fn printHelp() void {
    _ = printf(
        \\ocws — Our C-Written Shell (unified harness)
        \\
        \\Usage: ocws <subcommand> [args...]
        \\
        \\Subcommands:
        \\
    );
    for (subcommands) |sc| {
        _ = printf("  %-16s %s\n", sc.name, sc.description);
    }
    _ = printf(
        \\
        \\Built-in:
        \\  ocws status            Show system status
        \\  ocws rebuild           Rebuild all C utilities
        \\  ocws install           Build and install to ~/.local/bin/
        \\  ocws list              List all available binaries
        \\  ocws version           Show version info
        \\  ocws help              Show this help message
        \\
        \\Examples:
        \\  ocws shot              Take a screenshot
        \\  ocws brightness +10    Increase brightness by 10%
        \\  ocws kv set foo bar    Set key-value pair
        \\
    );
}

fn printVersion() void {
    _ = printf("ocws %s\n", VERSION);
}

fn execExternal(name: [*:0]const u8, argc: c_int, argv: [*c][*:0]const u8) void {
    var buf: [256]u8 = undefined;
    const path = bufPrintZ(&buf, "zig-out/bin/ocws-{s}", .{name});

    const pid = fork();
    if (pid == 0) {
        var new_argv_buf: [65]?[*:0]const u8 = undefined;
        new_argv_buf[0] = path;
        var i: usize = 1;
        var j: usize = 2;
        while (j < @as(usize, @intCast(argc))) : (j += 1) {
            if (i >= 63) break;
            new_argv_buf[i] = argv[j];
            i += 1;
        }
        new_argv_buf[i] = null;
        const new_argv: [*:null]const ?[*:0]const u8 = @ptrCast(&new_argv_buf);
        _ = execvp(path, new_argv);
        _ = fprintf(stderr, "ocws: command not found: %s\n", name);
        _exit(1);
    } else if (pid > 0) {
        var status: c_int = 0;
        _ = waitpid(pid, &status, 0);
        if (WIFEXITED(status)) {
            _exit(WEXITSTATUS(status));
        } else {
            _exit(1);
        }
    } else {
        _ = fprintf(stderr, "ocws: fork failed\n");
    }
}

fn printGodHelp() void {
    _ = printf(
        \\ocws — Built-in admin operations
        \\
        \\Usage: ocws <command> [args...]
        \\
        \\Commands:
        \\  status      Show system status (binaries, configs, health)
        \\  rebuild     Rebuild all C utilities with zig build
        \\  install     Build and install to ~/.local/bin/
        \\  list        List all available binaries
        \\  help        Show this help message
        \\
    );
}

fn printGodStatus() void {
    _ = printf("ocws: system status\n");
    _ = printf("  Version: %s\n", VERSION);
    _ = printf("  Binaries:\n");

    for (subcommands) |sc| {
        if (!sc.builtin) {
            var buf: [128]u8 = undefined;
            const path = bufPrintZ(&buf, "zig-out/bin/ocws-{s}", .{sc.name});
            if (access(path, F_OK) == 0) {
                _ = printf("    \x1b[32m✓\x1b[0m ocws-%s\n", sc.name);
            } else {
                _ = printf("    \x1b[31m✗\x1b[0m ocws-%s (not built)\n", sc.name);
            }
        }
    }
}

fn runGodRebuild() void {
    _ = printf("ocws: rebuilding all C utilities...\n");
    const pid = fork();
    if (pid == 0) {
        _ = execlp("zig", "zig", "build", @as(?[*:0]const u8, null));
        _exit(1);
    } else if (pid > 0) {
        var status: c_int = 0;
        _ = waitpid(pid, &status, 0);
        if (WIFEXITED(status) and WEXITSTATUS(status) == 0) {
            _ = printf("ocws: rebuild successful\n");
        } else {
            _ = fprintf(stderr, "ocws: rebuild failed\n");
        }
    }
}

fn runGodInstall() void {
    _ = printf("ocws: building release and installing to ~/.local/bin/\n");

    const pid = fork();
    if (pid == 0) {
        _ = execlp("zig", "zig", "build", "-Doptimize=ReleaseFast", @as(?[*:0]const u8, null));
        _exit(1);
    } else if (pid > 0) {
        var status: c_int = 0;
        _ = waitpid(pid, &status, 0);
        if (!WIFEXITED(status) or WEXITSTATUS(status) != 0) {
            _ = fprintf(stderr, "ocws: build failed\n");
            return;
        }
    }

    const home = getenv("HOME");
    if (home == null) {
        _ = fprintf(stderr, "ocws: HOME not set\n");
        return;
    }

    var hbuf: [512]u8 = undefined;
    const home_span = std.mem.span(home.?);
    const bin_dir_path = bufPrintZ(&hbuf, "{s}/.local/bin", .{home_span});
    _ = mkdir(bin_dir_path, 0o755);

    for (subcommands) |sc| {
        if (!sc.builtin) {
            var src_buf: [128]u8 = undefined;
            const src = bufPrintZ(&src_buf, "zig-out/bin/ocws-{s}", .{sc.name});
            var dst_buf: [128]u8 = undefined;
            const dst = bufPrintZ(&dst_buf, "{s}/ocws-{s}", .{ home_span, sc.name });
            const cp_pid = fork();
            if (cp_pid == 0) {
                _ = execlp("cp", "cp", src, dst, @as(?[*:0]const u8, null));
                _exit(1);
            } else if (cp_pid > 0) {
                var st: c_int = 0;
                _ = waitpid(cp_pid, &st, 0);
            }
        }
    }

    var unified_dst: [128]u8 = undefined;
    const dst_path = bufPrintZ(&unified_dst, "{s}/ocws", .{home_span});
    const cp_pid = fork();
    if (cp_pid == 0) {
        _ = execlp("cp", "cp", "zig-out/bin/ocws", dst_path, @as(?[*:0]const u8, null));
        _exit(1);
    } else if (cp_pid > 0) {
        var st: c_int = 0;
        _ = waitpid(cp_pid, &st, 0);
    }

    _ = printf("ocws: installed to %s\n", bin_dir_path);
}

fn runList() void {
    _ = printf("ocws: available binaries:\n");
    for (subcommands) |sc| {
        if (!sc.builtin) {
            _ = printf("  ocws-%s\n", sc.name);
        }
    }
}

fn runAdmin(argc: c_int, argv: [*c][*:0]const u8) void {
    if (argc <= 2) {
        printHelp();
        return;
    }

    const cmd = argv[2];
    if (eql(cmd, "help") or eql(cmd, "--help") or eql(cmd, "-h")) {
        printHelp();
    } else if (eql(cmd, "status")) {
        printGodStatus();
    } else if (eql(cmd, "rebuild")) {
        runGodRebuild();
    } else if (eql(cmd, "install")) {
        runGodInstall();
    } else if (eql(cmd, "list")) {
        runList();
    } else {
        _ = fprintf(stderr, "ocws: unknown command: %s\n", cmd);
        printHelp();
    }
}

pub fn main(init: process.Init) void {
    const argc: c_int = @intCast(init.minimal.args.vector.len);
    const argv_ptr: [*c][*:0]const u8 = @ptrCast(@constCast(init.minimal.args.vector.ptr));

    if (argc <= 1) {
        printHelp();
        return;
    }

    const subcmd = argv_ptr[1];

    if (eql(subcmd, "help") or eql(subcmd, "--help") or eql(subcmd, "-h")) {
        printHelp();
    } else if (eql(subcmd, "version") or eql(subcmd, "--version") or eql(subcmd, "-v")) {
        printVersion();
    } else if (eql(subcmd, "status")) {
        printGodStatus();
    } else if (eql(subcmd, "rebuild")) {
        runGodRebuild();
    } else if (eql(subcmd, "install")) {
        runGodInstall();
    } else if (eql(subcmd, "list")) {
        runList();
    } else {
        execExternal(subcmd, argc, argv_ptr);
    }
}
