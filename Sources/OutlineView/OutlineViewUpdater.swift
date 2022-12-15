import Cocoa

@available(macOS 10.15, *)
struct OutlineViewUpdater<Data: Sequence>
where Data.Element: Identifiable {
    /// Perform updates on the outline view based on the change in state.
    /// - NOTE: Calls to this method must be surrounded by
    ///  `NSOutlineView.beginUpdates` and `NSOutlineView.endUpdates`.
    ///  `OutlineViewDataSource.items` should be updated to the new state before calling this method.
    func performUpdates(
        outlineView: NSOutlineView,
        oldState: [TreeNode<Data.Element.ID>]?,
        newState: [OutlineViewItem<Data>]?,
        parent: OutlineViewItem<Data>?
    ) {
        let oldNonOptionalState = oldState ?? []
        let newNonOptionalState = newState ?? []

        guard oldState != nil || newState != nil else {
            // Early exit. No state to compare.
            return
        }

        let oldIds = oldState?.map { $0.value }
        let newIds = newNonOptionalState.map { $0.id }
        let diff = newIds.difference(from: oldIds ?? [])

        if !diff.isEmpty || oldIds != newIds {
            // Parent needs to be update as the children have changed.
            // Children are not reloaded to allow animation.
            outlineView.reloadItem(parent, reloadChildren: false)
        }
        
        if !outlineView.isItemExpanded(parent) {
            // Another early exit. If item isn't expanded, no need to compare its children.
            // They'll be updated when the item is later expanded.
            return
        }

        var removedElements = [TreeNode<Data.Element.ID>]()

        for change in diff {
            switch change {
            case .insert(offset: let offset, _, _):
                outlineView.insertItems(
                    at: IndexSet([offset]),
                    inParent: parent,
                    withAnimation: .effectFade)

            case .remove(offset: let offset, element: let element, _):
                let removedElement = oldNonOptionalState.first(where: { $0.value == element })!
                removedElements.append(removedElement)
                outlineView.removeItems(
                    at: IndexSet([offset]),
                    inParent: parent,
                    withAnimation: .effectFade)
            }
        }

        var oldUnchangedElements = oldNonOptionalState.reduce(into: [:], { $0[$1.value] = $1 })
        removedElements.forEach { oldUnchangedElements.removeValue(forKey: $0.value) }

        let newStateDict = newNonOptionalState.dictionaryFromIdentity()

        oldUnchangedElements
            .keys
            .map { (oldUnchangedElements[$0].unsafelyUnwrapped, newStateDict[$0].unsafelyUnwrapped) }
            .map { (outlineView, $0.0.children, $0.1.children, $0.1) }
            .forEach(performUpdates)
    }
}

@available(macOS 10.15, *)
fileprivate extension Sequence where Element: Identifiable {
    func dictionaryFromIdentity() -> [Element.ID: Element] {
        Dictionary(map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
    }
}
