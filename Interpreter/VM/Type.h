#ifndef type_h
#define type_h

#include "VMType.h"
typedef struct {
    enum VMType vmType;
    uint64_t data;
} Type;

#endif /* type_h */
