import Foundation

/// The ten core molecular scaffolds that function as PokeDrug "species."
///
/// Each scaffold is a recognizable structural chassis that determines which
/// PokeDrug types a compound can express. The scaffold predicts receptor affinity
/// more reliably than any other single variable, because selectivity arises from
/// structural mimicry of endogenous ligands.
public enum MolecularScaffold: String, Codable, Sendable, CaseIterable {
    /// Indole core + ethylamine sidechain. Serotonin itself is a tryptamine.
    /// Ki at 5-HT2A: psilocin 25-107 nM, DMT 77-360 nM.
    case tryptamine

    /// Fused tetracyclic indole. Tryptamine's "final evolution" — locked into
    /// optimal binding conformation. LSD Ki at 5-HT2A: 3-7 nM.
    case ergoline

    /// Pentacyclic morphinan mimics enkephalin Tyr1 residue.
    /// Morphine Ki at MOR: 1.2-14 nM.
    case morphinan

    /// Minimalist scaffold: phenyl ring + 2-carbon chain + amine.
    /// Parent structure of dopamine, norepinephrine, epinephrine.
    case phenethylamine

    /// Rigid bicyclic ring supporting DAT block (cocaine) or mAChR antagonism (atropine).
    case tropane

    /// Phytocannabinoid or neoclerodane diterpene scaffold.
    /// THC Ki at CB1: 5-80 nM. Salvinorin A Ki at KOR: 1.9 nM.
    case terpenoid

    /// Benzylisoquinoline — biosynthetic precursor to morphinan.
    /// Diverse non-CNS activities; morphinan's less-specialized ancestor.
    case isoquinoline

    /// 3,4-Methylenedioxy substitution pattern. Shifts SERT/DAT selectivity
    /// toward empathogenic profile. MDMA SERT/DAT ratio ~10:1.
    case benzodioxole

    /// Purine derivative structurally related to adenosine.
    /// Caffeine Ki at A1: ~12 uM, A2A: ~2.4-44 uM.
    case xanthine

    /// Complex polycyclic isoquinuclidine framework from Tabernanthe iboga.
    /// Hits alpha3beta4 nAChR (Ki ~20 nM), NMDA (~10-50 nM), sigma-2 (~90-200 nM),
    /// SERT (~500 nM), MOR (~130 nM), KOR (~2-4 uM).
    case iboga

    /// 1,4-Benzodiazepine fused ring system. Positive allosteric modulator of GABA-A
    /// at a site distinct from GABA binding. Diazepam Ki ~3-20 nM at BZD site.
    case benzodiazepine

    /// Tricyclic beta-carboline (pyrido[3,4-b]indole). Reversible MAO-A inhibitor
    /// and 5-HT2A ligand. Harmine Ki ~5 nM at MAO-A, ~300 nM at 5-HT2A.
    case betaCarboline

    /// Isoxazole-containing amino acid from Amanita muscaria.
    /// Direct GABA-A orthosteric agonist (binds the GABA site, not the BZD site).
    /// Muscimol Ki ~6-10 nM at GABA-A. Distinct from benzodiazepine modulation.
    case isoxazole
}

// MARK: - Metadata

extension MolecularScaffold {

    /// The primary PokeDrug type(s) this scaffold expresses.
    public var primaryTypes: [PokeDrugType] {
        switch self {
        case .tryptamine:       return [.serotonin]
        case .ergoline:         return [.serotonin, .dopamine]
        case .morphinan:        return [.opioid]
        case .phenethylamine:   return [.dopamine]
        case .tropane:          return [.dopamine]
        case .terpenoid:        return [.cannabinoid]
        case .isoquinoline:     return [.cholinergic]
        case .benzodioxole:     return [.empathogen]
        case .xanthine:         return [.adenosine]
        case .iboga:            return [.opioid, .dissociative, .empathogen]
        case .benzodiazepine:   return [.sedative]
        case .betaCarboline:    return [.serotonin]
        case .isoxazole:        return [.sedative]
        }
    }

