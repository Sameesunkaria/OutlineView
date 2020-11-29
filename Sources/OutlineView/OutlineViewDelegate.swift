//
//  OutlineViewDelegate.swift
//  
//
//  Created by Samar Sunkaria on 11/21/20.
//

import Cocoa
import SwiftUI

class OutlineViewDelegate<Item: Identifiable & Equatable>: NSObject, NSOutlineViewDelegate {
    let rowContent: (Item) -> NSView
    let selectionChanged: (Item?) -> Void
    var selectedItem: Item?

    func typedItem(_ item: Any) -> Item {
        item as! Item
    }

    init(
        rowContent: @escaping (Item) -> NSView,
        selectionChanged: @escaping (Item?) -> Void
    ) {
        self.rowContent = rowContent
        self.selectionChanged = selectionChanged
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        viewFor tableColumn: NSTableColumn?,
        item: Any
    ) -> NSView? {
        return rowContent(typedItem(item))
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
            if selectedItem != newSelection {
                selectedItem = newSelection
                selectionChanged(selectedItem)
            }
        }
    }

    func selectRow(for item: Item?, in outlineView: NSOutlineView) {
        // Returns -1 if row is not found.
        let index = outlineView.row(forItem: selectedItem)
        if index != -1 {
            outlineView.selectRowIndexes(IndexSet([index]), byExtendingSelection: false)
        } else {
            outlineView.deselectAll(nil)
        }
    }

    func changeSelectedItem(to item: Item?, in outlineView: NSOutlineView) {
        selectedItem = item
        selectRow(for: selectedItem, in: outlineView)
    }
}
