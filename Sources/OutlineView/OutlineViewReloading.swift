
import Combine
import Foundation

extension Notification.Name {
    static var OutlineViewReload: Self {
        .init("ReloadOutlineViewNotification")
    }
}

/// Forces an `OutlineView` to reload its row data, which may
/// be necessary if normal state property changes don't cause
/// data updates.
///
/// - Parameter id: The reloadIdentifier of the `OutlineView` to reload.
public func triggerReloadOfOutlineView(id: UUID) {
    NotificationCenter.default.post(
        name: .OutlineViewReload,
        object: nil,
        userInfo: ["id" : id]
    )
}

/// Forces an `OutlineView` to reload its row data for a given group
/// of rows by id, which may be necessary if normal state property
/// changes don't cause data updates.
///
/// - Parameters:
///   - id: The reloadIdentifier of the `OutlineView` to reload.
///   - itemIds: Array of ids of items in the `OutlineView` that need to
///     be reloaded.
public func triggerReloadOfOutlineView<L: Hashable>(id: UUID, itemIds: [L]) {
    NotificationCenter.default.post(
        name: .OutlineViewReload,
        object: nil,
        userInfo: [
            "id" : id,
            "items" : itemIds
        ]
    )
}

extension Notification {
    var outlineId: UUID? {
        userInfo?["id"] as? UUID
    }
    
    func outlineItemIds<L: Hashable>(as type: L.Type) -> [L]? {
        userInfo?["items"] as? [L]
    }
}
