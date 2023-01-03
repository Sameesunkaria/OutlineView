
/// An object representing the state of an OutlineView in which the content
/// of the OutlineView is Identifiable. The TreeMap should be able to stay
/// in sync with the OutlineView by reacting to data updates in the OutlineView.
@available(macOS 10.15, *)
class TreeMap<D: Hashable> {
    struct Node: Equatable {
        enum State: Equatable {
            case leaf
            case collapsed
            case expanded(children: [D])
        }

        var parentId: D?
        var state: State
        
        init(parentId: D?, isLeaf: Bool) {
            self.parentId = parentId
            self.state = isLeaf ? .leaf : .collapsed
        }
    }
        
    private (set) var rootData: [D] = []
    private var directory: [D : Node] = [:]
        
    init() {}
    
    init<Data: Sequence>(
        rootItems: [OutlineViewItem<Data>],
        itemIsExpanded: ((OutlineViewItem<Data>) -> Bool)
    ) where Data.Element: Identifiable, Data.Element.ID == D {
        // Add root items first
        for item in rootItems {
            addItem(item.value.id, isLeaf: item.children == nil, intoItem: nil, atIndex: nil)
        }
        
        // Loop through all items, adding their children if they're expanded
        var checkingItems: [(parentId: D?, item: OutlineViewItem<Data>)] = rootItems.map { (nil, $0) }
        while !checkingItems.isEmpty {
            let nextItem = checkingItems.popLast()!.item
            if itemIsExpanded(nextItem),
               let children = nextItem.children
            {
                let expandingChildren = children.map { ($0.id, $0.children == nil) }
                expandItem(nextItem.id, children: expandingChildren)
                checkingItems.append(contentsOf: children.map({ (nextItem.id, $0) }))
            }
        }
    }
    
    /// Adds an item to the TreeMap
    ///
    /// - Parameters:
    ///   - item: The ID of the item to add.
    ///   - isLeaf: True if this item can have no children.
    ///   - intoItem: The parent ID to insert this item into. If
    ///   intoItem is nil, the new item is inserted at the root level.
    ///   - atIndex: The index among other parent's children at which to
    ///   insert this item. If no index is given, the item is added to the
    ///   end of the array of children for the parent (or root if no
    ///   parent is given).
    func addItem(_ item: D, isLeaf: Bool, intoItem: D?, atIndex: Int?) {
        // Add to parent or root
        if let intoItem,
           let fullIntoItem = directory[intoItem],
           case var .expanded(intoChildren) = fullIntoItem.state
        {
            // Add to children of selected item
            if let atIndex {
                // insert at index
                intoChildren.insert(item, at: atIndex)
            } else if atIndex == nil {
                // append to end
                intoChildren.append(item)
            }
            
            directory[intoItem]!.state = .expanded(children: intoChildren)
        } else {
            // Add to root data
            if let atIndex {
                // insert at index
                rootData.insert(item, at: atIndex)
            } else {
                // append to end
                rootData.append(item)
            }
        }
        
        // create new node
        let newNode = Node(parentId: intoItem, isLeaf: isLeaf)
        directory[item] = newNode
    }
    
    /// Marks the item with the given ID as expanded by adding its
    /// children to the TreeMap
    ///
    /// - Parameters:
    ///   - item: the ID of the item to mark as expanded.
    ///   - children: An array of objects representing the expanded
    ///   item's children. Each child must have an ID and a boolean
    ///   indicating whether it is a leaf or internal node of the tree.
    func expandItem(_ item: D, children: [(id: D, isLeaf: Bool)]) {
        guard directory[item] != nil,
              case .collapsed = directory[item]!.state
        else { return }
        
        directory[item]?.state = .expanded(children: children.map(\.id))
        for child in children {
            directory[child.id] = Node(parentId: item, isLeaf: child.isLeaf)
        }
    }
    
