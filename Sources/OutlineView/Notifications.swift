import AppKit

extension NSOutlineView {
    
    /// Converts a notification from any of NSOutlineView's item notifiers
    /// into a tuple of the outlineView and the item that was notified about.
    ///
    /// Notifications this works for:
    /// - itemDidCollapseNotification
    /// - itemDidExpandNotification
    /// - itemWillCollapseNotification
    /// - itemWillExpandNotification
    ///
    /// If the Notification is in an incorrect format for any of the above notifications,
    /// this function returns nil.
    static func expansionNotificationInfo(_ note: Notification) -> (outlineView: NSOutlineView, object: Any)? {
        guard let outlineView = note.object as? NSOutlineView,
              let object = note.userInfo?["NSObject"]
        else { return nil }
        
        return (outlineView, object)
    }
    
}
