#include <stddef.h>

// Test A: Latency (The Ping)
int latency_test() {
    return 42;
}

// Test B: Throughput (The Data Pipeline)
void throughput_test(int* data, size_t len) {
    for (size_t i = 0; i < len; i++) {
        data[i] *= 2;
    }
}

// Test C: Iteration (The Busy Work)
int iteration_test(int input) {
    return input ^ 0x55;
}
