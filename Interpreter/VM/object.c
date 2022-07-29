#include <stdio.h>
#include <string.h>

#include "object.h"
#include "memory.h"
#include "ExplicitlyTypedValue.h"

typedef struct ObjString ObjString;

static ObjString* allocateString(unsigned char* chars, long length) {
    ObjString* string = COMPILER_ALLOCATE_OBJ(ObjString);
    string->length = length;
    string->data = chars;
    return string;
}

ObjString* compilerCopyString(const unsigned char* chars, long length) {
    char* heapAllocatedChars = COMPILER_MEM_ALLOCATE(char, length);
    memcpy(heapAllocatedChars, chars, length);
    
    return NULL;
}
