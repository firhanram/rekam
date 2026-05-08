import CoreMedia
import SwiftUI

struct TrimSliderView: View {
    let duration: CMTime
    @Binding var startSeconds: Double
    @Binding var endSeconds: Double
    let currentSeconds: Double
    let onScrub: (Double) -> Void

    private let trackHeight: CGFloat = 28
    private let handleWidth: CGFloat = 14

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let total = max(durationSeconds, 0.001)
            let startX = CGFloat(startSeconds / total) * width
            let endX = CGFloat(endSeconds / total) * width
            let playheadX = CGFloat(currentSeconds.clamped(0, total) / total) * width

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: AppSpacing.radiusBadge)
                    .fill(AppColors.surfacePlus)
                    .frame(height: trackHeight)

                // Selected range
                RoundedRectangle(cornerRadius: AppSpacing.radiusBadge)
                    .fill(AppColors.brandTint100)
                    .frame(width: max(0, endX - startX), height: trackHeight)
                    .offset(x: startX)

                // Playhead
                Rectangle()
                    .fill(AppColors.brand)
                    .frame(width: 2, height: trackHeight + 8)
                    .offset(x: playheadX - 1, y: -4)
                    .allowsHitTesting(false)

                // Start handle
                handle()
                    .offset(x: startX - handleWidth / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let t = Double(value.location.x / width) * total
                                let clamped = t.clamped(0, endSeconds - 0.1)
                                startSeconds = clamped
                                onScrub(clamped)
                            }
                    )

                // End handle
                handle()
                    .offset(x: endX - handleWidth / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let t = Double(value.location.x / width) * total
                                let clamped = t.clamped(startSeconds + 0.1, total)
                                endSeconds = clamped
                                onScrub(clamped)
                            }
                    )
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Tap-to-seek inside the selected range
                        let t = Double(value.location.x / width) * total
                        if t >= startSeconds, t <= endSeconds {
                            onScrub(t)
                        }
                    }
            )
        }
        .frame(height: trackHeight + 8)
    }

    private func handle() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppSpacing.radiusInput)
                .fill(AppColors.brand)
                .frame(width: handleWidth, height: trackHeight + 8)
            Image(systemName: "scissors")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
                .rotationEffect(.degrees(90))
        }
    }

    private var durationSeconds: Double {
        let v = CMTimeGetSeconds(duration)
        return v.isFinite ? max(v, 0) : 0
    }
}

private extension Double {
    func clamped(_ low: Double, _ high: Double) -> Double {
        Swift.min(Swift.max(self, low), high)
    }
}
