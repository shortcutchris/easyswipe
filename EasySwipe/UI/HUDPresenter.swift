import AppKit
import Foundation

@MainActor
protocol HUDPresenting {
    func showPreview(action: WindowGestureAction, near pointerLocation: CGPoint)
    func confirm(action: WindowGestureAction, near pointerLocation: CGPoint)
    func dismiss()
}

enum HUDPlacement {
    static func origin(
        near pointerLocation: CGPoint,
        panelSize: CGSize,
        visibleFrame: CGRect,
        gap: CGFloat = 8
    ) -> CGPoint {
        var x = pointerLocation.x + gap
        if x + panelSize.width > visibleFrame.maxX {
            x = pointerLocation.x - gap - panelSize.width
        }

        var y = pointerLocation.y - gap - panelSize.height
        if y < visibleFrame.minY {
            y = pointerLocation.y + gap
        }

        let maximumX = max(visibleFrame.minX, visibleFrame.maxX - panelSize.width)
        let maximumY = max(visibleFrame.minY, visibleFrame.maxY - panelSize.height)
        return CGPoint(
            x: min(max(x, visibleFrame.minX), maximumX),
            y: min(max(y, visibleFrame.minY), maximumY)
        )
    }
}

@MainActor
final class HUDPresenter: HUDPresenting {
    private let panel: NSPanel
    private let visualEffectView: NSVisualEffectView
    private let imageView: NSImageView
    private var hideWorkItem: DispatchWorkItem?
    private var presentationGeneration = 0

    init() {
        panel = NSPanel(
            contentRect: CGRect(x: 0, y: 0, width: 36, height: 36),
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
        visualEffectView.layer?.cornerRadius = 10
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
            imageView.widthAnchor.constraint(equalToConstant: 16),
            imageView.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    func showPreview(action: WindowGestureAction, near pointerLocation: CGPoint) {
        _ = preparePresentation()
        present(action: action, near: pointerLocation)
    }

    func confirm(action: WindowGestureAction, near pointerLocation: CGPoint) {
        let generation = preparePresentation()
        present(action: action, near: pointerLocation)

        let workItem = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                self?.hide(generation: generation)
            }
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38, execute: workItem)
    }

    func dismiss() {
        presentationGeneration += 1
        hideWorkItem?.cancel()
        hideWorkItem = nil
        panel.alphaValue = 0
        panel.orderOut(nil)
    }

    @discardableResult
    private func preparePresentation() -> Int {
        presentationGeneration += 1
        hideWorkItem?.cancel()
        hideWorkItem = nil
        return presentationGeneration
    }

    private func present(action: WindowGestureAction, near pointerLocation: CGPoint) {
        let wasVisible = panel.isVisible

        imageView.image = image(for: action)
        updateAccessibilityAppearance()

        let panelSize = panel.frame.size
        let visibleFrame =
            NSScreen.screens.first(where: { $0.frame.contains(pointerLocation) })?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? CGRect(origin: pointerLocation, size: panelSize)
        let origin = HUDPlacement.origin(
            near: pointerLocation,
            panelSize: panelSize,
            visibleFrame: visibleFrame
        )
        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()

        let shouldReduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if shouldReduceMotion || wasVisible {
            panel.alphaValue = 1
        } else {
            panel.alphaValue = 0
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.06
                panel.animator().alphaValue = 1
            }
        }
    }

    private func hide(generation: Int) {
        guard generation == presentationGeneration else { return }

        let duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.14
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            panel.animator().alphaValue = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            MainActor.assumeIsolated {
                guard self?.presentationGeneration == generation else { return }
                self?.panel.orderOut(nil)
                self?.hideWorkItem = nil
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
        case .maximize:
            preferredName = "arrow.up.left.and.arrow.down.right"
            fallbackName = "rectangle"
        }

        return NSImage(systemSymbolName: preferredName, accessibilityDescription: announcement(for: action))
            ?? NSImage(systemSymbolName: fallbackName, accessibilityDescription: announcement(for: action))
    }

    private func announcement(for action: WindowGestureAction) -> String {
        switch action {
        case .snapLeft: L10n.hudLeftAnnouncement
        case .snapRight: L10n.hudRightAnnouncement
        case .minimize: L10n.hudMinimizeAnnouncement
        case .maximize: L10n.hudMaximizeAnnouncement
        }
    }
}
