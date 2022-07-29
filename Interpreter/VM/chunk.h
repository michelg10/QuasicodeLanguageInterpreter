#ifndef chunk_h
#define chunk_h

#include "OpCode.h"
#include "common.h"
#include "memory.h"
typedef struct {
    int line;
    int correspondingBytecodeIndex;
} LineDebugInformation;

typedef struct {
    int codeCount;
    int lineInformationCount;
    int codeCapacity;
    int lineInformationCapacity;
#ifdef USE_EXTERNAL_CONSTANTS
    int constantsCount;
    int constantsCapacity;
#endif
    uint8_t* code;
    LineDebugInformation* lineInformation;
#ifdef USE_EXTERNAL_CONSTANTS
    uint64_t* constants;
#endif
    int maxDepth;
} Chunk;

Chunk* initChunk(void);
void freeChunk(Chunk* chunk);
void writeChunk(Chunk* chunk, uint8_t byte, int line);
void writeChunkUInt(Chunk* chunk, uint32_t val, int line);
void writeChunkLong(Chunk* chunk, uint64_t val, int line);

void writeChunkExplicitlyTypedValueObject(Chunk* chunk, void* object, int classId, int line);
void writeChunkExplicitlyTypedInt(Chunk* chunk, long value, int line);
void writeChunkExplicitlyTypedDouble(Chunk* chunk, double value, int line);
void writeChunkExplicitlyTypedBoolean(Chunk* chunk, bool value, int line);

int getChunkCodeCount(Chunk* chunk);
int addConstant(Chunk* chunk, uint64_t data);
void setMaxDepth(Chunk* chunk, int maxDepth);

#endif
