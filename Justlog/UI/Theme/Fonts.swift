import SwiftUI

extension Font {
    // VAG font family - using single font file for all weights
    static let vagRegular = Font.custom("VAGRounded-Light", size: 16)
    static let vagMedium = Font.custom("VAGRounded-Light", size: 16)
    static let vagBold = Font.custom("VAGRounded-Light", size: 16)
    
    // Font helpers with VAG family - all use same font file
    static func vag(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.custom("VAGRounded-Light", size: size)
    }
}

// Custom font modifier
struct VAGFontModifier: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    
    func body(content: Content) -> some View {
        content.font(.vag(size: size, weight: weight))
    }
}

extension View {
    func vagFont(size: CGFloat = 16, weight: Font.Weight = .regular) -> some View {
        modifier(VAGFontModifier(size: size, weight: weight))
    }
}