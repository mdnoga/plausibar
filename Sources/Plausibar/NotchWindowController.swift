import AppKit
import SwiftUI

@MainActor
final class NotchWindowController {
    private var panel: NSPanel?
    private let store: StatsStore

    init(store: StatsStore) {
        self.store = store
    }

    static var hasNotch: Bool {
        (NSScreen.main?.safeAreaInsets.top ?? 0) > 0
    }

    var isVisible: Bool { panel?.isVisible ?? false }

    func show() {
        if panel == nil { build() }
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func build() {
        guard let screen = NSScreen.main else { return }

        let notchWidth = computedNotchWidth(screen: screen)
        let notchHeight = max(screen.safeAreaInsets.top, 32)
        let sidePadding: CGFloat = 56
        let expandedExtra: CGFloat = 180
        let panelWidth = notchWidth + sidePadding * 2
        let panelHeight = notchHeight + expandedExtra + 20

        let x = screen.frame.midX - panelWidth / 2
        let y = screen.frame.maxY - panelHeight
        let rect = NSRect(x: x, y: y, width: panelWidth, height: panelHeight)

        let p = NSPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isFloatingPanel = true
        p.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1)
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        p.isMovable = false
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = false
        p.hidesOnDeactivate = false
        p.ignoresMouseEvents = false

        let container = HitTestContainerView(
            frame: NSRect(origin: .zero, size: rect.size),
            notchWidth: notchWidth,
            notchHeight: notchHeight,
            expandedExtra: expandedExtra
        )

        let host = NSHostingView(
            rootView: NotchView(
                notchWidth: notchWidth,
                notchHeight: notchHeight,
                onExpandedChange: { [weak container] expanded in
                    container?.isExpanded = expanded
                }
            )
            .environmentObject(store)
        )
        host.frame = container.bounds
        host.autoresizingMask = [.width, .height]
        container.addSubview(host)

        p.contentView = container

        self.panel = p
    }

    private func computedNotchWidth(screen: NSScreen) -> CGFloat {
        let left = screen.auxiliaryTopLeftArea?.width ?? 0
        let right = screen.auxiliaryTopRightArea?.width ?? 0
        let w = screen.frame.width - left - right
        return (w > 0 && w < 320) ? w : 200
    }
}
