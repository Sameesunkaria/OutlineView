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
    @State var selection: FileItem?
    var body: some View {
        OutlineView(data, children: \.children, selection: $selection) { fileItem in
            FileItemView(fileItem: fileItem)
        }
        .outlineViewStyle(.sourceList)
        .outlineViewIndentation(20)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
