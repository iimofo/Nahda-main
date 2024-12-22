import SwiftUI

struct DragToApproveButton: View {
    let width: CGFloat = UIScreen.main.bounds.width - 60
    let height: CGFloat = 60
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var isCompleting = false
    let onApprove: () -> Void
    
    // Haptic feedback generator
    private let haptic = UIImpactFeedbackGenerator(style: .medium)
    
    // Updated progress value to only consider positive x movement
    private var progress: CGFloat {
        min(max(max(dragOffset.width, 0) / (width * 0.75), 0), 1)
    }
    
    var body: some View {
        ZStack {
            // Background track
            RoundedRectangle(cornerRadius: height/2)
                .fill(Color(.systemGray6))
                .overlay(
                    ZStack {
                        // Progress overlay with gradient - Fixed alignment
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.3),
                                            Color.green.opacity(0.2)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: height/2))
                                .frame(width: min(max(dragOffset.width, 40) + height/2, geometry.size.width))
                        }
                        
                        // Dynamic text with arrow indicators
                        HStack(spacing: 4) {
                            if !isCompleting {
                                ForEach(0..<3) { index in
                                    Image(systemName: "chevron.right")
                                        .opacity(0.6)
                                        .offset(x: isDragging ? 5 : 0)
                                        .animation(
                                            .easeInOut(duration: 0.3)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(index) * 0.1),
                                            value: isDragging
                                        )
                                }
                            }
                            
                            Text(isCompleting ? "Task Approved!" : "Slide to Approve")
                                .foregroundColor(isCompleting ? .green : .gray)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .padding(.leading, 70)
                        .opacity(progress < 0.95 ? 1 : 0)
                    }
                )
            
            // Draggable button with constrained movement
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            isCompleting ? .green : .green.opacity(0.9),
                            isCompleting ? .green.opacity(0.9) : .green
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: height - 8, height: height - 8)
                .overlay(
                    Image(systemName: isCompleting ? "checkmark" : "chevron.right")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(isDragging ? 0.7 : 1)
                        .rotationEffect(.degrees(isCompleting ? 0 : isDragging ? 90 : 0))
                        .scaleEffect(isCompleting ? 1.2 : 1)
                )
                .offset(x: -width/2 + height/2 + 4)
                .offset(x: min(max(dragOffset.width, 0), width - height)) // Constrain to positive movement only
                .shadow(
                    color: .green.opacity(isDragging ? 0.3 : 0.2),
                    radius: isDragging ? 8 : 4,
                    x: 0,
                    y: isDragging ? 4 : 2
                )
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if !isCompleting {
                                isDragging = true
                                // Only allow positive x movement
                                dragOffset = CGSize(
                                    width: max(gesture.translation.width, 0),
                                    height: 0
                                )
                                
                                // Enhanced haptic feedback
                                if gesture.translation.width.truncatingRemainder(dividingBy: 40) < 1 {
                                    haptic.impactOccurred(intensity: min(progress + 0.3, 1.0))
                                }
                            }
                        }
                        .onEnded { gesture in
                            isDragging = false
                            if dragOffset.width > width * 0.75 && !isCompleting {
                                completeApproval()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
                .scaleEffect(isDragging ? 1.1 : 1)
        }
        .frame(width: width, height: height)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .animation(.easeInOut(duration: 0.3), value: isCompleting)
    }
    
    private func completeApproval() {
        haptic.impactOccurred(intensity: 1.0)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset.width = width - height
            isCompleting = true
        }
        
        // Slight delay before calling onApprove
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onApprove()
        }
    }
}

// Preview
#Preview {
    DragToApproveButton {
        print("Approved!")
    }
    .padding()
} 
