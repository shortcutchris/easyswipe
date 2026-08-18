import AppKit
import Foundation

@MainActor
protocol HUDPresenting {
    func show(action: WindowGestureAction, over targetFrame: CGRect)
}

@MainActor
final class HUDPresenter: HUDPresenting {
    private let panel: NSPanel
    private let visualEffectView: NSVisualEffectView
    private let imageView: NSImageView
    private var hideWorkItem: DispatchWorkItem?

    init() {
        panel = NSPanel(
            contentRect: CGRect(x: 0, y: 0, width: 56, height: 56),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isReleasedWhenClosed = false
        panel.alphaValue = 0

        visualEffectView = NSVisualEffectView(frame: panel.contentView?.bounds ?? .zero)
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 14
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false

        imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.contentTintColor = .labelColor
        imageView.translatesAutoresizingMaskIntoConstraints = false

        guard let contentView = panel.contentView else { return }
        contentView.addSubview(visualEffectView)
        visualEffectView.addSubview(imageView)

        NSLayoutConstraint.activate([
            visualEffectView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            visualEffectView.topAnchor.constraint(equalTo: contentView.topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: visualEffectView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    func show(action: WindowGestureAction, over targetFrame: CGRect) {
        hideWorkItem?.cancel()
        panel.orderOut(nil)

        imageView.image = image(for: action)
        updateAccessibilityAppearance()

        let panelSize = panel.frame.size
        let origin = CGPoint(
            x: targetFrame.midX - panelSize.width / 2,
            y: targetFrame.midY - panelSize.height / 2
        )
        panel.setFrameOrigin(origin)
        panel.alphaValue = 0
        panel.orderFrontRegardless()

        let shouldReduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if shouldReduceMotion {
            panel.alphaValue = 1
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.08
                panel.animator().alphaValue = 1
            }
        }

        let workItem = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                self?.hide()
            }
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38, execute: workItem)
    }

    private func hide() {
        let duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.14
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            panel.animator().alphaValue = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            MainActor.assumeIsolated {
                self?.panel.orderOut(nil)
            }
        }
    }

    private func updateAccessibilityAppearance() {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency {
            visualEffectView.material = .windowBackground
            visualEffectView.blendingMode = .withinWindow
        } else {
            visualEffectView.material = .hudWindow
            visualEffectView.blendingMode = .behindWindow
        }
    }

    private func image(for action: WindowGestureAction) -> NSImage? {
        let preferredName: String
        let fallbackName: String

        switch action {
        case .snapLeft:
            preferredName = "rectangle.lefthalf.filled"
            fallbackName = "arrow.left"
        case .snapRight:
            preferredName = "rectangle.righthalf.filled"
            fallbackName = "arrow.right"
        case .minimize:
            preferredName = "minus"
            fallbackName = "minus.circle"
        }

        return NSImage(systemSymbolName: preferredName, accessibilityDescription: announcement(for: action))
            ?? NSImage(systemSymbolName: fallbackName, accessibilityDescription: announcement(for: action))
    }

    private func announcement(for action: WindowGestureAction) -> String {
        switch action {
        case .snapLeft: L10n.hudLeftAnnouncement
        case .snapRight: L10n.hudRightAnnouncement
        case .minimize: L10n.hudMinimizeAnnouncement
        }
    }
}
