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

#define TYPED_VAL_FROM_OBJECT_SCALAR(classId, pointer)    ((ExplicitlyTypedValue){classId, 0, {.object = pointer}})
#define TYPED_VAL_FROM_INT_SCALAR(value)                  ((ExplicitlyTypedValue){-Int, 0, {.qsInt = value}})
#define TYPED_VAL_FROM_DOUBLE_SCALAR(value)               ((ExplicitlyTypedValue){-Double, 0, {.qsDouble = value}})
#define TYPED_VAL_FROM_BOOLEAN_SCALAR(value)              ((ExplicitlyTypedValue){-Boolean, 0, {.qsBoolean = value}})

#define TYPED_VAL_AS_OBJECT_SCALAR(value)                     ((value).as.object)
#define TYPED_VAL_AS_INT_SCALAR(value)                        ((value).as.qsInt)
#define TYPED_VAL_AS_DOUBLE_SCALAR(value)                     ((value).as.qsDouble)
#define TYPED_VAL_AS_BOOLEAN_SCALAR(value)                    ((value).as.qsBoolean)

#define TYPED_VAL_IS_OF_OBJECT(value)                         ((value).type > 0)
#define TYPED_VAL_IS_OF_INT(value)                            ((value).type == -Int)
#define TYPED_VAL_IS_OF_DOUBLE(value)                         ((value).type == -Double)
#define TYPED_VAL_IS_OF_BOOLEAN(value)                        ((value).type == -Boolean)
#define TYPED_VAL_IS_OF_ANY(value)                            ((value).type == -AnyType)

typedef struct {
    long length;
    void* data;
} ArrayType;

typedef struct {
    long length;
    int* data;
} StringClass;

#endif /* AnyValueType_h */
