#include "VM.h"
#include "memory.h"
#include "OpCode.h"
#include "string.h"
#include "disassembler.h"
#include "ExplicitlyTypedValue.h"
#ifdef TIME_EXECUTION
#include <time.h>
#endif


static void resetStack(VM* vm) {
    vm->stackTop = vm->stack;
}

void resetVM(VM* vm) {
    resetStack(vm);
}

VM* initVM(const char** classNames, const int* classNamesLength, int classesCount) {
    VM* vm = malloc(sizeof *vm);
    vm->classNamesLength = COMPILER_MEM_ALLOCATE(int, classesCount);
    vm->classesCount = classesCount;
    vm->classNamesArray = COMPILER_MEM_ALLOCATE(char*, classesCount);
    for (int i=0;i<vm->classesCount;i++) {
        vm->classNamesLength[i] = classNamesLength[i];
        vm->classNamesArray[i] = COMPILER_MEM_ALLOCATE(char, classNamesLength[i]);
        memcpy(vm->classNamesArray[i], classNames[i], classNamesLength[i]);
    }
    resetVM(vm);
    return vm;
}

void freeVM(VM* vm) {
    COMPILER_MEM_FREE(int, vm->classNamesLength);
    for (int i=0;i<vm->classesCount;i++) {
        COMPILER_MEM_FREE(char, vm->classNamesArray[i]);
    }
    COMPILER_MEM_FREE(char*, vm->classNamesArray);
    vm = realloc(vm, 0);
}

inline void push(VM* vm, void* value) {
    *vm->stackTop = *(uint64_t*)value;
    vm->stackTop++;
}

inline uint64_t pop(VM* vm) {
    vm->stackTop--;
    return *vm->stackTop;
}

