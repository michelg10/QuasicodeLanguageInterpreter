#include "benchmarkVMprimitives.h"
#include "VM.h"
#include <time.h>

#define VM_BENCHMARK_PRIMITIVE_TIMES 10

static double computeTimeUsed(clock_t start, clock_t end) {
    return ((double) (end - start)) / CLOCKS_PER_SEC;
}

void benchmarkVMprimitives() {
    double optimCheat = 0;
    clock_t start, end;
    double cpu_time_used;
    
    VM* vm = initVM();
    const int stackBytesMax = STACK_MAX;
    
    printf("===== write to memory =====\n");
    for (int i=0;i<stackBytesMax;i++) {
        uint8_t value = i%256;
        pushByte(vm, &value);
    }
    
    {
        printf("===== pushLong =====\n");
        double pushLongTime = 0;
        double standardCopyLongTime = 0;
        
        int testSize = stackBytesMax/8;
        long* test = malloc(8*testSize);
        long* standardCopy = malloc(8*testSize);
        for (int t=0;t<VM_BENCHMARK_PRIMITIVE_TIMES;t++) {
            resetVM(vm);
            
            for (int i=0;i<testSize;i++) {
                test[i] = i;
            }
            
            start = clock();
            for (int i=0;i<testSize;i++) {
                pushLong(vm, &test[i]);
            }
            end = clock();
            
            pushLongTime+=computeTimeUsed(start, end);
            
            start = clock();
            for (int i=0;i<testSize;i++) {
                standardCopy[i] = test[i];
            }
            end = clock();
            standardCopyLongTime+=computeTimeUsed(start, end);
            for (int i=0;i<testSize;i++) {
                optimCheat+=standardCopy[i];
            }
        }
        free(standardCopy);
        free(test);
        
        printf("pushLong time: %f\nStandard copy long time: %f\n", pushLongTime, standardCopyLongTime);
    }
    
    freeVM(vm);
    
    printf("(this is useless) optim cheat - %f\n", optimCheat);
}
