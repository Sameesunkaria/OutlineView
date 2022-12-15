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
public struct NoDropReceiver<Element: Identifiable>: DropReceiver {
    public typealias DataElement = Element
    
    public var acceptedTypes: [NSPasteboard.PasteboardType] { [] }
    
    public func readPasteboard(item: NSPasteboardItem) -> DraggedItem<Element>? {
        nil
    }
    
    public func validateDrop(target: DropTarget<Element>) -> ValidationResult<Element> {
        .deny
    }
    
    public func acceptDrop(target: DropTarget<Element>) -> Bool {
        false
    }

}

public typealias DragSourceWriter<D> = (D) -> NSPasteboardItem?
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
