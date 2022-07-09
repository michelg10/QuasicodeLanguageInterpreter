#ifndef common_h
#define common_h

#include <stdlib.h>
#include <stdbool.h>

#define INITIAL_ARRAY_CAPACITY 8
#define ARRAY_GROW_FACTOR 2

#define DEBUG_PRINT_CODE
//#define DEBUG_TRACE_EXECUTION
#define TIME_EXECUTION

#if defined(DEBUG_PRINT_CODE) || defined(DEBUG_TRACE_EXECUTION)
#define DEBUG_INCLUDE_TYPES
#endif

#endif /* common_h */
