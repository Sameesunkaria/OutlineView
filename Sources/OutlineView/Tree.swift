
class TreeNode<T> {
    
    var value: T
    weak var parent: TreeNode<T>?
    var children: [TreeNode<T>]?
    
    var isLeaf: Bool { children == nil }
    
    init(value: T) {
        self.value = value
    }
    
    func setIsLeaf(_ newVal: Bool) {
        children = newVal ? nil : []
    }
    
    @discardableResult
    func addChild(_ childValue: T) -> TreeNode<T>? {
        guard !isLeaf else { return nil }
        
        let child = TreeNode(value: childValue)
        children!.append(child)
        child.parent = self
        return child
    }
    
    @discardableResult
    func addChild(_ childNode: TreeNode<T>) -> TreeNode<T>? {
        guard !isLeaf else { return nil }
        
        children!.append(childNode)
        childNode.parent = self
        return childNode
    }
    
    @discardableResult
    func addChildren(_ childValues: [T]) -> [TreeNode<T>]? {
        guard !isLeaf else { return nil }
        return childValues.map { addChild($0)! }
    }
    
    @discardableResult
    func addChildren(_ childNodes: [TreeNode<T>]) -> [TreeNode<T>]? {
        guard !isLeaf else { return nil }
        return childNodes.map { addChild($0)! }
    }
    
}
