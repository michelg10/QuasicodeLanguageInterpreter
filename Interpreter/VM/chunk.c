#include "chunk.h"
#include <stdlib.h>
#include <string.h>

void resetChunk(Chunk* chunk) {
    chunk->codeCapacity = 0;
    chunk->constantsCapacity = 0;
    chunk->lineInformationCapacity = 0;
    chunk->codeCount = 0;
    chunk->constantsCount = 0;
    chunk->lineInformationCount = 0;
    chunk->code = NULL;
    chunk->constants = NULL;
    chunk->lineInformation = NULL;
    chunk->constantsDebugType = NULL;
    chunk->maxDepth = 0;
}

Chunk* initChunk() {
    Chunk* chunk = malloc(sizeof *chunk);
    resetChunk(chunk);
    return chunk;
}

void freeChunk(Chunk* chunk) {
    NOVM_FREE_ARRAY(uint8_t, chunk->code);
    NOVM_FREE_ARRAY(uint8_t, chunk->constants);
    NOVM_FREE_ARRAY(LineInformation, chunk->lineInformation);
    if (chunk->constantsDebugType != NULL) {
        NOVM_FREE_ARRAY(Type, chunk->constantsDebugType);
    }
    resetChunk(chunk);
    chunk = novm_reallocate(chunk, 0);
}

void writeChunk(Chunk* chunk, uint8_t byte, int line) {
    if (chunk->codeCount+1>chunk->codeCapacity) {
        const int newCodeCapacity = GROW_CAPACITY(chunk->codeCapacity);
        chunk->code = NOVM_GROW_ARRAY(uint8_t, chunk->code, newCodeCapacity);
        chunk->codeCapacity = newCodeCapacity;
    }
    
    chunk->code[chunk->codeCount] = byte;
    chunk->codeCount++;
    
    bool shouldEncodeLineInformation = false;
    if (chunk->lineInformationCount == 0) {
        shouldEncodeLineInformation = true;
    } else {
        shouldEncodeLineInformation = (chunk->lineInformation[chunk->lineInformationCount-1].line != line);
    }
    
    if (shouldEncodeLineInformation) {
        if (chunk->lineInformationCount+1>chunk->lineInformationCapacity) {
            const int newLineInformationCapacity = GROW_CAPACITY(chunk->lineInformationCapacity);
            chunk->lineInformation = NOVM_GROW_ARRAY(LineDebugInformation, chunk->lineInformation, newLineInformationCapacity);
            chunk->lineInformationCapacity = newLineInformationCapacity;
        }
        
        chunk->lineInformation[chunk->lineInformationCount] = (LineDebugInformation){line, chunk->codeCount-1};
        chunk->lineInformationCount++;
    }
}

void writeChunkLong(Chunk* chunk, uint64_t val, int line) {
    for (int i=0;i<8;i++) {
        uint8_t byte;
        memcpy(&byte, (&val)+i, 1);
        writeChunk(chunk, byte, line);
    }
}

int getChunkCodeCount(Chunk* chunk) {
    return chunk->codeCount;
}

int addConstant(Chunk* chunk, uint8_t* bytes, int len, Type type) {
    if (chunk->constantsCount+len>chunk->constantsCapacity) {
        int newConstantsCapacity = GROW_CAPACITY(chunk->constantsCount);
        while (newConstantsCapacity<chunk->codeCount+len) {
            newConstantsCapacity = GROW_CAPACITY(newConstantsCapacity);
        }
        chunk->constants = NOVM_GROW_ARRAY(uint8_t, chunk->constants, newConstantsCapacity);
        chunk->constantsCapacity = newConstantsCapacity;
    }
    const int index = chunk->constantsCount;
    memcpy(chunk->constants+chunk->constantsCount, bytes, len);
    chunk->constantsCount+=len;
    return index;
}

void setMaxDepth(Chunk* chunk, int maxDepth) {
    chunk->maxDepth = maxDepth;
}
