import AppKit

/// A protocol for use with `OutlineView`, implemented by a delegate to interact
/// with drop operations in an `OutlineView`.
@available(macOS 10.15, *)
public protocol DropReceiver {
    associatedtype DataElement: Identifiable
    
    /// Converts a `NSPasteboardItem` received by a drag-and-drop operation to the data
    /// element of an `OutlineView`.
    ///
    /// - Parameter item: The pasteboard item that is being dragged into the OutlineView
    ///
    /// - Returns: `nil` if the pasteboard item is not readable by this receiver, or
    ///   a tuple with the decoded item and its associated PasteboardType, which must
    ///   be included in `acceptedTypes`.
    func readPasteboard(item: NSPasteboardItem) -> DraggedItem<DataElement>?
    
    /// Defines the behavior of the `OutlineView` and the drag cursor when an item is
    /// being dragged. Called continuously as a dragged item is moved over the `OutlineView`.
    ///
    /// - Parameter target: A `DropTarget` describing where the dragged item
    ///   is currently positioned.
    ///
    /// - Returns: A case of `ValidationResult`, which will either highlight the area
    ///   of the `OutlineView` where the item will be dropped, or some other behavior.
    ///   See `ValidationResult` for possible return values.
    func validateDrop(target: DropTarget<DataElement>) -> ValidationResult<DataElement>
    
    /// Handles updating the data source once an item is dropped into the `OutlineView`.
    /// Called once after the drop completes and `validateDrop(target:)` returns a case
    /// other than `deny`.
    ///
    /// - Parameter target: A `DropTarget` with instances of the dropped items and
    ///   information about their position.
    ///
    /// - Returns: a boolean indicating that the drop was successful.
    func acceptDrop(target: DropTarget<DataElement>) -> Bool
}

@available(macOS 10.15, *)
public enum NoDropReceiver<Element: Identifiable>: DropReceiver {
    public typealias DataElement = Element
    
    public func readPasteboard(item: NSPasteboardItem) -> DraggedItem<Element>? {
        fatalError()
    }
    
    public func validateDrop(target: DropTarget<Element>) -> ValidationResult<Element> {
        fatalError()
    }
    
    public func acceptDrop(target: DropTarget<Element>) -> Bool {
        fatalError()
    }
}

public typealias DragSourceWriter<D> = (D) -> NSPasteboardItem?
public typealias DraggedItem<D> = (item: D, type: NSPasteboard.PasteboardType)

/// An struct describing what items are being dragged into an `OutlineView`, and
/// where in the data heirarchy they are being dropped.
@available(macOS 10.15, *)
public struct DropTarget<D> {
    /// A non-empty array of `DraggedItem` tuples, each with the item
    /// that is being dragged, and the `NSPasteboard.PasteboardType` that
    /// generated the item from the dragging pasteboard.
    public var items: [DraggedItem<D>]
    
    /// The `OutlineView` data element into which the target is dropping
    /// items.
    ///
    /// If `nil`, the items are intended to be dropped into the root of
    /// the data hierarchy. Otherwise, they are to be dropped into the given
    /// item's children array.
    public var intoElement: D?
    
    /// The index of the children array that the dragged items are to be
    /// dropped.
    ///
    /// If `nil`, assume that the items will be dropped at the default
    /// location for the children of `intoElement` (i.e. at the end,
    /// or into a default sorting order). Otherwise, the items should be
    /// inserted at the given index within the children.
    public var childIndex: Int?
    
    /// A closure that can be called to determine if the `OutlineView`'s
    /// representation of a given item is expanded. This may be used in
    /// `DropReceiver` functions that take a `DropTarget` as a parameter,
    /// in case the expanded state of the item affects the outcome of the
    /// function.
    public var isItemExpanded: ((D) -> Bool)
}

/// An enum describing the behavior of a dragged item as it moves over
/// the `OutlineView`.
public enum ValidationResult<D> {
    /// Indicates that the dragged item will be copied to the indicated
    /// location. The given location will be highlighted, and the cursor
    /// will show a "+" icon.
    case copy
    
    /// Indicates that the dragged item will be moved to the indicated
    /// location. The given location will be highlighted.
    case move
    
    /// Indicates that the dragged item will not be moved. No location
    /// will be highlighted.
    case deny
    
    /// Indicates that the dragged item will be copied to a different
    /// location than it is currently hovering over. The cursor will
    /// show a "+" icon, and the highlighted location will be determined
    /// by `item` and `childIndex`.
    ///
    /// - Parameters:
    ///   - item: The item that the dragged item will be added into as a child.
    ///     If no item is given, the dragged item will be added to the root of
    ///     the data structure.
    ///   - childIndex: The index of the child array of `item` where the dragged
    ///     item will be dropped. A nil value will cause `item` to be highlighted,
    ///     while a non-nil value will cause a space between rows to be highlighted.
    case copyRedirect(item: D?, childIndex: Int?)
    
    /// Indicates that the dragged item will be moved to a different
    /// location than it is currently hovering over. The highlighted location
    /// will be determined by the bound values in this enum.
    ///
    /// - Parameters:
    ///   - item: The item that the dragged item will be added into as a child.
    ///     If no item is given, the dragged item will be added to the root of
    ///     the data structure.
    ///   - childIndex: The index of the child array of `item` where the dragged
    ///     item will be dropped. A nil value will cause `item` to be highlighted,
    ///     while a non-nil value will cause a space between rows to be highlighted.
    case moveRedirect(item: D?, childIndex: Int?)
}
