import SwiftUI

// MARK: - Spacing (8pt grid)

/// Layout constants shared by session HUD and navigation chrome.
/// Mirrors Apple Design Resources spacing (iOS/iPadOS 27, macOS 27, watchOS 26).
public enum SessionSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 40
    public static let xxxl: CGFloat = 48

    /// Minimum interactive height (HIG / watchOS 26 tap targets).
    public static let minTapTarget: CGFloat = 44
    /// Phone primary session control height (one-handed).
    public static let phoneControlHeight: CGFloat = 52
}

// MARK: - Radii (concentric, continuous)

/// Corner radii nested to container curvature (Liquid Glass / iOS 26+ concentric pattern).
public enum SessionRadius {
    public static let chip: CGFloat = 10
    public static let control: CGFloat = 16
    public static let card: CGFloat = 22
    public static let panel: CGFloat = 26
    public static let sheet: CGFloat = 34

    public static func chipShape() -> RoundedRectangle {
        RoundedRectangle(cornerRadius: chip, style: .continuous)
    }

    public static func controlShape() -> RoundedRectangle {
        RoundedRectangle(cornerRadius: control, style: .continuous)
    }

    public static func cardShape() -> RoundedRectangle {
        RoundedRectangle(cornerRadius: card, style: .continuous)
    }

    public static func panelShape() -> RoundedRectangle {
        RoundedRectangle(cornerRadius: panel, style: .continuous)
    }
}

// MARK: - Palette

/// Product-layer colors. OS chrome stays native; these tokens brand HUD, SCI, CTAs, and state.
/// Semantics from FlexAIDΔS v2 (thebonhomme.com/tokens.css) — never reassigned.
public enum SessionPalette {
    /// ΔH / brand primary / pass / primary CTA.
    public static let accent = BrandColor.mint
    public static let onAccent = BrandColor.bg
    public static let sessionBackground = BrandColor.bg
    public static let panel = BrandColor.bgPanel
    public static let card = BrandColor.bgCard
    public static let foreground = BrandColor.fg
    public static let muted = BrandColor.fgMuted
    public static let secondaryFill = BrandColor.mint.opacity(0.08)
    public static let hairline = BrandColor.hairline
    /// SCI identity (Mac / single readout) — ΔS, not a band.
    public static let sciSignal = BrandColor.violet

    /// Discrete SCI color band (testable without relying on `Color` equality).
    public enum SCIBand: String, Sendable, Equatable {
        case apo, fail, warn, signal, pass

        public static func resolve(_ score: Double?) -> SCIBand {
            guard let score, score.isFinite else { return .apo }
            switch min(1, max(0, score)) {
            case ..<0.3: return .fail
            case 0.3..<0.6: return .warn
            case 0.6..<0.8: return .signal
            default: return .pass
            }
        }
    }

    /// Heart-rate temperature band (testable).
    public enum HeartRateBand: String, Sendable, Equatable {
        case apo, cryo, cold, physio, denature

        public static func resolve(_ bpm: Double?) -> HeartRateBand {
            guard let bpm, bpm.isFinite else { return .apo }
            switch bpm {
            case ..<100: return .cryo
            case 100..<130: return .cold
            case 130..<160: return .physio
            default: return .denature
            }
        }
    }

    /// Banded SCI: fail → warn → ΔS signal → pass. Nil is apo baseline.
    public static func sci(_ score: Double?) -> Color {
        switch SCIBand.resolve(score) {
        case .apo: return BrandColor.magnesium
        case .fail: return BrandColor.firetruck
        case .warn: return BrandColor.strawberry
        case .signal: return BrandColor.violet
        case .pass: return BrandColor.mint
        }
    }

    /// Heart-rate zones follow the temperature ramp (not yellow / gold).
    public static func heartRate(_ bpm: Double?) -> Color {
        switch HeartRateBand.resolve(bpm) {
        case .apo: return BrandColor.magnesium
        case .cryo: return BrandColor.tempCryo
        case .cold: return BrandColor.tempCold
        case .physio: return BrandColor.tempPhysio
        case .denature: return BrandColor.tempDenature
        }
    }

