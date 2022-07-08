#ifndef VM_h
#define VM_h

#include <stdio.h>
#include "common.h"
#include "chunk.h"

#define FRAMES_MAX 8192
#define BYTES_PER_FRAME 8*2048
#define STACK_MAX (FRAMES_MAX * BYTES_PER_FRAME)

typedef struct {
    uint8_t stack[STACK_MAX];
    uint8_t* stackTop;
    Chunk* chunk;
    uint8_t* ip; // this is getting moved to a call frame soon
} VM;

VM* initVM(void);
void freeVM(VM* vm);

void pushLong(VM* vm, uint64_t value);
void pushByte(VM* vm, uint8_t value);
uint64_t popLong(VM* vm);
uint8_t popByte(VM* vm);

#endif /* VM_h */
