enum OpCode {
    OP_return=0,
    OP_true=1,
    OP_false=2,
    OP_pop=3,
    OP_pop_n=4,
    OP_loadEmbeddedLongConstant=5,
    OP_loadConstantFromTable=6,
    OP_LONG_loadConstantFromTable=7,
    OP_negateInt=8,
    OP_negateDouble=9,
    OP_notBool=10,
    OP_greaterInt=11,
    OP_greaterDouble=12,
    OP_greaterString=13,
    OP_greaterOrEqualInt=14,
    OP_greaterOrEqualDouble=15,
    OP_greaterOrEqualString=16,
    OP_lessInt=17,
    OP_lessDouble=18,
    OP_lessString=19,
    OP_lessOrEqualInt=20,
    OP_lessOrEqualDouble=21,
    OP_lessOrEqualString=22,
    OP_equalEqualInt=23,
    OP_equalEqualDouble=24,
    OP_equalEqualString=25,
    OP_equalEqualBool=26,
    OP_notEqualInt=27,
    OP_notEqualDouble=28,
    OP_notEqualString=29,
    OP_notEqualBool=30,
    OP_minusInt=31,
    OP_minusDouble=32,
    OP_divideInt=33,
    OP_divideDouble=34,
    OP_multiplyInt=35,
    OP_multiplyDouble=36,
    OP_intDivideInt=37,
    OP_intDivideDouble=38,
    OP_modInt=39,
    OP_addInt=40,
    OP_addDouble=41,
    OP_addString=42,
    OP_orBool=43,
    OP_andBool=44,
};