    public static func trend(_ trend: SCITrend) -> Color {
        switch trend {
        case .improving: return BrandColor.mint
        case .stable: return BrandColor.magnesium
        case .declining: return BrandColor.strawberry
        }
    }

    public static func entropy(_ state: SessionEntropyState) -> Color {
        switch state {
        case .unknown: return BrandColor.magnesium
        case .grounding: return BrandColor.strawberry
        case .collapsed: return BrandColor.firetruck
        case .settling: return BrandColor.strawberry
        case .focused: return BrandColor.violet
        case .coherent: return BrandColor.mint
        }
    }
}

// MARK: - SCI trend chrome

public extension SCITrend {
    var symbolName: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
}

public extension InsightTrend {
    var symbolName: String { asSCITrend.symbolName }
}

// MARK: - Copy

/// User-facing HUD strings. Full `LocalizedString` set so catalogs stay intact.
public enum SessionHUDCopy {
    public static let focusIndex = LocalizedString(
        en: "Focus Index", fr: "Indice de concentration", es: "Índice de concentración",
        ja: "集中力指数", zh: "专注力指数", ko: "집중력 지수",
        ru: "Индекс концентрации", de: "Fokus-Index", ar: "مؤشر التركيز"
    )
    public static let sci = LocalizedString(
        en: "SCI", fr: "SCI", es: "SCI", ja: "SCI", zh: "SCI", ko: "SCI", ru: "SCI", de: "SCI", ar: "SCI"
    )
    public static let bpm = LocalizedString(
        en: "BPM", fr: "BPM", es: "PPM", ja: "BPM", zh: "次/分", ko: "BPM", ru: "уд/мин", de: "BPM", ar: "نبضة/د"
    )
    public static let heartRate = LocalizedString(
        en: "Heart Rate", fr: "Fréquence cardiaque", es: "Ritmo cardíaco",
        ja: "心拍数", zh: "心率", ko: "심박수",
        ru: "Пульс", de: "Herzfrequenz", ar: "معدل القلب"
    )
    public static let tempo = LocalizedString(
        en: "Tempo", fr: "Tempo", es: "Tempo", ja: "テンポ", zh: "节奏", ko: "템포", ru: "Темп", de: "Tempo", ar: "الإيقاع"
    )
    public static let pause = LocalizedString(
        en: "Pause", fr: "Pause", es: "Pausa", ja: "一時停止", zh: "暂停", ko: "일시 정지", ru: "Пауза", de: "Pause", ar: "إيقاف مؤقت"
    )
    public static let resume = LocalizedString(
        en: "Resume", fr: "Reprendre", es: "Reanudar", ja: "再開", zh: "继续", ko: "재개", ru: "Продолжить", de: "Fortsetzen", ar: "استئناف"
    )
    public static let end = LocalizedString(
        en: "End", fr: "Terminer", es: "Terminar", ja: "終了", zh: "结束", ko: "종료", ru: "Завершить", de: "Beenden", ar: "إنهاء"
    )
    public static let beginSession = LocalizedString(
        en: "Begin Session", fr: "Commencer la séance", es: "Comenzar sesión",
        ja: "セッションを開始", zh: "开始练习", ko: "세션 시작",
        ru: "Начать сессию", de: "Sitzung starten", ar: "بدء الجلسة"
    )
    public static let cancel = LocalizedString(
        en: "Cancel", fr: "Annuler", es: "Cancelar", ja: "キャンセル", zh: "取消", ko: "취소", ru: "Отмена", de: "Abbrechen", ar: "إلغاء"
    )
    public static let nextUp = LocalizedString(
        en: "Next Up", fr: "Prochaine posture", es: "Siguiente",
        ja: "次へ", zh: "下一个", ko: "다음",
        ru: "Далее", de: "Als Nächstes", ar: "التالي"
    )
    public static let getReady = LocalizedString(
        en: "Get Ready", fr: "Préparez-vous", es: "Prepárate",
        ja: "準備", zh: "准备", ko: "준비",
        ru: "Приготовьтесь", de: "Bereit machen", ar: "استعد"
    )
    public static let paused = LocalizedString(
        en: "Paused", fr: "En pause", es: "En pausa",
        ja: "一時停止", zh: "已暂停", ko: "일시 정지",
        ru: "Пауза", de: "Pausiert", ar: "متوقف مؤقتًا"
    )
    public static let music = LocalizedString(
        en: "Music", fr: "Musique", es: "Música", ja: "音楽", zh: "音乐", ko: "음악", ru: "Музыка", de: "Musik", ar: "موسيقى"
    )
    public static let airPods = LocalizedString(
        en: "AirPods", fr: "AirPods", es: "AirPods", ja: "AirPods", zh: "AirPods",
        ko: "AirPods", ru: "AirPods", de: "AirPods", ar: "AirPods"
    )
    public static let spatial = LocalizedString(
        en: "Spatial", fr: "Spatial", es: "Espacial", ja: "空間", zh: "空间",
        ko: "공간", ru: "Пространство", de: "Räumlich", ar: "مكاني"
    )
    public static let arCoach = LocalizedString(
        en: "AR Coach", fr: "Coach RA", es: "Coach RA", ja: "ARコーチ", zh: "AR教练",
        ko: "AR 코치", ru: "AR-тренер", de: "AR-Coach", ar: "مدرب الواقع المعزز"
    )
    public static let twoDCoach = LocalizedString(
        en: "2D Coach", fr: "Coach 2D", es: "Coach 2D", ja: "2Dコーチ", zh: "平面教练",
        ko: "2D 코치", ru: "2D-тренер", de: "2D-Coach", ar: "مدرب ثنائي الأبعاد"
    )
    public static let explainSCI = LocalizedString(
        en: "What SCI means", fr: "Que signifie le SCI", es: "Qué significa SCI",
        ja: "SCIの意味", zh: "SCI的含义", ko: "SCI의 의미",
        ru: "Что значит SCI", de: "Was SCI bedeutet", ar: "معنى SCI"
    )
    public static let plainLanguage = LocalizedString(
        en: "Plain language", fr: "Langage simple", es: "Lenguaje sencillo",
        ja: "わかりやすい説明", zh: "简明语言", ko: "쉬운 말",
        ru: "Простой язык", de: "Einfache Sprache", ar: "لغة مبسطة"
    )
}

