#if os(iOS)
import UIKit

/// Helper animation function to keep animations consistent, now with CADisplayLink support.
enum PanModalAnimator {
    /// Default transition duration
    enum Constants {
        static let defaultTransitionDuration: TimeInterval = 0.5
    }

    /// A proxy to relay displayLink callbacks
    private class DisplayLinkProxy {
        weak var animator: UIViewPropertyAnimator?
        let onUpdate: (CGFloat) -> Void

        init(animator: UIViewPropertyAnimator, onUpdate: @escaping (CGFloat) -> Void) {
            self.animator = animator
            self.onUpdate = onUpdate
        }

        @objc func update() {
            guard let animator = animator else { return }
            onUpdate(animator.fractionComplete)
        }
    }

    /// Animate with spring timing and report progress via CADisplayLink
    static func animate(
        _ animations: @escaping PanModalPresentable.AnimationBlockType,
        config: PanModalPresentable?,
        onUpdate: ((CGFloat) -> Void)? = nil,
        _ completion: PanModalPresentable.AnimationCompletionType? = nil
    ) {
        let transitionDuration = config?.transitionDuration ?? Constants.defaultTransitionDuration
        let springDamping = config?.springDamping ?? 1.0

        // 1. Build spring timing parameters
        let springTiming = UISpringTimingParameters(
            dampingRatio: springDamping,
            initialVelocity: .zero
        )

        // 2. Create the property animator
        let animator = UIViewPropertyAnimator(
            duration: transitionDuration,
            timingParameters: springTiming
        )
        animator.addAnimations {
            animations()
        }

        if let onUpdate {
            // 3. Set up CADisplayLink to observe fractionComplete
            let proxy = DisplayLinkProxy(animator: animator, onUpdate: onUpdate)
            let displayLink = CADisplayLink(target: proxy,
                                            selector: #selector(DisplayLinkProxy.update))
            displayLink.add(to: .main, forMode: .common)

            // 4. Invalidate displayLink when animation ends
            animator.addCompletion { _ in
                displayLink.invalidate()
            }
        }

        // 5. Also call the original completion
        animator.addCompletion { position in
            let finishedNormally = (position == .end)
            completion?(finishedNormally)
        }

        // 6. Start the animation
        animator.startAnimation()
    }
}
#endif
