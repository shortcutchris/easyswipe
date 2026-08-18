import AppKit
import Foundation

@MainActor
final class GlobalScrollMonitor {
    private var monitor: Any?
    private let handler: @MainActor (ScrollSample) -> Void

    init(handler: @escaping @MainActor (ScrollSample) -> Void) {
        self.handler = handler
    }

    var isRunning: Bool {
        monitor != nil
    }

    func start() {
        guard monitor == nil else { return }

        monitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            let sample = ScrollSample(event: event)
            DispatchQueue.main.async {
                self?.handler(sample)
            }
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

}
