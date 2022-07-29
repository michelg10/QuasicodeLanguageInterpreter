enum OpCode: Int {
    case OP_return
    case OP_true
    case OP_false
    case OP_pop
    case OP_pop_n
    case OP_popExplicitlyTypedValue
    case OP_loadEmbeddedByteConstant
    case OP_loadEmbeddedLongConstant
    case OP_loadEmbeddedExplicitlyTypedConstant
    case OP_loadConstantFromTable
    case OP_LONG_loadConstantFromTable
    case OP_negateInt
    case OP_negateDouble
    case OP_notBool
    case OP_greaterInt
    case OP_greaterDouble
    case OP_greaterString
    case OP_greaterOrEqualInt
    case OP_greaterOrEqualDouble
    case OP_greaterOrEqualString
    case OP_lessInt
    case OP_lessDouble
    case OP_lessString
    case OP_lessOrEqualInt
    case OP_lessOrEqualDouble
    case OP_lessOrEqualString
    case OP_equalEqualInt
    case OP_equalEqualDouble
    case OP_equalEqualString
    case OP_equalEqualBool
    case OP_notEqualInt
    case OP_notEqualDouble
    case OP_notEqualString
    case OP_notEqualBool
    case OP_minusInt
    case OP_minusDouble
    case OP_divideInt
    case OP_divideDouble
    case OP_multiplyInt
    case OP_multiplyDouble
    case OP_intDivideInt
    case OP_intDivideDouble
    case OP_modInt
    case OP_addInt
    case OP_addDouble
    case OP_addString
    case OP_orBool
    case OP_andBool
    case OP_outputInt
    case OP_outputDouble
    case OP_outputBoolean
    case OP_outputString
    case OP_outputArray
    case OP_outputAny
    case OP_outputClass
    case OP_outputVoid
}