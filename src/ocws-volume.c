#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>
#include <getopt.h>
#include "ocws-easing.h"

static char opt_device[64] = "@DEFAULT_SINK@";
static int opt_step = 5;
static int opt_duration = 200;
static int opt_interval = 500;
static char opt_format[32] = "sh"; // "sh" or "json"

static int run_cmd(const char *cmd) {
    return system(cmd);
}

static int get_volume(void) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "pactl get-sink-volume %s 2>/dev/null | grep -oP '\\d+%%' | head -1 | tr -d '%%'", opt_device);
    FILE *f = popen(cmd, "r");
    if (!f) return -1;
    int vol = -1;
    fscanf(f, "%d", &vol);
    pclose(f);
    return vol;
}

static int is_muted(void) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "pactl get-sink-mute %s 2>/dev/null", opt_device);
    FILE *f = popen(cmd, "r");
    if (!f) return 0;
    char buf[64] = {0};
    fgets(buf, sizeof(buf), f);
    pclose(f);
    return strstr(buf, "yes") != NULL;
}

static void animate_to(int target, int duration_ms) {
    int cur = get_volume();
    if (cur < 0) cur = target;
    if (cur == target) return;

    if (target < 0) target = 0;
    if (target > 150) target = 150;

    int steps = duration_ms / 10;
    if (steps < 1) steps = 1;

    double start_val = (double)cur;
    double end_val = (double)target;

    for (int i = 1; i <= steps; i++) {
        double t = (double)i / steps;
        double eased = ease_out_cubic(t);
        int val = (int)(start_val + (end_val - start_val) * eased + 0.5);
        if (val < 0) val = 0;
        if (val > 150) val = 150;

        char cmd[256];
        snprintf(cmd, sizeof(cmd), "pactl set-sink-volume %s %d%% 2>/dev/null", opt_device, val);
        run_cmd(cmd);
        usleep(10000);
    }
    
    // Ensure final state is set properly
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "pactl set-sink-volume %s %d%% 2>/dev/null", opt_device, target);
    run_cmd(cmd);
}

static void pct(int percent) {
    if (percent < 0) percent = 0;
    if (percent > 150) percent = 150;
    
    if (opt_duration > 0) {
        animate_to(percent, opt_duration);
    } else {
        char cmd[256];
        snprintf(cmd, sizeof(cmd), "pactl set-sink-volume %s %d%% 2>/dev/null", opt_device, percent);
        run_cmd(cmd);
    }
}

static void adjust(int delta) {
    int cur = get_volume();
    if (cur < 0) cur = 50;

    int target = cur + (delta > 0 ? opt_step : -opt_step);
    if (target < 0) target = 0;
    if (target > 150) target = 150;

    if (opt_duration > 0) {
        animate_to(target, opt_duration);
    } else {
        char cmd[256];
        snprintf(cmd, sizeof(cmd), "pactl set-sink-volume %s %d%% 2>/dev/null", opt_device, target);
        run_cmd(cmd);
    }
}

static void toggle_mute(void) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "pactl set-sink-mute %s toggle 2>/dev/null", opt_device);
    run_cmd(cmd);
}

static const char* get_icon(int vol, int muted) {
    if (muted || vol == 0) return "audio-volume-muted-symbolic";
    if (vol < 33) return "audio-volume-low-symbolic";
    if (vol < 66) return "audio-volume-medium-symbolic";
    return "audio-volume-high-symbolic";
}

static void print_state(int vol, int muted) {
    if (vol < 0) vol = 0;
    const char *icon = get_icon(vol, muted);

    if (strcmp(opt_format, "json") == 0) {
        printf("{\"volume\": %d, \"muted\": %s, \"icon\": \"%s\"}\n", vol, muted ? "true" : "false", icon);
    } else {
        printf("VOLUME=%d\n", vol);
        printf("VOLUME_MUTED=%s\n", muted ? "true" : "false");
        printf("VOLUME_ICON=%s\n", icon);
    }
    fflush(stdout);
}

static void show(void) {
    print_state(get_volume(), is_muted());
}

