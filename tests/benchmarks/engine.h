#ifndef ENGINE_H
#define ENGINE_H

#include <stddef.h>

int latency_test();
void throughput_test(int* data, size_t len);
int iteration_test(int input);

#endif
