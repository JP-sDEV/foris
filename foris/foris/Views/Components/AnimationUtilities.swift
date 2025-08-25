import SwiftUI

/// Collection of reusable animations and transitions for the app
/// Provides consistent animation patterns across different UI components
struct AnimationUtilities {
    
    // MARK: - Standard Animations
    
    /// Smooth ease-in-out animation for general UI transitions
    static let smooth = Animation.easeInOut(duration: 0.3)
    
    /// Quick animation for immediate feedback
    static let quick = Animation.easeInOut(duration: 0.15)
    
    /// Slow animation for dramatic effects
    static let slow = Animation.easeInOut(duration: 0.6)
    
    /// Spring animation for bouncy effects
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
    
    /// Gentle spring animation
    static let gentleSpring = Animation.spring(response: 0.4, dampingFraction: 0.9, blendDuration: 0)
    
    /// Bouncy spring animation
    static let bouncySpring = Animation.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)
    
    // MARK: - Specialized Animations
    
    /// Animation for button press feedback
    static let buttonPress = Animation.easeInOut(duration: 0.1)
    
    /// Animation for modal presentation
    static let modalPresentation = Animation.spring(response: 0.5, dampingFraction: 0.8)
    
    /// Animation for tab switching
    static let tabSwitch = Animation.easeInOut(duration: 0.25)
    
    /// Animation for loading states
    static let loading = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
    
    /// Animation for pulse effects
    static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    
    /// Animation for shake effects
    static let shake = Animation.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)
    
    // MARK: - Transition Animations
    
    /// Slide transition from leading edge
    static let slideFromLeading = AnyTransition.asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity),
        removal: .move(edge: .trailing).combined(with: .opacity)
    )
    
    /// Slide transition from trailing edge
    static let slideFromTrailing = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    
    /// Scale and fade transition
    static let scaleAndFade = AnyTransition.scale.combined(with: .opacity)
    
    /// Push transition (like navigation)
    static let push = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    )
    
    /// Modal transition (scale up from center)
    static let modal = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
    
    /// Flip transition
    static let flip = AnyTransition.asymmetric(
        insertion: .modifier(
            active: FlipModifier(angle: -90),
            identity: FlipModifier(angle: 0)
        ),
        removal: .modifier(
            active: FlipModifier(angle: 90),
            identity: FlipModifier(angle: 0)
        )
    )
}

// MARK: - Custom View Modifiers

/// Modifier for flip animations
private struct FlipModifier: ViewModifier {
    let angle: Double
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(angle),
                axis: (x: 0, y: 1, z: 0)
            )
    }
}

/// Modifier for shake animations
struct ShakeModifier: ViewModifier {
    @State private var shakeOffset: CGFloat = 0
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onChange(of: trigger) { _ in
                withAnimation(AnimationUtilities.shake) {
                    shakeOffset = 10
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shakeOffset = 0
                }
            }
    }
}

/// Modifier for pulse animations
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                if isActive {
                    withAnimation(AnimationUtilities.pulse) {
                        isPulsing = true
                    }
                }
            }
            .onChange(of: isActive) { active in
                if active {
                    withAnimation(AnimationUtilities.pulse) {
                        isPulsing = true
                    }
                } else {
                    withAnimation(AnimationUtilities.smooth) {
                        isPulsing = false
                    }
                }
            }
    }
}

/// Modifier for bounce animations
struct BounceModifier: ViewModifier {
    @State private var isBouncing = false
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isBouncing ? 1.2 : 1.0)
            .onChange(of: trigger) { _ in
                withAnimation(AnimationUtilities.bouncySpring) {
                    isBouncing = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(AnimationUtilities.gentleSpring) {
                        isBouncing = false
                    }
                }
            }
    }
}

/// Modifier for slide-in animations
struct SlideInModifier: ViewModifier {
    @State private var offset: CGFloat = 100
    @State private var opacity: Double = 0
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(AnimationUtilities.smooth.delay(delay)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

/// Modifier for fade-in animations
struct FadeInModifier: ViewModifier {
    @State private var opacity: Double = 0
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(AnimationUtilities.smooth.delay(delay)) {
                    opacity = 1
                }
            }
    }
}

/// Modifier for scale-in animations
struct ScaleInModifier: ViewModifier {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(AnimationUtilities.spring.delay(delay)) {
                    scale = 1.0
                    opacity = 1
                }
            }
    }
}

