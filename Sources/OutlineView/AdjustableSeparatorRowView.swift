import AppKit
import ObjectiveC

/// An NSTableRowView with an adjustable separator line.
class AdjustableSeparatorRowView: NSTableRowView {
    var separatorInsets: NSEdgeInsets = .zero

    public override init(frame frameRect: NSRect) {
        Self.setupSwizzling
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        Self.setupSwizzling
        super.init(coder: coder)
    }

    /// Our implementation of the private `_separatorRect` method.
    /// Computes the frame of the `_separatorView`.
    @objc
    func separatorRect() -> CGRect {
        // Get the frame from the original method.
        guard let rect = Self.originalSeparatorRect?(self) else {
            return .zero
        }

        // Inset the frame by the separatorInsets.
        return CGRect(
            x: rect.origin.x + separatorInsets.left,
            y: rect.origin.y + separatorInsets.top,
            width: rect.width - separatorInsets.left - separatorInsets.right,
            height: rect.height - separatorInsets.top - separatorInsets.bottom)
    }

    /// Stores the original implementation of `_separatorRect` if sucessfully swizzled.
    static var originalSeparatorRect: ((AdjustableSeparatorRowView) -> CGRect)?

    /// Swizzle the private `_separatorRect` defined on NSTableRowView.
    /// Should be executed early in the life-cycle of `AdjustableSeparatorRowView`.
    static let setupSwizzling: Void = {
        // Selector for _separatorRect.
        let privateSeparatorRectSelector = Selector(unmangle("^rdo`q`snqQdbs"))
        guard
            let originalMethod = class_getInstanceMethod(
                AdjustableSeparatorRowView.self,
                privateSeparatorRectSelector),
            let newMethod = class_getInstanceMethod(
                AdjustableSeparatorRowView.self,
                #selector(separatorRect))
        else { return }

        // Replace the original implmentation with our implementation.
        let originalImplementation = method_setImplementation(
            originalMethod,
            method_getImplementation(newMethod))

        // Store the original implementation for later use.
        originalSeparatorRect = { instance in
            let privateSeparatorRect = unsafeBitCast(
                originalImplementation,
                to: (@convention(c) (Any?, Selector?) -> CGRect).self)
            return privateSeparatorRect(instance, privateSeparatorRectSelector)
        }
    }()
}
