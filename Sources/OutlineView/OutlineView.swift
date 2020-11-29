import SwiftUI
import Cocoa

public struct OutlineView<Item: Identifiable & Hashable>: NSViewControllerRepresentable {
    public typealias NSViewControllerType = OutlineViewController<Item>

    var rowContent: (Item) -> NSView
    let items: [Item]
    let children: KeyPath<Item, [Item]?>

    public init(
        _ items: [Item],
        children: KeyPath<Item, [Item]?>,
        rowContent: @escaping (Item) -> NSView
    ) {
        self.items = items
        self.children = children
        self.rowContent = rowContent
    }

    public func makeNSViewController(context: Context) -> OutlineViewController<Item> {
        let controller = OutlineViewController(items: items, children: children, rowContent: rowContent)
        return controller
    }

    public func updateNSViewController(_ nsViewController: OutlineViewController<Item>, context: Context) {
        nsViewController.updateItems(newValue: items)
    }
}
