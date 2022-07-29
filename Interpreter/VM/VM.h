#ifndef VM_h
#define VM_h

#include <stdio.h>
#include "common.h"
#include "chunk.h"

#define FRAMES_MAX 8192
#define BYTES_PER_FRAME 8*2048
#define STACK_MAX (FRAMES_MAX * BYTES_PER_FRAME)/8

typedef struct {
    uint64_t stack[STACK_MAX];
    uint64_t* stackTop;
    uint32_t* potentialObjectsOnStackList; // for the GC
    uint32_t potentialObjectsOnStackListCount;
    uint32_t potentialObjectsOnStackListCapacity;
    char** classNamesArray;
    int* classNamesLength;
    int classesCount;
    Chunk* chunk;
    uint8_t* ip; // this is getting moved to a call frame soon
} VM;

void resetVM(VM* vm);
VM* initVM(const char** classNames, const int* classNamesLength, int classesCount);
void freeVM(VM* vm);
void interpret(VM* vm, Chunk* chunk);

void push(VM* vm, void* value);
uint64_t pop(VM* vm);
uint64_t* popByReference(VM* vm);
void popCount(VM* vm, uint8_t count);
void* topByReference(VM* vm);
uint64_t top(VM* vm);
void modifyTopInPlace(VM* vm, void* val);

#endif /* VM_h */
