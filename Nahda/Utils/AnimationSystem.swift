import SwiftUI

enum AppAnimation {
    static let spring = Animation.spring(response: 0.6, dampingFraction: 0.7)
    static let easeOut = Animation.easeOut(duration: 0.3)
    static let bouncy = Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 10)
    
    struct Durations {
        static let fast = 0.3
        static let normal = 0.5
        static let slow = 0.8
    }
    
    struct Delays {
        static let staggered: (Int) -> Double = { index in
            Double(index) * 0.1
        }
    }
}

struct AnimatedVisibility: ViewModifier {
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
    }
}

struct ShakeEffect: GeometryEffect {
    let amount: CGFloat
    let shakesPerUnit: CGFloat
    var animatableData: CGFloat
    
    init(amount: CGFloat = 10, shakesPerUnit: CGFloat = 3, animatableData: CGFloat) {
        self.amount = amount
        self.shakesPerUnit = shakesPerUnit
        self.animatableData = animatableData
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * shakesPerUnit),
            y: 0))
    }
}

extension View {
    func animatedVisibility(isVisible: Bool) -> some View {
        modifier(AnimatedVisibility(isVisible: isVisible))
    }
    
    func shake(amount: CGFloat = 10, shakesPerUnit: CGFloat = 3, animatableData: CGFloat) -> some View {
        modifier(ShakeEffect(amount: amount, shakesPerUnit: shakesPerUnit, animatableData: animatableData))
    }
} 
