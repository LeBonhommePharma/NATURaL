import Foundation

/// The twelve PokeDrug pharmacological "types," each corresponding to a major
/// pharmacological target class — a receptor, transporter, or ion channel
/// through which psychoactive molecules exert their effects.
///
/// Modeled after Pokemon elemental types. Most scaffolds carry a single primary
/// type; the most pharmacologically interesting molecules (LSD, MDMA, ibogaine)
/// are dual-type or triple-type.
public enum PokeDrugType: String, Codable, Sendable, CaseIterable {
    /// 5-HT2A receptor agonism. Endogenous: serotonin.
    case serotonin

    /// Mu-opioid receptor agonism. Endogenous: beta-endorphin.
    case opioid

    /// DAT inhibition / dopamine release. Endogenous: dopamine.
    case dopamine

    /// SERT release (serotonin flood). Endogenous: serotonin.
    case empathogen

    /// NMDA receptor antagonism. Endogenous: glutamate (blocked).
    case dissociative

    /// CB1/CB2 receptor agonism. Endogenous: anandamide.
    case cannabinoid

    /// Kappa-opioid receptor agonism. Endogenous: dynorphin.
    case kappa

    /// NET release / DAT release. Endogenous: norepinephrine.
    case stimulant

    /// GABA-A receptor positive allosteric modulation. Endogenous: GABA.
    case sedative

    /// nAChR agonism or mAChR antagonism. Endogenous: acetylcholine.
    case cholinergic

    /// A1/A2A adenosine receptor antagonism. Endogenous: adenosine.
    case adenosine

    /// Sigma-1/2 receptor modulation. Endogenous: neurosteroids.
    case sigma
}

// MARK: - Metadata

extension PokeDrugType {

