import Foundation

/// Yoga practice styles with distinct characteristics and benefits.
public enum YogaStyle: String, CaseIterable, Codable, Sendable {
    case pranayama
    case chairYoga
    case vinyasa
    case hatha
    case yin
    case restorative
    case power
    case standingBalance
    case prenatal
    
    public var localizedName: LocalizedString {
        switch self {
        case .pranayama:
            return LocalizedString(
                en: "Pranayama",
                fr: "Pranayama",
                es: "Pranayama",
                ja: "プラナヤマ",
                zh: "呼吸法",
                ko: "프라나야마",
                ru: "Пранаяма",
                de: "Pranayama",
                ar: "براناياما",
                it: "Pranayama",
                pt: "Pranayama"
            )
        case .chairYoga:
            return LocalizedString(
                en: "Chair Yoga",
                fr: "Yoga sur chaise",
                es: "Yoga en silla",
                ja: "チェアヨガ",
                zh: "椅子瑜伽",
                ko: "의자 요가",
                ru: "Йога на стуле",
                de: "Stuhl-Yoga",
                ar: "يوغا الكرسي",
                it: "Yoga sulla sedia",
                pt: "Yoga na cadeira"
            )
        case .vinyasa:
            return LocalizedString(
                en: "Vinyasa",
                fr: "Vinyasa",
                es: "Vinyasa",
                ja: "ヴィンヤサ",
                zh: "流瑜伽",
                ko: "빈야사",
                ru: "Виньяса",
                de: "Vinyasa",
                ar: "فينياسا",
                it: "Vinyasa",
                pt: "Vinyasa"
            )
        case .hatha:
            return LocalizedString(
                en: "Hatha",
                fr: "Hatha",
                es: "Hatha",
                ja: "ハタ",
                zh: "哈达瑜伽",
                ko: "하타",
                ru: "Хатха",
                de: "Hatha",
                ar: "هاثا",
                it: "Hatha",
                pt: "Hatha"
            )
        case .yin:
            return LocalizedString(
                en: "Yin",
                fr: "Yin",
                es: "Yin",
                ja: "陰ヨガ",
                zh: "阴瑜伽",
                ko: "음 요가",
                ru: "Инь-йога",
                de: "Yin",
                ar: "يين",
                it: "Yin",
                pt: "Yin"
            )
        case .restorative:
            return LocalizedString(
                en: "Restorative",
                fr: "Réparateur",
                es: "Restaurativo",
                ja: "リストラティブ",
                zh: "修复瑜伽",
                ko: "회복 요가",
                ru: "Восстановительная",
                de: "Erholsam",
                ar: "الاستعادة",
                it: "Ristorativo",
                pt: "Restaurativo"
            )
        case .power:
            return LocalizedString(
                en: "Power",
                fr: "Puissance",
                es: "Poder",
                ja: "パワーヨガ",
                zh: "力量瑜伽",
                ko: "파워 요가",
                ru: "Силовая",
                de: "Power",
                ar: "القوة",
                it: "Power",
                pt: "Poder"
            )
        case .standingBalance:
            return LocalizedString(
                en: "Standing Balance",
                fr: "Équilibre debout",
                es: "Equilibrio de pie",
                ja: "立位バランス",
                zh: "站立平衡",
                ko: "서서 균형",
                ru: "Баланс стоя",
                de: "Stehende Balance",
                ar: "التوازن واقفاً",
                it: "Equilibrio in piedi",
                pt: "Equilíbrio em pé"
            )
        case .prenatal:
            return LocalizedString(
                en: "Prenatal",
                fr: "Prénatal",
                es: "Prenatal",
                ja: "マタニティ",
                zh: "孕期瑜伽",
                ko: "산전 요가",
                ru: "Пренатальная",
                de: "Pränatales",
                ar: "ما قبل الولادة",
                it: "Prenatale",
                pt: "Pré-natal"
            )
        }
    }
    
    public var symbolName: String {
        switch self {
        case .pranayama:
            return "wind"
        case .chairYoga:
            return "chair.fill"
        case .vinyasa:
            return "figure.yoga"
        case .hatha:
            return "figure.mind.and.body"
        case .yin:
            return "moon.stars.fill"
        case .restorative:
            return "bed.double.fill"
        case .power:
            return "bolt.fill"
        case .standingBalance:
            return "figure.stand"
        case .prenatal:
            return "heart.circle.fill"
        }
    }
    
    public var accentHue: Double {
        switch self {
        case .pranayama:
            return 0.55 // Cyan/Blue
        case .chairYoga:
            return 0.35 // Green
        case .vinyasa:
            return 0.6  // Blue
        case .hatha:
            return 0.15 // Orange
        case .yin:
            return 0.75 // Purple
        case .restorative:
            return 0.8  // Purple/Pink
        case .power:
            return 0.0  // Red
        case .standingBalance:
            return 0.45 // Teal
        case .prenatal:
            return 0.9  // Pink
        }
    }
}