inline uint64_t* popByReference(VM* vm) {
    vm->stackTop--;
    return vm->stackTop;
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

inline void modifyTopInPlace(VM* vm, void* val) {
    *(vm->stackTop-1)=*(uint64_t*)val;
}

inline static uint64_t readLong(VM* vm) {
    uint64_t val = *(uint64_t*)(vm->ip);
    vm->ip+=8;
    return val;
}

inline static uint32_t read4Byte(VM* vm) {
    uint32_t val = *(uint32_t*)(vm->ip);
    vm->ip+=4;
    return val;
}

inline static void willAddPotentialObjectOnStack(VM* vm) {
    const uint32_t index = vm->stackTop - vm->stack;
    if (vm->potentialObjectsOnStackListCount+1>vm->potentialObjectsOnStackListCapacity) {
        int newPotentialObjectsOnStackListCapacity = GROW_CAPACITY(vm->potentialObjectsOnStackListCapacity);
        vm->potentialObjectsOnStackList = COMPILER_GROW_ARRAY(uint32_t, vm->potentialObjectsOnStackList, newPotentialObjectsOnStackListCapacity);
        vm->potentialObjectsOnStackListCapacity = newPotentialObjectsOnStackListCapacity;
    }
    vm->potentialObjectsOnStackList[vm->potentialObjectsOnStackListCount] = index;
    vm->potentialObjectsOnStackListCount++;
}

inline static void popPotentialObjectOnStack(VM* vm) {
    popCount(vm, 2);
    vm->potentialObjectsOnStackListCount--;
}

static void run(VM* vm) {
#define READ_INSTRUCTION_BYTE() (*(vm->ip++))
#define READ_LONG() (*(long*)popByReference(vm))
#define READ_DOUBLE() (*(double*)popByReference(vm))
#define READ_BOOL() (READ_DOUBLE() != 0)
#define READ_CONSTANT() (&(vm->chunk->constants[READ_INSTRUCTION_BYTE()]))
#define READ_LONG_CONSTANT() (&(vm->chunk->constants[read4Byte(vm)]))
    
#ifdef DEBUG_TRACE_EXECUTION
    int lineInformationIndex = 0;
#endif
    
    for (;;) {
#ifdef DEBUG_TRACE_EXECUTION
        printf("          ");
        for (uint64_t* slot = vm->stack;slot<vm->stackTop;slot++) {
            printf("[ ");
            printf("%llu", *slot);
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
        
#define INT_BINARY_OP(op) \
do { \
    long b = READ_LONG(); \
    long result = (*((long*)topByReference(vm))) op b; \
    modifyTopInPlace(vm, &result); \
} while (false)
#define DOUBLE_BINARY_OP(op) \
do { \
    double b = READ_DOUBLE(); \
    double result = (*((double*)topByReference(vm))) op b; \
    modifyTopInPlace(vm, &result); \
} while (false)
#define BOOL_BINARY_OP(op) \
do { \
    bool b = READ_BOOL(); \
    bool a = READ_BOOL(); \
    long result = a op b; \
    push(vm, &result); \
} while (false)
        uint8_t instruction;
        switch (instruction = READ_INSTRUCTION_BYTE()) {
            case OP_return: {
                return;
            }
            case OP_true: {
                long val = 1;
                push(vm, &val);
                break;
            }
            case OP_false: {
                long val = 0;
                push(vm, &val);
                break;
            }
            case OP_pop: {
                pop(vm);
                break;
            }
            case OP_pop_n: {
                uint8_t count = READ_INSTRUCTION_BYTE();
                popCount(vm, count);
                break;
            }
            case OP_popExplicitlyTypedValue: {
                popPotentialObjectOnStack(vm);
                break;
            }
            case OP_loadEmbeddedByteConstant: {
                uint64_t value = *(char*)&READ_INSTRUCTION_BYTE();
                push(vm, &value);
                break;
            }
            case OP_loadEmbeddedLongConstant: {
                uint64_t value = readLong(vm);
                push(vm, &value);
                break;
            }
            case OP_loadEmbeddedExplicitlyTypedConstant: {
                willAddPotentialObjectOnStack(vm);
                uint64_t value = readLong(vm);
                push(vm, &value);
                value = readLong(vm);
                push(vm, &value);
                break;
            }
#ifdef USE_EXTERNAL_CONSTANTS
            case OP_loadConstantFromTable: {
                push(vm, READ_CONSTANT());
                break;
            }
            case OP_LONG_loadConstantFromTable: {
                push(vm, READ_LONG_CONSTANT());
                break;
            }
#endif
            case OP_negateInt: {
                long val = -(*((long *)topByReference(vm)));
                modifyTopInPlace(vm, &val);
                break;
            }
            case OP_negateDouble: {
                double val = -((double)(*((double *)topByReference(vm))));
                modifyTopInPlace(vm, &val);
                break;
            }
            case OP_notBool: {
                bool val = !READ_BOOL();
                modifyTopInPlace(vm, &val);
            }
            case OP_greaterInt: {
                INT_BINARY_OP(>);
                break;
            }
            case OP_greaterDouble: {
                DOUBLE_BINARY_OP(>);
                break;
            }
            case OP_greaterString: {
                
            }
            case OP_greaterOrEqualInt: {
                INT_BINARY_OP(>=);
                break;
            }
            case OP_greaterOrEqualDouble: {
                DOUBLE_BINARY_OP(>=);
                break;
            }
            case OP_greaterOrEqualString: {
                
            }
            case OP_lessInt: {
                INT_BINARY_OP(<);
                break;
            }
            case OP_lessDouble: {
                DOUBLE_BINARY_OP(<);
                break;
            }
            case OP_lessString: {
                
            }
            case OP_lessOrEqualInt: {
                INT_BINARY_OP(<=);
                break;
            }
            case OP_lessOrEqualDouble: {
                DOUBLE_BINARY_OP(<=);
                break;
            }
            case OP_lessOrEqualString: {
                
            }
            case OP_equalEqualInt: {
                INT_BINARY_OP(==);
                break;
            }
            case OP_equalEqualDouble: {
                DOUBLE_BINARY_OP(==);
                break;
            }
            case OP_equalEqualString: {
                
            }
            case OP_equalEqualBool: {
                BOOL_BINARY_OP(==);
                break;
            }
            case OP_notEqualInt: {
                INT_BINARY_OP(!=);
                break;
            }
            case OP_notEqualDouble: {
                DOUBLE_BINARY_OP(!=);
                break;
            }
            case OP_notEqualString: {
                
            }
            case OP_notEqualBool: {
                BOOL_BINARY_OP(!=);
                break;
            }
            case OP_minusInt: {
                INT_BINARY_OP(-);
                break;
            }
            case OP_minusDouble: {
                DOUBLE_BINARY_OP(-);
                break;
            }
            case OP_divideInt: {
                INT_BINARY_OP(/);
                break;
            }
            case OP_divideDouble: {
                DOUBLE_BINARY_OP(/);
                break;
            }
            case OP_multiplyInt: {
                INT_BINARY_OP(*);
                break;
            }
            case OP_multiplyDouble: {
                DOUBLE_BINARY_OP(*);
                break;
            }
            case OP_intDivideInt: {
                // integer division for integer is just regular division
                INT_BINARY_OP(/);
                break;
            }
            case OP_intDivideDouble: {
                double b = READ_DOUBLE();
                double a = READ_DOUBLE();
                long result = a/b;
                push(vm, &result);
                break;
            }
            case OP_modInt: {
                INT_BINARY_OP(%);
                break;
            }
            case OP_addInt: {
                INT_BINARY_OP(+);
                break;
            }
            case OP_addDouble: {
                DOUBLE_BINARY_OP(+);
                break;
            }
            case OP_addString: {
                
            }
            case OP_orBool: {
                BOOL_BINARY_OP(||);
                break;
            }
            case OP_andBool: {
                BOOL_BINARY_OP(&&);
                break;
            }
            case OP_outputInt: {
                long val = READ_LONG();
//                printf("%li\n", val);
                break;
            }
            case OP_outputDouble: {
                double val = READ_DOUBLE();
//                printf("%f\n", val);
                break;
            }
            case OP_outputBoolean: {
                bool val = READ_BOOL();
//                printf("%s\n", val ? "true" : "false");
            }
            case OP_outputString: {
                
            }
            case OP_outputArray: {
                
            }
            case OP_outputAny: {
                
            }
            case OP_outputClass: {
                
            }
            case OP_outputVoid: {
                
            }
        }
    }
    
#undef INT_BINARY_OP
#undef READ_CONSTANT
#undef READ_INSTRUCTION_BYTE
#undef READ_LONG
#undef READ_DOUBLE
#undef READ_BOOL
}

void interpret(VM* vm, Chunk* chunk) {
#ifdef TIME_EXECUTION
    clock_t start, end;
    start = clock();
#endif
    vm->chunk = chunk;
    vm->ip = vm->chunk->code;
    run(vm);
#ifdef TIME_EXECUTION
    end = clock();
    printf("Quasicode execution time %f seconds\n\n", ((double)(end-start))/CLOCKS_PER_SEC);
#endif
}
