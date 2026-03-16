import Foundation

/// Natural biogeographic origins of psychoactive molecular scaffolds.
///
/// Each habitat represents an ecosystem where specific scaffolds evolved
/// in nature, creating a natural pharmacogeography of psychoactive chemistry.
public enum PokeDrugHabitat: String, Codable, Sendable, CaseIterable {
    /// Temperate/subtropical mushroom habitats. Home of tryptamine and ergoline
    /// lineages. Over 200 Psilocybe species produce psilocybin via a four-enzyme
    /// cluster that arose ~65 million years ago.
    case fungalForest

    /// Amazon basin, equatorial forests. The most scaffold-diverse habitat.
    /// Psychotria viridis (DMT), Erythroxylum coca (cocaine),
    /// Banisteriopsis caapi (beta-carboline MAOIs).
    case tropicalJungle

    /// Chihuahuan Desert, Andean slopes. Domain of phenethylamine psychedelics.
    /// Lophophora williamsii (peyote/mescaline), Echinopsis pachanoi (San Pedro).
    /// 5,700+ years of documented ceremonial use.
    case desertMesa

    /// Fertile Crescent through East Asia. Origin of the morphinan scaffold.
    /// Papaver somniferum (morphine, 17-enzyme 19-step pathway),
    /// Ephedra sinica (ephedrine), Camellia sinensis (caffeine).
    case asianHighlands

    /// Equatorial West Africa. Home of the iboga alkaloid.
    /// Tabernanthe iboga (ibogaine), Catha edulis (cathinone/khat).
    /// Bwiti spiritual tradition in Gabon.
    case africanRainforest

    /// Hindu Kush / Altai region. Ancestral home of Cannabis sativa.
    /// Cannabinoids via olivetolic acid + geranyl pyrophosphate -> CBGA pathway.
    case centralAsianSteppe

    /// Pan-tropical. Caffeine evolved independently at least five times:
    /// Coffea (Ethiopia), Camellia (China), Theobroma (Amazon),
    /// Paullinia (Amazon), Ilex (South America).
    case tropicalPlantations
}

// MARK: - Metadata

extension PokeDrugHabitat {

    /// Display name.
    public var displayName: LocalizedString {
        switch self {
        case .fungalForest:
            return LocalizedString(
                en: "Fungal Forest", fr: "Foret fongique",
                es: "Bosque Fúngico", ja: "菌類の森",
                zh: "真菌森林", ko: "균류의 숲",
                ru: "Грибной лес", de: "Pilzwald",
                ar: "غابة فطرية")
        case .tropicalJungle:
            return LocalizedString(
                en: "Tropical Jungle", fr: "Jungle tropicale",
                es: "Selva Tropical", ja: "熱帯ジャングル",
                zh: "热带丛林", ko: "열대 정글",
                ru: "Тропические джунгли", de: "Tropischer Dschungel",
                ar: "أدغال استوائية")
        case .desertMesa:
            return LocalizedString(
                en: "Desert Mesa", fr: "Mesa desertique",
                es: "Meseta Desértica", ja: "砂漠の台地",
                zh: "沙漠台地", ko: "사막 대지",
                ru: "Пустынное плато", de: "Wüstenplateau",
                ar: "هضبة صحراوية")
        case .asianHighlands:
            return LocalizedString(
                en: "Asian Highlands", fr: "Hauts plateaux asiatiques",
                es: "Altiplanos Asiáticos", ja: "アジア高原",
                zh: "亚洲高原", ko: "아시아 고원",
                ru: "Азиатское нагорье", de: "Asiatisches Hochland",
                ar: "المرتفعات الآسيوية")
        case .africanRainforest:
            return LocalizedString(
                en: "African Rainforest", fr: "Foret pluviale africaine",
                es: "Selva Africana", ja: "アフリカ熱帯雨林",
                zh: "非洲热带雨林", ko: "아프리카 열대우림",
                ru: "Африканский тропический лес", de: "Afrikanischer Regenwald",
                ar: "الغابة الاستوائية الأفريقية")
        case .centralAsianSteppe:
            return LocalizedString(
                en: "Central Asian Steppe", fr: "Steppe d'Asie centrale",
                es: "Estepa de Asia Central", ja: "中央アジアのステップ",
                zh: "中亚草原", ko: "중앙아시아 스텝",
                ru: "Центральноазиатская степь", de: "Zentralasiatische Steppe",
                ar: "سهوب آسيا الوسطى")
        case .tropicalPlantations:
            return LocalizedString(
                en: "Tropical Plantations", fr: "Plantations tropicales",
                es: "Plantaciones Tropicales", ja: "熱帯プランテーション",
                zh: "热带种植园", ko: "열대 농장",
                ru: "Тропические плантации", de: "Tropische Plantagen",
                ar: "مزارع استوائية")
        }
    }

