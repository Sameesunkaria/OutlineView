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
    
    var pasteboardTypes: [NSPasteboard.PasteboardType] {
        [
            .outlineViewItem,
            .fileURL,
            .fileContents,
            .string
        ]
    }
    
    init(rootData: [FileItem], childrenDirectory: [(FileItem, [FileItem]?)]) {
        self.dataAndChildren = childrenDirectory
        self.rootData = rootData
    }
    
    func childrenOfItem(_ item: FileItem) -> [FileItem]? {
        getChildrenOfID(item.id)
    }
    
    private func getItemWithID(_ identifier: FileItem.ID) -> FileItem? {
        dataAndChildren.first(where: { $0.item.id == identifier })?.item
    }
    
    private func getChildrenOfID(_ identifier: FileItem.ID) -> [FileItem]? {
        dataAndChildren.first(where: { $0.item.id == identifier })?.children
    }
    
    private func getParentOfID(_ identifier: FileItem.ID) -> FileItem? {
        dataAndChildren.first(where: { $0.children?.map(\.id).contains(identifier) ?? false })?.item
    }
    
    private func item(_ item: FileItem, isDescendentOf parent: FileItem) -> Bool {
        
        var currentParent = getParentOfID(item.id)
        while currentParent != nil {
            if currentParent == parent {
                return true
            } else {
                currentParent = getParentOfID(currentParent!.id)
            }
        }
        
        return false
    }
    
}

extension OutlineSampleViewModel: DropReceiver {
    func readPasteboard(item: NSPasteboardItem) -> DraggedItem<FileItem>? {
        guard let pasteboardType = item.availableType(from: pasteboardTypes)
        else { return nil }
        
        var result: FileItem? = nil
        switch pasteboardType {
        case .outlineViewItem:
            let encodedData = item.data(forType: pasteboardType)
            let decodedID = encodedData.flatMap { try? JSONDecoder().decode(String.self, from: $0) }
            result = decodedID.flatMap { getItemWithID($0) }
        case .fileURL:
            let filePath = item.string(forType: pasteboardType)
            let fileUrl = filePath.flatMap { URL(string: $0) }
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
        
        // Only dragging first item. Haven't dealt with how to handle multi-drags
        guard let singleDraggedItem = target.items.first
        else { return .deny }
                
        // Moving item into existing object?
        if let intoItem = target.intoElement {

            // Moving item into itself? Deny
            guard intoItem != singleDraggedItem.item else {
                return .deny
            }
            
            // Moving item into a non-folder? Deny.
            guard intoItem.isFolder else {
                return .deny
            }
            
        }
        
        // Calculate existing array of items we're dropping into
        let targetChildren: [FileItem]
        if target.intoElement == nil {
            // intoElement == nil means we're dragging into the root
            targetChildren = rootData
        } else if let childrenOfObject = getChildrenOfID(target.intoElement!.id) {
            // intoElement has children, so dragging into a folder
            targetChildren = childrenOfObject
        } else {
            // intoElement has no children... this shouldn't happen
            return .deny
        }
        
        // Deny moving item onto itself:
        if !targetChildren.isEmpty,
           let dropIndex = target.childIndex,
           let itemAlreadyAtIndex = targetChildren.firstIndex(of: singleDraggedItem.item),
           itemAlreadyAtIndex == dropIndex || itemAlreadyAtIndex == dropIndex - 1
        {
            return .deny
        }
        
        // Deny moving folder into itself or one of its sub-directories
        if let targetFolder = target.intoElement,
           targetFolder.isFolder,
           item(targetFolder, isDescendentOf: singleDraggedItem.item)
        {
            return .deny
        }
        
        // If moving into root, and no childIndex given, redirect to end of root
        if target.intoElement == nil,
           target.childIndex == nil
        {
            // Move if coming from within OutlineView, copy otherwise.
            if singleDraggedItem.type == .outlineViewItem {
                return .moveRedirect(item: nil, childIndex: rootData.count)
            } else {
                return .copyRedirect(item: nil, childIndex: rootData.count)
            }
        }
        
        // If moving into an unexpanded target folder but has a given child index,
        // redirect to remove the childIndex and add to the end of that folder's children.
        if target.intoElement != nil,
           !target.isItemExpanded(target.intoElement!),
           target.childIndex != nil
        {
            // Move if coming from within OutlineView, copy otherwise.
            if singleDraggedItem.type == .outlineViewItem {
                return .moveRedirect(item: target.intoElement, childIndex: nil)
            } else {
                return .copyRedirect(item: target.intoElement, childIndex: nil)
            }
        }

        // All tests have passed, so validate the move or copy as is.
        if singleDraggedItem.type == .outlineViewItem {
            return .move
        } else {
            return .copy
        }
    }
    
    func acceptDrop(target: DropTarget<FileItem>) -> Bool {
        
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
        
        // if an item is moved to a higher index in the same folder as it came from,
        // we need to subtract 1 from the insertion index when inserting after this step
        var subtractFromInsertIndex = 0
        if let previousIndex {
            // Remove previous item.
            if previousIndex.0 == nil {
                rootData.remove(at: previousIndex.1)
            } else {
                let idx = dataAndChildren.firstIndex(where: { $0.item.id == previousIndex.0!.id })!
                dataAndChildren[idx].children?.remove(at: previousIndex.1)
            }
            if previousIndex.0 == target.intoElement,
               let newIndex = target.childIndex,
               newIndex > previousIndex.1
            {
                subtractFromInsertIndex = 1
            }
        }
        
        if let intoItem = target.intoElement,
           let dataChildIndex = dataAndChildren.firstIndex(where: { $0.item.id == intoItem.id })
        {
            // Dropping into a folder
            if let basicIndex = target.childIndex {
                let insertIndex = basicIndex - subtractFromInsertIndex
                dataAndChildren[dataChildIndex].children?.insert(movedItem, at: insertIndex)
            } else {
                dataAndChildren[dataChildIndex].children?.append(movedItem)
            }
        } else if target.intoElement == nil {
            // Dropping into Root
            if let basicIndex = target.childIndex {
                let insertIndex = basicIndex - subtractFromInsertIndex
                rootData.insert(movedItem, at: insertIndex)
            } else {
                rootData.append(movedItem)
            }
        }
        
        // Update dataAndChildren if object was added from outside:
        if dataAndChildren.firstIndex(where: { $0.item.id == movedItem.id }) == nil {
            dataAndChildren.append((movedItem, movedItem.isFolder ? [] : nil))
        }
        
        objectWillChange.send()
        return true
    }
}
