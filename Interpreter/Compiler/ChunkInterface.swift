enum ChunkInterface {
    static func writeInstructionToChunk(chunk: UnsafeMutablePointer<Chunk>!, op: OpCode, index: Int) {
        writeChunk(chunk, UInt8(op.rawValue), Int32(index))
    }

    static func writeByteToChunk(chunk: UnsafeMutablePointer<Chunk>!, data: UInt8, index: Int) {
        writeChunk(chunk, data, Int32(index))
    }
    
    static func writeUIntToChunk(chunk: UnsafeMutablePointer<Chunk>!, data: UInt32, index: Int) {
        writeChunkUInt(chunk, data, Int32(index))
    }

    static func writeLongToChunk(chunk: UnsafeMutablePointer<Chunk>!, data: UInt64, index: Int) {
        writeChunkLong(chunk, data, Int32(index))
    }
    
    static func writeExplicitlyTypedValueObjectToChunk(
        chunk: UnsafeMutablePointer<Chunk>!,
        object: UnsafeMutableRawPointer!,
        classId: Int,
        index: Int
    ) {
        writeChunkExplicitlyTypedValueObject(chunk, object, Int32(classId), Int32(index))
    }
    
    static func writeExplicitlyTypedInt(chunk: UnsafeMutablePointer<Chunk>!, value: Int, index: Int) {
        writeChunkExplicitlyTypedInt(chunk, value, Int32(index))
    }
    
    static func writeExplicitlyTypedDouble(chunk: UnsafeMutablePointer<Chunk>!, value: Double, index: Int) {
        writeChunkExplicitlyTypedDouble(chunk, value, Int32(index))
    }
    
    static func writeExplicitlyTypedBoolean(chunk: UnsafeMutablePointer<Chunk>!, value: Bool, index: Int) {
        writeChunkExplicitlyTypedBoolean(chunk, value, Int32(index))
    }
    
    static func addConstantToChunk(chunk: UnsafeMutablePointer<Chunk>!, data: UInt64) -> Int {
        return Int(addConstant(chunk, data))
    }
}
