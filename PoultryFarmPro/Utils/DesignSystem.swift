import SwiftUI

// MARK: - Color Palette
extension Color {
    // Primary greens
    static let farmGreen        = Color(hex: "#2D6A4F")
    static let farmGreenLight   = Color(hex: "#52B788")
    static let farmGreenPale    = Color(hex: "#D8F3DC")
    static let farmGreenDeep    = Color(hex: "#1B4332")

    // Accent ambers
    static let hayAmber         = Color(hex: "#F4A261")
    static let hayAmberLight    = Color(hex: "#FFCB8E")
    static let hayAmberDeep     = Color(hex: "#E07B39")

    // Egg tones
    static let eggCream         = Color(hex: "#FFF8EC")
    static let eggYolk          = Color(hex: "#F9C74F")
    static let eggShell         = Color(hex: "#EDE0D4")

    // Soil/earth
    static let soilBrown        = Color(hex: "#7C5C3A")
    static let soilLight        = Color(hex: "#C09A6B")

    // Status
    static let healthGreen      = Color(hex: "#40916C")
    static let alertRed         = Color(hex: "#E63946")
    static let warningYellow    = Color(hex: "#F9C74F")
    static let infoBlue         = Color(hex: "#4CC9F0")

    // Neutrals
    static let cardBackground   = Color(hex: "#FAFAF7")
    static let surfaceLight     = Color(hex: "#F0EDE6")
    static let textPrimary      = Color(hex: "#1A2618")
    static let textSecondary    = Color(hex: "#5A6B57")
    static let textMuted        = Color(hex: "#9BA89A")
    static let divider          = Color(hex: "#E4E8E0")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let farmHero = LinearGradient(
        colors: [.farmGreenDeep, .farmGreen],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let ambientCard = LinearGradient(
        colors: [Color.farmGreenPale, Color.eggCream],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let eggGradient = LinearGradient(
        colors: [Color.eggYolk, Color.hayAmber],
        startPoint: .top, endPoint: .bottom
    )
    static let healthGradient = LinearGradient(
        colors: [Color.healthGreen, Color.farmGreenLight],
        startPoint: .leading, endPoint: .trailing
    )
    static let soilGradient = LinearGradient(
        colors: [Color.soilBrown, Color.soilLight],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Typography
extension Font {
    static func farmTitle(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func farmHeadline(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func farmBody(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func farmCaption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func farmNumber(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
}

// MARK: - Custom Button Styles
struct FarmPrimaryButtonStyle: ButtonStyle {
    var color: Color = .farmGreen
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.farmHeadline(16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct FarmSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.farmHeadline(16))
            .foregroundColor(.farmGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.farmGreen, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct FarmIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Card Modifier
struct FarmCardModifier: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
            )
    }
}

extension View {
    func farmCard(padding: CGFloat = 16) -> some View {
        modifier(FarmCardModifier(padding: padding))
    }
}

// MARK: - Custom Text Field
struct FarmTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .foregroundColor(.farmGreen)
                    .frame(width: 24)
            }
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.farmBody())
                    .foregroundColor(.textPrimary)
            } else {
                TextField(placeholder, text: $text)
                    .font(.farmBody())
                    .foregroundColor(.textPrimary)
                    .keyboardType(keyboardType)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.surfaceLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.divider, lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            Text(value)
                .font(.farmNumber(28))
                .foregroundColor(.white)
            Text(title)
                .font(.farmCaption(13))
                .foregroundColor(.white.opacity(0.85))
            Text(subtitle)
                .font(.farmCaption(11))
                .foregroundColor(.white.opacity(0.65))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(gradient)
                .shadow(color: Color.farmGreen.opacity(0.3), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil
    var body: some View {
        HStack {
            Text(title)
                .font(.farmHeadline(18))
                .foregroundColor(.textPrimary)
            Spacer()
            if let action = action, let onAction = onAction {
                Button(action: onAction) {
                    Text(action)
                        .font(.farmCaption(13))
                        .foregroundColor(.farmGreen)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(.farmGreenLight.opacity(0.7))
            Text(title)
                .font(.farmHeadline(18))
                .foregroundColor(.textPrimary)
            Text(message)
                .font(.farmBody(14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

// MARK: - Badge
struct StatusBadge: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.farmCaption(11))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(color)
            )
    }
}

// MARK: - Row Item
struct FarmRowItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var trailing: String? = nil
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.farmBody(15))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.farmCaption(12))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            if let trailing = trailing {
                Text(trailing)
                    .font(.farmCaption(13))
                    .foregroundColor(.textMuted)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textMuted)
        }
        .padding(.vertical, 4)
    }
}
