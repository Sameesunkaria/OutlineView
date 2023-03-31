//
//  ContentView.swift
//  OutlineViewExample
//
//  Created by Samar Sunkaria on 2/4/21.
//

import SwiftUI
import OutlineView
import Cocoa

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

    @State var rootTextColor: Color = Color(NSColor.textColor)
    @State var childTextColor: Color = Color(NSColor.textColor)
    
    let outlineId = UUID()
    
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
    
    var rootIds: [UUID] {
        data.map(\.id)
    }

    var outlineView: some View {
        OutlineView(
            data,
            selection: $selection,
            children: \.children,
            separatorInsets: { fileItem in
                NSEdgeInsets(
                    top: 0,
                    left: 23,
                    bottom: 0,
                    right: 0)
            }
        ) { fileItem in
            FileItemView(fileItem: fileItem, textColor: NSColor(rootIds.contains(fileItem.id) ? rootTextColor : childTextColor))
        }
        .outlineViewStyle(.inset)
        .outlineViewIndentation(20)
        .rowSeparator(separatorEnabled ? .visible : .hidden)
        .rowSeparatorColor(NSColor(separatorColor))
        .onChange(of: rootTextColor) { _ in
            triggerReloadOfOutlineView(id: outlineId, itemIds: rootIds)
        }
        .onChange(of: childTextColor) { _ in
            triggerReloadOfOutlineView(id: outlineId)
        }
    }

    var configBar: some View {
        HStack {
            ColorPicker(
                "Root Text Color:",
                selection: $rootTextColor)
            Button(
                "Set Child Text Color",
                action: { self.childTextColor = self.rootTextColor })
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
