/*
 * settings-ui.h — UI Helper Widgets
 * Reusable GTK3 widget builders for the OCWS Settings Panel.
 */

#ifndef SETTINGS_UI_H
#define SETTINGS_UI_H

#include <gtk/gtk.h>

// ============================================================
// Configuration
// ============================================================

#define OCWS_DIR    ".config/ocws"
#define THEME_DIR   ".config/ocws/themes"
#define KV_BIN      "ocws-kv"
#define VERSION     "0.1.0"

extern const char *OCWS_HOME;
void init_paths(void);

// ============================================================
// KV Store Helpers
// ============================================================

char* kv_get(const char *key);
void kv_set(const char *key, const char *value);

// ============================================================
// Command Execution
// ============================================================

void execute_command(GtkWidget *widget, gpointer data);

// ============================================================
// Card Widgets
// ============================================================

GtkWidget* create_card(const char *title, const char *icon);
GtkWidget* create_collapsible_card(const char *title, const char *icon, gboolean start_expanded);
GtkWidget* get_collapsible_content(GtkWidget *card);

// ============================================================
// Row Widgets
// ============================================================

GtkWidget* create_toggle_row(const char *label, const char *description, gboolean active);
GtkWidget* create_live_toggle_row(const char *label, const char *description, gboolean active, const char *cmd_on, const char *cmd_off);
GtkWidget* create_slider_row(const char *label, int value, int min, int max, const char *unit);
GtkWidget* create_live_slider_row(const char *label, int value, int min, int max, const char *unit, const char *cmd_template);
GtkWidget* create_button_group(const char *label, const char **options, int count, int active);
GtkWidget* create_action_row(const char *title, const char *subtitle, const char *button_label, const char *command);
GtkWidget* create_keybind_row(const char *label, const char *command);

// ============================================================
// Shell Card
// ============================================================

GtkWidget* create_shell_card(const char *title, const char *desc, const char *mode, const char *icon_name);

// ============================================================
// Healthcheck & System Info
// ============================================================

void load_healthcheck(GtkWidget *textview);
void load_system_info(GtkWidget *textview);

// ============================================================
// CSS
// ============================================================

void apply_css(GtkApplication *app);

#endif /* SETTINGS_UI_H */
