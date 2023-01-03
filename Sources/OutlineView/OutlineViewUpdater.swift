import Cocoa

@available(macOS 10.15, *)
struct OutlineViewUpdater<Data: Sequence>
where Data.Element: Identifiable {
    /// variable for testing purposes. When set to false (the default),
    /// `performUpdates` will escape its recursion for objects that are not
    /// expanded in the outlineView.
    var assumeOutlineIsExpanded = false
    
    /// Perform updates on the outline view based on the change in state.
    /// - NOTE: Calls to this method must be surrounded by
    ///  `NSOutlineView.beginUpdates` and `NSOutlineView.endUpdates`.
    ///  `OutlineViewDataSource.items` should be updated to the new state before calling this method.
    func performUpdates(
        outlineView: NSOutlineView,
        oldStateTree: TreeMap<Data.Element.ID>?,
        newState: [OutlineViewItem<Data>]?,
        parent: OutlineViewItem<Data>?
    ) {
        // Get states to compare: oldIds and newIds, as related to the given parent object
        let oldIds: [Data.Element.ID]?
        if let oldStateTree {
            if let parent {
                oldIds = oldStateTree.currentChildrenOfItem(parent.id)
            } else {
                oldIds = oldStateTree.rootData
            }
        } else {
            oldIds = nil
        }
        
        let newNonOptionalState = newState ?? []

        guard oldIds != nil || newState != nil else {
            // Early exit. No state to compare.
            return
        }

        let oldNonOptionalIds = oldIds ?? []
        let newIds = newNonOptionalState.map { $0.id }
        let diff = newIds.difference(from: oldNonOptionalIds)

        if !diff.isEmpty || oldIds != newIds {
            // Parent needs to be updated as the children have changed.
            // Children are not reloaded to allow animation.
            outlineView.reloadItem(parent, reloadChildren: false)
        }
        
        guard assumeOutlineIsExpanded || outlineView.isItemExpanded(parent) else {
            // Another early exit. If item isn't expanded, no need to compare its children.
            // They'll be updated when the item is later expanded.
            return
        }

        var oldUnchangedElements = newNonOptionalState
            .filter { oldNonOptionalIds.contains($0.id) }
            .reduce(into: [:], { $0[$1.id] = $1 })

        for change in diff {
            switch change {
            case .insert(offset: let offset, _, _):
                outlineView.insertItems(
                    at: IndexSet([offset]),
                    inParent: parent,
                    withAnimation: .effectFade)

            case .remove(offset: let offset, element: let element, _):
                oldUnchangedElements[element] = nil
                outlineView.removeItems(
                    at: IndexSet([offset]),
                    inParent: parent,
                    withAnimation: .effectFade)
            }
        }

        let newStateDict = newNonOptionalState.dictionaryFromIdentity()

        oldUnchangedElements
            .keys
            .map { newStateDict[$0].unsafelyUnwrapped }
            .map { (outlineView, oldStateTree, $0.children, $0) }
            .forEach(performUpdates)
    }
}

@available(macOS 10.15, *)
fileprivate extension Sequence where Element: Identifiable {
    func dictionaryFromIdentity() -> [Element.ID: Element] {
        Dictionary(map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
    }
}
