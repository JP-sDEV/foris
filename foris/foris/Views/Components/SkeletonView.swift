import SwiftUI

/// Skeleton loading view that provides animated placeholders for content
/// Supports various skeleton shapes and animations for different UI elements
struct SkeletonView: View {
    
    // MARK: - Properties
    
    /// The shape of the skeleton
    let shape: SkeletonShape
    
    /// Animation configuration
    let animation: SkeletonAnimation
    
    /// Whether the skeleton is currently animating
    @State private var isAnimating = false
    
    // MARK: - Initialization
    
    /// Initialize with shape and animation
    /// - Parameters:
    ///   - shape: The skeleton shape to display
    ///   - animation: Animation configuration
    init(shape: SkeletonShape = .rectangle, animation: SkeletonAnimation = .shimmer) {
        self.shape = shape
        self.animation = animation
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base skeleton shape
                baseShape
                    .fill(baseColor)
                
                // Animation overlay
                if animation == .shimmer {
                    shimmerOverlay(geometry: geometry)
                }
            }
        }
        .frame(height: shape.defaultHeight)
        .onAppear {
            startAnimation()
        }
        .accessibilityLabel("Loading content")
        .accessibilityAddTraits(.updatesFrequently)
    }
    
    // MARK: - Computed Properties
    
    private var baseShape: some Shape {
        switch shape {
        case .rectangle:
            return AnyShape(Rectangle())
        case .roundedRectangle(let radius):
            return AnyShape(RoundedRectangle(cornerRadius: radius))
        case .circle:
            return AnyShape(Circle())
        case .capsule:
            return AnyShape(Capsule())
        }
    }
    
    private var baseColor: Color {
        Color(UIColor.systemGray5)
    }
    
    private var shimmerColor: Color {
        Color(UIColor.systemGray4)
    }
    
    // MARK: - Animation Methods
    
    private func startAnimation() {
        switch animation {
        case .shimmer:
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        case .pulse:
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        case .none:
            break
        }
    }
    
    private func shimmerOverlay(geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        shimmerColor.opacity(0.6),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .rotationEffect(.degrees(30))
            .offset(x: isAnimating ? geometry.size.width * 1.5 : -geometry.size.width * 1.5)
            .mask(baseShape)
    }
}

// MARK: - Skeleton Shape Enum

extension SkeletonView {
    enum SkeletonShape {
        case rectangle
        case roundedRectangle(radius: CGFloat)
        case circle
        case capsule
        
        var defaultHeight: CGFloat {
            switch self {
            case .rectangle, .roundedRectangle:
                return 20
            case .circle:
                return 40
            case .capsule:
                return 30
            }
        }
    }
}

// MARK: - Skeleton Animation Enum

extension SkeletonView {
    enum SkeletonAnimation {
        case shimmer
        case pulse
        case none
    }
}

// MARK: - AnyShape Helper

private struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - Convenience Initializers

extension SkeletonView {
    /// Creates a text line skeleton
    static func textLine(width: CGFloat? = nil) -> some View {
        SkeletonView(shape: .roundedRectangle(radius: 4))
            .frame(width: width, height: 16)
    }
    
    /// Creates a title skeleton
    static func title() -> some View {
        SkeletonView(shape: .roundedRectangle(radius: 6))
            .frame(height: 24)
    }
    
    /// Creates a subtitle skeleton
    static func subtitle() -> some View {
        SkeletonView(shape: .roundedRectangle(radius: 4))
            .frame(height: 18)
    }
    
    /// Creates a button skeleton
    static func button() -> some View {
        SkeletonView(shape: .roundedRectangle(radius: 8))
            .frame(height: 44)
    }
    
    /// Creates an avatar skeleton
    static func avatar(size: CGFloat = 40) -> some View {
        SkeletonView(shape: .circle)
            .frame(width: size, height: size)
    }
    
    /// Creates an image skeleton
    static func image(width: CGFloat, height: CGFloat) -> some View {
        SkeletonView(shape: .roundedRectangle(radius: 8))
            .frame(width: width, height: height)
    }
    
    /// Creates a card skeleton
    static func card() -> some View {
        SkeletonView(shape: .roundedRectangle(radius: 12))
            .frame(height: 120)
    }
}

// MARK: - Skeleton Layouts

/// Pre-built skeleton layouts for common UI patterns
struct SkeletonLayouts {
    
