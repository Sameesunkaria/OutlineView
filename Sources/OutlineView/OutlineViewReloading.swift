
import Combine
import Foundation

extension Notification.Name {
    static var OutlineViewReload: Self {
        .init("ReloadOutlineViewNotification")
    }
}

/// Manually forces an OutlineView to reload its row data, which
/// may be necessary if normal state property changes don't cause
/// data updates.
/// - Parameter id: The id of the OutlineView to be reloaded.
public func triggerReloadOfOutlineView<K: Hashable>(id: K) {
    NotificationCenter.default.post(
        name: .OutlineViewReload,
        object: nil,
        userInfo: ["id" : id]
    )
}

/// Manually forces an OutlineView to reload its row data for a given
/// group of rows by id, which may be necessary if normal state property
/// changes don't cause data updates.
///
/// - Parameters:
///   - id: The id of the OutlineView to be reloaded.
///   - itemIds: Array of ids of items in the `OutlineView` that need to
///     be reloaded.
public func triggerReloadOfOutlineView<K: Hashable, L: Hashable>(id: K, itemIds: [L]) {
    NotificationCenter.default.post(
        name: .OutlineViewReload,
        object: nil,
        userInfo: [
            "id" : id,
            "items" : itemIds
        ]
    )
}

internal extension Notification {
    
    func outlineId<K: Hashable>(as type: K.Type) -> K? {
        userInfo?["id"] as? K
    }
    
    func outlineItemIds<L: Hashable>(as type: L.Type) -> [L]? {
        userInfo?["items"] as? [L]
    }
    
}