static void monitor(void) {
    int last_vol = -1;
    int last_mute = -1;
    while (1) {
        int vol = get_volume();
        int muted = is_muted();
        if (vol >= 0 && (vol != last_vol || muted != last_mute)) {
            print_state(vol, muted);
            last_vol = vol;
            last_mute = muted;
        }
        usleep(opt_interval * 1000);
    }
}

static void set_default_sink(const char *name) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "pactl set-default-sink %s 2>/dev/null", name);
    if (run_cmd(cmd) != 0) {
        fprintf(stderr, "error: failed to set default sink: %s\n", name);
    }
}

static void list_sinks(void) {
    run_cmd("pactl list sinks short 2>/dev/null");
}

static void usage(const char *prog) {
    fprintf(stderr,
        "Usage: %s [options] <command> [args]\n\n"
        "PulseAudio volume control with animations and formatting.\n\n"
        "Options:\n"
        "  -d, --device <dev>   Device to control (default: @DEFAULT_SINK@)\n"
        "  -s, --step <pct>     Volume step for up/down (default: 5)\n"
        "  -t, --duration <ms>  Animation duration in ms (default: 200, 0=disable)\n"
        "  -i, --interval <ms>  Polling interval for monitor (default: 500)\n"
        "  -f, --format <fmt>   Output format: sh, json (default: sh)\n"
        "  -h, --help           Show this help\n\n"
        "Commands:\n"
        "  get              Show current volume\n"
        "  set <0-150>      Set absolute volume\n"
        "  up               Increase volume by step\n"
        "  down             Decrease volume by step\n"
        "  mute             Toggle mute\n"
        "  min              Set to 0%%\n"
        "  max              Set to 100%%\n"
        "  monitor          Stream volume changes continuously\n"
        "  list             List available sinks\n"
        "  sink <name>      Set default sink\n\n"
        "Examples:\n"
        "  %s --device @DEFAULT_SOURCE@ get\n"
        "  %s --format json monitor\n"
        "  %s --duration 0 set 50\n",
        prog, prog, prog, prog);
}

int main(int argc, char *argv[]) {
    static struct option long_options[] = {
        {"device", required_argument, 0, 'd'},
        {"step", required_argument, 0, 's'},
        {"duration", required_argument, 0, 't'},
        {"interval", required_argument, 0, 'i'},
        {"format", required_argument, 0, 'f'},
        {"help", no_argument, 0, 'h'},
        {0, 0, 0, 0}
    };

    int opt;
    int opt_index = 0;
    while ((opt = getopt_long(argc, argv, "d:s:t:i:f:h", long_options, &opt_index)) != -1) {
        switch (opt) {
            case 'd': strncpy(opt_device, optarg, sizeof(opt_device) - 1); break;
            case 's': opt_step = atoi(optarg); break;
            case 't': opt_duration = atoi(optarg); break;
            case 'i': opt_interval = atoi(optarg); break;
            case 'f': strncpy(opt_format, optarg, sizeof(opt_format) - 1); break;
            case 'h': usage(argv[0]); return 0;
            default: usage(argv[0]); return 1;
        }
    }

    if (optind >= argc) { usage(argv[0]); return 1; }
    
    const char *cmd = argv[optind];

    if (strcmp(cmd, "get") == 0) show();
    else if (strcmp(cmd, "set") == 0 && optind + 1 < argc) pct(atoi(argv[optind + 1]));
    else if (strcmp(cmd, "up") == 0) adjust(1);
    else if (strcmp(cmd, "down") == 0) adjust(-1);
    else if (strcmp(cmd, "mute") == 0) toggle_mute();
    else if (strcmp(cmd, "min") == 0) pct(0);
    else if (strcmp(cmd, "max") == 0) pct(100);
    else if (strcmp(cmd, "monitor") == 0) monitor();
    else if (strcmp(cmd, "list") == 0) list_sinks();
    else if (strcmp(cmd, "sink") == 0 && optind + 1 < argc) set_default_sink(argv[optind + 1]);
    else { usage(argv[0]); return 1; }

    return 0;
}
