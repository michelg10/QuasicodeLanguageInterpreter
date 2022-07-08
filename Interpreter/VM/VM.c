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

inline void push(VM* vm, uint64_t value) {
    *vm->stackTop = value;
    vm->stackTop++;
}

inline uint64_t pop(VM* vm) {
    vm->stackTop--;
    return *vm->stackTop;
}

inline void popCount(VM* vm, uint8_t count) {
    vm->stackTop-=count;
}

inline void* topByReference(VM* vm) {
    return (void*)(vm->stackTop-1);
}
inline uint64_t top(VM* vm) {
    return *(vm->stackTop-1);
}

inline void modifyTopInPlace(VM* vm, long val) {
    *(vm->stackTop-1)=val;
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
                push(vm, 1);
                break;
            }
            case OP_false: {
                push(vm, 0);
                break;
            }
            case OP_pop: {
                pop(vm);
                break;
            }
            case OP_pop_n: {
                uint8_t count = READ_BYTE();
                popCount(vm, count);
                break;
            }
            case OP_loadEmbeddedLongConstant: {
                uint64_t value = readLong(vm);
                push(vm, value);
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
                long val = -(*((long *)topByReference(vm)));
                modifyTopInPlace(vm, val);
                break;
            }
            case OP_negateDouble: {
                double val = -((double)(*((double *)topByReference(vm))));
                modifyTopInPlace(vm, *(long*)&val);
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
