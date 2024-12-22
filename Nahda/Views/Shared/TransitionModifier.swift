import SwiftUI

struct SlideTransition: ViewModifier {
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: isPresented ? 0 : UIScreen.main.bounds.width)
            .opacity(isPresented ? 1 : 0)
            .animation(AppAnimation.spring, value: isPresented)
    }
}

extension View {
    func slideTransition(isPresented: Bool) -> some View {
        modifier(SlideTransition(isPresented: isPresented))
    }
} 
