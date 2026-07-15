// dock.h — Dock rendering via Blend2D (C implementation)
#ifndef DOCK_H
#define DOCK_H

#include <stdint.h>
#include "blend2d/blend2d.h"

struct BlendRenderer;

// Runtime icon size (settable from the shell; default 28)
extern int dock_icon_size;
#define DOCK_PAD 8

// Draw the dock background, icons, and focus indicators.
void dock_draw(struct BlendRenderer* renderer, int w, int h,
               const char** app_ids, const char** titles, int* focused,
               int top_count, int hover_idx);

// Hit-test: which icon is at mouse_x? Returns index or -1.
int dock_icon_at(int w, int h, int top_count, int mouse_x);

#endif // DOCK_H
