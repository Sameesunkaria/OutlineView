import XCTest
@testable import OutlineView

class OutlineViewDataSourceTests: XCTestCase {
    struct TestItem: Identifiable, Equatable {
        var id: Int
        var children: [TestItem]?
    }

    let items = [
        TestItem(id: 1, children: []),
        TestItem(id: 2, children: nil),
        TestItem(id: 3, children: [TestItem(id: 4, children: nil)]),
    ]
    .map { OutlineViewItem(value: $0, children: \TestItem.children) }

    let outlineView = NSOutlineView()

    func testInit() {
        let dataSource = OutlineViewDataSource(items: items)
        XCTAssertEqual(dataSource.items, items)
    }

    func testNumberOfChildrenOfItem() {
        let dataSource = OutlineViewDataSource(items: items)

        XCTAssertEqual(dataSource.outlineView(outlineView, numberOfChildrenOfItem: items[0]), 0)
        XCTAssertEqual(dataSource.outlineView(outlineView, numberOfChildrenOfItem: items[1]), 0)
        XCTAssertEqual(dataSource.outlineView(outlineView, numberOfChildrenOfItem: items[2]), 1)
        XCTAssertEqual(dataSource.outlineView(outlineView, numberOfChildrenOfItem: items[2].children![0]), 0)
    }

    func testItemIsExpandable() {
        let dataSource = OutlineViewDataSource(items: items)

        XCTAssertEqual(dataSource.outlineView(outlineView, isItemExpandable: items[0]), true)
        XCTAssertEqual(dataSource.outlineView(outlineView, isItemExpandable: items[1]), false)
        XCTAssertEqual(dataSource.outlineView(outlineView, isItemExpandable: items[2]), true)
        XCTAssertEqual(dataSource.outlineView(outlineView, isItemExpandable: items[2].children![0]), false)
    }

    func testChildOfItem() throws {
        let dataSource = OutlineViewDataSource(items: items)

        XCTAssertEqual(try XCTUnwrap(dataSource.outlineView(outlineView, child: 0, ofItem: nil) as? OutlineViewItem<[TestItem]>), items[0])
        XCTAssertEqual(try XCTUnwrap(dataSource.outlineView(outlineView, child: 1, ofItem: nil) as? OutlineViewItem<[TestItem]>), items[1])
        XCTAssertEqual(try XCTUnwrap(dataSource.outlineView(outlineView, child: 2, ofItem: nil) as? OutlineViewItem<[TestItem]>), items[2])
        XCTAssertEqual(try XCTUnwrap(dataSource.outlineView(outlineView, child: 0, ofItem: items[2]) as? OutlineViewItem<[TestItem]>), items[2].children![0])
    }
}
