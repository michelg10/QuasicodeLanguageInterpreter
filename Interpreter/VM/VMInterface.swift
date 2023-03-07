internal class VMInterface {
    func run(chunk: UnsafeMutablePointer<Chunk>!, classesRuntimeIdToClassNameArray: [String]) {
        var classNamesLength = UnsafeMutablePointer<Int32>.allocate(capacity: classesRuntimeIdToClassNameArray.count)
        for i in 0..<classesRuntimeIdToClassNameArray.count {
            classNamesLength[i] = Int32(classesRuntimeIdToClassNameArray[i].utf8.count + 1)
        }
        var classNamesArray = classesRuntimeIdToClassNameArray.map {
            UnsafePointer<Int8>(strdup($0))
        }
        var vm: UnsafeMutablePointer<VM>?
        classNamesArray.withUnsafeMutableBufferPointer { unsafePointer in
            vm = initVM(unsafePointer.baseAddress, classNamesLength, Int32(Int(classesRuntimeIdToClassNameArray.count)))
        }
        classNamesLength.deallocate()
        for ptr in classNamesArray {
            free(UnsafeMutablePointer(mutating: ptr))
        }
        
        interpret(vm, chunk)
        
        freeVM(vm)
    }
}
