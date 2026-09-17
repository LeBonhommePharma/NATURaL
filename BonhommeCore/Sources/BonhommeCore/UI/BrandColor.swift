import SwiftUI

/// FlexAIDΔS palette v2 hex — [thebonhomme.com/tokens.css](https://thebonhomme.com/tokens.css)
/// Locked so design-system/natural/MASTER.md and Swift HUD stay in lockstep.
public enum BrandPalette: Sendable {
    public static let bg: UInt32 = 0x08091A
    public static let fg: UInt32 = 0xE4E3F5
    public static let fgMuted: UInt32 = 0x8D8CB0
    public static let mint: UInt32 = 0x45E0A8
    public static let violet: UInt32 = 0x8B5CF6
    public static let tangerine: UInt32 = 0xFF9300
    public static let firetruck: UInt32 = 0xF5232B
    public static let aqua: UInt32 = 0x00A2FF
    public static let strawberry: UInt32 = 0xFF2F92
    public static let magnesium: UInt32 = 0xDCDCE4
    /// Thermodynamic gold chrome — optional, never a SCI/CTA substitute.
    public static let gold: UInt32 = 0xC4A359
}

public extension Color {
    /// sRGB from a locked FlexAIDΔS hex (`BrandPalette`). HUD colors must not drift from MASTER.md.
    init(brandHex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((brandHex >> 16) & 0xFF) / 255,
            green: Double((brandHex >> 8) & 0xFF) / 255,
            blue: Double(brandHex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// FlexAIDΔS palette v2 — [thebonhomme.com/tokens.css](https://thebonhomme.com/tokens.css)
///
/// Semantic bindings are the system: a key color is never reassigned to a
/// different thermodynamic quantity. Dark default (indigo ink). Light appearance
/// variants live in `BrandColors.xcassets`; session HUD always reads these sRGB values
/// so SCI / ΔH / ΔG stay identical across themes.
public enum BrandColor: Sendable {
    // MARK: Surfaces

    /// Page ink `#08091A`.
    public static let bg = Color(brandHex: BrandPalette.bg)
    /// Nav / inspector `#111226` @ 92%.
    public static let bgPanel = Color(red: 17 / 255, green: 18 / 255, blue: 38 / 255).opacity(0.92)
    /// Cards `#111226` @ 82%.
    public static let bgCard = Color(red: 17 / 255, green: 18 / 255, blue: 38 / 255).opacity(0.82)
    /// Body text `#E4E3F5` (15.60:1 on ink).
    public static let fg = Color(brandHex: BrandPalette.fg)
    /// Secondary `#8D8CB0` (6.12:1 on ink).
    public static let fgMuted = Color(brandHex: BrandPalette.fgMuted)

    // MARK: Key colors (quantity-bound)

    /// ΔH · enthalpy · brand primary · pass · CTA `#45E0A8`.
    public static let mint = Color(brandHex: BrandPalette.mint)
    /// ΔS · configurational entropy · SCI signal `#8B5CF6`.
    public static let violet = Color(brandHex: BrandPalette.violet)
    /// ΔG · free energy · stats `#FF9300`.
    public static let tangerine = Color(brandHex: BrandPalette.tangerine)
    /// T · temperature · hard fail `#F5232B`.
    public static let firetruck = Color(brandHex: BrandPalette.firetruck)
    /// ΔS_vib · vibrational `#00A2FF`.
    public static let aqua = Color(brandHex: BrandPalette.aqua)
    /// Receptor · pocket · warn `#FF2F92`.
    public static let strawberry = Color(brandHex: BrandPalette.strawberry)
    /// Apo baseline · reference `#DCDCE4`.
    public static let magnesium = Color(brandHex: BrandPalette.magnesium)

    // MARK: States / ramps

    public static let statePass = mint
    public static let stateWarn = strawberry
    public static let stateFail = firetruck
    /// Small fail labels on dark `#FF6B6B` (7.11:1).
    public static let stateFailText = Color(red: 1, green: 107 / 255, blue: 107 / 255)

    /// Temperature ramp (B-factor): cryo → denature. Equation hues stay out.
    public static let tempCryo = aqua
    public static let tempCold = Color(red: 127 / 255, green: 208 / 255, blue: 1) // #7FD0FF
    public static let tempAmbient = magnesium
    public static let tempPhysio = Color(red: 1, green: 122 / 255, blue: 92 / 255) // #FF7A5C
    public static let tempDenature = firetruck

    /// Magnesium hairline 12–20% (never snow white).
    public static let hairline = magnesium.opacity(0.16)
    public static let hairlineStrong = magnesium.opacity(0.20)

    // MARK: Asset catalog twins (IB / appearance)

    public static var mintAsset: Color { Color("BrandMint", bundle: .module) }
    public static var violetAsset: Color { Color("BrandViolet", bundle: .module) }
    public static var tangerineAsset: Color { Color("BrandTangerine", bundle: .module) }
    public static var firetruckAsset: Color { Color("BrandFiretruck", bundle: .module) }
    public static var aquaAsset: Color { Color("BrandAqua", bundle: .module) }
    public static var strawberryAsset: Color { Color("BrandStrawberry", bundle: .module) }
    public static var magnesiumAsset: Color { Color("BrandMagnesium", bundle: .module) }
    public static var bgAsset: Color { Color("BrandBg", bundle: .module) }
    public static var fgAsset: Color { Color("BrandFg", bundle: .module) }
}

/// SF Pro for prose; SF Mono for metrics / SCI (Apple platforms map `.monospaced` → SF Mono).
public enum SessionType {
    public static func metric(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .monospaced).weight(weight)
    }

    public static func metric(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    public static func prose(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default).weight(weight)
    }
}

public extension View {
    /// Colored glow elevation (tokens.css `--glow-*`). Never a neutral drop shadow.
    func sessionGlow(_ color: Color, radius: CGFloat = 10, paused: Bool = false) -> some View {
        shadow(color: paused ? .clear : color.opacity(0.40), radius: radius)
    }
}
