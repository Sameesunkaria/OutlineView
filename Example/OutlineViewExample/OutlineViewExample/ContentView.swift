//
//  ContentView.swift
//  OutlineViewExample
//
//  Created by Samar Sunkaria on 2/4/21.
//

import SwiftUI
import OutlineView
import Cocoa

extension NSPasteboard.PasteboardType {
    static var outlineViewItem: Self {
        .init("OutlineView.OutlineItem")
    }
}

struct FileItem: Hashable, Identifiable, CustomStringConvertible {
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
    
    func childWithId(_ searchId: UUID) -> Self? {
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

let data = [
    FileItem(name: "doc001.txt"),
    FileItem(
        name: "users",
        children: [
            FileItem(
                name: "user1234",
                children: [
                    FileItem(
                        name: "Photos",
                        children: [
                            FileItem(name: "photo001.jpg"),
                            FileItem(name: "photo002.jpg")]),
                    FileItem(
                        name: "Movies",
                        children: [FileItem(name: "movie001.mp4")]),
                    FileItem(name: "Documents", children: [])]),
            FileItem(
                name: "newuser",
                children: [FileItem(name: "Documents", children: [])])
        ]
    )
]

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme

    @State var selection: FileItem?
    @State var separatorColor: Color = Color(NSColor.separatorColor)
    @State var separatorEnabled = false
    
    private var readableDragTypes: [NSPasteboard.PasteboardType] = [
        .outlineViewItem,
        .string,
        .fileURL,
        .fileContents
    ]

    var body: some View {
        VStack {
            outlineView
            Divider()
            configBar
        }
        .background(
            colorScheme == .light
                ? Color(NSColor.textBackgroundColor)
                : Color.clear
        )
    }

    var outlineView: some View {
        OutlineView(
            data,
            children: \.children,
            selection: $selection,
            separatorInsets: { fileItem in
                NSEdgeInsets(
                    top: 0,
                    left: 23,
                    bottom: 0,
                    right: 0)
            }
        ) { fileItem in
            FileItemView(fileItem: fileItem)
        }
        .outlineViewStyle(.inset)
        .outlineViewIndentation(20)
        .rowSeparator(separatorEnabled ? .visible : .hidden)
        .rowSeparatorColor(NSColor(separatorColor))
        .dragDataSource {
            guard let encodedId = try? JSONEncoder().encode($0.id)
            else { return nil }
            let pbItem = NSPasteboardItem()
            pbItem.setData(encodedId, forType: .outlineViewItem)
            return pbItem
        }
        .acceptDrops(
            types: readableDragTypes,
            itemsFromPasteboard: itemsFromPasteboard,
            validateItem: validateDragItem,
            onDrop: onDrop
        )
        
    }

    var configBar: some View {
        HStack {
            Spacer()
            ColorPicker(
                "Set separator color:",
                selection: $separatorColor)
            Button(
                "Toggle separator",
                action: { separatorEnabled.toggle() })
        }
        .padding([.leading, .bottom, .trailing], 8)
    }
    
    private func getItemWithId(_ id: UUID) -> FileItem? {
        for item in data {
            if let result = item.childWithId(id) {
                return result
            }
        }
        return nil
    }
        
    private func itemsFromPasteboard(_ source: NSPasteboardItem) -> DraggedItem<FileItem>? {
        guard let pasteboardType = source.availableType(from: readableDragTypes)
        else { return nil }
        
        var result: FileItem? = nil
        switch pasteboardType {
        case .outlineViewItem:
            let encodedData = source.data(forType: pasteboardType)
            let decodedId = encodedData.flatMap { try? JSONDecoder().decode(UUID.self, from: $0) }
            result = decodedId.flatMap { getItemWithId($0) }
        case .fileURL:
            let filePath = source.string(forType: pasteboardType)
            let fileUrl = filePath.map { URL(fileURLWithPath: $0) }
            let fileName = fileUrl?.standardized.lastPathComponent
            result = fileName.map { FileItem(name: $0) }
        case .fileContents:
            let fileData = source.data(forType: pasteboardType) ?? Data()
            let sizeOfData = Int64(fileData.count)
            result = FileItem(name: ByteCountFormatter.string(fromByteCount: sizeOfData, countStyle: .file))
        case .string:
            let stringValue = source.string(forType: pasteboardType)
            result = stringValue.map { FileItem(name: $0) }
        default:
            break
        }
        
        return result.map { ($0, pasteboardType) }
    }
    
    private func validateDragItem(_ target: DropTarget<FileItem>) -> ValidationResult<FileItem> {
        
        guard !target.items.isEmpty
        else { return .deny }
        
        if target.intoElement == nil {
            return .copy
        } else if target.items.first!.item.childWithId(target.intoElement!.id) != nil {
            return .deny
        } else {
            return .move
        }
        
    }
    
    private func onDrop(_ target: DropTarget<FileItem>) -> Bool {
        print("""
        Dropping \(target.items.count) items onto item \(target.intoElement?.name ?? "root") \
        at index \(target.childIndex ?? -1)
        \(target.items.map { "\($0.item.name): \($0.type.rawValue)" })
        """)
        return false
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
