//
//  OutlineViewController.swift
//  
//
//  Created by Samar Sunkaria on 11/21/20.
//

import Cocoa
import SwiftUI

public class OutlineViewController<Item: Identifiable & Hashable>: NSViewController {
    let outlineView = NSOutlineView()
    let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 400))
    
    let dataSource: OutlineViewDataSource<Item>
    let delegate: OutlineViewDelegate<Item>

    init(
        items: [Item],
        children: KeyPath<Item, [Item]?>,
        rowContent: @escaping (Item) -> NSView,
        selectionChanged: @escaping (Item?) -> Void
    ) {
        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalRuler = true
        scrollView.drawsBackground = false

        outlineView.autoresizesOutlineColumn = false
        outlineView.headerView = nil
        outlineView.usesAutomaticRowHeights = true
        outlineView.selectionHighlightStyle = .sourceList

        let col = NSTableColumn()
        outlineView.addTableColumn(col)

        dataSource = OutlineViewDataSource(items: items, children: children)
        delegate = OutlineViewDelegate(rowContent: rowContent, selectionChanged: selectionChanged)
        outlineView.dataSource = dataSource
        outlineView.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    public override func loadView() {
        view = NSView()
    }

    public override func viewWillAppear() {
        // Workaround layout glitches that occur when the
        // outline view is presented for the first time.
        outlineView.reloadData()
        super.viewWillAppear()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func updateItems(newValue: [Item]) {
        let diff = newValue.difference(from: dataSource.items, by: { $0.id == $1.id }).inferringMoves()

        outlineView.beginUpdates()
        for change in diff {
            if case let .remove(offset, _, _) = change {
                outlineView.removeItems(at: IndexSet([offset]), inParent: nil, withAnimation: .effectFade)
            }
            if case let .insert(offset, _, _) = change {
                outlineView.insertItems(at: IndexSet([offset]), inParent: nil, withAnimation: .effectFade)
            }
        }

        dataSource.items = newValue
        outlineView.endUpdates()

        // Workaround layout issues with the first row.
        // It does not seem to adjust its height correctly based on the autolayout constraints.
        if !dataSource.items.isEmpty {
            outlineView.noteHeightOfRows(withIndexesChanged: IndexSet([0]))
        }
    }
}
