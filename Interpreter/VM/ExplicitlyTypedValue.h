#ifndef AnyValueType_h
#define AnyValueType_h

#include "VMType.h"
#include "common.h"
#include "object.h"

typedef struct Obj Obj;

typedef struct {
    int type;
    unsigned int arrayDepth;
    union {
        void* object;
        long qsInt;
        double qsDouble;
        bool qsBoolean;
    } as;
} ExplicitlyTypedValue;

/*
 ExplicitlyTypedValues will be used when:
 - an Any is used in the code (in which case, the type property would be any value besides any, unless if it is an array)
 - an instance of a class is used
 
 ExplicitlyTypedValues will NOT be used when:
 - there is simply an array. the compiler should take care of that.
 - even if it is an Any array, the Any array itself will not use ExplicitlyTypedValues. But the Anys within the array will
 
 */

#define ANY_VAL_FROM_OBJECT(classId, pointer)    ((ExplicitlyTypedValue){classId, 0, {.object = pointer}})
#define ANY_VAL_FROM_INT(value)                  ((ExplicitlyTypedValue){-Int, 0, {.qsInt = value}})
#define ANY_VAL_FROM_DOUBLE(value)               ((ExplicitlyTypedValue){-Double, 0, {.qsDouble = value}})
#define ANY_VAL_FROM_BOOLEAN(value)              ((ExplicitlyTypedValue){-Boolean, 0, {.qsBoolean = value}})

#define ANY_AS_OBJECT(value)                     ((value).as.object)
#define ANY_AS_INT(value)                        ((value).as.qsInt)
#define ANY_AS_DOUBLE(value)                     ((value).as.qsDouble)
#define ANY_AS_BOOLEAN(value)                    ((value).as.qsBoolean)

#define IS_OBJECT(value)                         ((value).type > 0)
#define IS_INT(value)                            ((value).type == -Int)
#define IS_DOUBLE(value)                         ((value).type == -Double)
#define IS_BOOLEAN(value)                        ((value).type == -Boolean)

typedef struct {
    long length;
    void* data;
} ArrayType;

typedef struct {
    long length;
    int* data;
} StringClass;

#endif /* AnyValueType_h */