    /// The primary pharmacological target for this type.
    public var pharmacologicalTarget: LocalizedString {
        switch self {
        case .serotonin:
            return LocalizedString(
                en: "5-HT2A receptor (agonism)", fr: "Recepteur 5-HT2A (agonisme)",
                es: "Receptor 5-HT2A (agonismo)", ja: "5-HT2A受容体（アゴニズム）",
                zh: "5-HT2A受体（激动）", ko: "5-HT2A 수용체 (작용제)",
                ru: "Рецептор 5-HT2A (агонизм)", de: "5-HT2A-Rezeptor (Agonismus)",
                ar: "مستقبل 5-HT2A (ناهض)")
        case .opioid:
            return LocalizedString(
                en: "Mu-opioid receptor (agonism)", fr: "Recepteur mu-opioide (agonisme)",
                es: "Receptor mu-opioide (agonismo)", ja: "μオピオイド受容体（アゴニズム）",
                zh: "μ阿片受体（激动）", ko: "μ-오피오이드 수용체 (작용제)",
                ru: "Мю-опиоидный рецептор (агонизм)", de: "Mu-Opioid-Rezeptor (Agonismus)",
                ar: "مستقبل مو-أفيوني (ناهض)")
        case .dopamine:
            return LocalizedString(
                en: "DAT inhibition / DA release", fr: "Inhibition du DAT / liberation de DA",
                es: "Inhibición del DAT / liberación de DA", ja: "DAT阻害 / DA放出",
                zh: "DAT抑制 / DA释放", ko: "DAT 억제 / DA 방출",
                ru: "Ингибирование DAT / высвобождение DA", de: "DAT-Hemmung / DA-Freisetzung",
                ar: "تثبيط DAT / إطلاق DA")
        case .empathogen:
            return LocalizedString(
                en: "SERT release (serotonin flood)", fr: "Liberation du SERT (inondation de serotonine)",
                es: "Liberación del SERT (inundación de serotonina)", ja: "SERT放出（セロトニン氾濫）",
                zh: "SERT释放（血清素泛滥）", ko: "SERT 방출 (세로토닌 범람)",
                ru: "Высвобождение SERT (серотониновый выброс)", de: "SERT-Freisetzung (Serotonin-Flut)",
                ar: "إطلاق SERT (فيضان السيروتونين)")
        case .dissociative:
            return LocalizedString(
                en: "NMDA receptor (antagonism)", fr: "Recepteur NMDA (antagonisme)",
                es: "Receptor NMDA (antagonismo)", ja: "NMDA受容体（拮抗）",
                zh: "NMDA受体（拮抗）", ko: "NMDA 수용체 (길항제)",
                ru: "Рецептор NMDA (антагонизм)", de: "NMDA-Rezeptor (Antagonismus)",
                ar: "مستقبل NMDA (مضاد)")
        case .cannabinoid:
            return LocalizedString(
                en: "CB1/CB2 receptor (agonism)", fr: "Recepteur CB1/CB2 (agonisme)",
                es: "Receptor CB1/CB2 (agonismo)", ja: "CB1/CB2受容体（アゴニズム）",
                zh: "CB1/CB2受体（激动）", ko: "CB1/CB2 수용체 (작용제)",
                ru: "Рецептор CB1/CB2 (агонизм)", de: "CB1/CB2-Rezeptor (Agonismus)",
                ar: "مستقبل CB1/CB2 (ناهض)")
        case .kappa:
            return LocalizedString(
                en: "Kappa-opioid receptor (agonism)", fr: "Recepteur kappa-opioide (agonisme)",
                es: "Receptor kappa-opioide (agonismo)", ja: "κオピオイド受容体（アゴニズム）",
                zh: "κ阿片受体（激动）", ko: "κ-오피오이드 수용체 (작용제)",
                ru: "Каппа-опиоидный рецептор (агонизм)", de: "Kappa-Opioid-Rezeptor (Agonismus)",
                ar: "مستقبل كابا-أفيوني (ناهض)")
        case .stimulant:
            return LocalizedString(
                en: "NET release / DAT release", fr: "Liberation du NET / liberation du DAT",
                es: "Liberación del NET / liberación del DAT", ja: "NET放出 / DAT放出",
                zh: "NET释放 / DAT释放", ko: "NET 방출 / DAT 방출",
                ru: "Высвобождение NET / высвобождение DAT", de: "NET-Freisetzung / DAT-Freisetzung",
                ar: "إطلاق NET / إطلاق DAT")
        case .sedative:
            return LocalizedString(
                en: "GABA-A receptor (PAM)", fr: "Recepteur GABA-A (MAP)",
                es: "Receptor GABA-A (MAP)", ja: "GABA-A受容体（PAM）",
                zh: "GABA-A受体（PAM）", ko: "GABA-A 수용체 (PAM)",
                ru: "Рецептор ГАМК-А (ПАМ)", de: "GABA-A-Rezeptor (PAM)",
                ar: "مستقبل GABA-A (معدّل تآزري إيجابي)")
        case .cholinergic:
            return LocalizedString(
                en: "nAChR agonism / mAChR antagonism", fr: "Agonisme nAChR / antagonisme mAChR",
                es: "Agonismo nAChR / antagonismo mAChR", ja: "nAChRアゴニズム / mAChR拮抗",
                zh: "nAChR激动 / mAChR拮抗", ko: "nAChR 작용 / mAChR 길항",
                ru: "Агонизм nAChR / антагонизм mAChR", de: "nAChR-Agonismus / mAChR-Antagonismus",
                ar: "ناهض nAChR / مضاد mAChR")
        case .adenosine:
            return LocalizedString(
                en: "A1/A2A receptor antagonism", fr: "Antagonisme du recepteur A1/A2A",
                es: "Antagonismo del receptor A1/A2A", ja: "A1/A2A受容体拮抗",
                zh: "A1/A2A受体拮抗", ko: "A1/A2A 수용체 길항",
                ru: "Антагонизм рецептора A1/A2A", de: "A1/A2A-Rezeptor-Antagonismus",
                ar: "مضاد مستقبل A1/A2A")
        case .sigma:
            return LocalizedString(
                en: "Sigma-1/2 receptor", fr: "Recepteur sigma-1/2",
                es: "Receptor sigma-1/2", ja: "シグマ1/2受容体",
                zh: "σ-1/2受体", ko: "시그마-1/2 수용체",
                ru: "Рецептор сигма-1/2", de: "Sigma-1/2-Rezeptor",
                ar: "مستقبل سيغما-1/2")
        }
    }

