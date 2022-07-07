//
//  memory.h
//  Interpreter
//
//  Created by Michel Guo on 2022/7/7.
//

#ifndef memory_h
#define memory_h

#include "common.h"

#define NOVM_ALLOCATE(type, count) (type*)novm_reallocate(NULL, sizeof(type)*(count))

#define NOVM_FREE(type, pointer) novm_reallocate(pointer, 0)

#define GROW_CAPACITY(capacity) ((capacity<16) ? 16 : (capacity*2))

#define NOVM_GROW_ARRAY(type, pointer, newCount) (type*)novm_reallocate(pointer, sizeof(type)*newCount)

#define NOVM_FREE_ARRAY(type, pointer) novm_reallocate(pointer, 0)

void* novm_reallocate(void* pointer, size_t newSize); // note that calls to the reallocate function may return null

#endif /* memory_h */
