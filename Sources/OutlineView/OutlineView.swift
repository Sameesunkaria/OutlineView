import SwiftUI
import Cocoa

public struct OutlineView<Data: Sequence>: NSViewControllerRepresentable
where Data.Element: Identifiable {
    public typealias NSViewControllerType = OutlineViewController<Data>

    let data: Data
    let children: KeyPath<Data.Element, Data?>
    @Binding var selection: Data.Element?
    var content: (Data.Element) -> NSView

    /// Creates an outline view from a collection of root data elements and
    /// a key path to its children.
    ///
    /// This initializer creates an instance that uniquely identifies views
    /// across updates based on the identity of the underlying data element.
    ///
    /// All generated rows begin in the collapsed state.
    ///
    /// Make sure that the identifier of a data element only changes if you
    /// mean to replace that element with a new element, one with a new
    /// identity. If the ID of an element changes, then the content view
    /// generated from that element will lose any current state and animations.
    ///
    /// - NOTE: All elements in data should be uniquely identified. Data with
    /// elements that have a repeated identity are not supported.
    ///
    /// - Parameters:
    ///   - data: A collection of tree-structured, identified data.
    ///   - children: A key path to a property whose non-`nil` value gives the
    ///     children of `data`. A non-`nil` but empty value denotes an element
    ///     capable of having children that's currently childless, such as an
    ///     empty directory in a file system. On the other hand, if the property
    ///     at the key path is `nil`, then the outline group treats `data` as a
    ///     leaf in the tree, like a regular file in a file system.
    ///   - selection: A binding to a selected value.
    ///   - content: A closure that produces an `NSView` based on an
    ///    element in `data`. The `NSView` should return the correct `fittingSize`
    ///    as it is used to determine the height of the cell.
    public init(
        _ data: Data,
        children: KeyPath<Data.Element, Data?>,
        selection: Binding<Data.Element?>,
        content: @escaping (Data.Element) -> NSView
    ) {
        self.data = data
        self.children = children
        self._selection = selection
        self.content = content
    }

    public func makeNSViewController(context: Context) -> OutlineViewController<Data> {
        let controller = OutlineViewController(
            data: data,
            children: children,
            content: content,
            selectionChanged: { selection = $0 })
        return controller
    }

    public func updateNSViewController(
        _ outlineController: OutlineViewController<Data>,
        context: Context
    ) {
        outlineController.updateData(newValue: data)
        outlineController.changeSelectedItem(to: selection)
    }
}
