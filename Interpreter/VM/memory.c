#include "memory.h"

void* novm_reallocate(void* pointer, size_t newSize) {
    if (newSize == 0) {
        free(pointer);
        return NULL;
    }
    
    void* result = realloc(pointer, newSize);
    return result;
}
