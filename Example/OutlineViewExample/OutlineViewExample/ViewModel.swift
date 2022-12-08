//
//  ViewModel.swift
//  OutlineViewExample
//
//  Created by Ryan Linn on 11/20/22.
//

import Cocoa
import OutlineView

extension NSPasteboard.PasteboardType {
    static var outlineViewItem: Self {
        .init("OutlineView.OutlineItem")
    }
}

class FileItem: Hashable, Identifiable, CustomStringConvertible {
    var id = UUID()
    var name: String
    var children: [FileItem]? = nil
    var description: String {
        switch children {
        case nil:
            return "📄 \(name)"
        case .some(let children):
            return children.isEmpty ? "📂 \(name)" : "📁 \(name)"
        }
    }
    
    init(name: String, children: [FileItem]? = nil) {
        self.name = name
        self.children = children
    }
    
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func childWithId(_ searchId: UUID) -> FileItem? {
        if searchId == id {
            return self
        } else if children != nil {
            for child in children! {
                if let result = child.childWithId(searchId) {
                    return result
                }
            }
        }
        return nil
    }
    
}

class OutlineSampleViewModel: ObservableObject {
    
    @Published var data: [FileItem]
    @Published private var parentOfItem: [FileItem.ID : FileItem.ID]
    
    init(data: [FileItem]) {
        parentOfItem = Self.lineageDirectory(for: data)
        self.data = data
        
        $data.map {
            Self.lineageDirectory(for: $0)
        }
        .assign(to: &$parentOfItem)
    }
    
    private static func lineageDirectory(for data: [FileItem]) -> [FileItem.ID : FileItem.ID] {
        var result: [FileItem.ID : FileItem.ID] = [:]
        var stack: [FileItem] = data
        var current: FileItem?
        repeat {
            if current == nil {
                current = stack.popLast()
            }
            if let children = current?.children {
                for child in children {
                    result[child.id] = current!.id
                }
                stack.append(contentsOf: children)
            }
            current = nil
        } while !stack.isEmpty || current != nil
        return result
    }

    private func getItemWithId(_ identifier: FileItem.ID) -> FileItem? {
        for item in data {
            if let found = item.childWithId(identifier) {
                return found
            }
        }
        return nil
    }
    
    private func getParentOfId(_ identifier: FileItem.ID) -> FileItem? {
        parentOfItem[identifier].flatMap { getItemWithId($0) }
    }
    
    private func item(_ item: FileItem, isChildOf parent: FileItem) -> Bool {
        item != parent && parent.childWithId(item.id) != nil
    }
    
}

extension OutlineSampleViewModel: DropReceiver {
    
    var acceptedTypes: [NSPasteboard.PasteboardType] {
        [
            .outlineViewItem,
            .fileURL,
            .fileContents,
            .string
        ]
    }
    
    func readPasteboard(item: NSPasteboardItem) -> DraggedItem<FileItem>? {
        guard let pasteboardType = item.availableType(from: acceptedTypes)
        else { return nil }
        
        var result: FileItem? = nil
        switch pasteboardType {
        case .outlineViewItem:
            let encodedData = item.data(forType: pasteboardType)
            let decodedId = encodedData.flatMap { try? JSONDecoder().decode(UUID.self, from: $0) }
            result = decodedId.flatMap { getItemWithId($0) }
        case .fileURL:
            let filePath = item.string(forType: pasteboardType)
            let fileUrl = filePath.map { URL(fileURLWithPath: $0) }
            let fileName = fileUrl?.standardized.lastPathComponent
            result = fileName.map { FileItem(name: $0) }
        case .fileContents:
            let fileData = item.data(forType: pasteboardType) ?? Data()
            let sizeOfData = Int64(fileData.count)
            result = FileItem(name: ByteCountFormatter.string(fromByteCount: sizeOfData, countStyle: .file))
        case .string:
            let stringValue = item.string(forType: pasteboardType)
            result = stringValue.map { FileItem(name: $0) }
        default:
            break
        }
        
        return result.map { ($0, pasteboardType) }
    }

    func validateDrop(target: DropTarget<FileItem>) -> ValidationResult<FileItem> {
        guard let singleDraggedItem = target.items.first
        else { return .deny }
        
        print("Validate Attempt: -----------------------")
        
        if let intoItem = target.intoElement {
            
            // Moving item into existing object
            if intoItem == singleDraggedItem.item {
                print("Validate: drop onto self: DENY")
                return .deny
            }
            
            // Moving item into a non-folder
            if intoItem.children == nil {
                print("Validate: Drop onto non-folder: DENY")
                return .deny
            }
            
            print("Validate: target \(intoItem.name), index \(target.childIndex ?? -1)")
        }
        
        let targetChildren = target.intoElement?.children ?? data
        
        // Moving item onto self:
        if !targetChildren.isEmpty,
           let dropIndex = target.childIndex,
           let itemAlreadyAtIndex = targetChildren.firstIndex(of: singleDraggedItem.item),
           abs(itemAlreadyAtIndex - dropIndex) <= 1
        {
            print("Validate: Drop on existing self: DENY")
            return .deny
        }
        
        // Moving folder into self
        if let targetFolder = target.intoElement,
           targetFolder.children != nil,
           item(targetFolder, isChildOf: singleDraggedItem.item)
        {
            print("Validate: Dragging folder into itself")
            return .deny
        }
        print("Validate: no target, index \(target.childIndex ?? -1)")

        return .move
    }
    
    func acceptDrop(target: DropTarget<FileItem>) -> Bool {
        print("""
        Dropping \(target.items.count) items onto item \(target.intoElement?.name ?? "root") \
        at index \(target.childIndex ?? -1)
        \(target.items.map { "\($0.item.name): \($0.type.rawValue)" })
        """)
        return false
    }
    
}
