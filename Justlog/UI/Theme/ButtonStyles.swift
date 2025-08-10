import SwiftUI

// MARK: - Android Material Design Button Styles

struct MaterialPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .default, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: 2,
                        x: 0,
                        y: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct MaterialSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .default, weight: .medium))
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.clear)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct MaterialCardButtonStyle: ButtonStyle {
    let height: CGFloat
    
    init(height: CGFloat = 56) {
        self.height = height
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct MaterialFloatingActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title2, design: .default, weight: .medium))
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(
                Circle()
                    .fill(Color.blue)
                    .shadow(
                        color: Color.black.opacity(0.2),
                        radius: 6,
                        x: 0,
                        y: 3
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct MaterialChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(MaterialColors.onSurface)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct MaterialOutlinedButtonStyle: ButtonStyle {
    let height: CGFloat
    
    init(height: CGFloat = 56) {
        self.height = height
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions for easy use

extension ButtonStyle where Self == MaterialPrimaryButtonStyle {
    static var materialPrimary: MaterialPrimaryButtonStyle {
        MaterialPrimaryButtonStyle()
    }
}

extension ButtonStyle where Self == MaterialSecondaryButtonStyle {
    static var materialSecondary: MaterialSecondaryButtonStyle {
        MaterialSecondaryButtonStyle()
    }
}

extension ButtonStyle where Self == MaterialCardButtonStyle {
    static var materialCard: MaterialCardButtonStyle {
        MaterialCardButtonStyle()
    }
    
    static func materialCard(height: CGFloat) -> MaterialCardButtonStyle {
        MaterialCardButtonStyle(height: height)
    }
}

extension ButtonStyle where Self == MaterialFloatingActionButtonStyle {
    static var materialFAB: MaterialFloatingActionButtonStyle {
        MaterialFloatingActionButtonStyle()
    }
}

extension ButtonStyle where Self == MaterialChipButtonStyle {
    static var materialChip: MaterialChipButtonStyle {
        MaterialChipButtonStyle()
    }
}

extension ButtonStyle where Self == MaterialOutlinedButtonStyle {
    static var materialOutlined: MaterialOutlinedButtonStyle {
        MaterialOutlinedButtonStyle()
    }
    
    static func materialOutlined(height: CGFloat) -> MaterialOutlinedButtonStyle {
        MaterialOutlinedButtonStyle(height: height)
    }
}

// MARK: - Material Text Field Style

@MainActor
struct MaterialTextFieldStyle: TextFieldStyle {
    let themeManager: ThemeManager?
    let placeholder: String
    
    init(themeManager: ThemeManager?, placeholder: String = "") {
        self.themeManager = themeManager
        self.placeholder = placeholder
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, MaterialSpacing.md)
            .padding(.vertical, MaterialSpacing.md)
            .font(.system(size: 16))
            .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Rounded Rectangle Shape

struct RoundedRectangleShape: Shape {
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            let cornerRadius = min(radius, min(rect.width, rect.height) / 2)
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        }
    }
}

struct RoundedCornerShape: Shape {
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            let cornerRadius = min(radius, min(rect.width, rect.height) / 2)
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        }
    }
}

extension Shape where Self == RoundedRectangleShape {
    static func roundedRectangle(radius: CGFloat) -> RoundedRectangleShape {
        RoundedRectangleShape(radius: radius)
    }
}

extension Shape where Self == RoundedCornerShape {
    static func roundedCorner(radius: CGFloat) -> RoundedCornerShape {
        RoundedCornerShape(radius: radius)
    }
}