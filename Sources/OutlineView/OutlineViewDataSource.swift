//
//  OutlineViewDataSource.swift
//  
//
//  Created by Samar Sunkaria on 11/21/20.
//

import Cocoa

class OutlineViewDataSource<Item: Identifiable>: NSObject, NSOutlineViewDataSource {
    var items: [Item]
    let childrenPath: KeyPath<Item, [Item]?>

    init(items: [Item], children: KeyPath<Item, [Item]?>) {
        self.items = items
        self.childrenPath = children
    }

    func typedItem(_ item: Any) -> Item {
        item as! Item
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        numberOfChildrenOfItem item: Any?
    ) -> Int {
        if let item = item.map(typedItem) {
            return item[keyPath: childrenPath]?.count ?? 0
        } else {
            return items.count
        }
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        isItemExpandable item: Any
    ) -> Bool {
        typedItem(item)[keyPath: childrenPath] != nil
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        child index: Int,
        ofItem item: Any?
    ) -> Any {
        if let item = item.map(typedItem) {
            // Should only be called if item has children.
            precondition(item[keyPath: childrenPath] != nil)
            return item[keyPath: childrenPath].unsafelyUnwrapped[index]
        } else {
            return items[index]
        }
    }
}
