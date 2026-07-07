/* OCWS Theme Utilities — Shared token loading for all C apps
 * Provides functions to load tokens.css and resolve colors at runtime.
 * Include this header in any OCWS GTK app that needs theme colors.
 * ============================================================ */

#ifndef OCWS_THEME_UTILS_H
#define OCWS_THEME_UTILS_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define OCWS_MAX_COLORS 64
#define OCWS_COLOR_LEN 16

typedef struct {
    char name[64];
    char value[OCWS_COLOR_LEN];
} ocws_token_t;

static ocws_token_t ocws_tokens[OCWS_MAX_COLORS];
static int ocws_token_count = 0;
static int ocws_tokens_loaded = 0;

/* Load tokens.css from ~/.config/ocws/tokens.css
 * Returns 1 on success, 0 on failure */
static int ocws_load_tokens(void) {
    if (ocws_tokens_loaded) return 1;

    const char *home = getenv("HOME");
    if (!home) home = "/tmp";

    char path[512];
    snprintf(path, sizeof(path), "%s/.config/ocws/tokens.css", home);

    FILE *f = fopen(path, "r");
    if (!f) return 0;

    char line[256];
    ocws_token_count = 0;

    while (fgets(line, sizeof(line), f) && ocws_token_count < OCWS_MAX_COLORS) {
        /* Parse: @define-color ocws_name #rrggbb; */
        char *p = strstr(line, "@define-color");
        if (!p) continue;

        p += 13; /* skip "@define-color" */
        while (*p == ' ' || *p == '\t') p++;

        /* Extract token name */
        char *name_start = p;
        while (*p && *p != ' ' && *p != '\t' && *p != ';') p++;
        int name_len = p - name_start;
        if (name_len <= 0 || name_len >= 64) continue;

        while (*p == ' ' || *p == '\t') p++;

        /* Extract color value (hex) */
        if (*p != '#') continue;
        char *color_start = p;
        while (*p && *p != ';' && *p != '\n' && *p != '\r') p++;
        int color_len = p - color_start;
        if (color_len < 4 || color_len >= OCWS_COLOR_LEN) continue;

        /* Store token */
        memcpy(ocws_tokens[ocws_token_count].name, name_start, name_len);
        ocws_tokens[ocws_token_count].name[name_len] = '\0';
        memcpy(ocws_tokens[ocws_token_count].value, color_start, color_len);
        ocws_tokens[ocws_token_count].value[color_len] = '\0';
        ocws_token_count++;
    }

    fclose(f);
    ocws_tokens_loaded = 1;
    return 1;
}

/* Get a color value by token name (e.g., "ocws_bg", "ocws_accent")
 * Returns the hex string (e.g., "#1e1e2e") or fallback if not found */
static const char* ocws_get_color(const char *name, const char *fallback) {
    if (!ocws_tokens_loaded) ocws_load_tokens();

    for (int i = 0; i < ocws_token_count; i++) {
        if (strcmp(ocws_tokens[i].name, name) == 0) {
            return ocws_tokens[i].value;
        }
    }
    return fallback;
}

/* Convenience macros for common colors */
#define OCWS_BG()       ocws_get_color("ocws_bg", "#1e1e2e")
#define OCWS_FG()       ocws_get_color("ocws_fg", "#cdd6f4")
#define OCWS_SURFACE0() ocws_get_color("ocws_surface0", "#313244")
#define OCWS_SURFACE1() ocws_get_color("ocws_surface1", "#45475a")
#define OCWS_ACCENT()   ocws_get_color("ocws_accent", "#89b4fa")
#define OCWS_URGENT()   ocws_get_color("ocws_urgent", "#f38ba8")
#define OCWS_OK()       ocws_get_color("ocws_ok", "#a6e3a1")
#define OCWS_MUTED()    ocws_get_color("ocws_muted", "#a6adc8")
#define OCWS_BORDER()   ocws_get_color("ocws_surface2", "#45475a")

/* Load tokens.css and append to a CSS buffer.
 * Returns the new position in the buffer. */
static int ocws_load_tokens_into_css(char *css, size_t css_size, int pos) {
    const char *home = getenv("HOME");
    if (!home) home = "/tmp";

    char path[512];
    snprintf(path, sizeof(path), "%s/.config/ocws/tokens.css", home);

    FILE *f = fopen(path, "r");
    if (!f) return pos;

    size_t n = fread(css + pos, 1, css_size - pos - 2048, f);
    fclose(f);
    return pos + (int)n;
}

#endif /* OCWS_THEME_UTILS_H */
