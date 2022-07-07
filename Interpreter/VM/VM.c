#include "VM.h"
#include "memory.h"

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
