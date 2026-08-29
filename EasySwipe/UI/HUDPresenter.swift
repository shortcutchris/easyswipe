import AppKit
import Foundation
import QuartzCore

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
    private enum PresentationPhase {
        case preview
        case confirmation
    }

    private let panel: NSPanel
    private let visualEffectView: NSVisualEffectView
    private let imageView: NSImageView
    private let animationsEnabled: @MainActor () -> Bool
    private var hideWorkItem: DispatchWorkItem?
    private var accentWorkItem: DispatchWorkItem?
    private var presentationGeneration = 0

    init(animationsEnabled: @escaping @MainActor () -> Bool = { true }) {
        self.animationsEnabled = animationsEnabled
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
        imageView.wantsLayer = true
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
        let generation = preparePresentation()
        present(
            action: action,
            near: pointerLocation,
            phase: .preview,
            generation: generation
        )
    }

    func confirm(action: WindowGestureAction, near pointerLocation: CGPoint) {
        let generation = preparePresentation()
        present(
            action: action,
            near: pointerLocation,
            phase: .confirmation,
            generation: generation
        )

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
        accentWorkItem?.cancel()
        accentWorkItem = nil
        resetVisualState()
        panel.alphaValue = 0
        panel.orderOut(nil)
    }

    @discardableResult
    private func preparePresentation() -> Int {
        presentationGeneration += 1
        hideWorkItem?.cancel()
        hideWorkItem = nil
        accentWorkItem?.cancel()
        accentWorkItem = nil
        resetVisualState()
        return presentationGeneration
    }

    private func present(
        action: WindowGestureAction,
        near pointerLocation: CGPoint,
        phase: PresentationPhase,
        generation: Int
    ) {
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

        guard shouldAnimate else {
            panel.alphaValue = 1
            return
        }

        if wasVisible {
            panel.alphaValue = 1
        } else {
            animateAppearance()
        }

        switch phase {
        case .preview:
            animatePreview(for: action)
        case .confirmation:
            animateConfirmation(for: action, generation: generation)
        }
    }

    private var shouldAnimate: Bool {
        SwindooMotion.shouldAnimate(
            preferenceEnabled: animationsEnabled(),
            reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        )
    }

    private func animateAppearance() {
        if let layer = visualEffectView.layer {
            let scale = CABasicAnimation(keyPath: "transform")
            scale.fromValue = NSValue(
                caTransform3D: CATransform3DMakeScale(
                    SwindooMotion.appearanceScale,
                    SwindooMotion.appearanceScale,
                    1
                )
            )
            scale.toValue = NSValue(caTransform3D: CATransform3DIdentity)
            scale.duration = SwindooMotion.appearanceDuration
            scale.timingFunction = CAMediaTimingFunction(name: .easeOut)
            layer.add(scale, forKey: "swindoo.hud.appearance")
        }

        panel.alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = SwindooMotion.appearanceDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    private func animatePreview(for action: WindowGestureAction) {
        guard let layer = imageView.layer else { return }

        let transform = CABasicAnimation(keyPath: "transform")
        transform.fromValue = NSValue(
            caTransform3D: layerTransform(
                for: SwindooMotion.previewStartTransform(for: action)
            )
        )
        transform.toValue = NSValue(caTransform3D: CATransform3DIdentity)
        transform.duration = SwindooMotion.appearanceDuration
        transform.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(transform, forKey: "swindoo.hud.preview.transform")

        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 0.55
        opacity.toValue = 1
        opacity.duration = SwindooMotion.appearanceDuration
        opacity.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(opacity, forKey: "swindoo.hud.preview.opacity")
    }

    private func animateConfirmation(for action: WindowGestureAction, generation: Int) {
        guard let layer = imageView.layer else { return }

        let motion = CAKeyframeAnimation(keyPath: "transform")
        motion.values = SwindooMotion.confirmationTransforms(for: action).map {
            NSValue(caTransform3D: layerTransform(for: $0))
        }
        motion.keyTimes = [0, 0.58, 1]
        motion.duration = SwindooMotion.feedbackDuration
        motion.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
        ]
        layer.add(motion, forKey: "swindoo.hud.confirmation")

        imageView.contentTintColor = .controlAccentColor
        let workItem = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard self?.presentationGeneration == generation else { return }
                self?.imageView.contentTintColor = .labelColor
                self?.accentWorkItem = nil
            }
        }
        accentWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + SwindooMotion.feedbackDuration,
            execute: workItem
        )
    }

    private func layerTransform(for transform: HUDIconTransform) -> CATransform3D {
        var result = CATransform3DMakeTranslation(
            transform.translationX,
            transform.translationY,
            0
        )
        result = CATransform3DScale(result, transform.scaleX, transform.scaleY, 1)
        return result
    }

    private func resetVisualState() {
        visualEffectView.layer?.removeAllAnimations()
        visualEffectView.layer?.setAffineTransform(.identity)
        imageView.layer?.removeAllAnimations()
        imageView.layer?.setAffineTransform(.identity)
        imageView.alphaValue = 1
        imageView.contentTintColor = .labelColor
    }

    private func hide(generation: Int) {
        guard generation == presentationGeneration else { return }

        let duration = shouldAnimate ? SwindooMotion.dismissalDuration : 0
        if duration == 0 {
            panel.alphaValue = 0
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = duration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().alphaValue = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            MainActor.assumeIsolated {
                guard self?.presentationGeneration == generation else { return }
                self?.panel.orderOut(nil)
                self?.hideWorkItem = nil
                self?.accentWorkItem?.cancel()
                self?.accentWorkItem = nil
                self?.resetVisualState()
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
            preferredName = "rectangle.compress.vertical"
            fallbackName = "minus"
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
