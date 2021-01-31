import Cocoa

class OutlineViewDataSource<Data: Sequence>: NSObject, NSOutlineViewDataSource
where Data.Element: Identifiable {
    var items: [OutlineViewItem<Data>]

    init(items: [OutlineViewItem<Data>]) {
        self.items = items
    }

    func typedItem(_ item: Any) -> OutlineViewItem<Data> {
        item as! OutlineViewItem<Data>
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        numberOfChildrenOfItem item: Any?
    ) -> Int {
        if let item = item.map(typedItem) {
            return item.children?.count ?? 0
        } else {
            return items.count
        }
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        isItemExpandable item: Any
    ) -> Bool {
        typedItem(item).children != nil
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        child index: Int,
        ofItem item: Any?
    ) -> Any {
        if let item = item.map(typedItem) {
            // Should only be called if item has children.
            return item.children.unsafelyUnwrapped[index]
        } else {
            return items[index]
        }
    }
}

extension OutlineViewDataSource {
    /// Perform updates on the outline view based on the change in state.
    /// - NOTE: Calls to this method must be surrounded by
    ///  `NSOutlineView.beginUpdates` and `NSOutlineView.endUpdates`.
    ///  `OutlineViewDataSource.items` should be updated to the new state before calling this method.
    func performUpdates(
        outlineView: NSOutlineView,
        oldState: [OutlineViewItem<Data>]?,
        newState: [OutlineViewItem<Data>]?,
        parent: OutlineViewItem<Data>?
    ) {
        let oldNonOptionalState = oldState ?? []
        let newNonOptionalState = newState ?? []

        guard !oldNonOptionalState.isEmpty || !newNonOptionalState.isEmpty else {
            // Early exit. No state to compare.
            return
        }

        let diff = newNonOptionalState.difference(
            from: oldNonOptionalState, by: { $0.value.id == $1.value.id })

        if !diff.isEmpty {
            // Parent needs to be update as the children have changed.
            // Children are not reloaded to allow animation.
            outlineView.reloadItem(parent, reloadChildren: false)
        }

        var removedElements = [OutlineViewItem<Data>]()

        for change in diff {
            switch change {
            case .insert(offset: let offset, _, _):
                outlineView.insertItems(
                    at: IndexSet([offset]),
                    inParent: parent,
                    withAnimation: .effectFade)

            case .remove(offset: let offset, element: let element, _):
                removedElements.append(element)
                outlineView.removeItems(
                    at: IndexSet([offset]),
                    inParent: parent,
                    withAnimation: .effectFade)
            }
        }

        var oldUnchangedElements = oldNonOptionalState.dictionaryFromIdentity()
        removedElements.forEach { oldUnchangedElements.removeValue(forKey: $0.id) }

        let newStateDict = newNonOptionalState.dictionaryFromIdentity()

        oldUnchangedElements
            .keys
            .map { (oldUnchangedElements[$0].unsafelyUnwrapped, newStateDict[$0].unsafelyUnwrapped) }
            .map { (outlineView, $0.0.children, $0.1.children, $0.1) }
            .forEach(performUpdates)
    }
}

fileprivate extension Sequence where Element: Identifiable {
    func dictionaryFromIdentity() -> [Element.ID: Element] {
        Dictionary(map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
    }
}
