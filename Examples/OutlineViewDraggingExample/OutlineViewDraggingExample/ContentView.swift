//
//  ContentView.swift
//  OutlineViewExample
//
//  Created by Samar Sunkaria on 2/4/21.
//

import SwiftUI
import OutlineView
import Cocoa

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme

    @StateObject var dataSource = sampleDataSource()
    @State var selection: FileItem?
    @State var separatorColor: Color = Color(NSColor.separatorColor)
    @State var separatorEnabled = false
    
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
            dataSource.rootData,
            children: dataSource.childrenOfItem,
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
            guard let encodedID = try? JSONEncoder().encode($0.id)
            else { return nil }
            let pbItem = NSPasteboardItem()
            pbItem.setData(encodedID, forType: .outlineViewItem)
            return pbItem
        }
        .onDrop(of: dataSource.pasteboardTypes, receiver: dataSource)
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
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
