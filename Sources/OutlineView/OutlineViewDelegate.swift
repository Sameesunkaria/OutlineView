import Cocoa

class OutlineViewDelegate<Data: Sequence>: NSObject, NSOutlineViewDelegate
where Data.Element: Identifiable {
    let content: (Data.Element) -> NSView
    let selectionChanged: (Data.Element?) -> Void
    var selectedItem: OutlineViewItem<Data>?

    func typedItem(_ item: Any) -> OutlineViewItem<Data> {
        item as! OutlineViewItem<Data>
    }

    init(
        content: @escaping (Data.Element) -> NSView,
        selectionChanged: @escaping (Data.Element?) -> Void
    ) {
        self.content = content
        self.selectionChanged = selectionChanged
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        viewFor tableColumn: NSTableColumn?,
        item: Any
    ) -> NSView? {
        content(typedItem(item).value)
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        heightOfRowByItem item: Any
    ) -> CGFloat {
        // It appears that for outline views with automatic row heights, the
        // initial height of the row still needs to be provided. Not providing
        // a height for each cell would lead to the outline view defaulting to the
        // `outlineView.rowHeight` when inserted. The cell may resize to the correct
        // height if the outlinew view is reloaded. I am not able to find a better
        // way to compute the final width of the cell other than hard-coding some
        // of the constants.

        // Width of disclosure indicator. Obtained by inspecting the view heirarchy.
        let outlineCellWidth: CGFloat = 13.0
        // Distance the disclosure indicator is pushed-back from the leading edge of the column.
        let outlineCellPushback: CGFloat = 4.0

        let column = outlineView.tableColumns.first.unsafelyUnwrapped
        let indentInset = CGFloat(outlineView.level(forItem: item)) * outlineView.indentationPerLevel

        let inset = indentInset + outlineCellWidth - outlineCellPushback
        let width = column.width - inset

        // The view is provided by the user. And the width info is not provided
        // separately. It does not seem efficient to create a new cell to find
        // out the width of a cell. In practice I have not experienced any issues
        // with a moderate number of cells.
        let view = content(typedItem(item).value)
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
        return view.fittingSize.height
    }

    func outlineViewItemDidExpand(_ notification: Notification) {
        let outlineView = notification.object as! NSOutlineView
        if outlineView.selectedRow == -1 {
            selectRow(for: selectedItem, in: outlineView)
        }
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        let outlineView = notification.object as! NSOutlineView
        if outlineView.selectedRow != -1 {
            let newSelection = outlineView.item(atRow: outlineView.selectedRow).map(typedItem)
            if selectedItem?.id != newSelection?.id {
                selectedItem = newSelection
                selectionChanged(selectedItem?.value)
            }
        }
    }

    func selectRow(
        for item: OutlineViewItem<Data>?,
        in outlineView: NSOutlineView
    ) {
        // Returns -1 if row is not found.
        let index = outlineView.row(forItem: selectedItem)
        if index != -1 {
            outlineView.selectRowIndexes(IndexSet([index]), byExtendingSelection: false)
        } else {
            outlineView.deselectAll(nil)
        }
    }

    func changeSelectedItem(
        to item: OutlineViewItem<Data>?,
        in outlineView: NSOutlineView
    ) {
        selectedItem = item
        selectRow(for: selectedItem, in: outlineView)
    }
}