/// Modifier for rotation animations
struct RotationModifier: ViewModifier {
    @State private var rotation: Double = 0
    let isActive: Bool
    let speed: Double
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                if isActive {
                    startRotation()
                }
            }
            .onChange(of: isActive) { active in
                if active {
                    startRotation()
                } else {
                    stopRotation()
                }
            }
    }
    
    private func startRotation() {
        withAnimation(.linear(duration: speed).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
    
    private func stopRotation() {
        withAnimation(AnimationUtilities.smooth) {
            rotation = 0
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Adds shake animation triggered by a boolean
    func shake(trigger: Bool) -> some View {
        self.modifier(ShakeModifier(trigger: trigger))
    }
    
    /// Adds pulse animation
    func pulse(isActive: Bool = true) -> some View {
        self.modifier(PulseModifier(isActive: isActive))
    }
    
    /// Adds bounce animation triggered by a boolean
    func bounce(trigger: Bool) -> some View {
        self.modifier(BounceModifier(trigger: trigger))
    }
    
    /// Adds slide-in animation from bottom
    func slideIn(delay: Double = 0) -> some View {
        self.modifier(SlideInModifier(delay: delay))
    }
    
    /// Adds fade-in animation
    func fadeIn(delay: Double = 0) -> some View {
        self.modifier(FadeInModifier(delay: delay))
    }
    
    /// Adds scale-in animation
    func scaleIn(delay: Double = 0) -> some View {
        self.modifier(ScaleInModifier(delay: delay))
    }
    
    /// Adds rotation animation
    func rotate(isActive: Bool = true, speed: Double = 1.0) -> some View {
        self.modifier(RotationModifier(isActive: isActive, speed: speed))
    }
    
    /// Adds button press animation
    func buttonPressAnimation() -> some View {
        self.scaleEffect(1.0)
            .animation(AnimationUtilities.buttonPress, value: UUID())
    }
    
    /// Adds smooth transition animation
    func smoothTransition<V: Equatable>(_ value: V) -> some View {
        self.animation(AnimationUtilities.smooth, value: value)
    }
    
    /// Adds spring transition animation
    func springTransition<V: Equatable>(_ value: V) -> some View {
        self.animation(AnimationUtilities.spring, value: value)
    }
    
    /// Adds conditional animation
    func conditionalAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V,
        condition: Bool
    ) -> some View {
        self.animation(condition ? animation : nil, value: value)
    }
}

// MARK: - Animated Containers

/// Container that animates its children with staggered delays
struct StaggeredAnimationContainer<Content: View>: View {
    let content: Content
    let staggerDelay: Double
    
    init(staggerDelay: Double = 0.1, @ViewBuilder content: () -> Content) {
        self.staggerDelay = staggerDelay
        self.content = content()
    }
    
    var body: some View {
        content
    }
}

/// Container for animated list items
struct AnimatedListContainer<Content: View>: View {
    let content: Content
    let itemCount: Int
    
    init(itemCount: Int, @ViewBuilder content: () -> Content) {
        self.itemCount = itemCount
        self.content = content()
    }
    
    var body: some View {
        LazyVStack(spacing: 0) {
            content
        }
    }
}

// MARK: - Animated Transitions for Navigation

struct NavigationTransition {
    /// Slide transition for navigation push/pop
    static let slide = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    
    /// Modal presentation transition
    static let modal = AnyTransition.move(edge: .bottom).combined(with: .opacity)
    
    /// Tab switching transition
    static let tab = AnyTransition.opacity.combined(with: .scale(scale: 0.95))
}

// MARK: - Loading Animation Components

struct LoadingDots: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                    .opacity(animationPhase == index ? 1.0 : 0.5)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            withAnimation(AnimationUtilities.smooth) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

struct LoadingWave: View {
    @State private var animationOffset: CGFloat = -100
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.accentColor.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 100)
                .offset(x: animationOffset)
                .onAppear {
                    withAnimation(AnimationUtilities.loading) {
                        animationOffset = geometry.size.width + 100
                    }
                }
        }
        .clipped()
    }
}

// MARK: - Preview Provider

#Preview("Animation Examples") {
    ScrollView {
        VStack(spacing: 30) {
            Text("Animation Examples")
                .font(.title)
                .fontWeight(.bold)
                .slideIn()
            
            // Shake animation
            Button("Shake Me") {
                // Trigger handled by state
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
            .shake(trigger: false)
            
            // Pulse animation
            Circle()
                .fill(Color.blue)
                .frame(width: 50, height: 50)
                .pulse()
            
            // Bounce animation
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green)
                .frame(width: 100, height: 50)
                .bounce(trigger: false)
            
            // Rotation animation
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .rotate()
            
            // Loading animations
            VStack(spacing: 20) {
                LoadingDots()
                
                LoadingWave()
                    .frame(height: 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(2)
            }
            
            // Staggered animations
            VStack(spacing: 10) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple)
                        .frame(height: 40)
                        .slideIn(delay: Double(index) * 0.1)
                }
            }
        }
        .padding()
    }
}

#Preview("Transition Examples") {
    struct TransitionDemo: View {
        @State private var showContent = false
        
        var body: some View {
            VStack(spacing: 20) {
                Button("Toggle Content") {
                    withAnimation(AnimationUtilities.spring) {
                        showContent.toggle()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if showContent {
                    VStack(spacing: 16) {
                        Text("Slide Transition")
                            .transition(AnimationUtilities.slideFromLeading)
                        
                        Text("Scale and Fade")
                            .transition(AnimationUtilities.scaleAndFade)
                        
                        Text("Modal Transition")
                            .transition(AnimationUtilities.modal)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
    
    return TransitionDemo()
}