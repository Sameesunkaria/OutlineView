import XCTest
@testable import OutlineView

final class TreeMapTests: XCTestCase {
    struct TestItem: Identifiable, Equatable {
        var id: Int
        var children: [TestItem]?
    }

    /// A basic TreeMap with 5 root objects (1 through 5),
    /// where all but item 5 are internal nodes, and all
    /// are collapsed.
    private var testTree: TreeMap<Int> {
        let rootItems = (1...5)
            .map { TestItem(id: $0, children: $0 == 5 ? nil : []) }
            .map { OutlineViewItem(value: $0, children: \TestItem.children) }
        return TreeMap(rootItems: rootItems, itemIsExpanded: { _ in false })
    }
    
    func testExpandItem() {
        let tree = testTree

        tree.expandItem(4, children: [
            (41, true),
            (42, false)
        ])

        let children = tree.currentChildrenOfItem(4)
        XCTAssertEqual(children, [41, 42])
    }
    
    func testIsItemExpandable() {
        let tree = testTree

        tree.expandItem(4, children: [
            (41, true),
            (42, false)
        ])

        XCTAssertTrue(tree.isItemExpandable(1))
        XCTAssertTrue(tree.isItemExpandable(2))
        XCTAssertTrue(tree.isItemExpandable(3))
        XCTAssertTrue(tree.isItemExpandable(4))
        XCTAssertFalse(tree.isItemExpandable(5))
        
        XCTAssertTrue(tree.isItemExpandable(42))
        XCTAssertFalse(tree.isItemExpandable(41))
    }
    
    func testIsItemExpanded() {
        let tree = testTree

        tree.expandItem(4, children: [
            (41, true),
            (42, false)
        ])

        for n in [1, 2, 3, 5, 41, 42] {
            XCTAssertFalse(tree.isItemExpanded(n))
        }
        
        XCTAssertTrue(tree.isItemExpanded(4))
    }
    
    func testCurrentChildrenOfItems() {
        let tree = testTree

        tree.expandItem(4, children: [
            (41, true),
            (42, false)
        ])
        
        XCTAssertEqual([41, 42], tree.currentChildrenOfItem(4))
    }
    
    func testAddItems() {
        let tree = testTree

        tree.expandItem(4, children: [
            (41, true),
            (44, false)
        ])

        tree.addItem(42, isLeaf: true, intoItem: 4, atIndex: 1)
        tree.addItem(43, isLeaf: false, intoItem: 4, atIndex: 2)
        tree.addItem(45, isLeaf: true, intoItem: 4, atIndex: nil)
        
        XCTAssertEqual(Array(41...45), tree.currentChildrenOfItem(4))
    }
    
    func testCollapseItems() {
        let tree = testTree

        tree.expandItem(4, children: [
            (41, true),
            (42, false)
        ])

        tree.collapseItem(4)
        
        XCTAssertFalse(tree.isItemExpanded(4))
        XCTAssertEqual(tree.currentChildrenOfItem(4), nil)
    }
    
    func testRemoveItems() {
        let tree = testTree
        
        tree.expandItem(
            4,
            children: (41...45).map({ ($0, false) })
        )
        
        tree.expandItem(
            45,
            children: (451...455).map({ ($0, false) })
        )
        
        let allIds = [1, 2, 3, 4, 5, 41, 42, 43, 44, 45, 451, 452, 453, 454, 455]
        XCTAssertEqual(Set(allIds), tree.allItemIds)
        tree.removeItem(4)
        XCTAssertEqual(tree.allItemIds, Set([1, 2, 3, 5]))
    }
            
    func testLineageOfItem() {
        let tree = testTree
        
        tree.expandItem(
            4,
            children: (41...45).map({ ($0, false) })
        )
        
        tree.expandItem(
            45,
            children: (451...455).map({ ($0, false) })
        )

        XCTAssertEqual(tree.lineageOfItem(455), [4, 45, 455])
    }
}
