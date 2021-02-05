import XCTest
@testable import OutlineView

class OutlineViewUpdaterTests: XCTestCase {
    struct TestItem: Identifiable, Equatable {
        var id: Int
        var children: [TestItem]?
    }

    let oldState = [
        TestItem(id: 0, children: nil),
        TestItem(id: 1, children: []),
        TestItem(id: 2, children: nil),
        TestItem(id: 3, children: [TestItem(id: 4, children: nil)]),
        TestItem(id: 5, children: [TestItem(id: 6, children: [TestItem(id: 7, children: nil)])]),
    ]
    .map { OutlineViewItem(value: $0, children: \TestItem.children) }


    let newState = [
        TestItem(id: 0, children: []),
        TestItem(id: 1, children: [TestItem(id: 4, children: nil)]),
        TestItem(id: 3, children: []),
        TestItem(id: 5, children: [TestItem(id: 6, children: nil)]),
        TestItem(id: 8, children: nil),
    ]
    .map { OutlineViewItem(value: $0, children: \TestItem.children) }

    func testPerformUpdates() {
        let outlineView = TestOutlineView()
        let updater = OutlineViewUpdater<[TestItem]>()

        updater.performUpdates(
            outlineView: outlineView,
            oldState: oldState,
            newState: newState,
            parent: nil)

        XCTAssertEqual(
            outlineView.insertedItems.sorted(),
            [
                UpdatedItem(parent: nil, index: 4),
                UpdatedItem(parent: 1, index: 0),
            ])

        XCTAssertEqual(
            outlineView.removedItems.sorted(),
            [
                UpdatedItem(parent: nil, index: 2),
                UpdatedItem(parent: 3, index: 0),
                UpdatedItem(parent: 6, index: 0),
            ])

        XCTAssertEqual(
            outlineView.reloadedItems.sorted(),
            [nil, 0, 1, 3, 6])
    }
}

extension OutlineViewUpdaterTests {
    struct UpdatedItem: Equatable, Comparable {
        let parent: Int?
        let index: Int

        static func < (lhs: Self, rhs: Self) -> Bool {
            switch ((lhs.parent, lhs.index), (rhs.parent, rhs.index)) {
            case ((nil, let l), (nil, let r)): return l < r
            case ((nil, _), (_, _)): return true
            case ((_, _), (nil, _)): return false
            case ((let l, _), (let r, _)): return l < r
            }
        }
    }

    class TestOutlineView: NSOutlineView {
        typealias Item = OutlineViewItem<[TestItem]>
        var insertedItems = [UpdatedItem]()
        var removedItems = [UpdatedItem]()
        var reloadedItems = [Item.ID?]()

        override func insertItems(
            at indexes: IndexSet,
            inParent parent: Any?,
            withAnimation animationOptions: NSTableView.AnimationOptions = []
        ) {
            indexes.forEach {
                insertedItems.append(UpdatedItem(parent: (parent as? Item)?.id, index: $0))
            }
        }

        override func removeItems(
            at indexes: IndexSet,
            inParent parent: Any?,
            withAnimation animationOptions: NSTableView.AnimationOptions = []
        ) {
            indexes.forEach {
                removedItems.append(UpdatedItem(parent: (parent as? Item)?.id, index: $0))
            }
        }

        override func reloadItem(
            _ item: Any?,
            reloadChildren: Bool
        ) {
            reloadedItems.append((item as? Item)?.id)
        }
    }
}

extension Optional: Comparable where Wrapped: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (nil, _): return true
        case (_, nil): return false
        case (let l, let r): return l.unsafelyUnwrapped < r.unsafelyUnwrapped
        }
    }
}
