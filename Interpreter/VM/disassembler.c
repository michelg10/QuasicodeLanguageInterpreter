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
    printf("%-32s %ld\n", name, value);
    return offset+9;
}

static int instructionWithByte(const char* name, Chunk* chunk, int offset) {
    printf("%-32s %4hhu\n", name, chunk->code[offset+1]);
    return offset+2;
}

static int instructionWith3Byte(const char* name, Chunk* chunk, int offset) {
    int value = *(long*)&chunk->code[offset];
    value = value>>4;
    printf("%-32s %d", name, value);
    return offset+4;
}

int disassembleInstruction(Chunk* chunk, int offset, int lineNumber, bool showLineNumber) {
    printf("%04lld ", offset);
    
    if (showLineNumber) {
        printf("%4lld ", lineNumber);
    } else {
        printf("   | ");
    }
    
    uint8_t instruction = chunk->code[offset];
    switch (instruction) {
        case OP_loadEmbeddedLongConstant:
            return instructionWithLong("OP_loadEmbeddedLongConstant", chunk, offset);
        case OP_true:
            return simpleInstruction("OP_true", offset);
        case OP_false:
            return simpleInstruction("OP_false", offset);
        case OP_pop:
            return simpleInstruction("OP_pop", offset);
        case OP_pop_n:
            return instructionWithByte("OP_pop_n", chunk, offset);
        case OP_loadConstantFromTable:
            return instructionWithByte("OP_loadConstantFromTable", chunk, offset);
        case OP_LONG_loadConstantFromTable:
            return instructionWith3Byte("OP_LONG_loadConstantFromTable", chunk, offset);
        case OP_addInt:
            return simpleInstruction("OP_addInt", offset);
        case OP_addDouble:
            return simpleInstruction("OP_addDouble", offset);
        case OP_addAny:
            return simpleInstruction("OP_addAny", offset);
        case OP_minusInt:
            return simpleInstruction("OP_minusInt", offset);
        case OP_minusDouble:
            return simpleInstruction("OP_minusDouble", offset);
        case OP_minusAny:
            return simpleInstruction("OP_minusAny", offset);
        case OP_multiplyInt:
            return simpleInstruction("OP_multiplyInt", offset);
        case OP_multiplyDouble:
            return simpleInstruction("OP_multiplyDouble", offset);
        case OP_multiplyAny:
            return simpleInstruction("OP_multiplyAny", offset);
        case OP_divideInt:
            return simpleInstruction("OP_divideInt", offset);
        case OP_divideDouble:
            return simpleInstruction("OP_divideDouble", offset);
        case OP_divideAny:
            return simpleInstruction("OP_divideAny", offset);
        case OP_intDivideInt:
            return simpleInstruction("OP_intDivideInt", offset);
        case OP_intDivideDouble:
            return simpleInstruction("OP_intDivideDouble", offset);
        case OP_intDivideAny:
            return simpleInstruction("OP_intDivideAny", offset);
        default:
            printf("Unknown opcode %d\n", instruction);
            return offset+1;
    }
    return 0;
}
