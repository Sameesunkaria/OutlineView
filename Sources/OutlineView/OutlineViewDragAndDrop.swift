import Foundation
import AppKit


@available(macOS 10.15, *)
public protocol DropReceiver {
    associatedtype DataElement: Identifiable
    
    var acceptedTypes: [NSPasteboard.PasteboardType] { get }
    
    func readPasteboard(item: NSPasteboardItem) -> DraggedItem<DataElement>?
    func validateDrop(target: DropTarget<DataElement>) -> ValidationResult<DataElement>
    func acceptDrop(target: DropTarget<DataElement>) -> Bool
    
}

@available(macOS 10.15, *)
public extension OutlineView {
    typealias DragSourceWriter = (Data.Element) -> NSPasteboardItem?
}

public typealias DraggedItem<D> = (item: D, type: NSPasteboard.PasteboardType)

@available(macOS 10.15, *)
public struct DropTarget<D> {
    public var items: [DraggedItem<D>]
    public var intoElement: D?
    public var childIndex: Int?
}

public enum ValidationResult<D> {
    case copy
    case move
    case deny
    case copyRedirect(item: D?, childIndex: Int?)
    case moveRedirect(item: D?, childIndex: Int?)
}