    /// Display name.
    public var displayName: LocalizedString {
        switch self {
        case .tryptamine:
            return LocalizedString(
                en: "Tryptamine", fr: "Tryptamine",
                es: "Triptamina", ja: "トリプタミン",
                zh: "色胺", ko: "트립타민",
                ru: "Триптамин", de: "Tryptamin",
                ar: "تريبتامين")
        case .ergoline:
            return LocalizedString(
                en: "Ergoline", fr: "Ergoline",
                es: "Ergolina", ja: "エルゴリン",
                zh: "麦角灵", ko: "에르골린",
                ru: "Эрголин", de: "Ergolin",
                ar: "إرغولين")
        case .morphinan:
            return LocalizedString(
                en: "Morphinan", fr: "Morphinane",
                es: "Morfinano", ja: "モルフィナン",
                zh: "吗啡烷", ko: "모르피난",
                ru: "Морфинан", de: "Morphinan",
                ar: "مورفينان")
        case .phenethylamine:
            return LocalizedString(
                en: "Phenethylamine", fr: "Phenethylamine",
                es: "Feniletilamina", ja: "フェネチルアミン",
                zh: "苯乙胺", ko: "페네틸아민",
                ru: "Фенэтиламин", de: "Phenethylamin",
                ar: "فينيثيلامين")
        case .tropane:
            return LocalizedString(
                en: "Tropane", fr: "Tropane",
                es: "Tropano", ja: "トロパン",
                zh: "托烷", ko: "트로판",
                ru: "Тропан", de: "Tropan",
                ar: "تروبان")
        case .terpenoid:
            return LocalizedString(
                en: "Terpenoid", fr: "Terpenoide",
                es: "Terpenoide", ja: "テルペノイド",
                zh: "萜类", ko: "테르페노이드",
                ru: "Терпеноид", de: "Terpenoid",
                ar: "تربينويد")
        case .isoquinoline:
            return LocalizedString(
                en: "Isoquinoline", fr: "Isoquinoline",
                es: "Isoquinolina", ja: "イソキノリン",
                zh: "异喹啉", ko: "이소퀴놀린",
                ru: "Изохинолин", de: "Isochinolin",
                ar: "أيزوكينولين")
        case .benzodioxole:
            return LocalizedString(
                en: "Benzodioxole", fr: "Benzodioxole",
                es: "Benzodioxol", ja: "ベンゾジオキソール",
                zh: "苯并二噁唑", ko: "벤조디옥솔",
                ru: "Бензодиоксол", de: "Benzodioxol",
                ar: "بنزوديوكسول")
        case .xanthine:
            return LocalizedString(
                en: "Xanthine", fr: "Xanthine",
                es: "Xantina", ja: "キサンチン",
                zh: "黄嘌呤", ko: "크산틴",
                ru: "Ксантин", de: "Xanthin",
                ar: "زانثين")
        case .iboga:
            return LocalizedString(
                en: "Iboga Alkaloid", fr: "Alcaloide d'iboga",
                es: "Alcaloide de iboga", ja: "イボガアルカロイド",
                zh: "伊博加生物碱", ko: "이보가 알칼로이드",
                ru: "Алкалоид ибоги", de: "Iboga-Alkaloid",
                ar: "قلويد إيبوغا")
        case .benzodiazepine:
            return LocalizedString(
                en: "Benzodiazepine", fr: "Benzodiazepine",
                es: "Benzodiazepina", ja: "ベンゾジアゼピン",
                zh: "苯二氮卓", ko: "벤조디아제핀",
                ru: "Бензодиазепин", de: "Benzodiazepin",
                ar: "بنزوديازيبين")
        case .betaCarboline:
            return LocalizedString(
                en: "Beta-Carboline", fr: "Beta-Carboline",
                es: "Beta-Carbolina", ja: "β-カルボリン",
                zh: "β-咔啉", ko: "베타-카르볼린",
                ru: "Бета-карболин", de: "Beta-Carbolin",
                ar: "بيتا كاربولين")
        case .isoxazole:
            return LocalizedString(
                en: "Isoxazole", fr: "Isoxazole",
                es: "Isoxazol", ja: "イソオキサゾール",
                zh: "异噁唑", ko: "이속사졸",
                ru: "Изоксазол", de: "Isoxazol",
                ar: "إيزوكسازول")
        }
    }

