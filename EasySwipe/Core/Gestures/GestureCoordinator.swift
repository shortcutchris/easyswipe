import Foundation

@MainActor
final class GestureCoordinator {
    private enum SessionState {
        case idle
        case blocked
        case tracking(AXWindowTarget)
    }

    private let resolver: any WindowResolving
    private let actionService: any WindowActionPerforming
    private let hudPresenter: any HUDPresenting
    private let configuration: GestureConfiguration

    private var recognizer: SwipeGestureRecognizer
    private var state: SessionState = .idle
    private var fallbackEndTimer: Timer?

    init(
        resolver: any WindowResolving,
        actionService: any WindowActionPerforming,
        hudPresenter: any HUDPresenting,
        configuration: GestureConfiguration = .default
    ) {
        self.resolver = resolver
        self.actionService = actionService
        self.hudPresenter = hudPresenter
        self.configuration = configuration
        recognizer = SwipeGestureRecognizer(configuration: configuration)
    }

    func handle(_ sample: ScrollSample) {
        guard sample.isPrecise else {
            if sample.phase == .began { cancel() }
            return
        }

        if sample.isMomentum {
            // Momentum is not a physical finger release and must never commit
            // a gesture. A phased sequence commits on `.ended`; an unphased
            // sequence commits only through the quiet-period fallback timer.
            if recognizer.isTracking { cancel() }
            return
        }

        switch sample.phase {
        case .mayBegin:
            resetForNewSequence()
        case .began:
            resetForNewSequence()
            beginIfPossible(at: sample.location)
            update(with: sample)
        case .changed:
            if case .idle = state {
                beginIfPossible(at: sample.location)
            }
            update(with: sample)
        case .ended:
            if case .idle = state {
                beginIfPossible(at: sample.location)
            }
            update(with: sample)
            finish()
        case .cancelled:
            cancel()
        case .unspecified:
            if case .idle = state {
                beginIfPossible(at: sample.location)
            }
            update(with: sample)
            scheduleFallbackEnd()
        }
    }

    func cancel() {
        fallbackEndTimer?.invalidate()
        fallbackEndTimer = nil
        recognizer.cancel()
        state = .idle
    }

    private func resetForNewSequence() {
        cancel()
    }

    private func beginIfPossible(at location: CGPoint) {
        guard case .idle = state else { return }
        guard let target = resolver.resolveTarget(at: location) else {
            state = .blocked
            return
        }

        recognizer.begin()
        state = .tracking(target)
    }

    private func update(with sample: ScrollSample) {
        guard case .tracking = state else { return }
        recognizer.update(
            deltaX: sample.physicalDeltaX,
            deltaY: sample.physicalDeltaY
        )
    }

    private func finish() {
        fallbackEndTimer?.invalidate()
        fallbackEndTimer = nil

        guard case .tracking(let target) = state else {
            state = .idle
            recognizer.cancel()
            return
        }

        let action = recognizer.finish()
        state = .idle

        guard let action,
            let result = actionService.perform(action, on: target)
        else {
            return
        }

        hudPresenter.show(action: result.action, over: result.hudFrame)
    }

    private func scheduleFallbackEnd() {
        fallbackEndTimer?.invalidate()
        fallbackEndTimer = Timer.scheduledTimer(
            withTimeInterval: configuration.fallbackEndDelay,
            repeats: false
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.finish()
            }
        }
    }
}
