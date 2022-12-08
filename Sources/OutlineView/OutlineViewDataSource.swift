import Cocoa

@available(macOS 10.15, *)
class OutlineViewDataSource<Data: Sequence, Drop: DropReceiver>: NSObject, NSOutlineViewDataSource
where Drop.DataElement == Data.Element {
    var items: [OutlineViewItem<Data>]
    var dropReceiver: Drop?
    var dragWriter: OutlineView<Data, Drop>.DragSourceWriter?
    let childrenPath: KeyPath<Data.Element, Data?>

    init(items: [OutlineViewItem<Data>], children: KeyPath<Data.Element, Data?>) {
        self.items = items
        self.childrenPath = children
    }

    private func typedItem(_ item: Any) -> OutlineViewItem<Data> {
        item as! OutlineViewItem<Data>
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        numberOfChildrenOfItem item: Any?
    ) -> Int {
        if let item = item.map(typedItem) {
            return item.children?.count ?? 0
        } else {
            return items.count
        }
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        isItemExpandable item: Any
    ) -> Bool {
        typedItem(item).children != nil
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        child index: Int,
        ofItem item: Any?
    ) -> Any {
        if let item = item.map(typedItem) {
            // Should only be called if item has children.
            return item.children.unsafelyUnwrapped[index]
        } else {
            return items[index]
        }
    }
    
    // MARK: - Drag & Drop
    
    func outlineView(
        _ outlineView: NSOutlineView,
        pasteboardWriterForItem item: Any
    ) -> NSPasteboardWriting? {
        
        guard let writer = dragWriter,
              let writeData = writer(typedItem(item).value)
        else { return nil }
        
        return writeData
    }
    
    private func dropTargetData(dragInfo: NSDraggingInfo, item: Any?, childIndex: Int) -> DropTarget<Data.Element>? {
        guard let dropReceiver = dropReceiver,
              let pasteboardItems = dragInfo.draggingPasteboard.pasteboardItems,
              !pasteboardItems.isEmpty
        else { return nil }
        
        let decodedItems = pasteboardItems.compactMap {
            dropReceiver.readPasteboard(item: $0)
        }
        
        let dropTarget = DropTarget<Data.Element>(
            items: decodedItems,
            intoElement: item.map({ typedItem($0) })?.value,
            childIndex: childIndex == NSOutlineViewDropOnItemIndex ? nil : childIndex
        )
        return dropTarget
    }
    
    func outlineView(
        _ outlineView: NSOutlineView,
        validateDrop info: NSDraggingInfo,
        proposedItem item: Any?,
        proposedChildIndex index: Int
    ) -> NSDragOperation {
        
        guard let dropTarget = dropTargetData(dragInfo: info, item: item, childIndex: index)
        else { return [] }
        
        let validationResult = dropReceiver!.validateDrop(target: dropTarget)

        switch validationResult {
            
        case .copy:
            return .copy
        case .move:
            return .move
        case .deny:
            return []
        case let .copyRedirect(item, childIndex):
            let redirectTarget = item.map { OutlineViewItem<Data>(value: $0, children: childrenPath) }
            outlineView.setDropItem(redirectTarget, dropChildIndex: childIndex ?? NSOutlineViewDropOnItemIndex)
            return .copy
        case let .moveRedirect(item, childIndex):
            let redirectTarget = item.map { OutlineViewItem<Data>(value: $0, children: childrenPath) }
            outlineView.setDropItem(redirectTarget, dropChildIndex: childIndex ?? NSOutlineViewDropOnItemIndex)
            return .move
        }
        
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        acceptDrop info: NSDraggingInfo,
        item: Any?,
        childIndex index: Int
    ) -> Bool {
        
        guard let dropTarget = dropTargetData(dragInfo: info, item: item, childIndex: index)
        else { return false }
        
        return dropReceiver!.acceptDrop(target: dropTarget)
    }

}
