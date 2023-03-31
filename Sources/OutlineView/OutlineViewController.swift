import Cocoa
import Combine

@available(macOS 10.15, *)
public class OutlineViewController<ID: Hashable, Data: Sequence, Drop: DropReceiver>: NSViewController
where Drop.DataElement == Data.Element {
    let outlineView = NSOutlineView()
    let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 400))
    
    let id: ID
    let dataSource: OutlineViewDataSource<Data, Drop>
    let delegate: OutlineViewDelegate<Data>
    let updater = OutlineViewUpdater<Data>()
    var reloadListener: AnyCancellable?

    let childrenSource: ChildSource<Data>

    init(
        id: ID,
        data: Data,
        childrenSource: ChildSource<Data>,
        content: @escaping (Data.Element) -> NSView,
        selectionChanged: @escaping (Data.Element?) -> Void,
        separatorInsets: ((Data.Element) -> NSEdgeInsets)?
    ) {
        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalRuler = true
        scrollView.drawsBackground = false

        outlineView.autoresizesOutlineColumn = false
        outlineView.headerView = nil
        outlineView.usesAutomaticRowHeights = true
        outlineView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle

        let onlyColumn = NSTableColumn()
        onlyColumn.resizingMask = .autoresizingMask
        outlineView.addTableColumn(onlyColumn)

        dataSource = OutlineViewDataSource(
            items: data.map { OutlineViewItem(value: $0, children: childrenSource) },
            childSource: childrenSource
        )
        delegate = OutlineViewDelegate(
            content: content,
            selectionChanged: selectionChanged,
            separatorInsets: separatorInsets)
        outlineView.dataSource = dataSource
        outlineView.delegate = delegate

        self.id = id
        self.childrenSource = childrenSource
        
        super.init(nibName: nil, bundle: nil)

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        reloadListener = NotificationCenter
            .default
            .publisher(for: .OutlineViewReload)
            .filter { $0.outlineId(as: ID.self) == id }
            .sink { [weak self] note in
                let itemIds = note.outlineItemIds(as: Data.Element.ID.self)
                self?.reloadRowData(itemIds: itemIds)
            }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    public override func loadView() {
        view = NSView()
    }

    public override func viewWillAppear() {
        // Size the column to take the full width. This combined with
        // the uniform column autoresizing style allows the column to
        // adjust its width with a change in width of the outline view.
        outlineView.sizeLastColumnToFit()
        super.viewWillAppear()
    }
}

// MARK: - Performing updates
@available(macOS 10.15, *)
extension OutlineViewController {
    func updateData(newValue: Data) {
        let newState = newValue.map { OutlineViewItem(value: $0, children: childrenSource) }

        outlineView.beginUpdates()

        dataSource.items = newState
        updater.performUpdates(
            outlineView: outlineView,
            oldStateTree: dataSource.treeMap,
            newState: newState,
            parent: nil)

        outlineView.endUpdates()
        
        // After updates, dataSource must rebuild its idTree for future updates
        dataSource.rebuildIDTree(rootItems: newState, outlineView: outlineView)
    }

    func changeSelectedItem(to item: Data.Element?) {
        delegate.changeSelectedItem(
            to: item.map { OutlineViewItem(value: $0, children: childrenSource) },
            in: outlineView)
    }

    @available(macOS 11.0, *)
    func setStyle(to style: NSOutlineView.Style) {
        outlineView.style = style
    }

    func setIndentation(to width: CGFloat) {
        outlineView.indentationPerLevel = width
    }

    func setRowSeparator(visibility: SeparatorVisibility) {
        switch visibility {
        case .hidden:
            outlineView.gridStyleMask = []
        case .visible:
            outlineView.gridStyleMask = .solidHorizontalGridLineMask
        }
    }

    func setRowSeparator(color: NSColor) {
        guard color != outlineView.gridColor else {
            return
        }

        outlineView.gridColor = color
        outlineView.reloadData()
    }
    
    /// Calls `reloadData()` on the outlineView. Currently does not
    /// use individual itemIds, although if implemented you could
    /// reload individual rows. OutlineViewController and DataSource
    /// would need to be changed in that case.
    func reloadRowData(itemIds: [Data.Element.ID]?) {
        // If no itemIds are given, reload everything
        guard let itemIds,
              !itemIds.isEmpty
        else {
            outlineView.reloadData()
            return
        }
        
        var itemsToReload = Set(itemIds)
        let rowCount = outlineView.numberOfRows
        var currentRow = 0
        
        // Reload individual rows while IDs are available
        while currentRow < rowCount,
              !itemsToReload.isEmpty
        {
            if let rowItem = outlineView.item(atRow: currentRow),
               let identifiableItem = rowItem as? any Identifiable,
               let itemId = identifiableItem.id as? Data.Element.ID,
               itemsToReload.contains(itemId)
            {
                outlineView.reloadItem(rowItem)
                itemsToReload.remove(itemId)
            }
            currentRow += 1
        }
    }
        
    func setDragSourceWriter(_ writer: DragSourceWriter<Data.Element>?) {
        dataSource.dragWriter = writer
    }
    
    func setDropReceiver(_ receiver: Drop?) {
        dataSource.dropReceiver = receiver
    }
    
    func setAcceptedDragTypes(_ acceptedTypes: [NSPasteboard.PasteboardType]?) {
        outlineView.unregisterDraggedTypes()
        if let acceptedTypes,
           !acceptedTypes.isEmpty
        {
            outlineView.registerForDraggedTypes(acceptedTypes)
        }
    }
}
