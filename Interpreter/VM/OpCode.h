#ifndef opcode_h
#define opcode_h

enum OpCode {
    OP_return=0,
    OP_true=1,
    OP_false=2,
    OP_pop=3,
    OP_pop_n=4,
    OP_loadEmbeddedLongConstant=5,
    OP_loadConstantFromTable=6,
    OP_LONG_loadConstantFromTable=7,
    OP_addInt=8,
    OP_addDouble=9,
    OP_addString=10,
    OP_addAny=11,
    OP_minusInt=12,
    OP_minusDouble=13,
    OP_minusAny=14,
    OP_multiplyInt=15,
    OP_multiplyDouble=16,
    OP_multiplyAny=17,
    OP_divideInt=18,
    OP_divideDouble=19,
    OP_divideAny=20,
    OP_intDivideInt=21,
    OP_intDivideDouble=22,
    OP_intDivideAny=23,
};

#endif /* opcode_h */
