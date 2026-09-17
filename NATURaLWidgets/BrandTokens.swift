import SwiftUI

/// FlexAIDΔS v2 tokens for widget / Live Activity targets that do not import BonhommeCore.
/// Source: https://thebonhomme.com/tokens.css
enum BrandTokens {
    static let bg = Color(red: 8 / 255, green: 9 / 255, blue: 26 / 255)
    static let fg = Color(red: 228 / 255, green: 227 / 255, blue: 245 / 255)
    static let mint = Color(red: 69 / 255, green: 224 / 255, blue: 168 / 255)
    static let violet = Color(red: 139 / 255, green: 92 / 255, blue: 246 / 255)
    static let tangerine = Color(red: 1, green: 147 / 255, blue: 0)
    static let strawberry = Color(red: 1, green: 47 / 255, blue: 146 / 255)
    static let firetruck = Color(red: 245 / 255, green: 35 / 255, blue: 43 / 255)
    static let magnesium = Color(red: 220 / 255, green: 220 / 255, blue: 228 / 255)
    static let aqua = Color(red: 0, green: 162 / 255, blue: 1)

    /// Match `SessionHUDMetrics.sciPercentText` — clamp [0, 1], non-finite → —.
    static func sciPercent(_ score: Double?) -> String {
        guard let score, score.isFinite else { return "—" }
        return "\(Int((min(1, max(0, score)) * 100).rounded()))"
    }

    static func sciPercentLabel(_ score: Double?) -> String {
        let body = sciPercent(score)
        return body == "—" ? "—" : "\(body)%"
    }
}
