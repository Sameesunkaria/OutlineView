import SwiftUI
import Cocoa

enum ChildSource<Data: Sequence> {
    case keyPath(KeyPath<Data.Element, Data?>)
    case provider((Data.Element) -> Data?)
    
    func children(for element: Data.Element) -> Data? {
        switch self {
        case .keyPath(let keyPath):
            return element[keyPath: keyPath]
        case .provider(let provider):
            return provider(element)
        }
    }
}

@available(macOS 10.15, *)
public struct OutlineView<Data: Sequence, Drop: DropReceiver>: NSViewControllerRepresentable
where Drop.DataElement == Data.Element {
    public typealias NSViewControllerType = OutlineViewController<Data, Drop>

    let data: Data
    let childSource: ChildSource<Data>
    @Binding var selection: Data.Element?
    var content: (Data.Element) -> NSView
    var separatorInsets: ((Data.Element) -> NSEdgeInsets)?

    /// Outline view style is unavailable on macOS 10.15 and below.
    /// Stored as `Any` to make the property available on all platforms.
    private var _styleStorage: Any?

    @available(macOS 11.0, *)
    var style: NSOutlineView.Style {
        get {
            _styleStorage
                .flatMap { $0 as? NSOutlineView.Style }
                ?? .automatic
        }
        set { _styleStorage = newValue }
    }

    var indentation: CGFloat = 13.0
    var separatorVisibility: SeparatorVisibility
    var separatorColor: NSColor = .separatorColor

    var dragDataSource: DragSourceWriter<Data.Element>?
    var dropReceiver: Drop? = nil
    var acceptedDropTypes: [NSPasteboard.PasteboardType]? = nil

    // MARK: NSViewControllerRepresentable
    
    public func makeNSViewController(context: Context) -> OutlineViewController<Data, Drop> {
        let controller = OutlineViewController<Data, Drop>(
            data: data,
            childrenSource: childSource,
            content: content,
            selectionChanged: { selection = $0 },
            separatorInsets: separatorInsets)
        controller.setIndentation(to: indentation)
        if #available(macOS 11.0, *) {
            controller.setStyle(to: style)
        }
        return controller
    }

    public func updateNSViewController(
        _ outlineController: OutlineViewController<Data, Drop>,
        context: Context
    ) {
        outlineController.updateData(newValue: data)
        outlineController.changeSelectedItem(to: selection)
        outlineController.setRowSeparator(visibility: separatorVisibility)
        outlineController.setRowSeparator(color: separatorColor)
        outlineController.setDragSourceWriter(dragDataSource)
        outlineController.setDropReceiver(dropReceiver)
        outlineController.setAcceptedDragTypes(acceptedDropTypes)
    }
}

// MARK: - Modifiers

@available(macOS 10.15, *)
public extension OutlineView {
    /// Sets the style for the `OutlineView`.
    @available(macOS 11.0, *)
    func outlineViewStyle(_ style: NSOutlineView.Style) -> Self {
        var mutableSelf = self
        mutableSelf.style = style
        return mutableSelf
    }

    /// Sets the width of the indentation per level for the `OutlineView`.
    func outlineViewIndentation(_ width: CGFloat) -> Self {
        var mutableSelf = self
        mutableSelf.indentation = width
        return mutableSelf
    }

    /// Sets the visibility of the separator between rows of the `OutlineView`.
    func rowSeparator(_ visibility: SeparatorVisibility) -> Self {
        var mutableSelf = self
        mutableSelf.separatorVisibility = visibility
        return mutableSelf
    }

    /// Sets the color of the separator between rows of this `OutlineView`.
    /// The default color for the separator is `NSColor.separatorColor`.
    func rowSeparatorColor(_ color: NSColor) -> Self {
        var mutableSelf = self
        mutableSelf.separatorColor = color
        return mutableSelf
    }

    /// Adds a drop receiver to the `OutlineView`, allowing it to react to drag
    /// and drop operations.
    ///
    /// - Parameters
    ///   - acceptedTypes: An array of `PasteboardType`s that the `DropReceiver` is able to read.
    ///   - receiver: A delegate conforming to `DropReceiver` that handles receiving a
    ///     drag-and-drop operation onto the `OutlineView`.
    func onDrop(of acceptedTypes: [NSPasteboard.PasteboardType], receiver: Drop) -> Self {
        var mutableSelf = self
        mutableSelf.acceptedDropTypes = acceptedTypes
        mutableSelf.dropReceiver = receiver
        return mutableSelf
    }
    
    /// Enables dragging of rows from the `OutlineView` by setting the `DragSourceWriter`
    /// of the `OutlineView`.
    ///
    /// The simplest way to create the data for the pasteboard item is to initialize
    /// the `NSPasteboardItem` and then calling `setData(_:forType:)` or other types
    /// of `set` functions.
    ///
    /// - Parameter writer: A closure that takes the `Data.Element` from a given row of
    /// the `OutlineView`, and returns an optional `NSPasteboardItem` with data about the
    /// item to be dragged. If `nil` is returned, that row can not be dragged.
    func dragDataSource(_ writer: @escaping DragSourceWriter<Data.Element>) -> Self {
        var mutableSelf = self
        mutableSelf.dragDataSource = writer
        return mutableSelf
    }
}

