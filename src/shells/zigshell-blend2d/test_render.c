// test_render.c — Quick test to verify Blend2D renders pixels
// gcc -o test_render test_render.c -I deps/blend2d -L build/deps/blend2d -lblend2d -lm
#include <stdio.h>
#include <string.h>
#include "blend2d/blend2d.h"

int main() {
    const int W = 100, H = 100;
    unsigned char buf[W * H * 4];
    memset(buf, 0, sizeof(buf));

    BLImageCore img;
    bl_image_init_as(&img, W, H, BL_FORMAT_PRGB32);

    BLContextCore ctx;
    bl_context_init_as(&ctx, &img, NULL);

    // Fill with solid red
    BLRect rect = {0, 0, W, H};
    bl_context_set_fill_style_rgba32(&ctx, 0xFFFF0000);
    bl_context_fill_rect_d(&ctx, &rect);

    // Flush to image
    bl_context_flush(&ctx, BL_CONTEXT_FLUSH_SYNC);

    // Copy pixels to our buffer
    BLImageData data;
    bl_image_make_mutable(&img, &data);
    int stride = data.stride;
    for (int y = 0; y < H; y++) {
        memcpy(buf + y * W * 4, (char*)data.pixel_data + y * stride, W * 4);
    }

    bl_context_end(&ctx);
    bl_context_destroy(&ctx);
    bl_image_destroy(&img);

    // Check if pixels are non-zero
    int nonzero = 0;
    for (int i = 0; i < W * H * 4; i++) {
        if (buf[i] != 0) nonzero++;
    }

    printf("Buffer: %d nonzero bytes out of %d\n", nonzero, W * H * 4);
    printf("First pixel: %02x %02x %02x %02x (ARGB)\n", buf[3], buf[2], buf[1], buf[0]);

    if (nonzero > 0) {
        printf("PASS: Blend2D rendered pixels\n");
    } else {
        printf("FAIL: No pixels rendered\n");
    }

    return nonzero > 0 ? 0 : 1;
}
