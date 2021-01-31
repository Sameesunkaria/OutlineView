import SwiftUI
import Cocoa

public struct OutlineView<Item: Identifiable>: NSViewControllerRepresentable {
    public typealias NSViewControllerType = OutlineViewController<Item>

    let items: [Item]
    let children: KeyPath<Item, [Item]?>
    @Binding var selection: Item?
    var rowContent: (Item) -> NSView

    public init(
        _ items: [Item],
        children: KeyPath<Item, [Item]?>,
        selection: Binding<Item?>,
        rowContent: @escaping (Item) -> NSView
    ) {
        self.items = items
        self.children = children
        self._selection = selection
        self.rowContent = rowContent
    }

    public func makeNSViewController(context: Context) -> OutlineViewController<Item> {
        let controller = OutlineViewController(
            items: items,
            children: children,
            rowContent: rowContent,
            selectionChanged: { selection = $0 })
        return controller
    }

    public func updateNSViewController(_ outlineController: OutlineViewController<Item>, context: Context) {
        outlineController.updateItems(newValue: items)
        outlineController.changeSelectedItem(to: selection)
    }
}
