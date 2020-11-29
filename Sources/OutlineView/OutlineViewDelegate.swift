//
//  OutlineViewDelegate.swift
//  
//
//  Created by Samar Sunkaria on 11/21/20.
//

import Cocoa
import SwiftUI

class OutlineViewDelegate<Item: Identifiable>: NSObject, NSOutlineViewDelegate {
    var rowContent: (Item) -> NSView

    func typedItem(_ item: Any) -> Item {
        item as! Item
    }

    init(rowContent: @escaping (Item) -> NSView) {
        self.rowContent = rowContent
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        viewFor tableColumn: NSTableColumn?,
        item: Any
    ) -> NSView? {
        return rowContent(typedItem(item))
    }
}
