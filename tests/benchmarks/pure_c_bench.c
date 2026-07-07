#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <stddef.h>

// Prototypes
int latency_test();
void throughput_test(int* data, size_t len);
int iteration_test(int input);

// We'll define the functions here or link them.
// To keep it simple for this demonstration, I'll just include the logic or link it.
// Since I'm writing the file, I'll re-include the logic or use a header.
// Better yet, I'll just use the functions we will link.

int main() {
    struct timespec start, end;

    // Test A: Latency
    clock_gettime(CLOCK_MONOTONIC, &start);
    for (int i = 0; i < 1000000; i++) {
        latency_test();
    }
    clock_gettime(CLOCK_MONOTONIC, &end);
    double latency_time = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    printf("LATENCY_C: %f\n", latency_time);

    // Test B: Throughput
    size_t len = 1000000;
    int* data = malloc(len * sizeof(int));
    for (size_t i = 0; i < len; i++) data[i] = i;

    clock_gettime(CLOCK_MONOTONIC, &start);
    throughput_test(data, len);
    clock_gettime(CLOCK_MONOTONIC, &end);
    double throughput_time = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    printf("THROUGHPUT_C: %f\n", throughput_time);
    free(data);

    // Test C: Iteration
    clock_gettime(CLOCK_MONOTONIC, &start);
    int val = 0;
    for (int i = 0; i < 1000000; i++) {
        val = iteration_test(val);
    }
    clock_gettime(CLOCK_MONOTONIC, &end);
    double iteration_time = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    printf("ITERATION_C: %f\n", iteration_time);

    return 0;
}
