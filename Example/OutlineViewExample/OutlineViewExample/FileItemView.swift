//
//  FileItemView.swift
//  OutlineViewExample
//
//  Created by Samar Sunkaria on 2/4/21.
//

import Cocoa

class FileItemView: NSTableCellView {
    init(fileItem: FileItem) {
        let field = NSTextField(string: fileItem.description)
        field.isEditable = false
        field.isBordered = false
        field.drawsBackground = false
        field.lineBreakMode = .byTruncatingTail

        super.init(frame: .zero)

        addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: leadingAnchor),
            field.trailingAnchor.constraint(equalTo: trailingAnchor),
            field.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            field.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
