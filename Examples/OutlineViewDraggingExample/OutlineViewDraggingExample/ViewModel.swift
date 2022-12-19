//
//  ViewModel.swift
//  OutlineViewExample
//
//  Created by Ryan Linn on 11/20/22.
//

import Cocoa
import OutlineView

func sampleDataSource() -> OutlineSampleViewModel {
    let fido = FileItem(fileName: "Fido")
    let chip = FileItem(fileName: "Chip")
    let rover = FileItem(fileName: "Rover")
    let spot = FileItem(fileName: "Spot")
    
    let fluffy = FileItem(fileName: "Fluffy")
    let fang = FileItem(fileName: "Fang")
    let tootsie = FileItem(fileName: "Tootsie")
    let milo = FileItem(fileName: "Milo")
    
    let bart = FileItem(fileName: "Bart")
    let leo = FileItem(fileName: "Leo")
    let lucy = FileItem(fileName: "Lucy")
    let dia = FileItem(fileName: "Dia")
    let templeton = FileItem(fileName: "Templeton")
    let chewy = FileItem(fileName: "Chewy")
    let pizza = FileItem(fileName: "Pizza")
    
    let dogsFolder = FileItem(folderName: "Dogs")
    let catsFolder = FileItem(folderName: "Cats")
    let otherFolder = FileItem(folderName: "Other")
    let ratsFolder = FileItem(folderName: "Rats")
    let fishFolder = FileItem(folderName: "Fish")
    let turtlesFolder = FileItem(folderName: "Turtles")
    
    let roots = [
        dogsFolder,
        catsFolder,
        otherFolder
    ]
    
    let childDirectory = [
        dogsFolder: [fido, chip, rover, spot],
        catsFolder: [fluffy, fang, tootsie, milo],
        otherFolder: [ratsFolder, fishFolder, turtlesFolder, chewy, pizza],
        ratsFolder: [templeton, leo, bart],
        fishFolder: [dia, lucy],
        turtlesFolder: []
    ]
    let childlessItems = [fido, chip, rover, spot, fluffy, fang, tootsie, milo, bart, leo, lucy, dia, templeton, chewy, pizza]
    let theChilds = childDirectory.map { ($0.key, $0.value) } + childlessItems.map { ($0, nil) }
    
    return OutlineSampleViewModel(rootData: roots, childrenDirectory: theChilds)
}

extension NSPasteboard.PasteboardType {
    static var outlineViewItem: Self {
        .init("OutlineView.OutlineItem")
    }
}

struct FileItem: Hashable, Identifiable, CustomStringConvertible {
    var name: String
    var isFolder: Bool
    
    var id: String { name }
    
    var description: String {
        if !isFolder {
            return "📄 \(name)"
        } else {
            return "📁 \(name)"
        }
    }
    
    init(folderName: String) {
        self.name = folderName
        isFolder = true
    }
    
    init(fileName: String) {
        self.name = fileName
        isFolder = false
    }
    
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
        
}

class OutlineSampleViewModel: ObservableObject {
    
    @Published var rootData: [FileItem]
    private var dataAndChildren: [(item: FileItem, children: [FileItem]?)]
    
    init(rootData: [FileItem], childrenDirectory: [(FileItem, [FileItem]?)]) {
        self.dataAndChildren = childrenDirectory
        self.rootData = rootData
    }
    
    func childrenOfItem(_ item: FileItem) -> [FileItem]? {
        getChildrenOfId(item.id)
    }
    
    private func getItemWithId(_ identifier: FileItem.ID) -> FileItem? {
        dataAndChildren.first(where: { $0.item.id == identifier })?.item
    }
    
    private func getChildrenOfId(_ identifier: FileItem.ID) -> [FileItem]? {
        dataAndChildren.first(where: { $0.item.id == identifier })?.children
    }
    
    private func getParentOfId(_ identifier: FileItem.ID) -> FileItem? {
        dataAndChildren.first(where: { $0.children?.map(\.id).contains(identifier) ?? false })?.item
    }
    
    private func item(_ item: FileItem, isDescendentOf parent: FileItem) -> Bool {
        
        var currentParent = getParentOfId(item.id)
        while currentParent != nil {
            if currentParent == parent {
                return true
            } else {
                currentParent = getParentOfId(currentParent!.id)
            }
        }
        
        return false
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
            let decodedId = encodedData.flatMap { try? JSONDecoder().decode(String.self, from: $0) }
            result = decodedId.flatMap { getItemWithId($0) }
        case .fileURL:
            let filePath = item.string(forType: pasteboardType)
            let fileUrl = filePath.map { URL(fileURLWithPath: $0) }
            let fileName = fileUrl?.standardized.lastPathComponent
            let isDirectory = (try? fileUrl?.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDirectory {
                result = fileName.map { FileItem(folderName: $0) }
            } else {
                result = fileName.map { FileItem(fileName: $0) }
            }
        case .fileContents:
            let fileData = item.data(forType: pasteboardType) ?? Data()
            let sizeOfData = Int64(fileData.count)
            let someFileName = ByteCountFormatter.string(fromByteCount: sizeOfData, countStyle: .file)
            result = FileItem(fileName: someFileName)
        case .string:
            let stringValue = item.string(forType: pasteboardType)
            result = stringValue.map { FileItem(fileName: $0) }
        default:
            break
        }
        
        return result.map { ($0, pasteboardType) }
    }

