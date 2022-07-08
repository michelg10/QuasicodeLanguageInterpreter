#include "VM.h"
#include "memory.h"
#include "OpCode.h"
#include "string.h"
#include "disassembler.h"

static void resetStack(VM* vm) {
    vm->stackTop = vm->stack;
}

static void resetVM(VM* vm) {
    resetStack(vm);
}

VM* initVM() {
    VM* vm = malloc(sizeof *vm);
    resetVM(vm);
    return vm;
}

void freeVM(VM* vm) {
    vm = realloc(vm, 0);
}

void pushLong(VM* vm, uint64_t value) {
    memcpy(vm->stackTop, &value, 8);
    vm->stackTop+=8;
}

void pushByte(VM* vm, uint8_t value) {
    *vm->stackTop = value;
    vm->stackTop++;
}

uint64_t popLong(VM* vm) {
    vm->stackTop-=8;
    return *vm->stackTop;
}

uint8_t popByte(VM* vm) {
    vm->stackTop--;
    return *vm->stackTop;
}

static void run(VM* vm) {
#define READ_BYTE() (*(vm->ip++))
    
#ifdef DEBUG_TRACE_EXECUTION
    int lineInformationIndex = 0;
#endif
    
    for (;;) {
#ifdef DEBUG_TRACE_EXECUTION
        printf("          ");
        for (uint8_t* slot = vm->stack;slot<vm->stackTop;slot++) {
            printf("[ ");
            printf("%hhu", *slot);
            printf(" ]");
        }
        printf("\n");
        
        int lineNumber;
        bool showLineNumber = false;
        int bytecodeLine = (int)(vm->ip - vm->chunk->code);
        if (lineInformationIndex < vm->chunk->lineInformationCount && bytecodeLine == vm->chunk->lineInformation[lineInformationIndex].correspondingBytecodeIndex) {
            lineNumber = vm->chunk->lineInformation[lineInformationIndex].line;
            showLineNumber = true;
            lineInformationIndex++;
        }
        
        disassembleInstruction(vm->chunk, (int)(vm->ip-vm->chunk->code), lineNumber, showLineNumber);
#endif
        uint8_t instruction;
        switch (instruction = READ_BYTE()) {
                
            case OP_return: {
                return;
            }
        }
    }
    
#undef READ_BYTE
}

void interpret(VM* vm, Chunk* chunk) {
    vm->chunk = chunk;
    vm->ip = vm->chunk->code;
    run(vm);
}