// MARK: - Initializers for macOS 10.15 and higher.

@available(macOS 10.15, *)
public extension OutlineView {
    /// Creates an `OutlineView` from a collection of root data elements and
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
    ///     at the key path is `nil`, then the outline view treats `data` as a
    ///     leaf in the tree, like a regular file in a file system.
    ///   - selection: A binding to a selected value.
    ///   - content: A closure that produces an `NSView` based on an
    ///     element in `data`. An `NSTableCellView` subclass is preferred.
    ///     The `NSView` should return the correct `fittingSize`
    ///     as it is used to determine the height of the cell.
    init(
        _ data: Data,
        children: KeyPath<Data.Element, Data?>,
        selection: Binding<Data.Element?>,
        content: @escaping (Data.Element) -> NSView
    ) {
        self.data = data
        self.childSource = .keyPath(children)
        self._selection = selection
        self.separatorVisibility = .hidden
        self.content = content
    }

    /// Creates an `OutlineView` from a collection of root data elements and
    /// a closure that provides children to each element.
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
    ///   - selection: A binding to a selected value.
    ///   - children: A closure whose non-`nil` return value gives the
    ///     children of `data`. A non-`nil` but empty value denotes an element
    ///     capable of having children that's currently childless, such as an
    ///     empty directory in a file system. On the other hand, if the value
    ///     from the closure is `nil`, then the outline view treats `data` as a
    ///     leaf in the tree, like a regular file in a file system.
    ///   - content: A closure that produces an `NSView` based on an
    ///     element in `data`. An `NSTableCellView` subclass is preferred.
    ///     The `NSView` should return the correct `fittingSize`
    ///     as it is used to determine the height of the cell.
    init(
        _ data: Data,
        selection: Binding<Data.Element?>,
        children: @escaping (Data.Element) -> Data?,
        content: @escaping (Data.Element) -> NSView
    ) {
        self.data = data
        self._selection = selection
        self.childSource = .provider(children)
        self.separatorVisibility = .hidden
        self.content = content
    }
}

// MARK: Initializers for macOS 10.15 and higher with NoDropReceiver.

@available(macOS 10.15, *)
public extension OutlineView where Drop == NoDropReceiver<Data.Element> {
    /// Creates an `OutlineView` from a collection of root data elements and
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
    ///     at the key path is `nil`, then the outline view treats `data` as a
    ///     leaf in the tree, like a regular file in a file system.
    ///   - selection: A binding to a selected value.
    ///   - content: A closure that produces an `NSView` based on an
    ///     element in `data`. An `NSTableCellView` subclass is preferred.
    ///     The `NSView` should return the correct `fittingSize`
    ///     as it is used to determine the height of the cell.
    init(
        _ data: Data,
        children: KeyPath<Data.Element, Data?>,
        selection: Binding<Data.Element?>,
        content: @escaping (Data.Element) -> NSView
    ) {
        self.data = data
        self.childSource = .keyPath(children)
        self._selection = selection
        self.separatorVisibility = .hidden
        self.content = content
    }

    /// Creates an `OutlineView` from a collection of root data elements and
    /// a closure that provides children to each element.
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
    ///   - selection: A binding to a selected value.
    ///   - children: A closure whose non-`nil` return value gives the
    ///     children of `data`. A non-`nil` but empty value denotes an element
    ///     capable of having children that's currently childless, such as an
    ///     empty directory in a file system. On the other hand, if the value
    ///     from the closure is `nil`, then the outline view treats `data` as a
    ///     leaf in the tree, like a regular file in a file system.
    ///   - content: A closure that produces an `NSView` based on an
    ///     element in `data`. An `NSTableCellView` subclass is preferred.
    ///     The `NSView` should return the correct `fittingSize`
    ///     as it is used to determine the height of the cell.
    init(
        _ data: Data,
        selection: Binding<Data.Element?>,
        children: @escaping (Data.Element) -> Data?,
        content: @escaping (Data.Element) -> NSView
    ) {
        self.data = data
        self._selection = selection
        self.childSource = .provider(children)
        self.separatorVisibility = .hidden
        self.content = content
    }
}

// MARK: Initializers for macOS 11 and higher.