    /// The endogenous ligand for the target receptor.
    public var endogenousLigand: LocalizedString {
        switch self {
        case .serotonin:
            return LocalizedString(
                en: "Serotonin", fr: "Serotonine",
                es: "Serotonina", ja: "セロトニン",
                zh: "血清素", ko: "세로토닌",
                ru: "Серотонин", de: "Serotonin",
                ar: "سيروتونين")
        case .opioid:
            return LocalizedString(
                en: "Beta-endorphin", fr: "Beta-endorphine",
                es: "Beta-endorfina", ja: "β-エンドルフィン",
                zh: "β-内啡肽", ko: "베타-엔돌핀",
                ru: "Бета-эндорфин", de: "Beta-Endorphin",
                ar: "بيتا إندورفين")
        case .dopamine:
            return LocalizedString(
                en: "Dopamine", fr: "Dopamine",
                es: "Dopamina", ja: "ドーパミン",
                zh: "多巴胺", ko: "도파민",
                ru: "Дофамин", de: "Dopamin",
                ar: "دوبامين")
        case .empathogen:
            return LocalizedString(
                en: "Serotonin", fr: "Serotonine",
                es: "Serotonina", ja: "セロトニン",
                zh: "血清素", ko: "세로토닌",
                ru: "Серотонин", de: "Serotonin",
                ar: "سيروتونين")
        case .dissociative:
            return LocalizedString(
                en: "Glutamate (blocked)", fr: "Glutamate (bloque)",
                es: "Glutamato (bloqueado)", ja: "グルタミン酸（遮断）",
                zh: "谷氨酸（被阻断）", ko: "글루타메이트 (차단됨)",
                ru: "Глутамат (заблокирован)", de: "Glutamat (blockiert)",
                ar: "غلوتامات (محظور)")
        case .cannabinoid:
            return LocalizedString(
                en: "Anandamide", fr: "Anandamide",
                es: "Anandamida", ja: "アナンダミド",
                zh: "花生四烯乙醇胺", ko: "아난다마이드",
                ru: "Анандамид", de: "Anandamid",
                ar: "أنانداميد")
        case .kappa:
            return LocalizedString(
                en: "Dynorphin", fr: "Dynorphine",
                es: "Dinorfina", ja: "ダイノルフィン",
                zh: "强啡肽", ko: "다이노르핀",
                ru: "Динорфин", de: "Dynorphin",
                ar: "داينورفين")
        case .stimulant:
            return LocalizedString(
                en: "Norepinephrine", fr: "Noradrenaline",
                es: "Norepinefrina", ja: "ノルエピネフリン",
                zh: "去甲肾上腺素", ko: "노르에피네프린",
                ru: "Норэпинефрин", de: "Noradrenalin",
                ar: "نورإبينفرين")
        case .sedative:
            return LocalizedString(
                en: "GABA", fr: "GABA",
                es: "GABA", ja: "GABA",
                zh: "GABA", ko: "GABA",
                ru: "ГАМК", de: "GABA",
                ar: "GABA")
        case .cholinergic:
            return LocalizedString(
                en: "Acetylcholine", fr: "Acetylcholine",
                es: "Acetilcolina", ja: "アセチルコリン",
                zh: "乙酰胆碱", ko: "아세틸콜린",
                ru: "Ацетилхолин", de: "Acetylcholin",
                ar: "أستيل كولين")
        case .adenosine:
            return LocalizedString(
                en: "Adenosine", fr: "Adenosine",
                es: "Adenosina", ja: "アデノシン",
                zh: "腺苷", ko: "아데노신",
                ru: "Аденозин", de: "Adenosin",
                ar: "أدينوسين")
        case .sigma:
            return LocalizedString(
                en: "Neurosteroids", fr: "Neurosteroides",
                es: "Neuroesteroides", ja: "ニューロステロイド",
                zh: "神经甾体", ko: "신경스테로이드",
                ru: "Нейростероиды", de: "Neurosteroide",
                ar: "ستيرويدات عصبية")
        }
    }

