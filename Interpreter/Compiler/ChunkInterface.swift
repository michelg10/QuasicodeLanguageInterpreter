class ChunkInterface {
    static func writeInstructionToChunk(chunk: UnsafeMutablePointer<Chunk>!, op: OpCode, line: Int) {
        writeChunk(chunk, UInt8(op.rawValue), Int32(line))
    }

    static func writeByteToChunk(chunk: UnsafeMutablePointer<Chunk>!, data: UInt8, line: Int) {
        writeChunk(chunk, data, Int32(line))
    }
    
    static func writeUIntToChunk(chunk: UnsafeMutablePointer<Chunk>!, data: UInt32, line: Int) {
        writeChunkUInt(chunk, data, Int32(line))
    }

    static func writeLongToChunk(chunk: UnsafeMutablePointer<Chunk>!, data: UInt64, line: Int) {
        writeChunkLong(chunk, data, Int32(line))
    }
    
    static func addConstantToChunk(chunk: UnsafeMutablePointer<Chunk>!, data: UInt64) -> Int {
        return Int(addConstant(chunk, data))
    }
}
