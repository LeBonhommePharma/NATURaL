import Foundation

/// Higher-order pharmacological super-families that group the twelve PokeDrug
/// types by shared neurotransmitter system or mechanism of action.
///
/// Each cluster defines a color family so that member types share a visually
/// coherent palette while remaining individually distinguishable. Inspired by
/// the Pokémon "egg group" concept — orthogonal to type, but revealing deeper
/// biological kinship.
public enum PokeDrugSuperaCluster: String, Codable, Sendable, CaseIterable {
    /// 5-HT pathway modulators: classical psychedelics, entactogens, and
    /// sigma-neurosteroid crosstalk. All roads lead through serotonin.
    /// Color family: purples / violets.
    case serotonergic

    /// Endorphin / dynorphin axis: mu-opioid euphoria and kappa-opioid
    /// dysphoria. Opposing poles of the same receptor superfamily.
    /// Color family: reds / crimsons.
    case opioidergic

    /// Catecholamine and purine activators: dopamine release, norepinephrine
    /// flood, and adenosine blockade. The brain's accelerator pedals.
    /// Color family: oranges / ambers / golds.
    case catecholaminergic

    /// CNS depressants: NMDA block, GABA-A potentiation, and cannabinoid
    /// receptor agonism. Distinct mechanisms, converging sedation.
    /// Color family: blues / teals / greens.
    case inhibitory

    /// Acetylcholine system: nicotinic agonism and muscarinic antagonism.
    /// The oldest pharmacological axis — tobacco and nightshade.
    /// Color family: earth / warm brown.
    case cholinergic
}

// MARK: - Cluster Membership

extension PokeDrugSuperaCluster {

    /// The PokeDrug types that belong to this cluster.
    public var memberTypes: [PokeDrugType] {
        switch self {
        case .serotonergic:
            return [.serotonin, .empathogen, .sigma]
        case .opioidergic:
            return [.opioid, .kappa]
        case .catecholaminergic:
            return [.dopamine, .stimulant, .adenosine]
        case .inhibitory:
            return [.dissociative, .sedative, .cannabinoid]
        case .cholinergic:
            return [.cholinergic]
        }
    }
}

// MARK: - Type → Cluster Lookup

extension PokeDrugType {

    /// The super-cluster this type belongs to.
    public var superaCluster: PokeDrugSuperaCluster {
        switch self {
        case .serotonin, .empathogen, .sigma:
            return .serotonergic
        case .opioid, .kappa:
            return .opioidergic
        case .dopamine, .stimulant, .adenosine:
            return .catecholaminergic
        case .dissociative, .sedative, .cannabinoid:
            return .inhibitory
        case .cholinergic:
            return .cholinergic
        }
    }
}

// MARK: - Metadata

extension PokeDrugSuperaCluster {

    /// Display name.
    public var displayName: LocalizedString {
        switch self {
        case .serotonergic:
            return LocalizedString(
                en: "Serotonergic", fr: "Sérotoninergique",
                es: "Serotoninérgico", ja: "セロトニン作動性",
                zh: "血清素能", ko: "세로토닌성",
                ru: "Серотонинергический", de: "Serotonerg",
                ar: "سيروتونيني")
        case .opioidergic:
            return LocalizedString(
                en: "Opioidergic", fr: "Opioïdergique",
                es: "Opioidérgico", ja: "オピオイド作動性",
                zh: "阿片能", ko: "오피오이드성",
                ru: "Опиоидергический", de: "Opioiderg",
                ar: "أفيوني")
        case .catecholaminergic:
            return LocalizedString(
                en: "Catecholaminergic", fr: "Catécholaminergique",
                es: "Catecolaminérgico", ja: "カテコールアミン作動性",
                zh: "儿茶酚胺能", ko: "카테콜아민성",
                ru: "Катехоламинергический", de: "Katecholaminerg",
                ar: "كاتيكولاميني")
        case .inhibitory:
            return LocalizedString(
                en: "Inhibitory", fr: "Inhibiteur",
                es: "Inhibitorio", ja: "抑制性",
                zh: "抑制性", ko: "억제성",
                ru: "Ингибиторный", de: "Inhibitorisch",
                ar: "مثبط")
        case .cholinergic:
            return LocalizedString(
                en: "Cholinergic", fr: "Cholinergique",
                es: "Colinérgico", ja: "コリン作動性",
                zh: "胆碱能", ko: "콜린성",
                ru: "Холинергический", de: "Cholinerg",
                ar: "كوليني")
        }
    }

