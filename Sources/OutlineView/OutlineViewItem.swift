/// A wrapper for holding the outline view data items. This wrapper exposes the `id` of the
/// wrapped value for its conformance to `Equatable` and `Hashable`. `NSOutlineView`
/// requires that Swift value types be "equal" to correctly find the stored item internally.
/// `OutlineView` chooses to use the `Identifiable` protocol for identifying items,
/// necessitating the use of a wrapper.
///
/// Reference: AppKit Release Notes for macOS 10.14 - API Changes - `NSOutlineView`
/// https://developer.apple.com/documentation/macos-release-notes/appkit-release-notes-for-macos-10_14
struct OutlineViewItem<Wrapped: Identifiable>: Equatable, Hashable, Identifiable {
    var childrenPath: KeyPath<Wrapped, [Wrapped]?>
    var value: Wrapped

    var children: [OutlineViewItem]? {
        value[keyPath: childrenPath]?.map { OutlineViewItem(value: $0, children: childrenPath) }
    }

    init(value: Wrapped, children: KeyPath<Wrapped, [Wrapped]?>) {
        self.value = value
        childrenPath = children
    }

    var id: Wrapped.ID {
        value.id
    }

    static func == (
        lhs: OutlineViewItem<Wrapped>,
        rhs: OutlineViewItem<Wrapped>
    ) -> Bool {
        lhs.value.id == rhs.value.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(value.id)
    }
}
