#include "VM.h"
#include "memory.h"
#include "OpCode.h"
#include "string.h"
#include "disassembler.h"

static void resetStack(VM* vm) {
    vm->stackTop = vm->stack;
}

void resetVM(VM* vm) {
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

inline void pushLong(VM* vm, void* value) {
    memcpy(vm->stackTop, &value, 8);
    vm->stackTop+=8;
}

inline void pushByte(VM* vm, void* value) {
    *vm->stackTop = *(uint8_t*)value;
    vm->stackTop++;
}

inline uint64_t popLong(VM* vm) {
    vm->stackTop-=8;
    return *vm->stackTop;
}

inline uint8_t popByte(VM* vm) {
    vm->stackTop--;
    return *vm->stackTop;
}

inline void popCount(VM* vm, uint8_t count) {
    vm->stackTop-=count;
}

inline void* topLongByReference(VM* vm) {
    return (void*)(vm->stackTop-8);
}

inline void* topByteByReference(VM* vm) {
    return (void*)vm->stackTop;
}

inline uint64_t topLong(VM* vm) {
    return *(vm->stackTop-8);
}

inline uint8_t topByte(VM* vm) {
    return *(vm->stackTop);
}

inline void modifyTopLongInPlace(VM* vm, void* val) {
    memcpy(vm->stackTop-8, val, 8);
}

inline void modifyTopByteInPlace(VM* vm, void* val) {
    *vm->stackTop = *((uint8_t*)val);
}

inline uint64_t readLong(VM* vm) {
    uint64_t val = *(uint64_t*)(vm->ip);
    vm->ip+=8;
    return val;
}

static void run(VM* vm) {
#define READ_BYTE() (*(vm->ip++))
    
#ifdef DEBUG_TRACE_EXECUTION
    int lineInformationIndex = 0;
#endif
    
    const uint8_t byteZero = 0;
    const uint8_t byteOne = 1;
    
    for (;;) {
#ifdef DEBUG_TRACE_EXECUTION
        printf("          ");
        for (uint8_t* slot = vm->stack;slot<vm->stackTop;slot++) {
            printf("[ ");
            printf("%hhu", *slot);
            printf(" ]");
        }
        printf("\n");
        
        int lineNumber=0;
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
            case OP_true: {
                pushByte(vm, (void*)&byteOne);
                break;
            }
            case OP_false: {
                pushByte(vm, (void*)&byteZero);
                break;
            }
            case OP_pop: {
                popByte(vm);
                break;
            }
            case OP_pop_n: {
                uint8_t count = READ_BYTE();
                popCount(vm, count);
                break;
            }
            case OP_loadEmbeddedLongConstant: {
                uint64_t value = readLong(vm);
                pushLong(vm, &value);
                break;
            }
            case OP_loadConstantFromTable: {
                // TODO
                break;
            }
            case OP_LONG_loadConstantFromTable: {
                // TODO
                break;
            }
            case OP_negateInt: {
                long val = -(*((long *)topLongByReference(vm)));
                modifyTopLongInPlace(vm, &val);
                break;
            }
            case OP_negateDouble: {
                double val = -((double)(*((double *)topLongByReference(vm))));
                modifyTopLongInPlace(vm, &val);
                break;
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
