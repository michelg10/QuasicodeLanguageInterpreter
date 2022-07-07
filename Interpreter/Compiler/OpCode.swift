enum OpCode: Int {
    case OP_loadEmbeddedLongConstant
    case OP_true
    case OP_false
    case OP_pop
    case OP_pop_n
    case OP_loadConstantFromTable
    case OP_LONG_loadConstantFromTable
    case OP_addInt
    case OP_addDouble
    case OP_addString
    case OP_addAny
    case OP_minusInt
    case OP_minusDouble
    case OP_minusAny
    case OP_multiplyInt
    case OP_multiplyDouble
    case OP_multiplyAny
    case OP_divideInt
    case OP_divideDouble
    case OP_divideAny
    case OP_intDivideInt
    case OP_intDivideDouble
    case OP_intDivideAny
}