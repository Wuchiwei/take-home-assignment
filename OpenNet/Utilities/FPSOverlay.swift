#if DEBUG
import SwiftUI
import QuartzCore

struct FPSOverlay: View {
    @State private var fps: Int?
    @State private var fpsTracker = FPSTracker()

    var body: some View {
        Group {
            if let fps {
                Text("\(fps) FPS")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(fpsColor.opacity(0.8))
                    )
            }
        }
        .onAppear { fpsTracker.start { fps = $0 } }
        .onDisappear { fpsTracker.stop() }
    }

    private var fpsColor: Color {
        guard let fps else { return .red }
        switch fps {
        case 55...: return .green
        case 45...: return .yellow
        default:    return .red
        }
    }
}

@MainActor
private final class FPSTracker {
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var onUpdate: ((Int) -> Void)?

    func start(onUpdate: @escaping (Int) -> Void) {
        self.onUpdate = onUpdate
        let displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        frameCount += 1
        let elapsed = link.timestamp - lastTimestamp
        if elapsed >= 1.0 {
            onUpdate?(frameCount)
            frameCount = 0
            lastTimestamp = link.timestamp
        }
    }
}
#endif
