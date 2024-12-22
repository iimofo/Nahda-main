import SwiftUI

enum ExpandDirection {
    case bottom, left, right, top
    
    var offsets: (CGFloat, CGFloat) {
        switch self {
        case .bottom: return (0, 80)
        case .left: return (-80, 0)
        case .top: return (0, -80)
        case .right: return (80, 0)
        }
    }
    
    var containerOffset: (CGFloat, CGFloat) {
        switch self {
        case .bottom: return (0, 20)
        case .left: return (-20, 0)
        case .top: return (0, -20)
        case .right: return (20, 0)
        }
    }
}

struct ExpandingView: View {
    @Binding var expand: Bool
    var direction: ExpandDirection
    var symbolName: String
    var action: () -> Void
    
    var body: some View {
        ZStack {
            ZStack {
                Image(systemName: symbolName)
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                    .padding()
                    .opacity(expand ? 0.85 : 0)
                    .scaleEffect(expand ? 1: 0)
                    .rotationEffect(expand ? .degrees(-43) : .degrees(0))
                    .animation(Animation.easeOut(duration: 0.15), value: expand)
            }
            .frame(width: 82, height: 82)
            .background(Color.white)
            .cornerRadius(expand ? 41 : 8)
            .scaleEffect(expand ? 1 : 0.5)
            .offset(x: expand ? direction.offsets.0 : 0, y: expand ? direction.offsets.1 : 0)
            .rotationEffect(expand ? .degrees(43) : .degrees(0))
            .animation(Animation.easeOut(duration: 0.25).delay(0.05), value: expand)
            .onTapGesture {
                action()
            }
        }
        .offset(x: direction.containerOffset.0, y: direction.containerOffset.1)
    }
} 