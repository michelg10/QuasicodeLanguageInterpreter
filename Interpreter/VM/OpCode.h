#ifndef opcode_h
#define opcode_h

enum OpCode {
    OP_return=0,
    OP_true=1,
    OP_false=2,
    OP_pop=3,
    OP_pop_n=4,
    OP_popExplicitlyTypedValue=5,
    OP_loadEmbeddedByteConstant=6,
    OP_loadEmbeddedLongConstant=7,
    OP_loadEmbeddedExplicitlyTypedConstant=8,
    OP_loadConstantFromTable=9,
    OP_LONG_loadConstantFromTable=10,
    OP_negateInt=11,
    OP_negateDouble=12,
    OP_notBool=13,
    OP_greaterInt=14,
    OP_greaterDouble=15,
    OP_greaterString=16,
    OP_greaterOrEqualInt=17,
    OP_greaterOrEqualDouble=18,
    OP_greaterOrEqualString=19,
    OP_lessInt=20,
    OP_lessDouble=21,
    OP_lessString=22,
    OP_lessOrEqualInt=23,
    OP_lessOrEqualDouble=24,
    OP_lessOrEqualString=25,
    OP_equalEqualInt=26,
    OP_equalEqualDouble=27,
    OP_equalEqualString=28,
    OP_equalEqualBool=29,
    OP_notEqualInt=30,
    OP_notEqualDouble=31,
    OP_notEqualString=32,
    OP_notEqualBool=33,
    OP_minusInt=34,
    OP_minusDouble=35,
    OP_divideInt=36,
    OP_divideDouble=37,
    OP_multiplyInt=38,
    OP_multiplyDouble=39,
    OP_intDivideInt=40,
    OP_intDivideDouble=41,
    OP_modInt=42,
    OP_addInt=43,
    OP_addDouble=44,
    OP_addString=45,
    OP_orBool=46,
    OP_andBool=47,
    OP_outputInt=48,
    OP_outputDouble=49,
    OP_outputBoolean=50,
    OP_outputString=51,
    OP_outputArray=52,
    OP_outputAny=53,
    OP_outputClass=54,
    OP_outputVoid=55,
};

#endif /* opcode_h */