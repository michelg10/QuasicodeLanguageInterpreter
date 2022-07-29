//
//  memory.h
//  Interpreter
//
//  Created by Michel Guo on 2022/7/7.
//

#ifndef memory_h
#define memory_h

#include "common.h"

#define COMPILER_MEM_ALLOCATE(type, count) (type*)compilerReallocate(NULL, sizeof(type)*(count))

#define COMPILER_ALLOCATE_OBJ(type) (type*)compilerReallocate(NULL, sizeof(type))

#define COMPILER_MEM_FREE(type, pointer) compilerReallocate(pointer, 0)

#define GROW_CAPACITY(capacity) ((capacity<16) ? 16 : (capacity*2))

#define COMPILER_GROW_ARRAY(type, pointer, newCount) (type*)compilerReallocate(pointer, sizeof(type)*newCount)

#define COMPILER_FREE_ARRAY(type, pointer) compilerReallocate(pointer, 0)

void* compilerReallocate(void* pointer, size_t newSize); // note that calls to the reallocate function may return null

#endif /* memory_h */