    /// Habitat description.
    public var description: LocalizedString {
        switch self {
        case .fungalForest:
            return LocalizedString(
                en: "Temperate and subtropical mushroom habitats producing tryptamine and ergoline alkaloids via L-tryptophan biosynthesis.",
                fr: "Habitats fongiques temperes et subtropicaux produisant des alcaloides tryptamine et ergoline via la biosynthese du L-tryptophane.",
                es: "Hábitats de hongos templados y subtropicales que producen alcaloides de triptamina y ergolina mediante biosíntesis de L-triptófano.",
                ja: "L-トリプトファン生合成によりトリプタミンおよびエルゴリンアルカロイドを産生する温帯・亜熱帯のキノコ生息地。",
                zh: "通过L-色氨酸生物合成产生色胺和麦角灵生物碱的温带和亚热带真菌栖息地。",
                ko: "L-트립토판 생합성을 통해 트립타민 및 에르골린 알칼로이드를 생산하는 온대 및 아열대 버섯 서식지.",
                ru: "Грибные местообитания умеренного и субтропического климата, продуцирующие триптаминовые и эрголиновые алкалоиды путём биосинтеза из L-триптофана.",
                de: "Gemäßigte und subtropische Pilzbiotope, die Tryptamin- und Ergolin-Alkaloide über L-Tryptophan-Biosynthese produzieren.",
                ar: "موائل فطرية معتدلة وشبه استوائية تنتج قلويدات التريبتامين والإرغولين عبر التخليق الحيوي لـ L-تريبتوفان.")
        case .tropicalJungle:
            return LocalizedString(
                en: "The most scaffold-diverse habitat, hosting DMT (chacruna), cocaine (coca), and beta-carboline MAOIs (ayahuasca vine).",
                fr: "L'habitat le plus diversifie en structures, abritant le DMT (chacruna), la cocaine (coca) et les IMAO beta-carbolines (liane d'ayahuasca).",
                es: "El hábitat más diverso en estructuras, albergando DMT (chacruna), cocaína (coca) y los IMAO beta-carbolinas (liana de ayahuasca).",
                ja: "最も骨格多様性の高い生息地。DMT（チャクルナ）、コカイン（コカ）、β-カルボリンMAOI（アヤワスカ蔓）を宿す。",
                zh: "骨架多样性最丰富的栖息地，包括DMT（恰克鲁纳）、可卡因（古柯）和β-咔啉MAOIs（死藤水藤）。",
                ko: "가장 다양한 골격을 보유한 서식지로, DMT(차크루나), 코카인(코카), 베타-카르볼린 MAOIs(아야와스카 덩굴)를 포함.",
                ru: "Самая разнообразная по скаффолдам среда обитания, содержащая ДМТ (чакруна), кокаин (кока) и бета-карболиновые ИМАО (лиана аяуаски).",
                de: "Der scaffoldreichste Lebensraum mit DMT (Chacruna), Kokain (Coca) und Beta-Carbolin-MAOIs (Ayahuasca-Liane).",
                ar: "الموئل الأكثر تنوعاً في الهياكل الجزيئية، يضم DMT (تشاكرونا) والكوكايين (كوكا) ومثبطات MAO بيتا كاربولين (كرمة الأياهواسكا).")
        case .desertMesa:
            return LocalizedString(
                en: "Arid landscapes where cacti synthesize mescaline from tyrosine. Peyote and San Pedro ceremonies span 5,700+ years.",
                fr: "Paysages arides ou les cactus synthetisent la mescaline a partir de la tyrosine. Les ceremonies du peyotl et de San Pedro s'etendent sur plus de 5 700 ans.",
                es: "Paisajes áridos donde los cactus sintetizan mescalina a partir de tirosina. Las ceremonias de peyote y San Pedro abarcan más de 5.700 años.",
                ja: "サボテンがチロシンからメスカリンを合成する乾燥地帯。ペヨーテとサンペドロの儀式は5,700年以上の歴史を持つ。",
                zh: "仙人掌从酪氨酸合成麦司卡林的干旱地带。佩奥特和圣佩德罗仪式跨越5700多年。",
                ko: "선인장이 티로신으로부터 메스칼린을 합성하는 건조 지대. 페요테와 산페드로 의식은 5,700년 이상의 역사를 가짐.",
                ru: "Засушливые ландшафты, где кактусы синтезируют мескалин из тирозина. Церемонии пейота и Сан-Педро насчитывают более 5700 лет.",
                de: "Trockene Landschaften, in denen Kakteen Mescalin aus Tyrosin synthetisieren. Peyote- und San-Pedro-Zeremonien reichen über 5.700 Jahre zurück.",
                ar: "مناظر طبيعية جافة حيث يصنع الصبار الميسكالين من التيروسين. تمتد طقوس البيوت وسان بيدرو لأكثر من 5700 عام.")
        case .asianHighlands:
            return LocalizedString(
                en: "Origin of the morphinan scaffold via Papaver somniferum's 17-enzyme, 19-step biosynthetic pathway from tyrosine.",
                fr: "Origine du squelette morphinane via la voie biosynthetique a 17 enzymes et 19 etapes du Papaver somniferum a partir de la tyrosine.",
                es: "Origen del esqueleto morfinano a través de la vía biosintética de 17 enzimas y 19 pasos del Papaver somniferum a partir de tirosina.",
                ja: "チロシンからのPapaver somniferumの17酵素・19段階生合成経路によるモルフィナン骨格の起源。",
                zh: "通过罂粟（Papaver somniferum）从酪氨酸出发的17酶19步生物合成途径产生的吗啡烷骨架的起源地。",
                ko: "티로신으로부터 양귀비(Papaver somniferum)의 17효소, 19단계 생합성 경로를 통한 모르피난 골격의 기원지.",
                ru: "Происхождение морфинанового каркаса через 17-ферментный, 19-ступенчатый биосинтетический путь Papaver somniferum из тирозина.",
                de: "Ursprung des Morphinan-Gerüsts über den 17-Enzym-, 19-Schritt-Biosyntheseweg von Papaver somniferum aus Tyrosin.",
                ar: "أصل هيكل المورفينان عبر مسار التخليق الحيوي المكون من 17 إنزيماً و19 خطوة لنبات الخشخاش المنوم من التيروسين.")
        case .africanRainforest:
            return LocalizedString(
                en: "Home of ibogaine (Tabernanthe iboga) and cathinone (Catha edulis). Bwiti spiritual tradition in Gabon.",
                fr: "Berceau de l'ibogaine (Tabernanthe iboga) et de la cathinone (Catha edulis). Tradition spirituelle Bwiti au Gabon.",
                es: "Hogar de la ibogaína (Tabernanthe iboga) y la catinona (Catha edulis). Tradición espiritual Bwiti en Gabón.",
                ja: "イボガイン（Tabernanthe iboga）とカチノン（Catha edulis）の故郷。ガボンのブウィティ精神的伝統。",
                zh: "伊博格碱（Tabernanthe iboga）和卡西酮（Catha edulis）的故乡。加蓬的布维提精神传统。",
                ko: "이보가인(Tabernanthe iboga)과 카티논(Catha edulis)의 고향. 가봉의 부위티 영적 전통.",
                ru: "Родина ибогаина (Tabernanthe iboga) и катинона (Catha edulis). Духовная традиция Бвити в Габоне.",
                de: "Heimat von Ibogain (Tabernanthe iboga) und Cathinon (Catha edulis). Bwiti-Spiritualtradition in Gabun.",
                ar: "موطن الإيبوغايين (Tabernanthe iboga) والكاثينون (Catha edulis). تقليد بويتي الروحاني في الغابون.")
        case .centralAsianSteppe:
            return LocalizedString(
                en: "Ancestral home of Cannabis sativa. THCA- and CBDA-synthases compete for the CBGA precursor.",
                fr: "Berceau ancestral du Cannabis sativa. Les THCA- et CBDA-synthases rivalisent pour le precurseur CBGA.",
                es: "Hogar ancestral del Cannabis sativa. Las sintasas de THCA y CBDA compiten por el precursor CBGA.",
                ja: "Cannabis sativaの原産地。THCAシンターゼとCBDAシンターゼがCBGA前駆体を巡って競合する。",
                zh: "大麻（Cannabis sativa）的祖先家园。THCA和CBDA合酶竞争CBGA前体。",
                ko: "대마(Cannabis sativa)의 원산지. THCA 및 CBDA 합성효소가 CBGA 전구체를 놓고 경쟁.",
                ru: "Прародина Cannabis sativa. ТГКА- и КБДА-синтазы конкурируют за предшественник КБГА.",
                de: "Urheimat von Cannabis sativa. THCA- und CBDA-Synthasen konkurrieren um den CBGA-Vorläufer.",
                ar: "الموطن الأصلي للقنب. تتنافس إنزيمات THCA وCBDA على السلف CBGA.")
        case .tropicalPlantations:
            return LocalizedString(
                en: "Caffeine evolved independently at least five times in unrelated plant families — the most dramatic convergent evolution in psychoactive chemistry.",
                fr: "La cafeine a evolue independamment au moins cinq fois dans des familles vegetales non apparentees — l'evolution convergente la plus spectaculaire de la chimie psychoactive.",
                es: "La cafeína evolucionó independientemente al menos cinco veces en familias de plantas no relacionadas — la evolución convergente más dramática en química psicoactiva.",
                ja: "カフェインは無関係な植物科で少なくとも5回独立に進化した — 精神活性化学における最も劇的な収斂進化。",
                zh: "咖啡因在无关的植物科中至少独立进化了五次 — 精神活性化学中最引人注目的趋同进化。",
                ko: "카페인은 무관한 식물과에서 최소 5번 독립적으로 진화했다 — 정신활성 화학에서 가장 극적인 수렴 진화.",
                ru: "Кофеин эволюционировал независимо как минимум пять раз в неродственных семействах растений — наиболее яркий пример конвергентной эволюции в психоактивной химии.",
                de: "Koffein hat sich mindestens fünfmal unabhängig in nicht verwandten Pflanzenfamilien entwickelt — die dramatischste konvergente Evolution in der psychoaktiven Chemie.",
                ar: "تطور الكافيين بشكل مستقل خمس مرات على الأقل في فصائل نباتية غير مترابطة — أكثر تطور تقاربي مثير في الكيمياء ذات التأثير النفسي.")
        }
    }

    /// Molecular scaffolds found in this habitat.
    public var scaffoldsFound: [MolecularScaffold] {
        switch self {
        case .fungalForest:         return [.tryptamine, .ergoline]
        case .tropicalJungle:       return [.tryptamine, .tropane]
        case .desertMesa:           return [.phenethylamine]
        case .asianHighlands:       return [.morphinan, .isoquinoline, .xanthine, .phenethylamine]
        case .africanRainforest:    return [.iboga, .phenethylamine]
        case .centralAsianSteppe:   return [.terpenoid]
        case .tropicalPlantations:  return [.xanthine]
        }
    }
}