    /// Marks the item with the given ID as collapsed/unexpanded by
    /// removing its children from the TreeMap
    ///
    /// - Parameters:
    ///   - item: The ID of the item to mark as collapsed.
    func collapseItem(_ item: D) {
        guard case let .expanded(existingChildIds) = directory[item]?.state
        else { return }
        directory[item]?.state = .collapsed
        for childId in existingChildIds {
            directory[childId] = nil
        }
    }
    
    /// Deletes an item from the TreeMap, along with all its children.
    ///
    /// - Parameter item: The ID of the item to remove.
    func removeItem(_ item: D) {
        // Remove all children from tree
        if case let .expanded(childIds) = directory[item]?.state {
            childIds.forEach { removeItem($0) }
        }
        
        // remove from parent
        if let parentId = directory[item]?.parentId,
           case var .expanded(siblingIDs) = directory[parentId]?.state,
           let childIdx = siblingIDs.firstIndex(of: item)
        {
            siblingIDs.remove(at: childIdx)
            directory[parentId]?.state = .expanded(children: siblingIDs)
        }
        
        // remove from root
        if let rootIdx = rootData.firstIndex(of: item) {
            rootData.remove(at: rootIdx)
        }
        
        // remove from directory
        directory[item] = nil
    }
    
    /// Gets the IDs of the children of the selected item if it is expanded.
    ///
    /// - Parameter item: the item to check for children.
    /// - Returns: An array of IDs of children if the item if it happens to
    /// be an internal node and is currently expanded.
    func currentChildrenOfItem(_ item: D) -> [D]? {
        switch directory[item]?.state {
        case let .expanded(children):
            return children
        default:
            return nil
        }
    }
    
    /// Tests whether the selected item is a leaf or an internal node that can expand.
    ///
    /// - Parameter item: the ID of the item to test
    /// - Returns: A boolean indicating whether the item can be expanded.
    func isItemExpandable(_ item: D) -> Bool {
        switch directory[item]?.state {
        case .none, .leaf:
            return false
        default:
            return true
        }
    }
    
    /// Tests whether the selected item is an expanded internal node.
    ///
    /// - Parameter item: The ID of the item to test.
    /// - Returns: A boolean indicating whether the item is currently expanded.
    func isItemExpanded(_ item: D) -> Bool {
        switch directory[item]?.state {
        case .expanded(_):
            return true
        default:
            return false
        }
    }
    
    /// Finds the full parentage of the selected item all the way from the root
    /// of the TreeMap
    ///
    /// - Parameter item: the ID of the item to search.
    /// - Returns: nil if the item doesn't exist in the TreeMap, otherwise an array
    /// of IDs to follow from the root of the TreeMap to get to the selected item,
    /// ending with the ID of the selected item.
    func lineageOfItem(_ item: D) -> [D]? {
        guard let node = directory[item] else { return nil }
        
        var result = [item]
        var parent = node.parentId
        while parent != nil {
            result.insert(parent!, at: 0)
            parent = directory[parent!]?.parentId
        }
        return result
    }
}

@available(macOS 10.15, *)
extension TreeMap: CustomStringConvertible {
    var description: String {
        var strings: [String] = []
        
        for rootItem in rootData {
            strings.append(contentsOf: descriptionStrings(for: rootItem))
        }
        
        return strings.joined(separator: "\n")
    }
    
    private func descriptionStrings(for item: D) -> [String] {
        let depth = lineageOfItem(item)!.count
        let selfDescription = "\(String(repeating: "- ", count: depth))\(item)"
        var res: [String] = [selfDescription]
        if case let .expanded(childIDs) = directory[item]?.state {
            childIDs.forEach { res.append(contentsOf: descriptionStrings(for: $0)) }
        }
        return res
    }
}

@available(macOS 10.15, *)
extension TreeMap.Node: Equatable {}

@available(macOS 10.15, *)
extension TreeMap: Equatable {
    static func == (lhs: TreeMap<D>, rhs: TreeMap<D>) -> Bool {
        lhs.directory == rhs.directory && lhs.rootData == rhs.rootData
    }
}
