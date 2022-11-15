import Foundation
import AppKit

@available(macOS 10.15, *)
extension OutlineView {
    
    public typealias DragSourceWriter = (Data.Element) -> NSPasteboardItem?

    public typealias PasteboardReader = (NSPasteboardItem) -> DraggedItem<Data.Element>?
    public typealias DropValidator = (DropTarget<Data.Element>) -> ValidationResult<Data.Element>
    public typealias DropResult = (DropTarget<Data.Element>) -> Bool
    
    internal struct DropHandlers {
        var acceptedTypes: [NSPasteboard.PasteboardType]
        var pasteboardReader: PasteboardReader
        var dropValidator: DropValidator
        var dropResult: DropResult
        
        init(
            acceptedTypes: [NSPasteboard.PasteboardType],
            pasteboardReader: @escaping PasteboardReader,
            dropValidator: @escaping DropValidator,
            dropResult: @escaping DropResult
        ) {
            self.pasteboardReader = pasteboardReader
            self.dropValidator = dropValidator
            self.dropResult = dropResult
            self.acceptedTypes = acceptedTypes
        }
    }
            
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
