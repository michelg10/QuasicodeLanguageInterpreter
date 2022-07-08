#include "VM.h"
#include "memory.h"
#include "OpCode.h"

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

static void run(VM* vm) {
#define READ_BYTE() (*(vm->ip++))
    
    
    for (;;) {
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
