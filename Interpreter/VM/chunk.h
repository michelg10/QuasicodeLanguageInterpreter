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
    int constantsCount;
    int constantsCapacity;
    uint8_t* code;
    LineDebugInformation* lineInformation;
    uint8_t* constants;
    int maxDepth;
} Chunk;

Chunk* initChunk(void);
void freeChunk(Chunk* chunk);
void writeChunk(Chunk* chunk, uint8_t byte, int line);
void writeChunkLong(Chunk* chunk, uint64_t val, int line);
int getChunkCodeCount(Chunk* chunk);
int addConstant(Chunk* chunk, uint8_t *bytes, int len);
void setMaxDepth(Chunk* chunk, int maxDepth);

#endif