    /// Core structural description.
    public var coreStructure: LocalizedString {
        switch self {
        case .tryptamine:
            return LocalizedString(
                en: "Indole ring + 2-carbon aminoethyl sidechain",
                fr: "Noyau indole + chaine aminoethyle a 2 carbones",
                es: "Anillo indol + cadena lateral aminoetilo de 2 carbonos",
                ja: "インドール環 + 2炭素アミノエチル側鎖",
                zh: "吲哚环 + 2碳氨基乙基侧链",
                ko: "인돌 고리 + 2탄소 아미노에틸 측쇄",
                ru: "Индольное кольцо + 2-углеродная аминоэтильная боковая цепь",
                de: "Indolring + 2-Kohlenstoff-Aminoethyl-Seitenkette",
                ar: "حلقة إندول + سلسلة أمينوإيثيل جانبية ثنائية الكربون")
        case .ergoline:
            return LocalizedString(
                en: "Rigid tetracyclic ring system (fused indole)",
                fr: "Systeme tetracyclique rigide (indole fusionne)",
                es: "Sistema tetracíclico rígido (indol fusionado)",
                ja: "剛直な四環式環系（縮合インドール）",
                zh: "刚性四环环系（稠合吲哚）",
                ko: "강직성 사환 고리계 (융합 인돌)",
                ru: "Жёсткая тетрациклическая кольцевая система (конденсированный индол)",
                de: "Starres tetracyclisches Ringsystem (fusioniertes Indol)",
                ar: "نظام حلقي رباعي صلب (إندول مندمج)")
        case .morphinan:
            return LocalizedString(
                en: "Pentacyclic phenanthrene with basic nitrogen",
                fr: "Phenanthrene pentacyclique avec azote basique",
                es: "Fenantreno pentacíclico con nitrógeno básico",
                ja: "塩基性窒素を持つ五環式フェナントレン",
                zh: "含碱性氮的五环菲",
                ko: "염기성 질소를 가진 오환 페난트렌",
                ru: "Пентациклический фенантрен с основным азотом",
                de: "Pentacyclisches Phenanthren mit basischem Stickstoff",
                ar: "فينانثرين خماسي الحلقات مع نيتروجين قاعدي")
        case .phenethylamine:
            return LocalizedString(
                en: "Phenyl ring + 2-carbon chain + amine",
                fr: "Cycle phenyle + chaine a 2 carbones + amine",
                es: "Anillo fenilo + cadena de 2 carbonos + amina",
                ja: "フェニル環 + 2炭素鎖 + アミン",
                zh: "苯环 + 2碳链 + 胺",
                ko: "페닐 고리 + 2탄소 사슬 + 아민",
                ru: "Фенильное кольцо + 2-углеродная цепь + амин",
                de: "Phenylring + 2-Kohlenstoff-Kette + Amin",
                ar: "حلقة فينيل + سلسلة ثنائية الكربون + أمين")
        case .tropane:
            return LocalizedString(
                en: "Rigid bicyclic 8-azabicyclo[3.2.1]octane",
                fr: "Bicyclique rigide 8-azabicyclo[3.2.1]octane",
                es: "8-azabiciclo[3.2.1]octano bicíclico rígido",
                ja: "剛直な二環式8-アザビシクロ[3.2.1]オクタン",
                zh: "刚性双环8-氮杂双环[3.2.1]辛烷",
                ko: "강직성 이환 8-아자비시클로[3.2.1]옥탄",
                ru: "Жёсткий бициклический 8-азабицикло[3.2.1]октан",
                de: "Starres bicyclisches 8-Azabicyclo[3.2.1]octan",
                ar: "8-آزابيسيكلو[3.2.1]أوكتان ثنائي الحلقات صلب")
        case .terpenoid:
            return LocalizedString(
                en: "Monoterpenoid C-ring fused to resorcinol via pyran",
                fr: "Anneau C terpenoide fusionne au resorcinol via pyrane",
                es: "Anillo C monoterpenoide fusionado al resorcinol vía pirano",
                ja: "ピラン環を介してレゾルシノールに縮合したモノテルペノイドC環",
                zh: "单萜C环通过吡喃与间苯二酚稠合",
                ko: "피란을 통해 레조르시놀에 융합된 모노테르페노이드 C-고리",
                ru: "Монотерпеноидное C-кольцо, конденсированное с резорцинолом через пиран",
                de: "Monoterpenoid-C-Ring fusioniert mit Resorcin über Pyran",
                ar: "حلقة C مونوتربينويد مندمجة مع الريزورسينول عبر البيران")
        case .isoquinoline:
            return LocalizedString(
                en: "Benzylisoquinoline — morphinan biosynthetic precursor",
                fr: "Benzylisoquinoline — precurseur biosynthetique du morphinane",
                es: "Bencilisoquinolina — precursor biosintético del morfinano",
                ja: "ベンジルイソキノリン — モルフィナン生合成前駆体",
                zh: "苄基异喹啉 — 吗啡烷生物合成前体",
                ko: "벤질이소퀴놀린 — 모르피난 생합성 전구체",
                ru: "Бензилизохинолин — биосинтетический предшественник морфинана",
                de: "Benzylisochinolin — Morphinan-Biosynthese-Vorläufer",
                ar: "بنزيل إيزوكينولين — سلف التخليق الحيوي للمورفينان")
        case .benzodioxole:
            return LocalizedString(
                en: "3,4-Methylenedioxy ring on phenethylamine backbone",
                fr: "Anneau 3,4-methylenedioxy sur squelette phenethylamine",
                es: "Anillo 3,4-metilendioxi sobre esqueleto de feniletilamina",
                ja: "フェネチルアミン骨格上の3,4-メチレンジオキシ環",
                zh: "苯乙胺骨架上的3,4-亚甲二氧基环",
                ko: "페네틸아민 골격 위의 3,4-메틸렌디옥시 고리",
                ru: "3,4-Метилендиоксильное кольцо на каркасе фенэтиламина",
                de: "3,4-Methylendioxyring auf Phenethylamin-Gerüst",
                ar: "حلقة 3,4-ميثيلين ديوكسي على هيكل فينيثيلأمين")
        case .xanthine:
            return LocalizedString(
                en: "Purine derivative (1,3,7-trimethylxanthine for caffeine)",
                fr: "Derive purique (1,3,7-trimethylxanthine pour la cafeine)",
                es: "Derivado purínico (1,3,7-trimetilxantina para la cafeína)",
                ja: "プリン誘導体（カフェインは1,3,7-トリメチルキサンチン）",
                zh: "嘌呤衍生物（咖啡因为1,3,7-三甲基黄嘌呤）",
                ko: "퓨린 유도체 (카페인은 1,3,7-트리메틸크산틴)",
                ru: "Производное пурина (1,3,7-триметилксантин для кофеина)",
                de: "Purinderivat (1,3,7-Trimethylxanthin für Koffein)",
                ar: "مشتق بيورين (1,3,7-ثلاثي ميثيل زانثين للكافيين)")
        case .iboga:
            return LocalizedString(
                en: "Polycyclic isoquinuclidine with embedded indole",
                fr: "Isoquinuclidine polycyclique avec indole integre",
                es: "Isoquinuclidina policíclica con indol integrado",
                ja: "インドールが組み込まれた多環式イソキヌクリジン",
                zh: "嵌入吲哚的多环异喹啶",
                ko: "인돌이 내장된 다환 이소퀴누클리딘",
                ru: "Полициклический изохинуклидин со встроенным индолом",
                de: "Polycyclisches Isochinuclidin mit eingebettetem Indol",
                ar: "إيزوكينوكليدين متعدد الحلقات مع إندول مدمج")
        case .benzodiazepine:
            return LocalizedString(
                en: "1,4-Benzodiazepine fused ring (benzene + 7-membered diazepine)",
                fr: "Anneau fusionne 1,4-benzodiazepine (benzene + diazepine a 7 chainons)",
                es: "Anillo fusionado 1,4-benzodiazepina (benceno + diazepina de 7 miembros)",
                ja: "1,4-ベンゾジアゼピン縮合環（ベンゼン + 7員ジアゼピン）",
                zh: "1,4-苯二氮卓稠合环（苯环 + 7元二氮杂环）",
                ko: "1,4-벤조디아제핀 융합 고리 (벤젠 + 7원 디아제핀)",
                ru: "Конденсированное кольцо 1,4-бензодиазепина (бензол + 7-членный диазепин)",
                de: "1,4-Benzodiazepin-Ringfusion (Benzol + 7-gliedriges Diazepin)",
                ar: "حلقة 1,4-بنزوديازيبين مندمجة (بنزين + ديازيبين سباعي الأعضاء)")
        case .betaCarboline:
            return LocalizedString(
                en: "Pyrido[3,4-b]indole tricyclic system",
                fr: "Systeme tricyclique pyrido[3,4-b]indole",
                es: "Sistema tricíclico pirido[3,4-b]indol",
                ja: "ピリド[3,4-b]インドール三環系",
                zh: "吡啶并[3,4-b]吲哚三环体系",
                ko: "피리도[3,4-b]인돌 삼환계",
                ru: "Трициклическая система пиридо[3,4-b]индола",
                de: "Pyrido[3,4-b]indol-Trizyklus",
                ar: "نظام ثلاثي الحلقات بيريدو[3,4-ب]إندول")
        case .isoxazole:
            return LocalizedString(
                en: "3-Hydroxy-5-aminomethylisoxazole (GABA bioisostere)",
                fr: "3-Hydroxy-5-aminomethylisoxazole (bioisostere du GABA)",
                es: "3-Hidroxi-5-aminometilisoxazol (bioisóstero del GABA)",
                ja: "3-ヒドロキシ-5-アミノメチルイソオキサゾール（GABAバイオアイソスター）",
                zh: "3-羟基-5-氨甲基异噁唑（GABA生物等排体）",
                ko: "3-하이드록시-5-아미노메틸이속사졸 (GABA 생물동등체)",
                ru: "3-Гидрокси-5-аминометилизоксазол (биоизостер ГАМК)",
                de: "3-Hydroxy-5-aminomethylisoxazol (GABA-Bioisoster)",
                ar: "3-هيدروكسي-5-أمينوميثيل إيزوكسازول (بديل حيوي متساوي لـ GABA)")
        }
    }
}
