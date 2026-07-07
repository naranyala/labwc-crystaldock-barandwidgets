#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <time.h>

int native_call() { return 0; }

int main() {
    int iters = 5000;
    struct timespec start, end;
    
    printf("Running %d iterations of Native Call vs Fork/Exec...\n\n", iters);
    
    // Test 1: Native
    clock_gettime(CLOCK_MONOTONIC, &start);
    for (int i=0; i<iters; i++) {
        native_call();
    }
    clock_gettime(CLOCK_MONOTONIC, &end);
    double native_time = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    
    // Test 2: Fork + Exec
    clock_gettime(CLOCK_MONOTONIC, &start);
    for (int i=0; i<iters; i++) {
        pid_t pid = fork();
        if (pid == 0) {
            execl("./dummy_cmd", "dummy_cmd", NULL);
            exit(1);
        } else {
            waitpid(pid, NULL, 0);
        }
    }
    clock_gettime(CLOCK_MONOTONIC, &end);
    double fork_time = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    
    printf("=== RESULTS ===\n");
    printf("Native C Call:  %.6f seconds\n", native_time);
    printf("POSIX fork():   %.6f seconds\n", fork_time);
    if (native_time > 0) {
        printf("Speedup:        Native is %.0fx faster\n", fork_time / native_time);
    }
    return 0;
}
