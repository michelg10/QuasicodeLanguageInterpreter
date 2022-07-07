#ifndef disassembler_h
#define disassembler_h

#include "chunk.h"

int getLine(Chunk* chunk, int instructionIndex);
void disassembleChunk(Chunk* chunk, const char* name);
int disassembleInstruction(Chunk* chunk, int offset, int lineNumber, bool showLineNumber);

#endif /* disassembler_h */
