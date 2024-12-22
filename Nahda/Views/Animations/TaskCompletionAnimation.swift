import SwiftUI

struct TaskCompletionAnimation: View {
    @Binding var isShowing: Bool
    let onCompletion: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    @State private var particlesScale: CGFloat = 0.1
    @State private var particlesOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .opacity(opacity)
            
            // Success circle with checkmark
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 100, height: 100)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // Checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .rotationEffect(.degrees(rotation))
                
                // Particle effects
                ForEach(0..<12) { index in
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .offset(x: 60)
                        .rotationEffect(.degrees(Double(index) * 30))
                        .scaleEffect(particlesScale)
                        .opacity(particlesOpacity)
                }
                
                // Success text
                Text("Task Completed!")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .offset(y: 80)
                    .opacity(opacity)
            }
        }
        .onChange(of: isShowing) { show in
            if show {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    scale = 1
                    opacity = 1
                }
                
                withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                    rotation = 360
                }
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    particlesScale = 1
                    particlesOpacity = 1
                }
                
                // Hide animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        scale = 0.5
                        opacity = 0
                        particlesScale = 0.1
                        particlesOpacity = 0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShowing = false
                        onCompletion()
                    }
                }
            }
        }
    }
} 