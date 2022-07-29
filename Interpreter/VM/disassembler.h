#ifndef disassembler_h
#define disassembler_h

#include "chunk.h"

int getLine(Chunk* chunk, int instructionIndex);
void disassembleChunk(const char** classNames, Chunk* chunk, const char* name);
int disassembleInstruction(const char** classNames, Chunk* chunk, int offset, int lineNumber, bool showLineNumber);

#endif /* disassembler_h */
