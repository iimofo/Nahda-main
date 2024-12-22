import SwiftUI

struct IntroAnimationView: View {
    @State private var showN = false
    @State private var showFullText = false
    @State private var showFinalView = false
    @State private var isAnimating = false
    @State private var glowOpacity = 0.0
    @State private var shakeEffect = false
    @State private var explodeEffect = false
    @State private var letterOffsets: [CGSize] = Array(repeating: .zero, count: 5)
    @State private var letterRotations: [Double] = Array(repeating: 0, count: 5)
    
    // Rocket states
    @State private var showRocket = false
    @State private var rocketPosition = CGSize(width: 400, height: -400)
    @State private var rocketRotation: Double = 45
    @State private var showExplosionParticles = false
    
    // Brand colors
    let primaryColor = Color.blue
    let textColor = Color.white
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            if !showFinalView {
                ZStack {
                    // Explosion particles
                    if showExplosionParticles {
                        ExplosionParticlesView()
                    }
                    
                    GeometryReader { geometry in
                        let centerX = geometry.size.width / 2
                        let centerY = geometry.size.height / 2
                        
                        ZStack {
                            // The 'N'
                            Text("N")
                                .font(.system(size: 80, weight: .bold))
                                .foregroundColor(textColor)
                                .opacity(showN ? 1 : 0)
                                .offset(x: showN ? (showFullText ? -110 : 0) : 0)
                                .offset(explodeEffect ? letterOffsets[0] : .zero)
                                .rotationEffect(.degrees(explodeEffect ? letterRotations[0] : 0))
                                .shaking(shakeEffect)
                                .overlay(
                                    Text("N")
                                        .font(.system(size: 80, weight: .bold))
                                        .foregroundColor(primaryColor)
                                        .opacity(glowOpacity)
                                        .blur(radius: 20)
                                )
                            
                            // "AHDA" part
                            HStack(spacing: -2) {
                                ForEach(Array("AHDA").indices, id: \.self) { index in
                                    Text(String(Array("AHDA")[index]))
                                        .font(.system(size: 80, weight: .bold))
                                        .foregroundColor(textColor)
                                        .offset(explodeEffect ? letterOffsets[index + 1] : .zero)
                                        .rotationEffect(.degrees(explodeEffect ? letterRotations[index + 1] : 0))
                                }
                            }
                            .opacity(showFullText ? 1 : 0)
                            .offset(x: showFullText ? 25 : 200)
                            .modifier(ShakeModifier(isShaking: shakeEffect))
                            
                            // Rocket
                            if showRocket {
                                RocketView()
                                    .frame(width: 50, height: 50)
                                    .rotationEffect(.degrees(rocketRotation))
                                    .offset(rocketPosition)
                            }
                        }
                        .position(x: centerX, y: centerY)
                        .shadow(color: primaryColor.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                }
            } else {
                Circle()
                    .fill(primaryColor)
                    .scaleEffect(isAnimating ? 4 : 0)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(.easeInOut(duration: 0.5), value: isAnimating)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Show N first
        withAnimation(.easeOut(duration: 0.5)) {
            showN = true
        }
        
        // Animate glow
        withAnimation(.easeInOut(duration: 0.8).repeatCount(2)) {
            glowOpacity = 0.7
        }
        
        // After N appears, animate the full text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showFullText = true
            }
            
            // Launch rocket after text appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                launchRocket()
            }
        }
    }
    
    private func launchRocket() {
        showRocket = true
        
        // Animate rocket to target
        withAnimation(.easeIn(duration: 0.8)) {
            rocketPosition = .zero
            rocketRotation = 225
        }
        
        // Start explosion sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showRocket = false
            showExplosionParticles = true
            shakeEffect = true
            
            // Prepare explosion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                prepareExplosion()
                
                withAnimation(.easeOut(duration: 0.5)) {
                    explodeEffect = true
                }
                
                // Final transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showFinalView = true
                        isAnimating = true
                    }
                }
            }
        }
    }
    
    private func prepareExplosion() {
        for i in 0..<5 {
            let randomAngle = Double.random(in: -360...360)
            let randomOffset = CGSize(
                width: CGFloat.random(in: -300...300),
                height: CGFloat.random(in: -300...300)
            )
            letterOffsets[i] = randomOffset
            letterRotations[i] = randomAngle
        }
    }
}

struct RocketView: View {
    var body: some View {
        Image(systemName: "airplane")
            .resizable()
            .scaledToFit()
            .foregroundColor(.red)
            .overlay(
                Image(systemName: "flame.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.orange)
                    .offset(x: -20)
                    .rotationEffect(.degrees(180))
            )
    }
}

struct ExplosionParticlesView: View {
    let particleCount = 20
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<particleCount, id: \.self) { _ in
                ExplosionParticle()
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
            }
        }
    }
}

struct ExplosionParticle: View {
    @State private var offset = CGSize.zero
    @State private var rotation = 0.0
    @State private var scale: CGFloat = 1
    @State private var opacity = 1.0
    
    var body: some View {
        Circle()
            .fill(Color.orange)
            .frame(width: 8, height: 8)
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                let randomAngle = Double.random(in: 0...360)
                let randomDistance = CGFloat.random(in: 50...150)
                offset = CGSize(
                    width: cos(randomAngle) * randomDistance,
                    height: sin(randomAngle) * randomDistance
                )
                rotation = Double.random(in: 0...360)
                scale = 0
                
                withAnimation(.easeOut(duration: 0.5)) {
                    scale = 1
                    opacity = 0
                }
            }
    }
}

struct ShakeModifier: ViewModifier {
    let isShaking: Bool
    
    func body(content: Content) -> some View {
        content.shake(amount: 5, shakesPerUnit: 2, animatableData: isShaking ? 1 : 0)
    }
}

extension View {
    func shaking(_ isShaking: Bool) -> some View {
        modifier(ShakeModifier(isShaking: isShaking))
    }
}

// Preview
#Preview {
    IntroAnimationView()
} 
