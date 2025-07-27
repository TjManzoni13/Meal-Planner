import SwiftUI

/// Splash screen view that displays animated food emojis when the app launches
struct SplashView: View {
    @State private var animate = false
    @State private var transitionDone = false
    
    // Food emojis that represent the meal planning theme
    let foodEmojis = ["🍕", "🍔", "🥗", "🍝", "🍜", "🥘", "🍖", "🍗", "🥩", "🥬", "🥕", "🍅", "🥑", "🥒", "🌽", "🥔", "🧀", "🥚", "🥛", "🍞", "🥨", "🥯", "🥐", "🥖", "🥞", "🧇", "🥓", "🍳", "🥪", "🌮", "🌯", "🥙", "🍟", "🍿", "🍩", "🍪", "🍰", "🧁", "🍦", "🍨", "🍧", "🍡", "🍭", "🍬", "🍫", "🍪", "🍩", "🍰", "🧁", "🍦", "🍨", "🍧"]
    
    var body: some View {
        ZStack {
            // Background using the app's theme color
            Color.appBackground.ignoresSafeArea()
            
            // Animated food emojis
            ForEach(0..<foodEmojis.count, id: \.self) { i in
                FoodEmojiView(
                    emoji: foodEmojis[i], 
                    index: i, 
                    animate: $animate
                )
            }
            
            // App logo/title overlay
            VStack(spacing: 20) {
                Text("🍽️")
                    .font(.system(size: 80))
                    .scaleEffect(animate ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 1.5).repeatCount(1, autoreverses: true), value: animate)
                
                Text("BuonApp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0).delay(0.5), value: animate)
                
                Text("The Meal Planner")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.black.opacity(0.9))
                    .opacity(animate ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0).delay(0.7), value: animate)
                
                Text("Plan - Shop - Enjoy")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.8))
                    .opacity(animate ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0).delay(0.9), value: animate)
            }
            
            // Transition to main app content
            if transitionDone {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Start the animation sequence
            animate = true
            
            // Transition to main app after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    transitionDone = true
                }
            }
        }
    }
}

/// Individual food emoji view with organized grid positioning and animations
struct FoodEmojiView: View {
    let emoji: String
    let index: Int
    @Binding var animate: Bool
    
    // Calculate organized grid position
    private var position: (x: CGFloat, y: CGFloat) {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Create a 8x7 grid (56 emojis total) for better spacing
        let columns = 8
        let rows = 7
        let column = index % columns
        let row = index / columns
        
        // Calculate spacing with more generous padding
        let horizontalSpacing = (screenWidth - 120) / CGFloat(columns - 1)
        let verticalSpacing = (screenHeight - 400) / CGFloat(rows - 1) // More space for title
        
        let x = 60 + CGFloat(column) * horizontalSpacing
        let y = 250 + CGFloat(row) * verticalSpacing
        
        return (x, y)
    }
    
    var body: some View {
        Text(emoji)
            .font(.system(size: 40))
            .position(x: position.x, y: position.y)
            .opacity(animate ? 1 : 0)
            .scaleEffect(animate ? 1 : 0.3)
            .rotationEffect(.degrees(animate ? Double.random(in: -90...90) : 0))
            .animation(
                .easeInOut(duration: 1.2)
                .delay(Double(index) * 0.03), 
                value: animate
            )
    }
}

#Preview {
    SplashView()
} 