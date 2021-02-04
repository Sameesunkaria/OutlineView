import XCTest
@testable import OutlineView

class OutlineViewItemTests: XCTestCase {
    struct TestItem: Identifiable, Equatable {
        var id: Int
        var children: [TestItem]?
    }

    let testItem = TestItem(
        id: 1,
        children: [
            TestItem(id: 2, children: nil),
            TestItem(id: 3, children: nil),
            TestItem(id: 4, children: nil),
        ])

    func testInit() {
        let outlineItem = OutlineViewItem(value: testItem, children: \TestItem.children)

        XCTAssertEqual(outlineItem.value, testItem)
        XCTAssertEqual(outlineItem.children?.map(\.value), testItem.children)
    }

    func testEquatable() {
        let firstOutlineItem = OutlineViewItem(value: testItem, children: \TestItem.children)

        let otherItem = TestItem(id: 1, children: nil)
        let secondOutlineItem = OutlineViewItem(value: otherItem, children: \TestItem.children)

        // Even though testItem and otherItem are not equal,
        // the OutlineViewItem should still be equal, as it derives its
        // Equatable conformance from the identity (id) of the value it wraps.
        XCTAssertNotEqual(testItem, otherItem)
        XCTAssertEqual(firstOutlineItem, secondOutlineItem)
    }

    func testHashable() {
        let firstOutlineItem = OutlineViewItem(value: testItem, children: \TestItem.children)

        let otherItem = TestItem(id: 1, children: nil)
        let secondOutlineItem = OutlineViewItem(value: otherItem, children: \TestItem.children)

        // Even though TestItem does not conform to Hashable, the
        // OutlineViewItem wrapping the TestItem will derives its
        // Hashable conformance from the identity (id) of the value it wraps.
        XCTAssertEqual(firstOutlineItem.hashValue, secondOutlineItem.hashValue)
    }

    func testIdentifiable() {
        let outlineItem = OutlineViewItem(value: testItem, children: \TestItem.children)

        XCTAssertEqual(outlineItem.id, testItem.id)
    }
}
