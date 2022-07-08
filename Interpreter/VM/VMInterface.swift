class VMInterface {
    func run(chunk: UnsafeMutablePointer<Chunk>!) {
        let vm = initVM()
        
        interpret(vm, chunk)
        
        freeVM(vm)
    }
}