@available(macOS 11.0, *)
public extension OutlineView {
    /// Creates an `OutlineView` from a collection of root data elements and
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
    ///     at the key path is `nil`, then the outline view treats `data` as a
    ///     leaf in the tree, like a regular file in a file system.
    ///   - selection: A binding to a selected value.
    ///   - separatorInsets: An optional closure that produces row separator lines
    ///     with the given insets for each item in the outline view. If this closure
    ///     is not provided (the default), separators are hidden.
    ///   - content: A closure that produces an `NSView` based on an
    ///     element in `data`. An `NSTableCellView` subclass is preferred.
    ///     The `NSView` should return the correct `fittingSize`
    ///     as it is used to determine the height of the cell.
    @available(macOS 11.0, *)
    init(
        _ data: Data,
        children: KeyPath<Data.Element, Data?>,
        selection: Binding<Data.Element?>,
        separatorInsets: ((Data.Element) -> NSEdgeInsets)? = nil,
        content: @escaping (Data.Element) -> NSView
    ) {
        self.data = data
        self.childSource = .keyPath(children)
        self._selection = selection
        self.separatorInsets = separatorInsets
        self.separatorVisibility = separatorInsets == nil ? .hidden : .visible
        self.content = content
    }

    /// Creates an `OutlineView` from a collection of root data elements and
    /// a closure that provides children to each element.
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
    ///   - selection: A binding to a selected value.
    ///   - children: A closure whose non-`nil` return value gives the
    ///     children of `data`. A non-`nil` but empty value denotes an element
    ///     capable of having children that's currently childless, such as an
    ///     empty directory in a file system. On the other hand, if the value
    ///     from the closure is `nil`, then the outline view treats `data` as a
    ///     leaf in the tree, like a regular file in a file system.
    ///   - separatorInsets: An optional closure that produces row separator lines
    ///     with the given insets for each item in the outline view. If this closure
    ///     is not provided (the default), separators are hidden.
    ///   - content: A closure that produces an `NSView` based on an
    ///     element in `data`. An `NSTableCellView` subclass is preferred.
    ///     The `NSView` should return the correct `fittingSize`
    ///     as it is used to determine the height of the cell.
    @available(macOS 11.0, *)
    init(
        _ data: Data,
        selection: Binding<Data.Element?>,
        children: @escaping (Data.Element) -> Data?,
        separatorInsets: ((Data.Element) -> NSEdgeInsets)? = nil,
        content: @escaping (Data.Element) -> NSView
    ) {
        self.data = data
        self._selection = selection
        self.childSource = .provider(children)
        self.separatorInsets = separatorInsets
        self.separatorVisibility = separatorInsets == nil ? .hidden : .visible
        self.content = content
    }
}

// MARK: Initializers for macOS 11 and higher with NoDropReceiver.

@available(macOS 11.0, *)
public extension OutlineView where Drop == NoDropReceiver<Data.Element> {
    /// Creates an `OutlineView` from a collection of root data elements and
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
    ///     at the key path is `nil`, then the outline view treats `data` as a
    ///     leaf in the tree, like a regular file in a file system.
    ///   - selection: A binding to a selected value.
    ///   - separatorInsets: An optional closure that produces row separator lines
    ///     with the given insets for each item in the outline view. If this closure
    ///     is not provided (the default), separators are hidden.
    ///   - content: A closure that produces an `NSView` based on an
    ///     element in `data`. An `NSTableCellView` subclass is preferred.
    ///     The `NSView` should return the correct `fittingSize`
    ///     as it is used to determine the height of the cell.
    init(
        _ data: Data,
        children: KeyPath<Data.Element, Data?>,
        selection: Binding<Data.Element?>,
        separatorInsets: ((Data.Element) -> NSEdgeInsets)? = nil,
        content: @escaping (Data.Element) -> NSView
    ) {
        self.data = data
        self.childSource = .keyPath(children)
        self._selection = selection
        self.separatorInsets = separatorInsets
        self.separatorVisibility = separatorInsets == nil ? .hidden : .visible
        self.content = content
    }

    /// Creates an `OutlineView` from a collection of root data elements and
    /// a closure that provides children to each element.
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
    ///   - selection: A binding to a selected value.
    ///   - children: A closure whose non-`nil` return value gives the
    ///     children of `data`. A non-`nil` but empty value denotes an element
    ///     capable of having children that's currently childless, such as an
    ///     empty directory in a file system. On the other hand, if the value
    ///     from the closure is `nil`, then the outline view treats `data` as a
    ///     leaf in the tree, like a regular file in a file system.
    ///   - separatorInsets: An optional closure that produces row separator lines
    ///     with the given insets for each item in the outline view. If this closure
    ///     is not provided (the default), separators are hidden.
    ///   - content: A closure that produces an `NSView` based on an
    ///     element in `data`. An `NSTableCellView` subclass is preferred.
    ///     The `NSView` should return the correct `fittingSize`
    ///     as it is used to determine the height of the cell.
    init(
        _ data: Data,
        selection: Binding<Data.Element?>,
        children: @escaping (Data.Element) -> Data?,
        separatorInsets: ((Data.Element) -> NSEdgeInsets)? = nil,
        content: @escaping (Data.Element) -> NSView
    ) {
        self.data = data
        self._selection = selection
        self.childSource = .provider(children)
        self.separatorInsets = separatorInsets
        self.separatorVisibility = separatorInsets == nil ? .hidden : .visible
        self.content = content
    }
}
