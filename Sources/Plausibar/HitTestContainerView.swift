import AppKit

/// Panel contentView that returns nil from `hitTest(_:)` for points outside the
/// currently-drawn notch shape. Clicks in the transparent regions below the
/// collapsed strip (and inside the notch cutout itself) pass through to
/// whatever window is underneath instead of being swallowed by the panel.
final class HitTestContainerView: NSView {
    var isExpanded: Bool = false
    let notchWidth: CGFloat
    let notchHeight: CGFloat
    let expandedExtra: CGFloat

    init(frame: NSRect, notchWidth: CGFloat, notchHeight: CGFloat, expandedExtra: CGFloat) {
        self.notchWidth = notchWidth
        self.notchHeight = notchHeight
        self.expandedExtra = expandedExtra
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        let w = bounds.width
        let h = bounds.height
        let shapeH = isExpanded ? notchHeight + expandedExtra : notchHeight
        let topY = h - shapeH

        if local.y < topY { return nil }

        let nl = (w - notchWidth) / 2
        let nr = nl + notchWidth
        if local.y >= h - notchHeight && local.x > nl && local.x < nr {
            return nil
        }

        return super.hitTest(point)
    }
}
