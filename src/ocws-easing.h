#ifndef OCWS_EASING_H
#define OCWS_EASING_H

/* easeOutCubic: t starts at 0 and ends at 1 */
static inline double ease_out_cubic(double t) {
    return 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
}

#endif
