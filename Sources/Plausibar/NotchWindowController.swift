import AppKit
import SwiftUI

@MainActor
final class NotchWindowController {
    private var panel: NSPanel?
    private let store: StatsStore

    private var notchWidth: CGFloat = 0
    private var notchHeight: CGFloat = 0
    private var contentWidth: CGFloat = 0
    private let expandedExtra: CGFloat = 180
    private let collapseDelay: Duration = .milliseconds(420)

    private var collapseTask: Task<Void, Never>?

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

        notchWidth = computedNotchWidth(screen: screen)
        notchHeight = max(screen.safeAreaInsets.top, 32)
        let sidePadding: CGFloat = 56
        contentWidth = notchWidth + sidePadding * 2

        let rect = frameRect(expanded: false, screen: screen)

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

        let host = NSHostingView(
            rootView: NotchView(
                notchWidth: notchWidth,
                notchHeight: notchHeight,
                onExpandedChange: { [weak self] expanded in
                    self?.setExpanded(expanded)
                }
            )
            .environmentObject(store)
        )
        host.frame = NSRect(origin: .zero, size: rect.size)
        host.autoresizingMask = [.width, .height]
        p.contentView = host

        self.panel = p
    }

    private func setExpanded(_ expanded: Bool) {
        collapseTask?.cancel()
        if expanded {
            applyFrame(expanded: true)
        } else {
            collapseTask = Task { [weak self] in
                try? await Task.sleep(for: self?.collapseDelay ?? .milliseconds(420))
                guard let self, !Task.isCancelled else { return }
                self.applyFrame(expanded: false)
            }
        }
    }

    private func applyFrame(expanded: Bool) {
        guard let panel, let screen = NSScreen.main else { return }
        panel.setFrame(frameRect(expanded: expanded, screen: screen), display: true, animate: false)
    }

    private func frameRect(expanded: Bool, screen: NSScreen) -> NSRect {
        let h = expanded ? notchHeight + expandedExtra : notchHeight
        return NSRect(
            x: screen.frame.midX - contentWidth / 2,
            y: screen.frame.maxY - h,
            width: contentWidth,
            height: h
        )
    }

    private func computedNotchWidth(screen: NSScreen) -> CGFloat {
        let left = screen.auxiliaryTopLeftArea?.width ?? 0
        let right = screen.auxiliaryTopRightArea?.width ?? 0
        let w = screen.frame.width - left - right
        return (w > 0 && w < 320) ? w : 200
    }
}