    /// The prototype drug that exemplifies this type.
    public var prototypeDrug: LocalizedString {
        switch self {
        case .serotonin:
            return LocalizedString(
                en: "Psilocin", fr: "Psilocine",
                es: "Psilocina", ja: "サイロシン",
                zh: "裸盖菇素", ko: "실로신",
                ru: "Псилоцин", de: "Psilocin",
                ar: "سيلوسين")
        case .opioid:
            return LocalizedString(
                en: "Morphine", fr: "Morphine",
                es: "Morfina", ja: "モルヒネ",
                zh: "吗啡", ko: "모르핀",
                ru: "Морфин", de: "Morphin",
                ar: "مورفين")
        case .dopamine:
            return LocalizedString(
                en: "Amphetamine", fr: "Amphetamine",
                es: "Anfetamina", ja: "アンフェタミン",
                zh: "苯丙胺", ko: "암페타민",
                ru: "Амфетамин", de: "Amphetamin",
                ar: "أمفيتامين")
        case .empathogen:
            return LocalizedString(
                en: "MDMA", fr: "MDMA",
                es: "MDMA", ja: "MDMA",
                zh: "MDMA", ko: "MDMA",
                ru: "МДМА", de: "MDMA",
                ar: "MDMA")
        case .dissociative:
            return LocalizedString(
                en: "Ketamine", fr: "Ketamine",
                es: "Ketamina", ja: "ケタミン",
                zh: "氯胺酮", ko: "케타민",
                ru: "Кетамин", de: "Ketamin",
                ar: "كيتامين")
        case .cannabinoid:
            return LocalizedString(
                en: "THC", fr: "THC",
                es: "THC", ja: "THC",
                zh: "THC", ko: "THC",
                ru: "ТГК", de: "THC",
                ar: "THC")
        case .kappa:
            return LocalizedString(
                en: "Salvinorin A", fr: "Salvinorine A",
                es: "Salvinorina A", ja: "サルビノリンA",
                zh: "鼠尾草素A", ko: "살비노린 A",
                ru: "Сальвинорин А", de: "Salvinorin A",
                ar: "سالفينورين أ")
        case .stimulant:
            return LocalizedString(
                en: "Cathinone", fr: "Cathinone",
                es: "Catinona", ja: "カチノン",
                zh: "卡西酮", ko: "카티논",
                ru: "Катинон", de: "Cathinon",
                ar: "كاثينون")
        case .sedative:
            return LocalizedString(
                en: "Apigenin", fr: "Apigenine",
                es: "Apigenina", ja: "アピゲニン",
                zh: "芹菜素", ko: "아피게닌",
                ru: "Апигенин", de: "Apigenin",
                ar: "أبيجينين")
        case .cholinergic:
            return LocalizedString(
                en: "Nicotine / Atropine", fr: "Nicotine / Atropine",
                es: "Nicotina / Atropina", ja: "ニコチン / アトロピン",
                zh: "尼古丁 / 阿托品", ko: "니코틴 / 아트로핀",
                ru: "Никотин / Атропин", de: "Nikotin / Atropin",
                ar: "نيكوتين / أتروبين")
        case .adenosine:
            return LocalizedString(
                en: "Caffeine", fr: "Cafeine",
                es: "Cafeína", ja: "カフェイン",
                zh: "咖啡因", ko: "카페인",
                ru: "Кофеин", de: "Koffein",
                ar: "كافيين")
        case .sigma:
            return LocalizedString(
                en: "DMT (secondary)", fr: "DMT (secondaire)",
                es: "DMT (secundario)", ja: "DMT（二次的）",
                zh: "DMT（次要）", ko: "DMT (이차적)",
                ru: "ДМТ (вторичный)", de: "DMT (sekundär)",
                ar: "DMT (ثانوي)")
        }
    }

    /// Hex color code for UI rendering.
    public var color: String {
        switch self {
        case .serotonin:    return "#7B68EE"  // Medium slate blue
        case .opioid:       return "#DC143C"  // Crimson
        case .dopamine:     return "#FF8C00"  // Dark orange
        case .empathogen:   return "#FF69B4"  // Hot pink
        case .dissociative: return "#4682B4"  // Steel blue
        case .cannabinoid:  return "#228B22"  // Forest green
        case .kappa:        return "#8B008B"  // Dark magenta
        case .stimulant:    return "#FFD700"  // Gold
        case .sedative:     return "#6B8E23"  // Olive drab
        case .cholinergic:  return "#CD853F"  // Peru
        case .adenosine:    return "#8B4513"  // Saddle brown
        case .sigma:        return "#708090"  // Slate gray
        }
    }
}
