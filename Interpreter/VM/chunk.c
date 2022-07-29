#include "chunk.h"
#include "ExplicitlyTypedValue.h"
#include <stdlib.h>
#include <string.h>

void resetChunk(Chunk* chunk) {
    chunk->codeCapacity = 0;
#ifdef USE_EXTERNAL_CONSTANTS
    chunk->constantsCapacity = 0;
#endif
    chunk->lineInformationCapacity = 0;
    chunk->codeCount = 0;
#ifdef USE_EXTERNAL_CONSTANTS
    chunk->constantsCount = 0;
#endif
    chunk->lineInformationCount = 0;
    chunk->code = NULL;
#ifdef USE_EXTERNAL_CONSTANTS
    chunk->constants = NULL;
#endif
    chunk->lineInformation = NULL;
    chunk->maxDepth = 0;
}

Chunk* initChunk() {
    Chunk* chunk = malloc(sizeof *chunk);
    resetChunk(chunk);
    return chunk;
}

void freeChunk(Chunk* chunk) {
    COMPILER_FREE_ARRAY(uint8_t, chunk->code);
#ifdef USE_EXTERNAL_CONSTANTS
    COMPILER_FREE_ARRAY(uint64_t, chunk->constants);
#endif
    COMPILER_FREE_ARRAY(LineInformation, chunk->lineInformation);
    resetChunk(chunk);
    chunk = compilerReallocate(chunk, 0);
}

void writeChunk(Chunk* chunk, uint8_t byte, int line) {
    if (chunk->codeCount+1>chunk->codeCapacity) {
        const int newCodeCapacity = GROW_CAPACITY(chunk->codeCapacity);
        chunk->code = COMPILER_GROW_ARRAY(uint8_t, chunk->code, newCodeCapacity);
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
            chunk->lineInformation = COMPILER_GROW_ARRAY(LineDebugInformation, chunk->lineInformation, newLineInformationCapacity);
            chunk->lineInformationCapacity = newLineInformationCapacity;
        }
        
        chunk->lineInformation[chunk->lineInformationCount] = (LineDebugInformation){line, chunk->codeCount-1};
        chunk->lineInformationCount++;
    }
}

void writeChunkLong(Chunk* chunk, uint64_t val, int line) {
    for (int i=0;i<8;i++) {
        uint8_t byte;
        memcpy(&byte, ((uint8_t*)(&val))+i, 1);
        writeChunk(chunk, byte, line);
    }
}

void writeChunkUInt(Chunk* chunk, uint32_t val, int line) {
    for (int i=0;i<4;i++) {
        uint8_t byte;
        memcpy(&byte, ((uint8_t*)(&val))+i, 1);
        writeChunk(chunk, byte, line);
    }
}

static void writeChunkExplicitlyTypedValue(Chunk* chunk, ExplicitlyTypedValue value, int line) {
    for (int i=0;i<16;i++) {
        uint8_t byte;
        memcpy(&byte, ((uint8_t*)(&value))+i, 1);
        writeChunk(chunk, byte, line);
    }
}

void writeChunkExplicitlyTypedValueObject(Chunk* chunk, void* object, int classId, int line) {
    writeChunkExplicitlyTypedValue(chunk, TYPED_VAL_FROM_OBJECT_SCALAR(classId, object), line);
}

void writeChunkExplicitlyTypedInt(Chunk* chunk, long value, int line) {
    writeChunkExplicitlyTypedValue(chunk, TYPED_VAL_FROM_INT_SCALAR(value), line);
}

void writeChunkExplicitlyTypedDouble(Chunk* chunk, double value, int line) {
    writeChunkExplicitlyTypedValue(chunk, TYPED_VAL_FROM_DOUBLE_SCALAR(value), line);
}

void writeChunkExplicitlyTypedBoolean(Chunk* chunk, bool value, int line) {
    writeChunkExplicitlyTypedValue(chunk, TYPED_VAL_FROM_BOOLEAN_SCALAR(value), line);
}

int getChunkCodeCount(Chunk* chunk) {
    return chunk->codeCount;
}

int addConstant(Chunk* chunk, uint64_t data) {
#ifdef USE_EXTERNAL_CONSTANTS
    if (chunk->constantsCount+1>chunk->constantsCapacity) {
        int newConstantsCapacity = GROW_CAPACITY(chunk->constantsCapacity);
        while (newConstantsCapacity<chunk->codeCount+1) {
            newConstantsCapacity = GROW_CAPACITY(newConstantsCapacity);
        }
        chunk->constants = COMPILER_GROW_ARRAY(uint64_t, chunk->constants, newConstantsCapacity);
        chunk->constantsCapacity = newConstantsCapacity;
    }
    const int index = chunk->constantsCount;
    chunk->constants[chunk->constantsCount] = data;
    chunk->constantsCount+=1;
    return index;
#else
    return -1;
#endif
}

void setMaxDepth(Chunk* chunk, int maxDepth) {
    chunk->maxDepth = maxDepth;
}