// MARK: - Glass / material chrome

public extension View {
    /// Liquid Glass on iOS/macOS/tvOS 26+ SDKs; ultra-thin material otherwise.
    /// Navigation bars are left to the system — this is for custom HUD surfaces only.
    @ViewBuilder
    func sessionGlassFill<S: Shape>(in shape: S) -> some View {
        #if os(watchOS)
        background(.ultraThinMaterial, in: shape)
        #else
        #if compiler(>=6.2)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
        #else
        background(.ultraThinMaterial, in: shape)
        #endif
        #endif
    }

    @ViewBuilder
    func sessionProminentButtonStyle() -> some View {
        #if os(watchOS)
        buttonStyle(.borderedProminent)
        #else
        #if compiler(>=6.2)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
        #else
        buttonStyle(.borderedProminent)
        #endif
        #endif
    }

    @ViewBuilder
    func sessionGlassButtonStyle() -> some View {
        #if os(watchOS)
        buttonStyle(.bordered)
        #else
        #if compiler(>=6.2)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
        #else
        buttonStyle(.bordered)
        #endif
        #endif
    }
}

// MARK: - Motion

public enum SessionMotion {
    /// Pause decorative TimelineView loops when Reduce Motion is on.
    public static func timelinePaused(_ reduceMotion: Bool) -> Bool { reduceMotion }

    public static func timelineInterval(_ reduceMotion: Bool) -> Double {
        reduceMotion ? 1.0 : (1.0 / 30.0)
    }
}
