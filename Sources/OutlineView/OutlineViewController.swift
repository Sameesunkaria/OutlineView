import Cocoa

public class OutlineViewController<Item: Identifiable>: NSViewController {
    let outlineView = NSOutlineView()
    let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 400))
    
    let dataSource: OutlineViewDataSource<Item>
    let delegate: OutlineViewDelegate<Item>

    let childrenPath: KeyPath<Item, [Item]?>

    init(
        items: [Item],
        children: KeyPath<Item, [Item]?>,
        rowContent: @escaping (Item) -> NSView,
        selectionChanged: @escaping (Item?) -> Void
    ) {
        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalRuler = true
        scrollView.drawsBackground = false

        outlineView.autoresizesOutlineColumn = false
        outlineView.headerView = nil
        outlineView.usesAutomaticRowHeights = true
        outlineView.selectionHighlightStyle = .sourceList
        outlineView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle

        let onlyColumn = NSTableColumn()
        onlyColumn.resizingMask = .autoresizingMask
        outlineView.addTableColumn(onlyColumn)

        dataSource = OutlineViewDataSource(
            items: items.map { OutlineViewItem(value: $0, children: children) })
        delegate = OutlineViewDelegate(rowContent: rowContent, selectionChanged: selectionChanged)
        outlineView.dataSource = dataSource
        outlineView.delegate = delegate

        childrenPath = children

        super.init(nibName: nil, bundle: nil)

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
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
extension OutlineViewController {
    func updateItems(newValue: [Item]) {
        let newState = newValue.map { OutlineViewItem(value: $0, children: childrenPath) }

        outlineView.beginUpdates()

        let oldState = dataSource.items
        dataSource.items = newState
        dataSource.performUpdates(
            outlineView: outlineView,
            oldState: oldState,
            newState: newState,
            parent: nil)

        outlineView.endUpdates()
    }

    func changeSelectedItem(to item: Item?) {
        delegate.changeSelectedItem(
            to: item.map { OutlineViewItem(value: $0, children: childrenPath) },
            in: outlineView)
    }
}
