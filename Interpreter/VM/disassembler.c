#include "disassembler.h"
#include <stdio.h>

void disassembleChunk(Chunk* chunk, const char* name) {
    printf("== %s == \n", name);
    
    int lineNumber=-1;
    bool showLineNumber = false;
    int currentLineInformationIndex = 0;
    for (int offset=0;offset<chunk->codeCount;) {
        if (currentLineInformationIndex < chunk->lineInformationCount && chunk->lineInformation[currentLineInformationIndex].correspondingBytecodeIndex == offset) {
            currentLineInformationIndex = true;
            lineNumber = chunk->lineInformation[currentLineInformationIndex].line;
            currentLineInformationIndex++;
        }
        offset = disassembleInstruction(chunk, offset, lineNumber, showLineNumber);
        showLineNumber = false;
    }
}

int getLine(Chunk* chunk, int instructionIndex) {
    int lineNumber = -1;
    for (int i=0;i<chunk->lineInformationCount;i++) {
        if (chunk->lineInformation[i].correspondingBytecodeIndex<=instructionIndex) {
            lineNumber = chunk->lineInformation[i].line;
        } else {
            break;
        }
    }
    return lineNumber;
}

static int simpleInstruction(const char* name, int offset) {
    printf("%s\n", name);
    return offset+1;
}

static int instructionWithLong(const char* name, Chunk* chunk, int offset) {
    long *value = (void*)&chunk->code[offset+1];
    printf("%-32s %ld\n", name, *value);
    return offset+9;
}

static int instructionWithByte(const char* name, Chunk* chunk, int offset) {
    printf("%-32s %4hhu\n", name, chunk->code[offset+1]);
    return offset+2;
}

static int instructionWith4Byte(const char* name, Chunk* chunk, int offset) {
    unsigned int value = *(unsigned int*)&chunk->code[offset+1];
    printf("%-32s %d\n", name, value);
    return offset+5;
}

int disassembleInstruction(Chunk* chunk, int offset, int lineNumber, bool showLineNumber) {
    printf("%04lld ", offset);
    
    if (showLineNumber) {
        printf("%4lld ", lineNumber);
    } else {
        printf("   | ");
    }
    
#define SIMPLE_INSTRUCTION(name) case name: return simpleInstruction(#name, offset);
    uint8_t instruction = chunk->code[offset];
    switch (instruction) {
        SIMPLE_INSTRUCTION(OP_return)
        SIMPLE_INSTRUCTION(OP_true)
        SIMPLE_INSTRUCTION(OP_false)
        SIMPLE_INSTRUCTION(OP_pop)
        case OP_pop_n:
            return instructionWithByte("OP_pop_n", chunk, offset);
        case OP_loadEmbeddedByteConstant:
            return instructionWithByte("OP_loadEmbeddedByteConstant", chunk, offset);
        case OP_loadEmbeddedLongConstant:
            return instructionWithLong("OP_loadEmbeddedLongConstant", chunk, offset);
        case OP_loadConstantFromTable:
            return instructionWithByte("OP_loadConstantFromTable", chunk, offset);
        case OP_LONG_loadConstantFromTable:
            return instructionWith4Byte("OP_LONG_loadConstantFromTable", chunk, offset);
        SIMPLE_INSTRUCTION(OP_negateInt)
        SIMPLE_INSTRUCTION(OP_negateDouble)
        SIMPLE_INSTRUCTION(OP_notBool)
        SIMPLE_INSTRUCTION(OP_greaterInt)
        SIMPLE_INSTRUCTION(OP_greaterDouble)
        SIMPLE_INSTRUCTION(OP_greaterString)
        SIMPLE_INSTRUCTION(OP_greaterOrEqualInt)
        SIMPLE_INSTRUCTION(OP_greaterOrEqualDouble)
        SIMPLE_INSTRUCTION(OP_greaterOrEqualString)
        SIMPLE_INSTRUCTION(OP_lessInt)
        SIMPLE_INSTRUCTION(OP_lessDouble)
        SIMPLE_INSTRUCTION(OP_lessString)
        SIMPLE_INSTRUCTION(OP_lessOrEqualInt)
        SIMPLE_INSTRUCTION(OP_lessOrEqualDouble)
        SIMPLE_INSTRUCTION(OP_lessOrEqualString)
        SIMPLE_INSTRUCTION(OP_equalEqualInt)
        SIMPLE_INSTRUCTION(OP_equalEqualDouble)
        SIMPLE_INSTRUCTION(OP_equalEqualString)
        SIMPLE_INSTRUCTION(OP_equalEqualBool)
        SIMPLE_INSTRUCTION(OP_notEqualInt)
        SIMPLE_INSTRUCTION(OP_notEqualDouble)
        SIMPLE_INSTRUCTION(OP_notEqualString)
        SIMPLE_INSTRUCTION(OP_notEqualBool)
        SIMPLE_INSTRUCTION(OP_minusInt)
        SIMPLE_INSTRUCTION(OP_minusDouble)
        SIMPLE_INSTRUCTION(OP_divideInt)
        SIMPLE_INSTRUCTION(OP_divideDouble)
        SIMPLE_INSTRUCTION(OP_multiplyInt)
        SIMPLE_INSTRUCTION(OP_multiplyDouble)
        SIMPLE_INSTRUCTION(OP_intDivideInt)
        SIMPLE_INSTRUCTION(OP_intDivideDouble)
        SIMPLE_INSTRUCTION(OP_modInt)
        SIMPLE_INSTRUCTION(OP_addInt)
        SIMPLE_INSTRUCTION(OP_addDouble)
        SIMPLE_INSTRUCTION(OP_addString)
        SIMPLE_INSTRUCTION(OP_orBool)
        SIMPLE_INSTRUCTION(OP_andBool)
        SIMPLE_INSTRUCTION(OP_outputInt)
        SIMPLE_INSTRUCTION(OP_outputDouble)
        SIMPLE_INSTRUCTION(OP_outputBoolean)
        SIMPLE_INSTRUCTION(OP_outputString)
        SIMPLE_INSTRUCTION(OP_outputArray)
        SIMPLE_INSTRUCTION(OP_outputAny)
        SIMPLE_INSTRUCTION(OP_outputClass)
        SIMPLE_INSTRUCTION(OP_outputVoid)
        default:
            printf("Unknown opcode %d\n", instruction);
            return offset+1;
    }
    return 0;
#undef SIMPLE_INSTRUCTION
}
