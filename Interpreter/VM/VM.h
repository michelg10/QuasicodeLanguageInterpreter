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
void interpret(VM* vm, Chunk* chunk);

void pushLong(VM* vm, void* value);
void pushByte(VM* vm, void* value);
uint64_t popLong(VM* vm);
uint8_t popByte(VM* vm);
void popCount(VM* vm, uint8_t count);
void* topLongByReference(VM* vm);
void* topByteByReference(VM* vm);
uint64_t topLong(VM* vm);
uint8_t topByte(VM* vm);
void modifyTopLongInPlace(VM* vm, void* val);
void modifyTopByteInPlace(VM* vm, void* val);
uint64_t readLong(VM* vm);

#endif /* VM_h */
