import Cocoa
import Combine

@available(macOS 10.15, *)
class OutlineViewDataSource<Data: Sequence, Drop: DropReceiver>: NSObject, NSOutlineViewDataSource
where Drop.DataElement == Data.Element {
    var items: [OutlineViewItem<Data>]
    var dropReceiver: Drop
    var dragWriter: DragSourceWriter<Data.Element>?
    let childrenSource: ChildSource<Data>
    
    var treeMap: TreeMap<Data.Element.ID>
    
    private var dropExpansionNotificationToken: AnyCancellable? {
        didSet {
            // In case the original notification listener doesn't stop itself
            // as set up in `acceptDrop...`, add this as a backup to end the
            // notification listener after a short period.
            if dropExpansionNotificationToken != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.dropExpansionNotificationToken = nil
                }
            }
        }
    }
    private var willExpandToken: AnyCancellable?
    private var didCollapseToken: AnyCancellable?
        
    init(items: [OutlineViewItem<Data>], childSource: ChildSource<Data>, dropReceiver: Drop) {
        self.items = items
        self.childrenSource = childSource
        self.dropReceiver = dropReceiver
        
        treeMap = TreeMap()
        for item in items {
            treeMap.addItem(item.value.id, isLeaf: item.children == nil, intoItem: nil, atIndex: nil)
        }
        
        super.init()
        
        // Listen for expand/collapse notifications in order to keep TreeMap up to date
        willExpandToken = NotificationCenter.default.publisher(for: NSOutlineView.itemWillExpandNotification)
            .receive(on: DispatchQueue.main)
            .compactMap { NSOutlineView.expansionNotificationInfo($0) }
            .sink(receiveValue: receiveItemWillExpandNotification)
        didCollapseToken = NotificationCenter.default.publisher(for: NSOutlineView.itemDidCollapseNotification)
            .receive(on: DispatchQueue.main)
            .compactMap { NSOutlineView.expansionNotificationInfo($0) }
            .sink(receiveValue: receiveItemDidCollapseNotification)
    }
        
    func rebuildIdTree(rootItems: [OutlineViewItem<Data>], outlineView: NSOutlineView) {
        treeMap = TreeMap(rootItems: rootItems, itemIsExpanded: { outlineView.isItemExpanded($0) })
    }
    
    private func typedItem(_ item: Any) -> OutlineViewItem<Data> {
        item as! OutlineViewItem<Data>
    }

    // MARK: - Basic Data Source
    
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
        
    func outlineView(
        _ outlineView: NSOutlineView,
        validateDrop info: NSDraggingInfo,
        proposedItem item: Any?,
        proposedChildIndex index: Int
    ) -> NSDragOperation {
        guard let dropTarget = dropTargetData(in: outlineView, dragInfo: info, item: item, childIndex: index)
        else { return [] }
        
        let validationResult = dropReceiver.validateDrop(target: dropTarget)

        switch validationResult {
        case .copy:
            return .copy
        case .move:
            return .move
        case .deny:
            return []
        case let .copyRedirect(item, childIndex):
            let redirectTarget = item.map { OutlineViewItem<Data>(value: $0, children: childrenSource) }
            outlineView.setDropItem(redirectTarget, dropChildIndex: childIndex ?? NSOutlineViewDropOnItemIndex)
            return .copy
        case let .moveRedirect(item, childIndex):
            let redirectTarget = item.map { OutlineViewItem<Data>(value: $0, children: childrenSource) }
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
        guard let dropTarget = dropTargetData(in: outlineView, dragInfo: info, item: item, childIndex: index)
        else { return false }
        
        // Perform `acceptDrop(target:)` to get result of drop
        let dropIsSuccessful = dropReceiver.acceptDrop(target: dropTarget)
        
        // If drop was successful, but onto an unexpanded item, a quirk of NSOutlineView
        // will cause the item to expand with the newly dropped item already in it, which
        // messes up OutlineViewUpdater's attempt to update the contents of the item (by adding
        // the dragged items onto items already displayed in the parent item).
        // To fix this, we briefly listen for itemDidExpandNotification, and reload the item just
        // after it expands, then cancel our listener.
        if dropIsSuccessful,
           !outlineView.isItemExpanded(item)
        {
            dropExpansionNotificationToken = NotificationCenter.default
                .publisher(for: NSOutlineView.itemDidExpandNotification, object: outlineView)
                .compactMap { NSOutlineView.expansionNotificationInfo($0) }
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: receiveItemDidExpandNotification)
        }
        
        return dropIsSuccessful
    }
}

// MARK: - Helper Functions

@available(macOS 10.15, *)
private extension OutlineViewDataSource {
    func receiveItemDidExpandNotification(outlineView: NSOutlineView, expandedObject: Any) {
        // Notification only needs to be received once, so release the observer
        dropExpansionNotificationToken = nil
        
        // Reload the item and its children in order to make sure the newly-expanded
        // item displays the correct children after update.
        DispatchQueue.main.async {
            outlineView.reloadItem(expandedObject, reloadChildren: true)
        }
    }

    func receiveItemWillExpandNotification(outlineView: NSOutlineView, objectToExpand: Any) {
        guard let outlineDataSource = outlineView.dataSource,
              outlineDataSource.isEqual(self)
        else { return }
        
        let typedObjToExpand = typedItem(objectToExpand)
        let childIds = typedObjToExpand.children?.map { ($0.id, $0.children == nil) }
        treeMap.expandItem(typedObjToExpand.value.id, children: childIds!)
    }
    
    func receiveItemDidCollapseNotification(outlineView: NSOutlineView, collapsedObject: Any) {
        guard let outlineDataSource = outlineView.dataSource,
              outlineDataSource.isEqual(self)
        else { return }
        
        let typedObjThatCollapsed = typedItem(collapsedObject)
        treeMap.collapseItem(typedObjThatCollapsed.value.id)
    }
    
    func dropTargetData(
        in outlineView: NSOutlineView,
        dragInfo: NSDraggingInfo,
        item: Any?,
        childIndex: Int
    ) -> DropTarget<Data.Element>? {
        guard let pasteboardItems = dragInfo.draggingPasteboard.pasteboardItems,
              !pasteboardItems.isEmpty
        else { return nil }
        
        let decodedItems = pasteboardItems.compactMap {
            dropReceiver.readPasteboard(item: $0)
        }
        
        let dropTarget = DropTarget<Data.Element>(
            items: decodedItems,
            intoElement: item.map(typedItem)?.value,
            childIndex: childIndex == NSOutlineViewDropOnItemIndex ? nil : childIndex,
            isItemExpanded: { item in
                let typed = OutlineViewItem<Data>(value: item, children: self.childrenSource)
                return outlineView.isItemExpanded(typed)
            }
        )
        return dropTarget
    }
}

// MARK: - Extra Initializers

@available(macOS 10.15, *)
extension OutlineViewDataSource where Drop == NoDropReceiver<Data.Element> {
    convenience init(items: [OutlineViewItem<Data>], childSource: ChildSource<Data>) {
        self.init(
            items: items,
            childSource: childSource,
            dropReceiver: NoDropReceiver()
        )
    }
}
