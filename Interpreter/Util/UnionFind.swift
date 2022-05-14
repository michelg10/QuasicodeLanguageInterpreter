class UnionFind {
    var parent: [Int]
    
    init(size: Int) {
        parent = Array(repeating: 0, count: size)
        for i in 0..<size {
            parent[i] = i
        }
    }
    
    func findParent(_ x: Int) -> Int {
        if x == parent[x] {
            return x
        } else {
            parent[x] = findParent(parent[x])
            return parent[x]
        }
    }
    
    func unite(_ x1: Int, _ x2: Int) {
        let x1Par = findParent(x1)
        let x2Par = findParent(x2)
        
        if x1Par == x2Par {
            return
        }
        
        parent[x2Par] = x1Par
    }
}