    /// The shared neurotransmitter system or mechanism that unifies this cluster.
    public var unifyingMechanism: LocalizedString {
        switch self {
        case .serotonergic:
            return LocalizedString(
                en: "5-HT pathway modulation", fr: "Modulation de la voie 5-HT",
                es: "Modulación de la vía 5-HT", ja: "5-HT経路の調節",
                zh: "5-HT通路调节", ko: "5-HT 경로 조절",
                ru: "Модуляция пути 5-HT", de: "5-HT-Signalweg-Modulation",
                ar: "تعديل مسار 5-HT")
        case .opioidergic:
            return LocalizedString(
                en: "Endogenous opioid peptide axis", fr: "Axe peptidique opioïde endogène",
                es: "Eje peptídico opioide endógeno", ja: "内因性オピオイドペプチド軸",
                zh: "内源性阿片肽轴", ko: "내인성 오피오이드 펩타이드 축",
                ru: "Ось эндогенных опиоидных пептидов", de: "Endogene Opioidpeptid-Achse",
                ar: "محور الببتيد الأفيوني الداخلي")
        case .catecholaminergic:
            return LocalizedString(
                en: "Catecholamine / purine activation", fr: "Activation catécholamine / purine",
                es: "Activación catecolamina / purina", ja: "カテコールアミン/プリン活性化",
                zh: "儿茶酚胺/嘌呤激活", ko: "카테콜아민/퓨린 활성화",
                ru: "Катехоламиновая / пуриновая активация", de: "Katecholamin-/Purin-Aktivierung",
                ar: "تنشيط الكاتيكولامين / البيورين")
        case .inhibitory:
            return LocalizedString(
                en: "CNS depression via distinct mechanisms", fr: "Dépression du SNC par mécanismes distincts",
                es: "Depresión del SNC por mecanismos distintos", ja: "異なるメカニズムによるCNS抑制",
                zh: "通过不同机制的CNS抑制", ko: "다양한 기전을 통한 CNS 억제",
                ru: "Угнетение ЦНС различными механизмами", de: "ZNS-Dämpfung über verschiedene Mechanismen",
                ar: "تثبيط الجهاز العصبي المركزي بآليات مختلفة")
        case .cholinergic:
            return LocalizedString(
                en: "Acetylcholine receptor modulation", fr: "Modulation du récepteur de l'acétylcholine",
                es: "Modulación del receptor de acetilcolina", ja: "アセチルコリン受容体の調節",
                zh: "乙酰胆碱受体调节", ko: "아세틸콜린 수용체 조절",
                ru: "Модуляция ацетилхолинового рецептора", de: "Acetylcholinrezeptor-Modulation",
                ar: "تعديل مستقبل الأستيل كولين")
        }
    }

    /// Hex color for the cluster (anchor WoW class color from the cluster).
    public var color: String {
        switch self {
        case .serotonergic:      return "#8788EE"  // Warlock (serotonin anchor)
        case .opioidergic:       return "#C41E3A"  // Death Knight (opioid anchor)
        case .catecholaminergic: return "#FF7C0A"  // Druid (dopamine anchor)
        case .inhibitory:        return "#3FC7EB"  // Mage (dissociative anchor)
        case .cholinergic:       return "#C69B6D"  // Warrior (cholinergic anchor)
        }
    }
}
