func writeInstructionToChunk(chunk: UnsafeMutablePointer<Chunk>!, op: OpCode, line: Int) {
    writeChunk(chunk, UInt8(op.rawValue), Int32(line))
}

func writeByteToChunk(chunk: UnsafeMutablePointer<Chunk>!, data: UInt8, line: Int) {
    writeChunk(chunk, data, Int32(line))
}

func writeLongToChunk(chunk: UnsafeMutablePointer<Chunk>!, data: UInt64, line: Int) {
    writeChunkLong(chunk, data, Int32(line))
}