    /// Post card skeleton layout
    static func postCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author info
            HStack(spacing: 12) {
                SkeletonView.avatar(size: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    SkeletonView.textLine(width: 120)
                    SkeletonView.textLine(width: 80)
                }
                
                Spacer()
            }
            
            // Post content
            VStack(alignment: .leading, spacing: 8) {
                SkeletonView.title()
                SkeletonView.textLine()
                SkeletonView.textLine(width: 200)
            }
            
            // Action buttons
            HStack(spacing: 20) {
                SkeletonView.textLine(width: 60)
                SkeletonView.textLine(width: 80)
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    /// User card skeleton layout
    static func userCard() -> some View {
        HStack(spacing: 12) {
            SkeletonView.avatar(size: 50)
            
            VStack(alignment: .leading, spacing: 6) {
                SkeletonView.textLine(width: 140)
                SkeletonView.textLine(width: 100)
            }
            
            Spacer()
            
            SkeletonView.button()
                .frame(width: 80)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    /// Challenge card skeleton layout
    static func challengeCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonView.title()
                Spacer()
                SkeletonView.textLine(width: 60)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                SkeletonView.textLine()
                SkeletonView.textLine(width: 180)
            }
            
            HStack {
                SkeletonView.textLine(width: 100)
                Spacer()
                SkeletonView.button()
                    .frame(width: 100)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    /// League card skeleton layout
    static func leagueCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonView.image(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonView.title()
                    SkeletonView.textLine(width: 120)
                }
                
                Spacer()
            }
            
            SkeletonView.textLine()
            SkeletonView.textLine(width: 160)
            
            HStack {
                SkeletonView.textLine(width: 80)
                Spacer()
                SkeletonView.button()
                    .frame(width: 90)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    /// Profile header skeleton layout
    static func profileHeader() -> some View {
        VStack(spacing: 16) {
            SkeletonView.avatar(size: 100)
            
            VStack(spacing: 8) {
                SkeletonView.title()
                    .frame(width: 150)
                SkeletonView.textLine(width: 200)
            }
            
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    SkeletonView.textLine(width: 40)
                    SkeletonView.textLine(width: 60)
                }
                
                VStack(spacing: 4) {
                    SkeletonView.textLine(width: 40)
                    SkeletonView.textLine(width: 70)
                }
                
                VStack(spacing: 4) {
                    SkeletonView.textLine(width: 40)
                    SkeletonView.textLine(width: 50)
                }
            }
            
            SkeletonView.button()
                .frame(width: 120)
        }
        .padding()
    }
}

// MARK: - View Modifiers

extension View {
    /// Adds skeleton loading state overlay
    func skeletonLoading(_ isLoading: Bool, skeleton: @escaping () -> some View) -> some View {
        ZStack {
            if isLoading {
                skeleton()
            } else {
                self
            }
        }
    }
    
    /// Adds skeleton loading with fade transition
    func skeletonLoadingWithTransition<Skeleton: View>(
        _ isLoading: Bool,
        @ViewBuilder skeleton: @escaping () -> Skeleton
    ) -> some View {
        ZStack {
            self
                .opacity(isLoading ? 0 : 1)
            
            if isLoading {
                skeleton()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

// MARK: - Preview Provider

#Preview("Basic Skeletons") {
    VStack(spacing: 20) {
        SkeletonView.textLine()
        SkeletonView.title()
        SkeletonView.avatar()
        SkeletonView.button()
        SkeletonView.card()
    }
    .padding()
}

#Preview("Skeleton Layouts") {
    ScrollView {
        VStack(spacing: 20) {
            SkeletonLayouts.postCard()
            SkeletonLayouts.userCard()
            SkeletonLayouts.challengeCard()
            SkeletonLayouts.leagueCard()
        }
        .padding()
    }
}

#Preview("Animation Types") {
    VStack(spacing: 20) {
        Text("Shimmer Animation")
            .font(.headline)
        SkeletonView(shape: .roundedRectangle(radius: 8), animation: .shimmer)
            .frame(height: 40)
        
        Text("Pulse Animation")
            .font(.headline)
        SkeletonView(shape: .roundedRectangle(radius: 8), animation: .pulse)
            .frame(height: 40)
        
        Text("No Animation")
            .font(.headline)
        SkeletonView(shape: .roundedRectangle(radius: 8), animation: .none)
            .frame(height: 40)
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 20) {
        SkeletonLayouts.postCard()
        SkeletonLayouts.userCard()
    }
    .padding()
    .preferredColorScheme(.dark)
}