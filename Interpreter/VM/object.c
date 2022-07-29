#include <stdio.h>
#include <string.h>

#include "object.h"
#include "memory.h"
#include "ExplicitlyTypedValue.h"

struct ObjString* compilerCopyString(const char* chars, int length) {
    char* heapAllocatedChars = COMPILER_MEM_ALLOCATE(char, length);
    memcpy(heapAllocatedChars, chars, length);
    
    return NULL;
}