    func validateDrop(target: DropTarget<FileItem>) -> ValidationResult<FileItem> {
        guard let singleDraggedItem = target.items.first
        else { return .deny }
        
        print("Validate Attempt: -----------------------")
        print("Dragged Item: \(singleDraggedItem.item.isFolder ? "Folder" : "File") \(singleDraggedItem.item.name)")
        
        if let intoItem = target.intoElement {
            
            // Moving item into existing object
            if intoItem == singleDraggedItem.item {
                print("Validate: drop onto self: DENY")
                return .deny
            }
            
            // Moving item into a non-folder
            if !intoItem.isFolder {
                print("Validate: Drop onto non-folder: DENY")
                return .deny
            }
            
        }
        
        let targetChildren: [FileItem]
        if target.intoElement == nil {
            // intoElement == nil means we're dragging into the root
            targetChildren = rootData
        } else if let childrenOfObject = getChildrenOfId(target.intoElement!.id) {
            // intoElement has children, so dragging into a folder
            targetChildren = childrenOfObject
        } else {
            // intoElement has no children... this shouldn't happen
            print("Validate: drop onto non-folder AGAIN: DENY")
            return .deny
        }
        
        // Moving item onto self:
        if !targetChildren.isEmpty,
           let dropIndex = target.childIndex,
           let itemAlreadyAtIndex = targetChildren.firstIndex(of: singleDraggedItem.item),
           itemAlreadyAtIndex == dropIndex || itemAlreadyAtIndex == dropIndex - 1
        {
            print("Validate: Drop on existing self: DENY")
            return .deny
        }
        
        // Moving folder into self
        if let targetFolder = target.intoElement,
           targetFolder.isFolder,
           item(targetFolder, isDescendentOf: singleDraggedItem.item)
        {
            print("Validate: Dragging folder into itself")
            return .deny
        }
        
        if target.intoElement == nil,
           target.childIndex == nil
        {
            print("Validate: into root with no index")
            return .moveRedirect(item: nil, childIndex: rootData.count)
        }
        
        if target.intoElement != nil,
           !target.isItemExpanded(target.intoElement!),
           target.childIndex != nil
        {
            print("Validate, dragging into unexpanded target...")
            return .moveRedirect(item: target.intoElement, childIndex: nil)
        }

        print("Validate: target \(target.intoElement?.name ?? "root"), index \(target.childIndex ?? -1)")
        return .move
    }
    
    func acceptDrop(target: DropTarget<FileItem>) -> Bool {
        print("""
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        Dropping \(target.items.count) items onto item \(target.intoElement?.name ?? "root") \
        at index \(target.childIndex ?? -1)
        \(target.items.map { "\($0.item.name): \($0.type.rawValue)" })
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        """)
        
        let movedItem = target.items[0].item
        
        // get existing index of moved item in order to remove it before re-inserting to target
        let previousIndex: (FileItem?, Int)?
        if let rootIndex = rootData.firstIndex(of: movedItem) {
            previousIndex = (nil, rootIndex)
        } else if let (parent, siblings) = dataAndChildren.first(where: { $0.children?.contains(movedItem) ?? false }) {
            previousIndex = (parent, siblings!.firstIndex(of: movedItem)!)
        } else {
            previousIndex = nil
        }
        
        var subtractFromInsertIndex = false
        if let previousIndex {
            // Remove previous item.
            if previousIndex.0 == nil {
                rootData.remove(at: previousIndex.1)
            } else {
                let idx = dataAndChildren.firstIndex(where: { $0.item.id == previousIndex.0!.id })!
                dataAndChildren[idx].children?.remove(at: previousIndex.1)
            }
            if previousIndex.0 == target.intoElement,
               (target.childIndex ?? -1) > previousIndex.1
            {
                subtractFromInsertIndex = true
            }
        }
        
        if let intoItem = target.intoElement,
           let dataChildIndex = dataAndChildren.firstIndex(where: { $0.item.id == intoItem.id })
        {
            // Dropping into a folder
            if let basicIndex = target.childIndex {
                let insertIndex = basicIndex - (subtractFromInsertIndex ? 1 : 0)
                dataAndChildren[dataChildIndex].children?.insert(movedItem, at: insertIndex)
            } else {
                dataAndChildren[dataChildIndex].children?.append(movedItem)
            }
        } else if target.intoElement == nil {
            // Dropping into Root
            if let basicIndex = target.childIndex {
                let insertIndex = basicIndex - (subtractFromInsertIndex ? 1 : 0)
                rootData.insert(movedItem, at: insertIndex)
            } else {
                rootData.append(movedItem)
            }
        }
        
        objectWillChange.send()
        return true
    }
    
}
