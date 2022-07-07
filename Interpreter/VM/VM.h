#ifndef VM_h
#define VM_h

#include <stdio.h>
#include "common.h"

#define FRAMES_MAX 8192
#define BYTES_PER_FRAME 8*2048
#define STACK_MAX (FRAMES_MAX * BYTES_PER_FRAME)

typedef struct {
    uint8_t stack[STACK_MAX];
    uint8_t* stackTop;
    uint8_t* ip; // this is getting moved to a call frame soon
} VM;

VM* initVM(void);
void freeVM(VM* vm);

#endif /* VM_h */
