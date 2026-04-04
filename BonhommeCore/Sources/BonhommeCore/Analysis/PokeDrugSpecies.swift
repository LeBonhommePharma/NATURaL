import Foundation

/// A complete PokeDrug "Pokedex entry" combining type, scaffold, stats,
/// habitat, and flavor text for a psychoactive natural product or derivative.
///
/// Links to existing PharmacokineticProfile and BindingEntropyProfile
/// via the shared substanceId key.
public struct PokeDrugSpecies: Sendable {
    /// Links to PharmacokineticProfile.substanceId and BindingEntropyProfile.substanceId.
    public let substanceId: String

    /// Display name (bilingual).
    public let name: LocalizedString

    /// Primary PokeDrug type.
    public let primaryType: PokeDrugType

    /// Optional secondary type (e.g., LSD is Serotonin/Dopamine).
    public let secondaryType: PokeDrugType?

    /// Molecular scaffold ("species").
    public let scaffold: MolecularScaffold

    /// Six base stats (1-5 star ratings).
    public let stats: PokeDrugStats

    /// Natural habitat. Nil for fully synthetic compounds.
    public let habitat: PokeDrugHabitat?

    /// Pokedex-style flavor text.
    public let flavorText: LocalizedString

    /// Dex number for catalog ordering.
    public let dexNumber: Int

    public init(
        substanceId: String,
        name: LocalizedString,
        primaryType: PokeDrugType,
        secondaryType: PokeDrugType? = nil,
        scaffold: MolecularScaffold,
        stats: PokeDrugStats,
        habitat: PokeDrugHabitat? = nil,
        flavorText: LocalizedString,
        dexNumber: Int
    ) {
        self.substanceId = substanceId
        self.name = name
        self.primaryType = primaryType
        self.secondaryType = secondaryType
        self.scaffold = scaffold
        self.stats = stats
        self.habitat = habitat
        self.flavorText = flavorText
        self.dexNumber = dexNumber
    }
}

// MARK: - Cross-Reference Convenience

extension PokeDrugSpecies {

    /// Corresponding pharmacokinetic profile, if available.
    public var pharmacokineticProfile: PharmacokineticProfile? {
        PharmacokineticProfile.profile(for: substanceId)
    }

    /// Corresponding binding entropy profile, if available.
    public var bindingEntropyProfile: BindingEntropyProfile? {
        BindingEntropyProfile.profile(for: substanceId)
    }

    /// All types this species expresses (primary + secondary).
    public var types: [PokeDrugType] {
        if let secondary = secondaryType {
            return [primaryType, secondary]
        }
        return [primaryType]
    }

    /// All thermodynamic binding profiles for this species (all targets).
    public var thermodynamicProfiles: [ThermodynamicBindingProfile] {
        ThermodynamicBindingProfile.profiles(for: substanceId)
    }

    /// Primary-target thermodynamic binding profile, if available.
    public var primaryThermodynamicProfile: ThermodynamicBindingProfile? {
        ThermodynamicBindingProfile.profile(for: substanceId)
    }

    /// Attack stat derived from primary target Ki (nM) via thermodynamic data.
    /// Returns nil if no thermodynamic profile or affinity data is available.
    public var derivedAttack: Int? {
        guard let profile = primaryThermodynamicProfile,
              let ki = profile.affinity.bestAffinityNM else { return nil }
        return PokeDrugStats.deriveAttack(kiNM: ki)
    }

    /// Sp. Atk stat derived from selectivity ratio (best off-target Ki / primary Ki).
    /// Returns nil if fewer than 2 targets or no affinity data.
    public var derivedSpecialAttack: Int? {
        let profiles = thermodynamicProfiles
        guard let primary = profiles.first(where: { $0.isPrimaryTarget }),
              let primaryKi = primary.affinity.bestAffinityNM else { return nil }
        let offTargets = profiles.filter { !$0.isPrimaryTarget }
        guard let bestOffTarget = offTargets.compactMap({ $0.affinity.bestAffinityNM }).min() else {
            // Single target — maximum selectivity
            return 5
        }
        guard primaryKi > 0 else { return 1 }
        let ratio = bestOffTarget / primaryKi
        return PokeDrugStats.deriveSpecialAttack(selectivityRatio: ratio)
    }
}

// MARK: - New PharmacokineticProfile Entries for PokeDrug Substances

extension PharmacokineticProfile {

    /// N,N-Dimethyltryptamine (DMT). 5-HT2A + sigma-1 agonist.
    /// Smoked onset < 30 sec, t1/2 ~15-20 min. No oral activity without MAOIs.
    /// Strassman 1994, Barker 2018.
    public static let dmt = PharmacokineticProfile(
        substanceId: "dmt",
        name: LocalizedString(en: "DMT", fr: "DMT", es: "DMT", ja: "DMT", zh: "DMT", ko: "DMT", ru: "ДМТ", de: "DMT", ar: "دي إم تي"),
        therapeuticClass: .psychedelic,
        onsetMinutes: 0.5,
        tmaxMinutes: 5,
        halfLifeMinutes: 20,
        expectedDeltaHRange: -0.5...0.4,
        mechanism: .mixed,
        fdaApproved: false,
        scheduled: true,
        bindingEntropyKcal: 1.0
    )

    /// Mescaline (3,4,5-trimethoxyphenethylamine). 5-HT2A agonist.
    /// Oral onset 45-90 min, dose 200-400 mg, t1/2 ~6h.
    /// Shulgin & Shulgin, PiHKAL; Chagas-Paula 2019.
    public static let mescaline = PharmacokineticProfile(
        substanceId: "mescaline",
        name: LocalizedString(en: "Mescaline", fr: "Mescaline", es: "Mescalina", ja: "メスカリン", zh: "麦司卡林", ko: "메스칼린", ru: "Мескалин", de: "Mescalin", ar: "ميسكالين"),
        therapeuticClass: .psychedelic,
        onsetMinutes: 45,
        tmaxMinutes: 120,
        halfLifeMinutes: 360,
        expectedDeltaHRange: -0.4...0.3,
        mechanism: .mixed,
        fdaApproved: false,
        scheduled: true,
        bindingEntropyKcal: 2.0
    )

    /// Salvinorin A. Selective KOR agonist from Salvia divinorum.
    /// Smoked onset < 30 sec, duration ~8 min. Ki 1.9 nM at KOR.
    /// Roth et al. 2002, Butelman et al. 2004.
    public static let salvinorinA = PharmacokineticProfile(
        substanceId: "salvinorin-a",
        name: LocalizedString(en: "Salvinorin A", fr: "Salvinorine A", es: "Salvinorina A", ja: "サルビノリンA", zh: "沙尔维诺林A", ko: "살비노린 A", ru: "Сальвинорин А", de: "Salvinorin A", ar: "سالفينورين أ"),
        therapeuticClass: .psychedelic,
        onsetMinutes: 0.5,
        tmaxMinutes: 2,
        halfLifeMinutes: 8,
        expectedDeltaHRange: -0.3...0.2,
        mechanism: .unknown,
        fdaApproved: false,
        scheduled: false,
        bindingEntropyKcal: 2.5
    )

    /// Ibogaine. Multi-target alkaloid from Tabernanthe iboga.
    /// Oral onset 1-3h, t1/2 ~4-7h (ibogaine), metabolite noribogaine t1/2 24-48h.
    /// Mash et al. 2001, Glue et al. 2015.
    public static let ibogaine = PharmacokineticProfile(
        substanceId: "ibogaine",
        name: LocalizedString(en: "Ibogaine", fr: "Ibogaine", es: "Ibogaína", ja: "イボガイン", zh: "伊博格碱", ko: "이보가인", ru: "Ибогаин", de: "Ibogain", ar: "إيبوغايين"),
        therapeuticClass: .psychedelic,
        onsetMinutes: 60,
        tmaxMinutes: 180,
        halfLifeMinutes: 300,
        expectedDeltaHRange: -0.8...0.5,
        mechanism: .mixed,
        fdaApproved: false,
        scheduled: true,
        bindingEntropyKcal: 2.8
    )

    /// Cathinone. Natural beta-keto amphetamine from Catha edulis (khat).
    /// Oral onset ~30 min, t1/2 ~1.5h. NET/DAT releaser.
    /// Brenneisen et al. 1990, Toennes et al. 2003.
    public static let cathinone = PharmacokineticProfile(
        substanceId: "cathinone",
        name: LocalizedString(en: "Cathinone", fr: "Cathinone", es: "Catinona", ja: "カチノン", zh: "卡西酮", ko: "카티논", ru: "Катинон", de: "Cathinon", ar: "كاثينون"),
        therapeuticClass: .stimulant,
        onsetMinutes: 30,
        tmaxMinutes: 90,
        halfLifeMinutes: 90,
        expectedDeltaHRange: -1.2...(-0.4),
        mechanism: .sympathomimetic,
        fdaApproved: false,
        scheduled: true,
        bindingEntropyKcal: 1.3
    )

    /// Apigenin. Flavonoid from chamomile. Weak GABA-A PAM at BZD site.
    /// Oral onset ~30-60 min, t1/2 ~12h. Ki ~1-10 uM at BZD site.
    /// Viola et al. 1995, Salehi et al. 2019.
    public static let apigenin = PharmacokineticProfile(
        substanceId: "apigenin",
        name: LocalizedString(en: "Apigenin", fr: "Apigenine", es: "Apigenina", ja: "アピゲニン", zh: "芹菜素", ko: "아피게닌", ru: "Апигенин", de: "Apigenin", ar: "أبيجينين"),
        therapeuticClass: .sedativeHypnotic,
        onsetMinutes: 30,
        tmaxMinutes: 90,
        halfLifeMinutes: 720,
        expectedDeltaHRange: 0.1...0.5,
        mechanism: .parasympathomimetic,
        fdaApproved: false,
        scheduled: false,
        bindingEntropyKcal: 1.0
    )

    /// Psilocin (4-HO-DMT). Active metabolite of psilocybin. Direct 5-HT2A agonist.
    /// Oral onset 20-40 min (from psilocybin prodrug), t1/2 ~2.5-3h.
    /// Passie et al. 2002, Brown et al. 2017.
    public static let psilocin = PharmacokineticProfile(
        substanceId: "psilocin",
        name: LocalizedString(en: "Psilocin", fr: "Psilocine", es: "Psilocina", ja: "サイロシン", zh: "裸盖菇辛", ko: "실로신", ru: "Псилоцин", de: "Psilocin", ar: "سيلوسين"),
        therapeuticClass: .psychedelic,
        onsetMinutes: 20,
        tmaxMinutes: 80,
        halfLifeMinutes: 165,
        expectedDeltaHRange: -0.5...0.4,
        mechanism: .mixed,
        fdaApproved: false,
        scheduled: true,
        bindingEntropyKcal: 0.9
    )

    /// MDA (3,4-methylenedioxyamphetamine). Empathogen + psychedelic.
    /// Oral onset 30-60 min, t1/2 ~8-12h. SERT releaser + 5-HT2A agonist.
    /// Nichols 1986, Baumann et al. 2007.
    public static let mda = PharmacokineticProfile(
        substanceId: "mda",
        name: LocalizedString(en: "MDA", fr: "MDA", es: "MDA", ja: "MDA", zh: "MDA", ko: "MDA", ru: "МДА", de: "MDA", ar: "إم دي إيه"),
        therapeuticClass: .psychedelic,
        onsetMinutes: 30,
        tmaxMinutes: 90,
        halfLifeMinutes: 600,
        expectedDeltaHRange: -0.6...0.3,
        mechanism: .mixed,
        fdaApproved: false,
        scheduled: true,
        bindingEntropyKcal: 1.5
    )

    /// Muscimol. GABA-A orthosteric agonist from Amanita muscaria.
    /// Oral onset 30-90 min, t1/2 ~4-6h. Ki ~6-10 nM at GABA-A.
    /// Johnston et al. 1968, Krogsgaard-Larsen 1977.
    public static let muscimol = PharmacokineticProfile(
        substanceId: "muscimol",
        name: LocalizedString(en: "Muscimol", fr: "Muscimol", es: "Muscimol", ja: "ムシモール", zh: "蝇蕈醇", ko: "무시몰", ru: "Мусцимол", de: "Muscimol", ar: "موسيمول"),
        therapeuticClass: .sedativeHypnotic,
        onsetMinutes: 30,
        tmaxMinutes: 120,
        halfLifeMinutes: 300,
        expectedDeltaHRange: 0.2...0.8,
        mechanism: .parasympathomimetic,
        fdaApproved: false,
        scheduled: false,
        bindingEntropyKcal: 0.8
    )

    /// Ephedrine. Sympathomimetic alkaloid from Ephedra sinica.
    /// Oral onset 15-30 min, t1/2 ~3-6h. Indirect NET/DAT release + direct alpha/beta agonism.
    /// Weiner 1980, Andraws et al. 2005.
    public static let ephedrine = PharmacokineticProfile(
        substanceId: "ephedrine",
        name: LocalizedString(en: "Ephedrine", fr: "Ephedrine", es: "Efedrina", ja: "エフェドリン", zh: "麻黄碱", ko: "에페드린", ru: "Эфедрин", de: "Ephedrin", ar: "إيفيدرين"),
        therapeuticClass: .stimulant,
        onsetMinutes: 15,
        tmaxMinutes: 60,
        halfLifeMinutes: 300,
        expectedDeltaHRange: -1.0...(-0.3),
        mechanism: .sympathomimetic,
        fdaApproved: true,
        scheduled: false,
        bindingEntropyKcal: 1.1
    )

    /// Mitragynine. Primary alkaloid from Mitragyna speciosa (kratom).
    /// Oral onset 15-30 min, t1/2 ~3.5h (parent), metabolite 7-OH-mitragynine active.
    /// MOR partial agonist Ki ~230 nM + 5-HT2A, alpha-2 adrenergic.
    /// Kruegel et al. 2016, Hemby et al. 2019.
    public static let mitragynine = PharmacokineticProfile(
        substanceId: "mitragynine",
        name: LocalizedString(en: "Mitragynine", fr: "Mitragynine", es: "Mitraginina", ja: "ミトラギニン", zh: "帽柱木碱", ko: "미트라기닌", ru: "Митрагинин", de: "Mitragynin", ar: "ميتراجينين"),
        therapeuticClass: .opioidAnalgesic,
        onsetMinutes: 15,
        tmaxMinutes: 60,
        halfLifeMinutes: 210,
        expectedDeltaHRange: -0.4...0.2,
        mechanism: .mixed,
        fdaApproved: false,
        scheduled: false,
        bindingEntropyKcal: 2.0
    )

    /// CBD (Cannabidiol). Non-psychoactive phytocannabinoid from Cannabis sativa.
    /// Oral onset 30-90 min, t1/2 ~18-32h. Low CB1 affinity but modulates multiple targets.
    /// FDA-approved as Epidiolex for epilepsy.
    /// Pertwee 2008, Devinsky et al. 2017.
    public static let cbd = PharmacokineticProfile(
        substanceId: "cbd",
        name: LocalizedString(en: "CBD", fr: "CBD", es: "CBD", ja: "CBD", zh: "CBD", ko: "CBD", ru: "КБД", de: "CBD", ar: "سي بي دي"),
        therapeuticClass: .cannabinoid,
        onsetMinutes: 30,
        tmaxMinutes: 150,
        halfLifeMinutes: 1500,
        expectedDeltaHRange: 0.0...0.3,
        mechanism: .mixed,
        fdaApproved: true,
        scheduled: false,
        bindingEntropyKcal: 1.8
    )

    /// Harmine. Beta-carboline MAO-A inhibitor from Banisteriopsis caapi (ayahuasca vine).
    /// Oral onset 20-40 min, t1/2 ~1-3h. MAO-A Ki ~5 nM + 5-HT2A Ki ~300 nM.
    /// Buckholtz & Boggan 1977, Brierley & Davidson 2012.
    public static let harmine = PharmacokineticProfile(
        substanceId: "harmine",
        name: LocalizedString(en: "Harmine", fr: "Harmine", es: "Harmina", ja: "ハルミン", zh: "骆驼蓬碱", ko: "하르민", ru: "Гармин", de: "Harmin", ar: "هارمين"),
        therapeuticClass: .psychedelic,
        onsetMinutes: 20,
        tmaxMinutes: 60,
        halfLifeMinutes: 120,
        expectedDeltaHRange: -0.3...0.3,
        mechanism: .mixed,
        fdaApproved: false,
        scheduled: false,
        bindingEntropyKcal: 1.4
    )
}


// MARK: - Species Catalog

extension PokeDrugSpecies {

    /// The complete PokeDrug Pokedex: all known species with their types,
    /// scaffolds, stats, habitats, and descriptions.
    ///
    /// Stats derived from published Ki values (PDSP, ChEMBL), crystal structures
    /// (Roth/Kobilka labs), safety ratios (Gable, Nutt et al. 2010 Lancet).
    public static let knownSpecies: [PokeDrugSpecies] = [

        // MARK: #001 - LSD (Ergoline)

        PokeDrugSpecies(
            substanceId: "lsd",
            name: LocalizedString(en: "LSD", fr: "LSD", es: "LSD", ja: "LSD", zh: "LSD", ko: "LSD", ru: "ЛСД", de: "LSD", ar: "إل إس دي"),
            primaryType: .serotonin,
            secondaryType: .dopamine,
            scaffold: .ergoline,
            stats: PokeDrugStats(
                hp: 5,      // TI ~1000; no confirmed direct deaths
                attack: 5,  // Ki 3-7 nM at 5-HT2A
                defense: 4, // t1/2 3.6h + EL2 lid = 12h effect
                specialAttack: 2, // Pan-aminergic (all 13 5-HT subtypes + D1/D2/D3)
                specialDefense: 2, // Full tolerance in 3 days
                speed: 3    // 30-45 min oral onset
            ),
            habitat: .fungalForest,
            flavorText: LocalizedString(
                en: "The rigid ergoline tetracycle traps in the 5-HT2A pocket for hours via an extracellular loop 2 lid. Active at 20-100 micrograms — the most potent psychoactive compound by weight.",
                fr: "Le tetracycle ergoline rigide se piege dans la poche 5-HT2A pendant des heures via un couvercle de boucle extracellulaire 2. Actif a 20-100 microgrammes — le compose psychoactif le plus puissant au poids.",
                es: "El tetraciclo ergolina rigido se atrapa en el bolsillo 5-HT2A durante horas mediante una tapa del bucle extracelular 2. Activo a 20-100 microgramos — el compuesto psicoactivo mas potente por peso.",
                ja: "剛直なエルゴリン四環系は細胞外ループ2の蓋を介して5-HT2Aポケットに数時間捕捉される。20-100マイクログラムで活性 — 重量あたり最も強力な精神活性化合物。",
                zh: "刚性麦角灵四环体系通过细胞外环2盖结构在5-HT2A口袋中捕获数小时。在20-100微克时即有活性——按重量计最强效的精神活性化合物。",
                ko: "강직한 에르골린 사환계는 세포외 루프 2 뚜껑을 통해 5-HT2A 포켓에 수시간 포획된다. 20-100마이크로그램에서 활성 — 중량 기준 가장 강력한 정신활성 화합물.",
                ru: "Жесткий эрголиновый тетрацикл захватывается в кармане 5-HT2A на часы через крышку внеклеточной петли 2. Активен при 20-100 мкг — самое мощное психоактивное соединение по массе.",
                de: "Der starre Ergolin-Tetrazyklus wird uber einen extrazellularen Schleife-2-Deckel stundenlang in der 5-HT2A-Tasche gefangen. Aktiv bei 20-100 Mikrogramm — die potenteste psychoaktive Substanz nach Gewicht.",
                ar: "يُحبس رباعي الحلقة الإرغولين الصلب في جيب 5-HT2A لساعات عبر غطاء الحلقة خارج الخلوية 2. فعّال عند 20-100 ميكروغرام — أقوى مركب نفساني التأثير بالوزن."
            ),
            dexNumber: 1
        ),

        // MARK: #002 - Psilocybin (Tryptamine)

        PokeDrugSpecies(
            substanceId: "psilocybin",
            name: LocalizedString(en: "Psilocybin", fr: "Psilocybine", es: "Psilocibina", ja: "シロシビン", zh: "赛洛西宾", ko: "실로시빈", ru: "Псилоцибин", de: "Psilocybin", ar: "سيلوسيبين"),
            primaryType: .serotonin,
            scaffold: .tryptamine,
            stats: PokeDrugStats(
                hp: 5,      // TI ~1000; Nutt 2010: 5/100 harm score
                attack: 4,  // Psilocin Ki 25-107 nM
                defense: 3, // t1/2 ~3h
                specialAttack: 3, // 5-HT2A/2B/1A selective
                specialDefense: 2, // Full tolerance in 3 days
                speed: 3    // 20-40 min oral
            ),
            habitat: .fungalForest,
            flavorText: LocalizedString(
                en: "Nature's prodrug: the phosphate ester ensures oral stability, then alkaline phosphatase frees active psilocin in vivo. Produced by 200+ Psilocybe species via a 65-million-year-old enzyme cluster.",
                fr: "La prodrogue de la nature: l'ester phosphate assure la stabilite orale, puis la phosphatase alcaline libere la psilocine active in vivo. Produit par plus de 200 especes de Psilocybe via un cluster enzymatique vieux de 65 millions d'annees.",
                es: "La prodroga de la naturaleza: el ester fosfato asegura estabilidad oral, luego la fosfatasa alcalina libera psilocina activa in vivo. Producida por mas de 200 especies de Psilocybe mediante un cluster enzimatico de 65 millones de anos.",
                ja: "天然のプロドラッグ：リン酸エステルが経口安定性を確保し、アルカリホスファターゼが生体内で活性シロシンを遊離する。6500万年前の酵素クラスターを介して200種以上のシロシベ属が産生。",
                zh: "大自然的前药：磷酸酯确保口服稳定性，然后碱性磷酸酶在体内释放活性裸盖菇素。由200多种裸盖菇属通过6500万年前的酶簇产生。",
                ko: "자연의 전구약물: 인산에스테르가 경구 안정성을 보장하고, 알칼리성 포스파타제가 생체 내에서 활성 실로신을 유리시킨다. 6500만 년 된 효소 클러스터를 통해 200종 이상의 실로시베 속이 생산.",
                ru: "Пролекарство природы: фосфатный эфир обеспечивает пероральную стабильность, затем щелочная фосфатаза высвобождает активный псилоцин in vivo. Производится более чем 200 видами Psilocybe через ферментный кластер возрастом 65 млн лет.",
                de: "Das Prodrug der Natur: Der Phosphatester sichert orale Stabilitat, dann setzt alkalische Phosphatase aktives Psilocin in vivo frei. Von uber 200 Psilocybe-Arten uber einen 65 Millionen Jahre alten Enzymcluster produziert.",
                ar: "الدواء الأولي للطبيعة: يضمن إستر الفوسفات الاستقرار الفموي، ثم يحرر الفوسفاتاز القلوي السيلوسين النشط في الجسم الحي. تنتجه أكثر من 200 نوع من جنس سيلوسيب عبر عنقود إنزيمي عمره 65 مليون سنة."
            ),
            dexNumber: 2
        ),

        // MARK: #003 - DMT (Tryptamine)

        PokeDrugSpecies(
            substanceId: "dmt",
            name: LocalizedString(en: "DMT", fr: "DMT", es: "DMT", ja: "DMT", zh: "DMT", ko: "DMT", ru: "ДМТ", de: "DMT", ar: "دي إم تي"),
            primaryType: .serotonin,
            secondaryType: .sigma,
            scaffold: .tryptamine,
            stats: PokeDrugStats(
                hp: 4,      // TI ~20 (ayahuasca context)
                attack: 3,  // Ki 77-360 nM at 5-HT2A
                defense: 1, // t1/2 ~15 min smoked
                specialAttack: 3, // 5-HT2A + sigma-1
                specialDefense: 5, // NO tolerance — unique among serotonergics
                speed: 5    // <30 sec smoked
            ),
            habitat: .tropicalJungle,
            flavorText: LocalizedString(
                en: "The only serotonergic psychedelic that produces zero measurable tolerance. Smoked, it reaches peak brain concentration in under 30 seconds — a glass cannon with maximum Speed.",
                fr: "Le seul psychedelique serotoninergique qui ne produit aucune tolerance mesurable. Fume, il atteint la concentration cerebrale maximale en moins de 30 secondes — un canon de verre avec une Vitesse maximale.",
                es: "El unico psicodelico serotoninergico que produce cero tolerancia medible. Fumado, alcanza la concentracion cerebral maxima en menos de 30 segundos — un canon de cristal con Velocidad maxima.",
                ja: "測定可能な耐性がゼロの唯一のセロトニン作動性サイケデリクス。喫煙で30秒以内に脳内最高濃度に到達 — 最大スピードのガラスの大砲。",
                zh: "唯一不产生可测量耐受性的血清素能致幻剂。吸入后30秒内达到脑内峰值浓度——具有最大速度的玻璃大炮。",
                ko: "측정 가능한 내성이 전혀 없는 유일한 세로토닌 작용성 사이키델릭. 흡연 시 30초 이내에 뇌 최고 농도 도달 — 최대 스피드의 유리 대포.",
                ru: "Единственный серотонинергический психоделик с нулевой измеримой толерантностью. При курении достигает пиковой концентрации в мозге менее чем за 30 секунд — стеклянная пушка с максимальной Скоростью.",
                de: "Das einzige serotonerge Psychedelikum ohne messbare Toleranz. Geraucht erreicht es in unter 30 Sekunden die maximale Gehirnkonzentration — eine Glaskanone mit maximaler Geschwindigkeit.",
                ar: "المخدر السيروتونيني الوحيد الذي لا ينتج أي تحمل قابل للقياس. عند التدخين يصل إلى ذروة التركيز الدماغي في أقل من 30 ثانية — مدفع زجاجي بأقصى سرعة."
            ),
            dexNumber: 3
        ),

        // MARK: #004 - Morphine (Morphinan)

        PokeDrugSpecies(
            substanceId: "morphine",
            name: LocalizedString(en: "Morphine", fr: "Morphine", es: "Morfina", ja: "モルヒネ", zh: "吗啡", ko: "모르핀", ru: "Морфин", de: "Morphin", ar: "مورفين"),
            primaryType: .opioid,
            scaffold: .morphinan,
            stats: PokeDrugStats(
                hp: 2,      // TI ~15
                attack: 5,  // Ki 1.2-14 nM at MOR
                defense: 3, // t1/2 2-3h
                specialAttack: 4, // MOR/KOR 20-100x selectivity
                specialDefense: 1, // Rapid tolerance
                speed: 3    // 15-30 min oral
            ),
            habitat: .asianHighlands,
            flavorText: LocalizedString(
                en: "The pentacyclic morphinan locks phenol and nitrogen into the exact geometry of enkephalin Tyr1. The 17-enzyme biosynthetic pathway in Papaver somniferum is one of nature's most complex.",
                fr: "Le morphinane pentacyclique verrouille le phenol et l'azote dans la geometrie exacte de la Tyr1 de l'enkephaline. La voie biosynthetique a 17 enzymes chez Papaver somniferum est l'une des plus complexes de la nature.",
                es: "El morfinano pentaciclico fija el fenol y el nitrogeno en la geometria exacta de la Tyr1 de la encefalina. La via biosintetica de 17 enzimas en Papaver somniferum es una de las mas complejas de la naturaleza.",
                ja: "五環性モルヒナンはフェノールと窒素をエンケファリンTyr1の正確な幾何学配置に固定する。ケシ（Papaver somniferum）の17酵素生合成経路は自然界で最も複雑なものの一つ。",
                zh: "五环吗啡烷将酚基和氮原子锁定在脑啡肽Tyr1的精确几何构型中。罂粟（Papaver somniferum）的17酶生物合成途径是自然界最复杂的途径之一。",
                ko: "오환성 모르피난은 페놀과 질소를 엔케팔린 Tyr1의 정확한 기하학적 구조로 고정한다. 양귀비(Papaver somniferum)의 17효소 생합성 경로는 자연계에서 가장 복잡한 것 중 하나이다.",
                ru: "Пентациклический морфинан фиксирует фенол и азот в точной геометрии Tyr1 энкефалина. 17-ферментный биосинтетический путь Papaver somniferum — один из самых сложных в природе.",
                de: "Das pentazyklische Morphinan fixiert Phenol und Stickstoff in der exakten Geometrie von Enkephalin-Tyr1. Der 17-Enzym-Biosyntheseweg in Papaver somniferum gehort zu den komplexesten der Natur.",
                ar: "يثبت المورفينان خماسي الحلقات الفينول والنيتروجين في الهندسة الدقيقة لـ Tyr1 الإنكيفالين. مسار التخليق الحيوي المكون من 17 إنزيماً في خشخاش الأفيون هو أحد أكثر المسارات تعقيداً في الطبيعة."
            ),
            dexNumber: 4
        ),

        // MARK: #005 - Fentanyl (Synthetic Opioid)

        PokeDrugSpecies(
            substanceId: "fentanyl",
            name: LocalizedString(en: "Fentanyl", fr: "Fentanyl", es: "Fentanilo", ja: "フェンタニル", zh: "芬太尼", ko: "펜타닐", ru: "Фентанил", de: "Fentanyl", ar: "فنتانيل"),
            primaryType: .opioid,
            scaffold: .morphinan, // Synthetic but targets same pocket
            stats: PokeDrugStats(
                hp: 1,      // TI ~2-3, razor-thin margin
                attack: 5,  // Ki 1.35 nM
                defense: 4, // t1/2 3-7h
                specialAttack: 4, // MOR/KOR ~120x
                specialDefense: 1, // Rapid tolerance
                speed: 5    // Seconds IV
            ),
            habitat: nil, // Fully synthetic
            flavorText: LocalizedString(
                en: "A synthetic phenethyl piperidine with the lowest HP stat in the PokeDrug system. The difference between effective dose and lethal dose is razor-thin — TI of 2-3.",
                fr: "Une piperidine phenethylique synthetique avec la plus faible stat HP du systeme PokeDrug. La difference entre dose efficace et dose letale est infime — IT de 2-3.",
                es: "Una piperidina fenetilica sintetica con la stat de HP mas baja del sistema PokeDrug. La diferencia entre dosis efectiva y dosis letal es minima — IT de 2-3.",
                ja: "PokeDrugシステムで最低のHPステータスを持つ合成フェネチルピペリジン。有効用量と致死量の差は極めて薄い — 治療指数2〜3。",
                zh: "一种合成苯乙基哌啶，在PokeDrug系统中HP属性最低。有效剂量与致死剂量之间的差距极其微小——治疗指数仅为2-3。",
                ko: "PokeDrug 시스템에서 가장 낮은 HP 스탯을 가진 합성 페네틸 피페리딘. 유효 용량과 치사량의 차이가 극히 근소하다 — 치료 지수 2-3.",
                ru: "Синтетический фенэтилпиперидин с самым низким показателем HP в системе PokeDrug. Разница между эффективной и летальной дозой минимальна — терапевтический индекс 2-3.",
                de: "Ein synthetisches Phenethylpiperidin mit dem niedrigsten HP-Wert im PokeDrug-System. Der Unterschied zwischen wirksamer und todlicher Dosis ist hauchdünn — TI von 2-3.",
                ar: "بيبيريدين فينيثيلي اصطناعي بأدنى إحصائية HP في نظام PokeDrug. الفرق بين الجرعة الفعالة والجرعة المميتة ضئيل للغاية — مؤشر علاجي 2-3."
            ),
            dexNumber: 5
        ),

        // MARK: #006 - MDMA (Benzodioxole)

        PokeDrugSpecies(
            substanceId: "mdma",
            name: LocalizedString(en: "MDMA", fr: "MDMA", es: "MDMA", ja: "MDMA", zh: "MDMA", ko: "MDMA", ru: "МДМА", de: "MDMA", ar: "إم دي إم إيه"),
            primaryType: .empathogen,
            secondaryType: .stimulant,
            scaffold: .benzodioxole,
            stats: PokeDrugStats(
                hp: 3,      // TI ~16
                attack: 3,  // SERT Ki 238-740 nM
                defense: 4, // t1/2 6-9h
                specialAttack: 3, // SERT/DAT ~10:1
                specialDefense: 2, // "Loss of magic"
                speed: 3    // 30-60 min
            ),
            habitat: nil, // Semi-synthetic (safrole precursor from tropical plants)
            flavorText: LocalizedString(
                en: "The methylenedioxy ring shifts the phenethylamine backbone toward SERT release: 10:1 serotonin-over-dopamine flooding creates prosocial warmth rather than stimulant rush. Breakthrough therapy for PTSD.",
                fr: "L'anneau methylenedioxy deplace le squelette phenethylamine vers la liberation de SERT: l'inondation de serotonine 10:1 par rapport a la dopamine cree une chaleur prosociale plutot qu'un rush stimulant. Therapie de rupture pour le TSPT.",
                es: "El anillo metilendioxi desplaza el esqueleto fenetilamina hacia la liberacion de SERT: la inundacion de serotonina 10:1 sobre dopamina crea calidez prosocial en vez de rush estimulante. Terapia innovadora para el TEPT.",
                ja: "メチレンジオキシ環がフェネチルアミン骨格をSERT放出側にシフトさせる：ドーパミンに対するセロトニン10:1の放出が覚醒剤様ラッシュではなく向社会的温かみを生み出す。PTSDの画期的治療法。",
                zh: "亚甲二氧基环将苯乙胺骨架转向SERT释放：10:1的血清素对多巴胺释放产生亲社会的温暖感而非兴奋剂般的冲击。PTSD的突破性疗法。",
                ko: "메틸렌디옥시 고리가 페네틸아민 골격을 SERT 방출 쪽으로 이동시킨다: 도파민 대비 세로토닌 10:1 방출이 각성제 러시 대신 친사회적 온기를 만든다. PTSD 획기적 치료법.",
                ru: "Метилендиоксикольцо смещает фенэтиламиновый скелет к высвобождению SERT: соотношение серотонина к дофамину 10:1 создает просоциальное тепло вместо стимуляторного раша. Прорывная терапия ПТСР.",
                de: "Der Methylendioxyring verschiebt das Phenethylamin-Grundgerust zur SERT-Freisetzung: 10:1-Serotonin-uber-Dopamin-Flutung erzeugt prosoziale Warme statt Stimulanzienrausch. Durchbruchstherapie fur PTBS.",
                ar: "تحول حلقة الميثيلين ديوكسي الهيكل العظمي للفينيثيلامين نحو إطلاق SERT: إغراق السيروتونين بنسبة 10:1 مقابل الدوبامين يخلق دفئاً اجتماعياً بدلاً من اندفاع المنشطات. علاج اختراقي لاضطراب ما بعد الصدمة."
            ),
            dexNumber: 6
        ),

        // MARK: #007 - Amphetamine (Phenethylamine)

        PokeDrugSpecies(
            substanceId: "amphetamine",
            name: LocalizedString(en: "Amphetamine", fr: "Amphetamine", es: "Anfetamina", ja: "アンフェタミン", zh: "安非他明", ko: "암페타민", ru: "Амфетамин", de: "Amphetamin", ar: "أمفيتامين"),
            primaryType: .dopamine,
            secondaryType: .stimulant,
            scaffold: .phenethylamine,
            stats: PokeDrugStats(
                hp: 2,      // TI ~5-10
                attack: 4,  // NET Ki 70-100 nM
                defense: 5, // t1/2 10-13h
                specialAttack: 3, // NET/DAT preferring
                specialDefense: 2, // Euphoria tolerance
                speed: 3    // 20-60 min
            ),
            habitat: nil, // Synthetic
            flavorText: LocalizedString(
                en: "Alpha-methylation of phenethylamine — the single most consequential modification in stimulant pharmacology. Blocks MAO, enables reverse transport, extends half-life from seconds to 10-13 hours.",
                fr: "Alpha-methylation de la phenethylamine — la modification la plus consequente de la pharmacologie des stimulants. Bloque la MAO, permet le transport inverse, prolonge la demi-vie de secondes a 10-13 heures.",
                es: "Alfa-metilacion de la fenetilamina — la modificacion mas trascendental en la farmacologia de estimulantes. Bloquea la MAO, permite el transporte inverso, extiende la vida media de segundos a 10-13 horas.",
                ja: "フェネチルアミンのα-メチル化 — 覚醒剤薬理学における最も重大な単一修飾。MAOを阻害し、逆輸送を可能にし、半減期を秒単位から10〜13時間に延長する。",
                zh: "苯乙胺的α-甲基化——兴奋剂药理学中最具影响力的单一修饰。阻断MAO，实现逆向转运，将半衰期从数秒延长至10-13小时。",
                ko: "페네틸아민의 알파-메틸화 — 각성제 약리학에서 가장 중대한 단일 변형. MAO를 차단하고, 역수송을 가능하게 하며, 반감기를 수 초에서 10-13시간으로 연장한다.",
                ru: "Альфа-метилирование фенэтиламина — самая значимая модификация в фармакологии стимуляторов. Блокирует МАО, обеспечивает обратный транспорт, увеличивает период полувыведения с секунд до 10-13 часов.",
                de: "Alpha-Methylierung von Phenethylamin — die folgenreichste Einzelmodifikation in der Stimulanzien-Pharmakologie. Blockiert MAO, ermoglicht Rucktransport, verlangert die Halbwertszeit von Sekunden auf 10-13 Stunden.",
                ar: "ألفا-مثيلة الفينيثيلامين — التعديل الأكثر أهمية في علم أدوية المنشطات. يحجب MAO ويمكّن النقل العكسي ويمدد عمر النصف من ثوانٍ إلى 10-13 ساعة."
            ),
            dexNumber: 7
        ),

        // MARK: #008 - Cocaine (Tropane)

        PokeDrugSpecies(
            substanceId: "cocaine",
            name: LocalizedString(en: "Cocaine", fr: "Cocaine", es: "Cocaína", ja: "コカイン", zh: "可卡因", ko: "코카인", ru: "Кокаин", de: "Kokain", ar: "كوكايين"),
            primaryType: .dopamine,
            scaffold: .tropane,
            stats: PokeDrugStats(
                hp: 2,      // TI ~15
                attack: 3,  // DAT Ki 200-700 nM
                defense: 1, // t1/2 ~1h
                specialAttack: 1, // Non-selective DAT/SERT/NET
                specialDefense: 2, // Sensitization paradox
                speed: 5    // Seconds smoked/IV
            ),
            habitat: .tropicalJungle,
            flavorText: LocalizedString(
                en: "The rigid tropane bicycle positions its 3-beta-benzoyloxy group into the DAT binding pocket. The stereochemistry at a single carbon determines whether a tropane is a stimulant or a deliriant.",
                fr: "Le bicycle tropane rigide positionne son groupe 3-beta-benzoyloxy dans la poche de liaison du DAT. La stereochimie a un seul carbone determine si un tropane est un stimulant ou un delirant.",
                es: "La bicicleta tropano rigida posiciona su grupo 3-beta-benzoiloxi en el bolsillo de union del DAT. La estereoquimica en un solo carbono determina si un tropano es estimulante o delirante.",
                ja: "剛直なトロパン二環構造は3-β-ベンゾイルオキシ基をDAT結合ポケットに配置する。単一の炭素の立体化学がトロパンが覚醒剤かせん妄剤かを決定する。",
                zh: "刚性托烷双环将其3-β-苯甲酰氧基定位于DAT结合口袋中。单个碳原子的立体化学决定了托烷是兴奋剂还是致谵妄剂。",
                ko: "강직한 트로판 이환 구조는 3-β-벤조일옥시기를 DAT 결합 포켓에 배치한다. 단일 탄소의 입체화학이 트로판이 각성제인지 섬망제인지를 결정한다.",
                ru: "Жесткий тропановый бицикл размещает свою 3-бета-бензоилоксигруппу в связывающем кармане DAT. Стереохимия одного атома углерода определяет, является ли тропан стимулятором или делириантом.",
                de: "Das starre Tropan-Bizyklus positioniert seine 3-beta-Benzoyloxygruppe in der DAT-Bindetasche. Die Stereochemie an einem einzigen Kohlenstoff bestimmt, ob ein Tropan ein Stimulans oder ein Delirantium ist.",
                ar: "تضع الحلقة الثنائية التروبانية الصلبة مجموعة 3-بيتا-بنزويلوكسي في جيب ارتباط DAT. تحدد الكيمياء الفراغية عند ذرة كربون واحدة ما إذا كان التروبان منشطاً أم مهذياً."
            ),
            dexNumber: 8
        ),

        // MARK: #009 - THC (Terpenoid)

        PokeDrugSpecies(
            substanceId: "thc",
            name: LocalizedString(en: "THC", fr: "THC", es: "THC", ja: "THC", zh: "THC", ko: "THC", ru: "ТГК", de: "THC", ar: "تي إتش سي"),
            primaryType: .cannabinoid,
            scaffold: .terpenoid,
            stats: PokeDrugStats(
                hp: 5,      // TI >1000; no confirmed direct deaths
                attack: 4,  // CB1 Ki 5-80 nM
                defense: 5, // t1/2 25-36h terminal
                specialAttack: 3, // CB1/CB2 dual
                specialDefense: 3, // Slow tolerance, 1-2 weeks
                speed: 4    // Seconds-minutes smoked
            ),
            habitat: .centralAsianSteppe,
            flavorText: LocalizedString(
                en: "A single pyran ring closure separates psychoactive THC from non-psychoactive CBD. The Phe200/Trp356 twin toggle switch in CB1 activates only when the closed ring engages.",
                fr: "Une seule fermeture d'anneau pyrane separe le THC psychoactif du CBD non psychoactif. Le commutateur double Phe200/Trp356 dans CB1 ne s'active que lorsque l'anneau ferme s'engage.",
                es: "Un solo cierre de anillo pirano separa el THC psicoactivo del CBD no psicoactivo. El interruptor doble Phe200/Trp356 en CB1 se activa solo cuando el anillo cerrado se acopla.",
                ja: "単一のピラン環閉環が精神活性THCと非精神活性CBDを分ける。CB1のPhe200/Trp356ツイントグルスイッチは閉環が結合した時のみ活性化する。",
                zh: "单一吡喃环闭合将精神活性THC与非精神活性CBD区分开来。CB1中的Phe200/Trp356双重开关仅在闭合环结合时才被激活。",
                ko: "단일 피란 고리 폐환이 정신활성 THC와 비정신활성 CBD를 구분한다. CB1의 Phe200/Trp356 이중 토글 스위치는 닫힌 고리가 결합할 때만 활성화된다.",
                ru: "Единственное замыкание пиранового кольца отделяет психоактивный ТГК от непсихоактивного КБД. Двойной переключатель Phe200/Trp356 в CB1 активируется только при замкнутом кольце.",
                de: "Ein einziger Pyranringschluss trennt psychoaktives THC von nicht-psychoaktivem CBD. Der Phe200/Trp356-Doppelschalter in CB1 aktiviert sich nur, wenn der geschlossene Ring einrastet.",
                ar: "إغلاق حلقة بيران واحدة يفصل THC ذا التأثير النفسي عن CBD غير النفسي التأثير. مفتاح التبديل المزدوج Phe200/Trp356 في CB1 ينشط فقط عندما تتصل الحلقة المغلقة."
            ),
            dexNumber: 9
        ),

        // MARK: #010 - Salvinorin A (Terpenoid)

        PokeDrugSpecies(
            substanceId: "salvinorin-a",
            name: LocalizedString(en: "Salvinorin A", fr: "Salvinorine A", es: "Salvinorina A", ja: "サルビノリンA", zh: "沙尔维诺林A", ko: "살비노린 A", ru: "Сальвинорин А", de: "Salvinorin A", ar: "سالفينورين أ"),
            primaryType: .kappa,
            scaffold: .terpenoid,
            stats: PokeDrugStats(
                hp: 4,      // No deaths reported
                attack: 5,  // Ki 1.9 nM at KOR
                defense: 1, // 8 min brain clearance
                specialAttack: 5, // >5000x KOR selective — highest in PokeDrug
                specialDefense: 4, // Minimal tolerance
                speed: 5    // <30 sec smoked
            ),
            habitat: .tropicalJungle,
            flavorText: LocalizedString(
                en: "The most selective naturally occurring psychoactive compound: >5,000-fold KOR preference. The first non-nitrogenous opioid ligand, binding via a non-canonical epitope in TM II/VII. A glass cannon.",
                fr: "Le compose psychoactif naturel le plus selectif: preference KOR >5000 fois. Le premier ligand opioide non azote, se liant via un epitope non canonique dans TM II/VII. Un canon de verre.",
                es: "El compuesto psicoactivo natural mas selectivo: preferencia KOR >5,000 veces. El primer ligando opioide no nitrogenado, uniendose mediante un epitopo no canonico en TM II/VII. Un canon de cristal.",
                ja: "最も選択性の高い天然精神活性化合物：KOR選好性5,000倍以上。初の非窒素含有オピオイドリガンドで、TM II/VIIの非正規エピトープを介して結合する。ガラスの大砲。",
                zh: "选择性最高的天然精神活性化合物：KOR偏好性超过5,000倍。第一个非含氮阿片配体，通过TM II/VII中的非典型表位结合。一门玻璃大炮。",
                ko: "가장 선택성이 높은 천연 정신활성 화합물: KOR 선호도 5,000배 이상. 최초의 비질소 오피오이드 리간드로, TM II/VII의 비정규 에피토프를 통해 결합한다. 유리 대포.",
                ru: "Самое селективное природное психоактивное соединение: предпочтение КОР >5000 раз. Первый безазотный опиоидный лиганд, связывающийся через неканонический эпитоп в ТМ II/VII. Стеклянная пушка.",
                de: "Die selektivste naturlich vorkommende psychoaktive Verbindung: >5.000-fache KOR-Praferenz. Der erste stickstofffreie Opioid-Ligand, der uber ein nicht-kanonisches Epitop in TM II/VII bindet. Eine Glaskanone.",
                ar: "أكثر المركبات النفسية التأثير الطبيعية انتقائية: تفضيل KOR أكثر من 5,000 ضعف. أول رابط أفيوني غير نيتروجيني، يرتبط عبر حاتمة غير تقليدية في TM II/VII. مدفع زجاجي."
            ),
            dexNumber: 10
        ),

        // MARK: #011 - Caffeine (Xanthine)

        PokeDrugSpecies(
            substanceId: "caffeine",
            name: LocalizedString(en: "Caffeine", fr: "Cafeine", es: "Cafeína", ja: "カフェイン", zh: "咖啡因", ko: "카페인", ru: "Кофеин", de: "Koffein", ar: "كافيين"),
            primaryType: .adenosine,
            scaffold: .xanthine,
            stats: PokeDrugStats(
                hp: 4,      // TI ~100
                attack: 1,  // A1 Ki ~12 uM (weak)
                defense: 4, // t1/2 3-7h
                specialAttack: 2, // Non-selective A1/A2A
                specialDefense: 3, // Days-weeks tolerance
                speed: 4    // 15-45 min
            ),
            habitat: .tropicalPlantations,
            flavorText: LocalizedString(
                en: "Evolved independently at least five times in unrelated plant families. Normal coffee yields 20-60 uM plasma concentration — enough for 30-50% adenosine receptor occupancy despite weak Ki.",
                fr: "A evolue independamment au moins cinq fois dans des familles vegetales non apparentees. Le cafe normal produit 20-60 uM de concentration plasmatique — suffisant pour 30-50% d'occupation des recepteurs malgre un Ki faible.",
                es: "Evoluciono independientemente al menos cinco veces en familias de plantas no relacionadas. El cafe normal produce 20-60 uM de concentracion plasmatica — suficiente para 30-50% de ocupacion del receptor de adenosina pese a un Ki debil.",
                ja: "無関係の植物科で少なくとも5回独立に進化した。通常のコーヒーは血漿濃度20〜60 μMをもたらす — 弱いKiにもかかわらずアデノシン受容体占有率30〜50%に十分。",
                zh: "在不相关的植物科中至少独立进化了五次。普通咖啡产生20-60 μM的血浆浓度——尽管Ki较弱，仍足以占据30-50%的腺苷受体。",
                ko: "관련 없는 식물과에서 최소 5회 독립적으로 진화했다. 일반 커피는 혈장 농도 20-60 μM을 생성 — 약한 Ki에도 불구하고 아데노신 수용체 점유율 30-50%에 충분하다.",
                ru: "Эволюционировал независимо минимум пять раз в неродственных семействах растений. Обычный кофе дает плазменную концентрацию 20-60 мкМ — достаточно для 30-50% занятости аденозиновых рецепторов несмотря на слабый Ki.",
                de: "Mindestens funfmal unabhangig in nicht verwandten Pflanzenfamilien entstanden. Normaler Kaffee liefert 20-60 uM Plasmakonzentration — genug fur 30-50% Adenosinrezeptorbelegung trotz schwachem Ki.",
                ar: "تطور بشكل مستقل خمس مرات على الأقل في عائلات نباتية غير مرتبطة. ينتج القهوة العادية تركيزاً بلازمياً 20-60 ميكرومولار — كافٍ لشغل 30-50% من مستقبلات الأدينوزين رغم ضعف Ki."
            ),
            dexNumber: 11
        ),

        // MARK: #012 - Nicotine (Cholinergic)

        PokeDrugSpecies(
            substanceId: "nicotine",
            name: LocalizedString(en: "Nicotine", fr: "Nicotine", es: "Nicotina", ja: "ニコチン", zh: "尼古丁", ko: "니코틴", ru: "Никотин", de: "Nikotin", ar: "نيكوتين"),
            primaryType: .cholinergic,
            scaffold: .tropane, // Pyridine-pyrrolidine, closest scaffold family
            stats: PokeDrugStats(
                hp: 2,      // TI ~10-15 (narrow for pure compound)
                attack: 4,  // nAChR agonist, moderate affinity
                defense: 2, // t1/2 ~2h
                specialAttack: 3, // Selective for nAChR subtypes
                specialDefense: 1, // Rapid tolerance + dependence
                speed: 5    // ~10 min inhaled, seconds IV
            ),
            habitat: .tropicalJungle,
            flavorText: LocalizedString(
                en: "A pyridine-pyrrolidine that mimics acetylcholine at nicotinic receptors. One rotatable bond between its two rings. Extreme Speed but poor Sp. Def — the archetype of addictive pharmacokinetics.",
                fr: "Une pyridine-pyrrolidine qui mime l'acetylcholine aux recepteurs nicotiniques. Une liaison rotative entre ses deux cycles. Vitesse extreme mais mauvaise Def. Sp. — l'archetype de la pharmacocinetique addictive.",
                es: "Una piridina-pirrolidina que mimetiza la acetilcolina en los receptores nicotinicos. Un enlace rotable entre sus dos anillos. Velocidad extrema pero pobre Def. Esp. — el arquetipo de la farmacocinetica adictiva.",
                ja: "ニコチン受容体でアセチルコリンを模倣するピリジン-ピロリジン。2つの環の間に回転可能な結合が1つ。極端なスピードだが低い特防 — 依存性薬物動態の原型。",
                zh: "一种在烟碱受体上模拟乙酰胆碱的吡啶-吡咯烷。两个环之间有一个可旋转键。极高速度但特防差——成瘾性药代动力学的原型。",
                ko: "니코틴 수용체에서 아세틸콜린을 모방하는 피리딘-피롤리딘. 두 고리 사이에 회전 가능한 결합 하나. 극한의 스피드지만 낮은 특방 — 중독성 약동학의 원형.",
                ru: "Пиридин-пирролидин, имитирующий ацетилхолин на никотиновых рецепторах. Одна вращающаяся связь между двумя кольцами. Экстремальная Скорость, но слабая Сп. Защита — архетип аддиктивной фармакокинетики.",
                de: "Ein Pyridin-Pyrrolidin, das Acetylcholin an nikotinischen Rezeptoren nachahmt. Eine drehbare Bindung zwischen seinen beiden Ringen. Extreme Geschwindigkeit aber schwache Sp. Vert. — der Archetyp suchterzeugender Pharmakokinetik.",
                ar: "بيريدين-بيروليدين يحاكي الأسيتيل كولين في المستقبلات النيكوتينية. رابطة دوّارة واحدة بين حلقتيه. سرعة قصوى لكن دفاع خاص ضعيف — النموذج الأصلي للحركيات الدوائية المسببة للإدمان."
            ),
            dexNumber: 12
        ),

        // MARK: #013 - Atropine (Tropane)

        PokeDrugSpecies(
            substanceId: "atropine",
            name: LocalizedString(en: "Atropine", fr: "Atropine", es: "Atropina", ja: "アトロピン", zh: "阿托品", ko: "아트로핀", ru: "Атропин", de: "Atropin", ar: "أتروبين"),
            primaryType: .cholinergic,
            scaffold: .tropane,
            stats: PokeDrugStats(
                hp: 2,      // Narrow TI, especially in children
                attack: 4,  // Potent mAChR antagonist
                defense: 3, // t1/2 ~4h
                specialAttack: 3, // Selective mAChR antagonist
                specialDefense: 3,
                speed: 3    // 15-60 min oral
            ),
            habitat: .asianHighlands,
            flavorText: LocalizedString(
                en: "The 3-alpha-tropic acid ester on the tropane ring fits muscarinic receptors instead of DAT. Same scaffold as cocaine, completely different pharmacology — stereochemistry at C-3 is the switch.",
                fr: "L'ester d'acide tropique 3-alpha sur le cycle tropane s'adapte aux recepteurs muscariniques au lieu du DAT. Meme squelette que la cocaine, pharmacologie completement differente — la stereochimie au C-3 est le commutateur.",
                es: "El ester del acido tropico 3-alfa en el anillo tropano se ajusta a los receptores muscarinicos en vez del DAT. Mismo esqueleto que la cocaina, farmacologia completamente diferente — la estereoquimica en C-3 es el interruptor.",
                ja: "トロパン環上の3-α-トロパ酸エステルがDATではなくムスカリン受容体に適合する。コカインと同じ骨格だが全く異なる薬理作用 — C-3の立体化学がスイッチとなる。",
                zh: "托烷环上的3-α-托品酸酯适配毒蕈碱受体而非DAT。与可卡因相同的骨架，药理作用完全不同——C-3位的立体化学是关键开关。",
                ko: "트로판 고리의 3-α-트로프산 에스테르가 DAT 대신 무스카린 수용체에 결합한다. 코카인과 동일한 골격이지만 완전히 다른 약리작용 — C-3의 입체화학이 스위치이다.",
                ru: "3-альфа-троповой эфир на тропановом кольце подходит к мускариновым рецепторам вместо DAT. Тот же скаффолд, что у кокаина, совершенно другая фармакология — стереохимия при C-3 является переключателем.",
                de: "Der 3-alpha-Tropasaureester am Tropanring passt zu muskarinischen Rezeptoren statt zum DAT. Gleiches Grundgerust wie Kokain, vollig andere Pharmakologie — die Stereochemie an C-3 ist der Schalter.",
                ar: "إستر حمض التروبيك 3-ألفا على حلقة التروبان يتلاءم مع المستقبلات المسكارينية بدلاً من DAT. نفس الهيكل العظمي للكوكايين، علم أدوية مختلف تماماً — الكيمياء الفراغية عند C-3 هي المفتاح."
            ),
            dexNumber: 13
        ),

        // MARK: #014 - Ketamine (Dissociative)

        PokeDrugSpecies(
            substanceId: "ketamine",
            name: LocalizedString(en: "Ketamine", fr: "Ketamine", es: "Ketamina", ja: "ケタミン", zh: "氯胺酮", ko: "케타민", ru: "Кетамин", de: "Ketamin", ar: "كيتامين"),
            primaryType: .dissociative,
            scaffold: .phenethylamine, // Arylcyclohexylamine class
            stats: PokeDrugStats(
                hp: 3,      // Moderate TI; anesthetic doses well-characterized
                attack: 4,  // NMDA channel blocker, effective at clinical doses
                defense: 2, // t1/2 ~2.5h
                specialAttack: 3, // Primarily NMDA but hits opioid, DA
                specialDefense: 2, // Tolerance develops over weeks
                speed: 4    // 5-20 min intranasal
            ),
            habitat: nil, // Fully synthetic
            flavorText: LocalizedString(
                en: "An arylcyclohexylamine that blocks the NMDA ion channel pore. FDA-approved as Spravato (esketamine) for treatment-resistant depression. Rapid antidepressant onset within hours.",
                fr: "Une arylcyclohexylamine qui bloque le pore du canal ionique NMDA. Approuve par la FDA comme Spravato (esketamine) pour la depression resistante au traitement. Action antidepressive rapide en quelques heures.",
                es: "Una arilciclohexilamina que bloquea el poro del canal ionico NMDA. Aprobada por la FDA como Spravato (esketamina) para la depresion resistente al tratamiento. Inicio antidepresivo rapido en horas.",
                ja: "NMDAイオンチャネル孔を遮断するアリールシクロヘキシルアミン。治療抵抗性うつ病に対しSpravato（エスケタミン）としてFDA承認。数時間以内に迅速な抗うつ効果発現。",
                zh: "一种阻断NMDA离子通道孔的芳基环己胺。以Spravato（艾司氯胺酮）获FDA批准用于难治性抑郁症。数小时内快速起效的抗抑郁作用。",
                ko: "NMDA 이온 채널 구멍을 차단하는 아릴사이클로헥실아민. 치료 저항성 우울증에 대해 Spravato(에스케타민)로 FDA 승인. 수 시간 내 빠른 항우울 효과 발현.",
                ru: "Арилциклогексиламин, блокирующий пору ионного канала NMDA. Одобрен FDA как Справато (эскетамин) для терапевтически резистентной депрессии. Быстрое антидепрессивное действие в течение часов.",
                de: "Ein Arylcyclohexylamin, das die NMDA-Ionenkanalpore blockiert. FDA-zugelassen als Spravato (Esketamin) bei therapieresistenter Depression. Schneller antidepressiver Wirkungseintritt innerhalb von Stunden.",
                ar: "أريل سيكلوهكسيل أمين يحجب مسام القناة الأيونية NMDA. معتمد من FDA باسم Spravato (إسكيتامين) للاكتئاب المقاوم للعلاج. بداية سريعة للتأثير المضاد للاكتئاب خلال ساعات."
            ),
            dexNumber: 14
        ),

        // MARK: #015 - Mescaline (Phenethylamine)

        PokeDrugSpecies(
            substanceId: "mescaline",
            name: LocalizedString(en: "Mescaline", fr: "Mescaline", es: "Mescalina", ja: "メスカリン", zh: "麦司卡林", ko: "메스칼린", ru: "Мескалин", de: "Mescalin", ar: "ميسكالين"),
            primaryType: .serotonin,
            scaffold: .phenethylamine,
            stats: PokeDrugStats(
                hp: 4,      // High safety ratio
                attack: 2,  // Ki ~3600-6400 nM (weak, compensated by high dose)
                defense: 3, // t1/2 ~6h
                specialAttack: 3, // 5-HT2A selective at psychedelic doses
                specialDefense: 2, // Tolerance similar to other psychedelics
                speed: 2    // 45-90 min oral
            ),
            habitat: .desertMesa,
            flavorText: LocalizedString(
                en: "3,4,5-Trimethoxylation transforms the stimulant phenethylamine into a psychedelic — a complete type change from Dopamine to Serotonin. 5,700+ years of ceremonial use in peyote cacti.",
                fr: "La 3,4,5-trimethoxylation transforme la phenethylamine stimulante en psychedelique — un changement de type complet de Dopamine a Serotonine. Plus de 5 700 ans d'utilisation ceremonielle dans les cactus peyotl.",
                es: "La 3,4,5-trimetoxilacion transforma la fenetilamina estimulante en un psicodelico — un cambio de tipo completo de Dopamina a Serotonina. Mas de 5.700 anos de uso ceremonial en cactus de peyote.",
                ja: "3,4,5-トリメトキシル化が覚醒剤フェネチルアミンをサイケデリクスに変換する — ドーパミンからセロトニンへの完全なタイプチェンジ。ペヨーテサボテンでの5,700年以上の儀式的使用。",
                zh: "3,4,5-三甲氧基化将兴奋剂苯乙胺转化为致幻剂——从多巴胺到血清素的完全类型转换。在佩奥特仙人掌中有超过5,700年的仪式使用历史。",
                ko: "3,4,5-트리메톡실화가 각성제 페네틸아민을 사이키델릭으로 전환한다 — 도파민에서 세로토닌으로의 완전한 타입 변환. 페요테 선인장에서 5,700년 이상의 의식적 사용.",
                ru: "3,4,5-Триметоксилирование превращает стимулятор фенэтиламин в психоделик — полная смена типа с Дофамина на Серотонин. Более 5 700 лет церемониального использования в кактусах пейота.",
                de: "3,4,5-Trimethoxylierung verwandelt das Stimulans Phenethylamin in ein Psychedelikum — ein vollstandiger Typwechsel von Dopamin zu Serotonin. Uber 5.700 Jahre zeremonieller Gebrauch in Peyote-Kakteen.",
                ar: "يحول الميثوكسيل الثلاثي 3,4,5 الفينيثيلامين المنشط إلى مخدر نفسي — تغيير كامل في النوع من الدوبامين إلى السيروتونين. أكثر من 5,700 سنة من الاستخدام الاحتفالي في صبار البيوت."
            ),
            dexNumber: 15
        ),

        // MARK: #016 - Ibogaine (Iboga)

        PokeDrugSpecies(
            substanceId: "ibogaine",
            name: LocalizedString(en: "Ibogaine", fr: "Ibogaine", es: "Ibogaína", ja: "イボガイン", zh: "伊博格碱", ko: "이보가인", ru: "Ибогаин", de: "Ibogain", ar: "إيبوغايين"),
            primaryType: .opioid,
            secondaryType: .dissociative,
            scaffold: .iboga,
            stats: PokeDrugStats(
                hp: 1,      // Narrow TI (hERG cardiac risk)
                attack: 5,  // nAChR Ki ~20 nM
                defense: 5, // Noribogaine t1/2 24-48h
                specialAttack: 1, // Hits 6+ targets — lowest selectivity
                specialDefense: 5, // Single dose; non-repeated
                speed: 2    // 1-3h oral
            ),
            habitat: .africanRainforest,
            flavorText: LocalizedString(
                en: "The only triple-type natural compound: Opioid/Dissociative/Empathogen. Engages 6+ pharmacologically distinct targets simultaneously. Noribogaine sustains effects for days. Narrow HP from hERG block.",
                fr: "Le seul compose naturel a triple type: Opioide/Dissociatif/Empathogene. Engage 6+ cibles pharmacologiquement distinctes simultanement. La noribogaine maintient les effets pendant des jours. HP etroit du blocage hERG.",
                es: "El unico compuesto natural de triple tipo: Opioide/Disociativo/Empatogeno. Involucra 6+ dianas farmacologicamente distintas simultaneamente. La noribogaina mantiene los efectos durante dias. HP estrecho por bloqueo hERG.",
                ja: "唯一のトリプルタイプ天然化合物：オピオイド/解離性/エンパソゲン。6つ以上の薬理学的に異なる標的を同時に結合。ノルイボガインが効果を数日間持続。hERGブロックによる狭いHP。",
                zh: "唯一的三重类型天然化合物：阿片/解离/共情。同时作用于6个以上药理学上不同的靶点。去甲伊博格碱可维持数天的效果。因hERG阻断导致HP狭窄。",
                ko: "유일한 삼중 타입 천연 화합물: 오피오이드/해리성/엠파토겐. 약리학적으로 구별되는 6개 이상의 표적에 동시 작용. 노르이보가인이 수일간 효과를 지속. hERG 차단으로 인한 좁은 HP.",
                ru: "Единственное природное соединение тройного типа: Опиоид/Диссоциатив/Эмпатоген. Задействует 6+ фармакологически различных мишеней одновременно. Норибогаин поддерживает эффекты днями. Узкий HP из-за блокады hERG.",
                de: "Die einzige Naturverbindung mit Dreifachtyp: Opioid/Dissoziativ/Empathogen. Bindet gleichzeitig an 6+ pharmakologisch unterschiedliche Ziele. Noribogain halt die Wirkung tagelang aufrecht. Enger HP durch hERG-Blockade.",
                ar: "المركب الطبيعي الوحيد ثلاثي النوع: أفيوني/تفارقي/إمباثوجين. يستهدف 6+ أهداف دوائية مختلفة في وقت واحد. يحافظ النوريبوغايين على التأثيرات لأيام. HP ضيق بسبب حصار hERG."
            ),
            dexNumber: 16
        ),

        // MARK: #017 - Cathinone (Phenethylamine)

        PokeDrugSpecies(
            substanceId: "cathinone",
            name: LocalizedString(en: "Cathinone", fr: "Cathinone", es: "Catinona", ja: "カチノン", zh: "卡西酮", ko: "카티논", ru: "Катинон", de: "Cathinon", ar: "كاثينون"),
            primaryType: .stimulant,
            scaffold: .phenethylamine,
            stats: PokeDrugStats(
                hp: 2,      // Similar to amphetamine
                attack: 3,  // Moderate NET/DAT release
                defense: 2, // t1/2 ~1.5h
                specialAttack: 2, // Non-selective monoamine releaser
                specialDefense: 2,
                speed: 3    // 30 min oral (khat chewing)
            ),
            habitat: .africanRainforest,
            flavorText: LocalizedString(
                en: "Nature's amphetamine: a beta-keto phenethylamine from Catha edulis. The keto group makes it less potent than amphetamine but still an effective NET/DAT releaser. Chewed fresh in the Horn of Africa.",
                fr: "L'amphetamine de la nature: une beta-keto phenethylamine de Catha edulis. Le groupe keto la rend moins puissante que l'amphetamine mais reste un liberateur NET/DAT efficace. Machee fraiche dans la Corne de l'Afrique.",
                es: "La anfetamina de la naturaleza: una beta-ceto fenetilamina de Catha edulis. El grupo ceto la hace menos potente que la anfetamina pero sigue siendo un liberador NET/DAT eficaz. Masticada fresca en el Cuerno de Africa.",
                ja: "天然のアンフェタミン：カート（Catha edulis）由来のβ-ケトフェネチルアミン。ケト基によりアンフェタミンより弱いが、依然として有効なNET/DAT放出剤。アフリカの角で生の葉を咀嚼。",
                zh: "大自然的安非他明：来自恰特草（Catha edulis）的β-酮基苯乙胺。酮基使其效力不如安非他明，但仍是有效的NET/DAT释放剂。在非洲之角新鲜咀嚼。",
                ko: "자연의 암페타민: 카트(Catha edulis)에서 유래한 β-케토 페네틸아민. 케토기가 암페타민보다 약하게 만들지만 여전히 효과적인 NET/DAT 방출제. 아프리카의 뿔에서 신선하게 씹어 섭취.",
                ru: "Амфетамин природы: бета-кето фенэтиламин из Catha edulis. Кетогруппа делает его менее мощным, чем амфетамин, но он остается эффективным релизером NET/DAT. Жуют свежим на Африканском Роге.",
                de: "Das Amphetamin der Natur: ein Beta-Keto-Phenethylamin aus Catha edulis. Die Ketogruppe macht es schwacher als Amphetamin, aber es bleibt ein wirksamer NET/DAT-Releaser. Am Horn von Afrika frisch gekaut.",
                ar: "أمفيتامين الطبيعة: بيتا-كيتو فينيثيلامين من القات (Catha edulis). مجموعة الكيتو تجعله أقل فعالية من الأمفيتامين لكنه يبقى محرراً فعالاً لـ NET/DAT. يُمضغ طازجاً في القرن الأفريقي."
            ),
            dexNumber: 17
        ),

        // MARK: #018 - Apigenin (Flavonoid/Sedative)

        PokeDrugSpecies(
            substanceId: "apigenin",
            name: LocalizedString(en: "Apigenin", fr: "Apigenine", es: "Apigenina", ja: "アピゲニン", zh: "芹菜素", ko: "아피게닌", ru: "Апигенин", de: "Apigenin", ar: "أبيجينين"),
            primaryType: .sedative,
            scaffold: .isoquinoline, // Flavonoid — closest phenolic scaffold
            stats: PokeDrugStats(
                hp: 5,      // Extremely safe; natural flavonoid
                attack: 1,  // BZD-site affinity ~uM (very weak)
                defense: 4, // t1/2 ~12h
                specialAttack: 2, // GABA-A PAM, some other targets
                specialDefense: 3,
                speed: 2    // 30-60 min oral
            ),
            habitat: .tropicalPlantations,
            flavorText: LocalizedString(
                en: "A flavonoid from chamomile that acts as a weak GABA-A PAM at the benzodiazepine site. Maximum HP and minimum Attack — the gentlest sedative in the PokeDrug system.",
                fr: "Un flavonoide de la camomille qui agit comme un faible MAP du GABA-A au site des benzodiazepines. HP maximal et Attaque minimale — le sedatif le plus doux du systeme PokeDrug.",
                es: "Un flavonoide de la manzanilla que actua como un debil MAM del GABA-A en el sitio de benzodiacepinas. HP maximo y Ataque minimo — el sedante mas suave del sistema PokeDrug.",
                ja: "ベンゾジアゼピン部位でGABA-Aの弱い正のアロステリック調節因子として作用するカモミール由来のフラボノイド。最大HPと最小攻撃力 — PokeDrugシステムで最も穏やかな鎮静剤。",
                zh: "一种来自洋甘菊的黄酮类化合物，在苯二氮卓位点充当弱GABA-A正变构调节剂。最大HP和最小攻击——PokeDrug系统中最温和的镇静剂。",
                ko: "벤조디아제핀 부위에서 약한 GABA-A 양성 알로스테릭 조절제로 작용하는 카모마일 유래 플라보노이드. 최대 HP와 최소 공격력 — PokeDrug 시스템에서 가장 온화한 진정제.",
                ru: "Флавоноид из ромашки, действующий как слабый позитивный аллостерический модулятор ГАМК-А в бензодиазепиновом сайте. Максимальный HP и минимальная Атака — самый мягкий седатик в системе PokeDrug.",
                de: "Ein Flavonoid aus Kamille, das als schwacher GABA-A-PAM an der Benzodiazepin-Bindungsstelle wirkt. Maximaler HP und minimaler Angriff — das sanfteste Sedativum im PokeDrug-System.",
                ar: "فلافونويد من البابونج يعمل كمعدل تفارغي إيجابي ضعيف لـ GABA-A في موقع البنزوديازيبين. أقصى HP وأدنى هجوم — أخف مهدئ في نظام PokeDrug."
            ),
            dexNumber: 18
        ),

        // MARK: #019 - GHB (Sedative)

        PokeDrugSpecies(
            substanceId: "ghb",
            name: LocalizedString(en: "GHB", fr: "GHB", es: "GHB", ja: "GHB", zh: "GHB", ko: "GHB", ru: "ГОМК", de: "GHB", ar: "جي إتش بي"),
            primaryType: .sedative,
            scaffold: .isoquinoline, // Simple GABA analog, closest functional match
            stats: PokeDrugStats(
                hp: 2,      // Narrow TI; steep dose-response
                attack: 3,  // GABA-B agonist at therapeutic doses
                defense: 1, // t1/2 30-60 min
                specialAttack: 2,
                specialDefense: 2,
                speed: 3    // 15-45 min oral
            ),
            habitat: nil, // Endogenous neurotransmitter / synthetic
            flavorText: LocalizedString(
                en: "An endogenous neurotransmitter and GABA-B agonist. FDA-approved as Xyrem for narcolepsy. The steep dose-response curve creates a dangerously narrow therapeutic window.",
                fr: "Un neurotransmetteur endogene et agoniste GABA-B. Approuve par la FDA comme Xyrem pour la narcolepsie. La courbe dose-reponse abrupte cree une fenetre therapeutique dangereusement etroite.",
                es: "Un neurotransmisor endogeno y agonista GABA-B. Aprobado por la FDA como Xyrem para la narcolepsia. La curva dosis-respuesta pronunciada crea una ventana terapeutica peligrosamente estrecha.",
                ja: "内因性神経伝達物質でありGABA-Bアゴニスト。ナルコレプシーに対しXyremとしてFDA承認。急峻な用量反応曲線が危険なほど狭い治療域を生み出す。",
                zh: "一种内源性神经递质和GABA-B激动剂。以Xyrem获FDA批准用于发作性睡病。陡峭的剂量-反应曲线造成了危险的狭窄治疗窗口。",
                ko: "내인성 신경전달물질이자 GABA-B 작용제. 기면증 치료제 Xyrem으로 FDA 승인. 급경사 용량-반응 곡선이 위험할 정도로 좁은 치료 창을 만든다.",
                ru: "Эндогенный нейромедиатор и агонист ГАМК-Б. Одобрен FDA как Xyrem для нарколепсии. Крутая кривая доза-ответ создает опасно узкое терапевтическое окно.",
                de: "Ein endogener Neurotransmitter und GABA-B-Agonist. FDA-zugelassen als Xyrem bei Narkolepsie. Die steile Dosis-Wirkungs-Kurve schafft ein gefahrlich enges therapeutisches Fenster.",
                ar: "ناقل عصبي داخلي وناهض GABA-B. معتمد من FDA باسم Xyrem لعلاج الخدار. منحنى الجرعة-الاستجابة الحاد يخلق نافذة علاجية ضيقة بشكل خطير."
            ),
            dexNumber: 19
        ),

        // MARK: #020 - Methamphetamine (Phenethylamine)

        PokeDrugSpecies(
            substanceId: "methamphetamine",
            name: LocalizedString(en: "Methamphetamine", fr: "Methamphetamine", es: "Metanfetamina", ja: "メタンフェタミン", zh: "甲基苯丙胺", ko: "메스암페타민", ru: "Метамфетамин", de: "Methamphetamin", ar: "ميثامفيتامين"),
            primaryType: .dopamine,
            secondaryType: .stimulant,
            scaffold: .phenethylamine,
            stats: PokeDrugStats(
                hp: 1,      // Very narrow safety margin
                attack: 4,  // Potent DA/NE releaser
                defense: 5, // t1/2 10-12h
                specialAttack: 2, // Non-selective monoamine
                specialDefense: 1, // Rapid euphoria tolerance
                speed: 4    // Fast depending on route
            ),
            habitat: nil, // Synthetic
            flavorText: LocalizedString(
                en: "N-methylation of amphetamine: further increases lipophilicity and CNS penetration, boosting potency 3-5x while narrowing the safety margin. Each evolution step increases Attack while decreasing HP.",
                fr: "N-methylation de l'amphetamine: augmente encore la lipophilie et la penetration du SNC, augmentant la puissance de 3-5x tout en retrecissant la marge de securite. Chaque etape d'evolution augmente l'Attaque tout en diminuant les HP.",
                es: "N-metilacion de la anfetamina: aumenta aun mas la lipofilicidad y la penetracion en el SNC, potenciando la potencia 3-5x mientras estrecha el margen de seguridad. Cada paso evolutivo aumenta el Ataque mientras disminuye el HP.",
                ja: "アンフェタミンのN-メチル化：親油性とCNS浸透性をさらに高め、効力を3〜5倍に増強しつつ安全域を狭める。進化の各段階で攻撃力が上がりHPが下がる。",
                zh: "安非他明的N-甲基化：进一步增加亲脂性和中枢神经系统穿透力，将效力提升3-5倍同时收窄安全边际。每一步进化都增加攻击力同时降低HP。",
                ko: "암페타민의 N-메틸화: 친유성과 CNS 침투성을 더욱 높여 효력을 3-5배 증강하면서 안전 마진을 좁힌다. 각 진화 단계마다 공격력은 증가하고 HP는 감소한다.",
                ru: "N-метилирование амфетамина: дополнительно увеличивает липофильность и проникновение в ЦНС, повышая потенцию в 3-5 раз при сужении запаса безопасности. Каждый шаг эволюции увеличивает Атаку, снижая HP.",
                de: "N-Methylierung von Amphetamin: erhoht Lipophilie und ZNS-Penetration weiter, steigert die Potenz um das 3-5-fache bei gleichzeitiger Verengung der Sicherheitsmarge. Jeder Evolutionsschritt erhoht Angriff und senkt HP.",
                ar: "مثيلة-N للأمفيتامين: تزيد من محبة الدهون واختراق الجهاز العصبي المركزي، مما يعزز الفعالية 3-5 أضعاف مع تضييق هامش الأمان. كل خطوة تطورية تزيد الهجوم وتنقص HP."
            ),
            dexNumber: 20
        ),

        // MARK: #021 - Dronabinol (Terpenoid)

        PokeDrugSpecies(
            substanceId: "dronabinol",
            name: LocalizedString(en: "Dronabinol", fr: "Dronabinol", es: "Dronabinol", ja: "ドロナビノール", zh: "屈大麻酚", ko: "드로나비놀", ru: "Дронабинол", de: "Dronabinol", ar: "درونابينول"),
            primaryType: .cannabinoid,
            scaffold: .terpenoid,
            stats: PokeDrugStats(
                hp: 5,      // Same as THC
                attack: 4,  // Same pharmacology
                defense: 5, // Same t1/2
                specialAttack: 3,
                specialDefense: 3,
                speed: 2    // Oral: slower than smoked THC
            ),
            habitat: nil, // Synthetic THC
            flavorText: LocalizedString(
                en: "Synthetic THC (Marinol). Identical pharmacodynamics to plant-derived THC but oral-only formulation reduces Speed stat. FDA-approved, Schedule III.",
                fr: "THC synthetique (Marinol). Pharmacodynamique identique au THC derive de plantes mais la formulation orale uniquement reduit la stat Vitesse. Approuve par la FDA, Annexe III.",
                es: "THC sintetico (Marinol). Farmacodinamica identica al THC derivado de plantas pero la formulacion solo oral reduce la stat de Velocidad. Aprobado por la FDA, Lista III.",
                ja: "合成THC（マリノール）。植物由来THCと同一の薬力学だが、経口専用製剤がスピードステータスを低下させる。FDA承認、スケジュールIII。",
                zh: "合成THC（Marinol）。与植物来源THC药效学相同，但仅口服制剂降低了速度属性。FDA批准，附表III。",
                ko: "합성 THC (마리놀). 식물 유래 THC와 동일한 약력학이지만 경구 전용 제형이 스피드 스탯을 낮춘다. FDA 승인, 스케줄 III.",
                ru: "Синтетический ТГК (Маринол). Фармакодинамика идентична растительному ТГК, но пероральная форма снижает показатель Скорости. Одобрен FDA, Список III.",
                de: "Synthetisches THC (Marinol). Identische Pharmakodynamik wie pflanzliches THC, aber die orale Formulierung reduziert den Geschwindigkeitswert. FDA-zugelassen, Schedule III.",
                ar: "THC اصطناعي (مارينول). ديناميكيات دوائية مطابقة لـ THC المشتق من النبات لكن التركيبة الفموية فقط تقلل إحصائية السرعة. معتمد من FDA، الجدول III."
            ),
            dexNumber: 21
        ),
        // MARK: #022 - Diazepam (Benzodiazepine)

        PokeDrugSpecies(
            substanceId: "diazepam",
            name: LocalizedString(en: "Diazepam", fr: "Diazepam", es: "Diazepam", ja: "ジアゼパム", zh: "地西泮", ko: "디아제팜", ru: "Диазепам", de: "Diazepam", ar: "ديازيبام"),
            primaryType: .sedative,
            scaffold: .benzodiazepine,
            stats: PokeDrugStats(
                hp: 3,      // TI ~10-20; lethal in combination
                attack: 4,  // Ki ~10-20 nM at GABA-A BZD site
                defense: 5, // t1/2 20-100h (+ active metabolite desmethyldiazepam)
                specialAttack: 3, // GABA-A selective PAM, some muscle relaxant
                specialDefense: 1, // Rapid tolerance, severe dependence
                speed: 4    // Oral onset 15-30 min, rapid absorption
            ),
            habitat: nil,
            flavorText: LocalizedString(
                en: "The archetypal 1,4-benzodiazepine. Allosteric potentiation of GABA-A chloride flux via the benzodiazepine binding site between alpha and gamma subunits. Long-acting due to active metabolite desmethyldiazepam (t1/2 ~100h).",
                fr: "La 1,4-benzodiazepine archetypale. Potentialisation allosterique du flux de chlorure GABA-A via le site de liaison des benzodiazepines entre les sous-unites alpha et gamma. Action prolongee due au metabolite actif desmethyldiazepam (t1/2 ~100h).",
                es: "La 1,4-benzodiazepina arquetipica. Potenciacion alosterica del flujo de cloruro GABA-A a traves del sitio de union de benzodiazepinas entre las subunidades alfa y gamma. Accion prolongada debido al metabolito activo desmetildiazepam (t1/2 ~100h).",
                ja: "典型的な1,4-ベンゾジアゼピン。アルファとガンマサブユニット間のベンゾジアゼピン結合部位を介したGABA-A塩素イオン流のアロステリック増強。活性代謝物デスメチルジアゼパム（t1/2 ~100h）により長時間作用。",
                zh: "典型的1,4-苯二氮卓。通过α和γ亚基之间的苯二氮卓结合位点对GABA-A氯离子通量进行变构增强。由于活性代谢物去甲西泮（t1/2 ~100h）而长效。",
                ko: "전형적인 1,4-벤조디아제핀. 알파와 감마 소단위 사이의 벤조디아제핀 결합 부위를 통한 GABA-A 염소 이온 플럭스의 알로스테릭 강화. 활성 대사체 데스메틸디아제팜(t1/2 ~100h)으로 인해 장시간 작용.",
                ru: "Архетипический 1,4-бензодиазепин. Аллостерическая потенциация хлоридного потока ГАМК-А через сайт связывания бензодиазепинов между альфа- и гамма-субъединицами. Длительное действие благодаря активному метаболиту десметилдиазепаму (t1/2 ~100ч).",
                de: "Das archetypische 1,4-Benzodiazepin. Allosterische Potenzierung des GABA-A-Chloridflusses uber die Benzodiazepin-Bindungsstelle zwischen Alpha- und Gamma-Untereinheiten. Langwirkend durch aktiven Metaboliten Desmethyldiazepam (t1/2 ~100h).",
                ar: "البنزوديازيبين 1,4 النموذجي. تعزيز تفارغي لتدفق كلوريد GABA-A عبر موقع ربط البنزوديازيبين بين الوحدات الفرعية ألفا وغاما. طويل المفعول بسبب المستقلب النشط ديسميثيل ديازيبام (t1/2 ~100 ساعة)."
            ),
            dexNumber: 22
        ),

        // MARK: #023 - Psilocin (Tryptamine)

        PokeDrugSpecies(
            substanceId: "psilocin",
            name: LocalizedString(en: "Psilocin", fr: "Psilocine", es: "Psilocina", ja: "サイロシン", zh: "脱磷酸裸盖菇素", ko: "실로신", ru: "Псилоцин", de: "Psilocin", ar: "سيلوسين"),
            primaryType: .serotonin,
            scaffold: .tryptamine,
            stats: PokeDrugStats(
                hp: 5,      // TI ~1000; no confirmed deaths from psilocin alone
                attack: 5,  // Ki 6-10 nM at 5-HT2A (dephosphorylated active form)
                defense: 2, // t1/2 ~2.5h; rapid glucuronidation
                specialAttack: 3, // 5-HT2A/2B/1A; narrower than LSD
                specialDefense: 2, // Full tolerance in 3 days
                speed: 4    // Onset 15-30 min oral (no prodrug delay vs psilocybin)
            ),
            habitat: .fungalForest,
            flavorText: LocalizedString(
                en: "The active metabolite of psilocybin, formed by alkaline phosphatase dephosphorylation. Direct 5-HT2A agonist with Ki 6-10 nM. Faster onset than the prodrug but identical receptor pharmacology. Unstable in solution due to oxidation of the 4-hydroxyindole.",
                fr: "Le metabolite actif de la psilocybine, forme par dephosphorylation par la phosphatase alcaline. Agoniste direct du 5-HT2A avec Ki 6-10 nM. Debut plus rapide que le prodrogue mais pharmacologie receptorielle identique. Instable en solution en raison de l'oxydation du 4-hydroxyindole.",
                es: "El metabolito activo de la psilocibina, formado por desfosforilacion por fosfatasa alcalina. Agonista directo de 5-HT2A con Ki 6-10 nM. Inicio mas rapido que el profarmaco pero farmacologia receptorial identica. Inestable en solucion debido a la oxidacion del 4-hidroxiindol.",
                ja: "アルカリホスファターゼ脱リン酸化により生成されるシロシビンの活性代謝物。Ki 6-10 nMの直接的5-HT2Aアゴニスト。プロドラッグより速い発現だが受容体薬理学は同一。4-ヒドロキシインドールの酸化により溶液中で不安定。",
                zh: "由碱性磷酸酶脱磷酸形成的赛洛西宾活性代谢物。直接5-HT2A激动剂，Ki 6-10 nM。比前药起效更快但受体药理学相同。由于4-羟基吲哚氧化而在溶液中不稳定。",
                ko: "알칼리 포스파타아제 탈인산화로 형성되는 실로시빈의 활성 대사체. Ki 6-10 nM의 직접적 5-HT2A 작용제. 전구약물보다 빠른 발현이지만 동일한 수용체 약리학. 4-하이드록시인돌 산화로 용액에서 불안정.",
                ru: "Активный метаболит псилоцибина, образующийся при дефосфорилировании щелочной фосфатазой. Прямой агонист 5-HT2A с Ki 6-10 нМ. Более быстрое начало действия, чем у пролекарства, но идентичная рецепторная фармакология. Нестабилен в растворе из-за окисления 4-гидроксииндола.",
                de: "Der aktive Metabolit von Psilocybin, gebildet durch alkalische Phosphatase-Dephosphorylierung. Direkter 5-HT2A-Agonist mit Ki 6-10 nM. Schnellerer Wirkungseintritt als das Prodrug, aber identische Rezeptorpharmakologie. Instabil in Losung aufgrund der Oxidation des 4-Hydroxyindols.",
                ar: "المستقلب النشط للسيلوسيبين، يتكون عن طريق إزالة الفسفرة بالفوسفاتاز القلوية. ناهض مباشر لـ 5-HT2A مع Ki 6-10 نانومول. بداية أسرع من الدواء الأولي لكن بنفس الحركية الدوائية المستقبلية. غير مستقر في المحلول بسبب أكسدة 4-هيدروكسي إندول."
            ),
            dexNumber: 23
        ),

        // MARK: #024 - MDA (Benzodioxole)

        PokeDrugSpecies(
            substanceId: "mda",
            name: LocalizedString(en: "MDA", fr: "MDA", es: "MDA", ja: "MDA", zh: "MDA", ko: "MDA", ru: "МДА", de: "MDA", ar: "إم دي إيه"),
            primaryType: .empathogen,
            secondaryType: .serotonin,
            scaffold: .benzodioxole,
            stats: PokeDrugStats(
                hp: 2,      // TI ~10; serotonergic neurotoxicity at high doses
                attack: 4,  // EC50 ~100 nM SERT release + 5-HT2A Ki ~300 nM
                defense: 4, // t1/2 ~8-12h; N-demethylation to HHA
                specialAttack: 4, // Dual: SERT releaser + 5-HT2A agonist
                specialDefense: 1, // Serotonin depletion; 3+ week recovery
                speed: 3    // Oral onset 30-60 min
            ),
            habitat: nil,
            flavorText: LocalizedString(
                en: "The parent compound of MDMA, lacking the N-methyl group. Dual mechanism: monoamine release via SERT/DAT/NET plus direct 5-HT2A agonism producing more psychedelic character than MDMA. Nichols 1986 established the structure-empathogenesis relationship.",
                fr: "Le compose parent du MDMA, depourvu du groupe N-methyle. Double mecanisme: liberation de monoamines via SERT/DAT/NET plus agonisme direct du 5-HT2A produisant un caractere plus psychedelique que le MDMA. Nichols 1986 a etabli la relation structure-empathogenese.",
                es: "El compuesto madre del MDMA, sin el grupo N-metilo. Doble mecanismo: liberacion de monoaminas via SERT/DAT/NET mas agonismo directo de 5-HT2A produciendo un caracter mas psicodelico que el MDMA. Nichols 1986 establecio la relacion estructura-empatogenesis.",
                ja: "N-メチル基を欠くMDMAの親化合物。二重機構：SERT/DAT/NETを介したモノアミン放出と直接的5-HT2Aアゴニズムにより、MDMAよりサイケデリックな性質を生む。Nichols 1986が構造-共感発生関係を確立。",
                zh: "MDMA的母体化合物，缺少N-甲基。双重机制：通过SERT/DAT/NET释放单胺加上直接5-HT2A激动作用，产生比MDMA更强的致幻特性。Nichols 1986建立了结构-共情发生关系。",
                ko: "N-메틸기가 없는 MDMA의 모체 화합물. 이중 기전: SERT/DAT/NET을 통한 모노아민 방출과 직접적 5-HT2A 작용으로 MDMA보다 더 환각적 특성 생성. Nichols 1986이 구조-공감발생 관계 확립.",
                ru: "Родительское соединение МДМА без N-метильной группы. Двойной механизм: высвобождение моноаминов через СЕРТ/ДАТ/НЭТ плюс прямой агонизм 5-HT2A, создающий более психоделический характер, чем у МДМА. Николс 1986 установил связь структура-эмпатогенез.",
                de: "Die Muttersubstanz von MDMA ohne N-Methylgruppe. Doppelmechanismus: Monoamin-Freisetzung uber SERT/DAT/NET plus direkter 5-HT2A-Agonismus mit starkerem psychedelischem Charakter als MDMA. Nichols 1986 etablierte die Struktur-Empathogenese-Beziehung.",
                ar: "المركب الأم لـ MDMA، بدون مجموعة N-ميثيل. آلية مزدوجة: إطلاق أحادي الأمين عبر SERT/DAT/NET بالإضافة إلى ناهض مباشر لـ 5-HT2A مما ينتج طابعاً أكثر نفسانية من MDMA. أسس نيكولز 1986 علاقة البنية-التعاطف."
            ),
            dexNumber: 24
        ),

        // MARK: #025 - Scopolamine (Tropane)

        PokeDrugSpecies(
            substanceId: "scopolamine",
            name: LocalizedString(en: "Scopolamine", fr: "Scopolamine", es: "Escopolamina", ja: "スコポラミン", zh: "东莨菪碱", ko: "스코폴라민", ru: "Скополамин", de: "Scopolamin", ar: "سكوبولامين"),
            primaryType: .cholinergic,
            scaffold: .tropane,
            stats: PokeDrugStats(
                hp: 2,      // TI ~10; anticholinergic toxidrome lethal
                attack: 3,  // Ki ~0.3-1 nM at mAChR (sub-nM but nonselective)
                defense: 3, // t1/2 ~4-5h; hepatic CYP3A4
                specialAttack: 2, // Nonselective across M1-M5 subtypes
                specialDefense: 3, // Moderate tolerance development
                speed: 3    // Transdermal slow; oral 20-30 min
            ),
            habitat: .tropicalJungle,
            flavorText: LocalizedString(
                en: "Tropane alkaloid anticholinergic from Brugmansia and Datura species. Sub-nanomolar muscarinic antagonist (Ki ~0.3 nM) blocking all five mAChR subtypes. Used clinically as a transdermal patch for motion sickness. Deliriant at high doses via central M1 blockade.",
                fr: "Anticholinergique alcaloide tropane de Brugmansia et Datura. Antagoniste muscarinique sub-nanomolaire (Ki ~0,3 nM) bloquant les cinq sous-types mAChR. Utilise cliniquement en patch transdermique contre le mal des transports. Deliriant a hautes doses via le blocage central M1.",
                es: "Alcaloide tropano anticolinergico de Brugmansia y Datura. Antagonista muscarinico sub-nanomolar (Ki ~0,3 nM) que bloquea los cinco subtipos mAChR. Usado clinicamente como parche transdermico para mareo. Delirante a dosis altas via bloqueo central M1.",
                ja: "ブルグマンシアとダチュラ由来のトロパンアルカロイド抗コリン薬。サブナノモル濃度のムスカリン拮抗薬（Ki ~0.3 nM）で5つ全てのmAChRサブタイプを遮断。経皮パッチとして乗り物酔いに臨床使用。高用量で中枢M1遮断によるせん妄。",
                zh: "来自曼陀罗属植物的托烷生物碱抗胆碱药。亚纳摩尔级毒蕈碱拮抗剂（Ki ~0.3 nM）阻断全部五种mAChR亚型。临床用作透皮贴剂治疗晕动病。高剂量时通过中枢M1阻断产生谵妄。",
                ko: "브루그만시아와 다투라 종에서 유래한 트로판 알칼로이드 항콜린제. 서브나노몰 무스카린 길항제(Ki ~0.3 nM)로 5가지 모든 mAChR 하위 유형 차단. 멀미용 경피 패치로 임상 사용. 고용량에서 중추 M1 차단을 통한 섬망.",
                ru: "Тропановый алкалоид-антихолинергик из Бругмансии и Датуры. Субнаномолярный мускариновый антагонист (Ki ~0,3 нМ), блокирующий все пять подтипов мАХР. Клинически используется как трансдермальный пластырь от укачивания. Делириант в высоких дозах через центральную блокаду М1.",
                de: "Tropanalkaloid-Anticholinergikum aus Brugmansia und Datura. Subnanomolarer Muskarinantagonist (Ki ~0,3 nM), der alle funf mAChR-Subtypen blockiert. Klinisch als transdermales Pflaster gegen Reisekrankheit. Deliriant in hohen Dosen uber zentrale M1-Blockade.",
                ar: "قلويد تروبان مضاد للكولين من البروغمانسيا والداتورا. مضاد موسكاريني دون نانومولي (Ki ~0.3 نانومول) يحجب جميع الأنواع الفرعية الخمسة لـ mAChR. يُستخدم سريرياً كلصقة عبر الجلد لدوار الحركة. مُهلِّس بجرعات عالية عبر حصار M1 المركزي."
            ),
            dexNumber: 25
        ),

        // MARK: #026 - Muscimol (Isoxazole)

        PokeDrugSpecies(
            substanceId: "muscimol",
            name: LocalizedString(en: "Muscimol", fr: "Muscimol", es: "Muscimol", ja: "ムシモール", zh: "蝇蕈醇", ko: "무시몰", ru: "Мусцимол", de: "Muscimol", ar: "موسيمول"),
            primaryType: .sedative,
            scaffold: .isoxazole,
            stats: PokeDrugStats(
                hp: 3,      // TI ~15-20; Amanita muscaria rarely lethal
                attack: 4,  // Ki ~6-10 nM at GABA-A orthosteric site
                defense: 3, // t1/2 ~4-6h
                specialAttack: 1, // Orthosteric GABA-A agonist; hits all subtypes
                specialDefense: 3, // Moderate tolerance development
                speed: 2    // Oral onset 30-90 min (variable absorption)
            ),
            habitat: .fungalForest,
            flavorText: LocalizedString(
                en: "Isoxazole amino acid from Amanita muscaria, acting as a direct GABA-A orthosteric agonist (Ki ~6 nM). Unlike benzodiazepines which are allosteric, muscimol binds the GABA site itself. Produces a unique dreamy delirium distinct from GABAergic sedation. Krogsgaard-Larsen 1977.",
                fr: "Acide amine isoxazole d'Amanita muscaria, agissant comme agoniste orthosterique direct du GABA-A (Ki ~6 nM). Contrairement aux benzodiazepines allosteriques, le muscimol se lie au site GABA lui-meme. Produit un delire onirique unique distinct de la sedation GABAergique. Krogsgaard-Larsen 1977.",
                es: "Aminoacido isoxazol de Amanita muscaria, actuando como agonista ortosterico directo de GABA-A (Ki ~6 nM). A diferencia de las benzodiazepinas alostericas, el muscimol se une al sitio GABA mismo. Produce un delirio onirico unico distinto de la sedacion GABAergica. Krogsgaard-Larsen 1977.",
                ja: "テングタケ由来のイソキサゾールアミノ酸。直接的GABA-Aオルソステリックアゴニスト（Ki ~6 nM）として作用。アロステリックなベンゾジアゼピンとは異なり、ムシモールはGABA部位自体に結合。GABA作動性鎮静とは異なる独特の夢見心地のせん妄を生じる。Krogsgaard-Larsen 1977。",
                zh: "来自毒蝇伞的异恶唑氨基酸，作为直接GABA-A正位激动剂（Ki ~6 nM）发挥作用。与变构的苯二氮卓不同，蝇蕈醇结合GABA位点本身。产生独特的梦幻谵妄，与GABA能镇静不同。Krogsgaard-Larsen 1977。",
                ko: "독우산광대버섯의 이소옥사졸 아미노산. 직접적 GABA-A 정위 작용제(Ki ~6 nM)로 작용. 알로스테릭인 벤조디아제핀과 달리 무시몰은 GABA 부위 자체에 결합. GABA성 진정과 다른 독특한 몽환적 섬망 생성. Krogsgaard-Larsen 1977.",
                ru: "Изоксазольная аминокислота из Мухомора красного, действующая как прямой ортостерический агонист ГАМК-А (Ki ~6 нМ). В отличие от аллостерических бензодиазепинов, мусцимол связывается непосредственно с сайтом ГАМК. Вызывает уникальный сноподобный делирий, отличный от ГАМКергической седации. Krogsgaard-Larsen 1977.",
                de: "Isoxazol-Aminosaure aus Amanita muscaria, die als direkter GABA-A-orthosterischer Agonist (Ki ~6 nM) wirkt. Anders als allosterische Benzodiazepine bindet Muscimol an die GABA-Stelle selbst. Erzeugt ein einzigartiges traumartiges Delirium, verschieden von GABAerger Sedierung. Krogsgaard-Larsen 1977.",
                ar: "حمض أميني إيزوكسازولي من فطر أمانيتا موسكاريا، يعمل كناهض موضعي مباشر لـ GABA-A (Ki ~6 نانومول). على عكس البنزوديازيبينات التفارغية، يرتبط الموسيمول بموقع GABA نفسه. ينتج هذياناً حالماً فريداً مختلفاً عن التهدئة GABAergic. Krogsgaard-Larsen 1977."
            ),
            dexNumber: 26
        ),

        // MARK: #027 - Ephedrine (Phenethylamine)

        PokeDrugSpecies(
            substanceId: "ephedrine",
            name: LocalizedString(en: "Ephedrine", fr: "Ephedrine", es: "Efedrina", ja: "エフェドリン", zh: "麻黄碱", ko: "에페드린", ru: "Эфедрин", de: "Ephedrin", ar: "إيفيدرين"),
            primaryType: .stimulant,
            scaffold: .phenethylamine,
            stats: PokeDrugStats(
                hp: 3,      // TI ~20-30; cardiovascular risk at high doses
                attack: 3,  // Indirect sympathomimetic; EC50 ~1-5 uM NET/DAT
                defense: 3, // t1/2 ~3-6h
                specialAttack: 2, // Nonselective: alpha + beta adrenergic + monoamine release
                specialDefense: 3, // Moderate tachyphylaxis
                speed: 4    // Oral onset 15-30 min; rapid absorption
            ),
            habitat: .asianHighlands,
            flavorText: LocalizedString(
                en: "Phenylpropanoid alkaloid from Ephedra sinica (ma huang). Mixed indirect + direct sympathomimetic: displaces NE from vesicles via NET reversal plus direct alpha/beta adrenoceptor agonism. 4000-year history in traditional Chinese medicine. FDA OTC bronchodilator.",
                fr: "Alcaloide phenylpropanoide d'Ephedra sinica (ma huang). Sympathomimetique mixte indirect + direct: deplace la NE des vesicules via l'inversion du NET plus agonisme direct des adrenorecepteurs alpha/beta. 4000 ans d'histoire en medecine traditionnelle chinoise. Bronchodilatateur OTC FDA.",
                es: "Alcaloide fenilpropanoide de Ephedra sinica (ma huang). Simpaticomimetico mixto indirecto + directo: desplaza NE de vesiculas via reversion NET mas agonismo directo de adrenorreceptores alfa/beta. 4000 anos de historia en medicina tradicional china. Broncodilatador OTC FDA.",
                ja: "マオウ（Ephedra sinica）由来のフェニルプロパノイドアルカロイド。混合型間接＋直接交感神経作用薬：NET逆転による小胞からのNE放出とアルファ/ベータアドレナリン受容体直接作用。漢方医学で4000年の歴史。FDA OTC気管支拡張薬。",
                zh: "来自麻黄（Ephedra sinica）的苯丙烷类生物碱。混合间接+直接拟交感神经药：通过NET逆转从囊泡中置换NE加上直接α/β肾上腺素受体激动。中医药4000年历史。FDA非处方支气管扩张剂。",
                ko: "마황(Ephedra sinica)에서 유래한 페닐프로파노이드 알칼로이드. 혼합 간접+직접 교감신경흥분제: NET 역전을 통한 소포에서의 NE 방출과 직접적 알파/베타 아드레날린 수용체 작용. 전통 중의학에서 4000년 역사. FDA OTC 기관지확장제.",
                ru: "Фенилпропаноидный алкалоид из Эфедры хвощевой (ма хуан). Смешанный непрямой + прямой симпатомиметик: вытесняет НЭ из везикул через реверсию НЭТ плюс прямой агонизм альфа/бета-адренорецепторов. 4000 лет истории в традиционной китайской медицине. Безрецептурный бронходилататор FDA.",
                de: "Phenylpropanoid-Alkaloid aus Ephedra sinica (Ma Huang). Gemischtes indirektes + direktes Sympathomimetikum: verdrangt NE aus Vesikeln uber NET-Umkehr plus direkten Alpha/Beta-Adrenozeptor-Agonismus. 4000 Jahre Geschichte in der traditionellen chinesischen Medizin. FDA OTC-Bronchodilatator.",
                ar: "قلويد فينيل بروبانويد من الإيفيدرا سينيكا (ما هوانغ). محاكي ودي مختلط غير مباشر + مباشر: يزيح النورإبينفرين من الحويصلات عبر انعكاس NET بالإضافة إلى ناهض مباشر لمستقبلات ألفا/بيتا الأدرينالية. 4000 عام من التاريخ في الطب الصيني التقليدي. موسع قصبي FDA بدون وصفة."
            ),
            dexNumber: 27
        ),

        // MARK: #028 - Mitragynine (Isoquinoline)

        PokeDrugSpecies(
            substanceId: "mitragynine",
            name: LocalizedString(en: "Mitragynine", fr: "Mitragynine", es: "Mitraginina", ja: "ミトラギニン", zh: "帽柱木碱", ko: "미트라기닌", ru: "Митрагинин", de: "Mitragynin", ar: "ميتراجينين"),
            primaryType: .opioid,
            secondaryType: .serotonin,
            scaffold: .isoquinoline,
            stats: PokeDrugStats(
                hp: 3,      // TI ~20; respiratory depression lower than classical opioids
                attack: 3,  // MOR Ki ~230 nM (partial agonist); 7-OH metabolite more potent
                defense: 3, // t1/2 ~3.5h (parent); active metabolites extend
                specialAttack: 4, // MOR + 5-HT2A + alpha-2 + delta opioid
                specialDefense: 2, // Cross-tolerance with classical opioids
                speed: 3    // Oral onset 15-30 min
            ),
            habitat: .tropicalJungle,
            flavorText: LocalizedString(
                en: "Indole alkaloid from Mitragyna speciosa (kratom). Partial mu-opioid agonist (Ki ~230 nM) with biased signaling — preferentially activates G-protein over beta-arrestin, potentially reducing respiratory depression. CYP3A4 converts to 7-OH-mitragynine (Ki ~50 nM). Kruegel et al. 2016.",
                fr: "Alcaloide indolique de Mitragyna speciosa (kratom). Agoniste partiel mu-opioide (Ki ~230 nM) avec signalisation biaisee — active preferentiellement la proteine G par rapport a la beta-arrestine, reduisant potentiellement la depression respiratoire. CYP3A4 convertit en 7-OH-mitragynine (Ki ~50 nM). Kruegel et al. 2016.",
                es: "Alcaloide indolico de Mitragyna speciosa (kratom). Agonista parcial mu-opioide (Ki ~230 nM) con senalizacion sesgada — activa preferencialmente la proteina G sobre la beta-arrestina, reduciendo potencialmente la depresion respiratoria. CYP3A4 convierte a 7-OH-mitraginina (Ki ~50 nM). Kruegel et al. 2016.",
                ja: "ミトラギナ・スペシオサ（クラトム）由来のインドールアルカロイド。偏向シグナリングを持つ部分的μオピオイドアゴニスト（Ki ~230 nM）— βアレスチンよりGタンパク質を優先的に活性化し、呼吸抑制を潜在的に軽減。CYP3A4が7-OH-ミトラギニン（Ki ~50 nM）に変換。Kruegel et al. 2016。",
                zh: "来自帽柱木（kratom）的吲哚生物碱。偏向信号传导的部分μ阿片受体激动剂（Ki ~230 nM）——优先激活G蛋白而非β-arrestin，可能减少呼吸抑制。CYP3A4转化为7-OH-帽柱木碱（Ki ~50 nM）。Kruegel et al. 2016。",
                ko: "미트라기나 스페시오사(크라톰)의 인돌 알칼로이드. 편향 신호전달을 가진 부분적 μ-오피오이드 작용제(Ki ~230 nM) — 베타-아레스틴보다 G-단백질을 우선적으로 활성화하여 잠재적으로 호흡 억제 감소. CYP3A4가 7-OH-미트라기닌(Ki ~50 nM)으로 전환. Kruegel et al. 2016.",
                ru: "Индольный алкалоид из Митрагины прекрасной (кратом). Парциальный агонист мю-опиоидных рецепторов (Ki ~230 нМ) с предвзятой сигнализацией — предпочтительно активирует G-белок над бета-аррестином, потенциально снижая угнетение дыхания. CYP3A4 конвертирует в 7-ОН-митрагинин (Ki ~50 нМ). Kruegel et al. 2016.",
                de: "Indolalkaloid aus Mitragyna speciosa (Kratom). Partieller Mu-Opioid-Agonist (Ki ~230 nM) mit verzerrter Signalgebung — aktiviert bevorzugt G-Protein uber Beta-Arrestin und reduziert potenziell Atemdepression. CYP3A4 konvertiert zu 7-OH-Mitragynin (Ki ~50 nM). Kruegel et al. 2016.",
                ar: "قلويد إندول من ميتراجينا سبيسيوسا (كراتوم). ناهض جزئي لمستقبلات الأفيون مو (Ki ~230 نانومول) مع إشارات منحازة — ينشط بروتين G تفضيلياً على بيتا-أريستين، مما قد يقلل تثبيط التنفس. CYP3A4 يحول إلى 7-OH-ميتراجينين (Ki ~50 نانومول). Kruegel et al. 2016."
            ),
            dexNumber: 28
        ),

        // MARK: #029 - CBD (Terpenoid)

        PokeDrugSpecies(
            substanceId: "cbd",
            name: LocalizedString(en: "CBD", fr: "CBD", es: "CBD", ja: "CBD", zh: "大麻二酚", ko: "CBD", ru: "КБД", de: "CBD", ar: "سي بي دي"),
            primaryType: .cannabinoid,
            scaffold: .terpenoid,
            stats: PokeDrugStats(
                hp: 5,      // No LD50 established; WHO 2017: favorable safety profile
                attack: 1,  // Very low CB1 affinity (Ki >1 uM); negative allosteric modulator
                defense: 5, // t1/2 ~18-32h; extensive first-pass CYP2C19/3A4
                specialAttack: 5, // Multi-target: TRPV1, 5-HT1A, GPR55, PPARgamma, FAAH inhibition
                specialDefense: 4, // Minimal tolerance; no abuse potential
                speed: 2    // Oral onset 30-90 min; low bioavailability (~6%)
            ),
            habitat: .tropicalPlantations,
            flavorText: LocalizedString(
                en: "Non-intoxicating phytocannabinoid from Cannabis sativa. Negative allosteric modulator at CB1 (does not produce high). Multi-target pharmacology: TRPV1 agonist, 5-HT1A partial agonist, GPR55 antagonist, FAAH inhibitor. FDA-approved as Epidiolex for Dravet/Lennox-Gastaut epilepsy. Devinsky et al. 2017.",
                fr: "Phytocannabinoide non intoxicant de Cannabis sativa. Modulateur allosterique negatif au CB1 (ne produit pas d'ivresse). Pharmacologie multi-cibles: agoniste TRPV1, agoniste partiel 5-HT1A, antagoniste GPR55, inhibiteur FAAH. Approuve par la FDA comme Epidiolex pour l'epilepsie de Dravet/Lennox-Gastaut. Devinsky et al. 2017.",
                es: "Fitocannabinoide no intoxicante de Cannabis sativa. Modulador alosterico negativo en CB1 (no produce intoxicacion). Farmacologia multidiana: agonista TRPV1, agonista parcial 5-HT1A, antagonista GPR55, inhibidor FAAH. Aprobado por FDA como Epidiolex para epilepsia Dravet/Lennox-Gastaut. Devinsky et al. 2017.",
                ja: "カンナビス・サティバ由来の非中毒性フィトカンナビノイド。CB1のネガティブアロステリックモジュレーター（酩酊を生じない）。マルチターゲット薬理学：TRPV1アゴニスト、5-HT1A部分アゴニスト、GPR55アンタゴニスト、FAAH阻害剤。ドラベ/レノックス・ガストー型てんかんのエピディオレックスとしてFDA承認。Devinsky et al. 2017。",
                zh: "来自大麻的非致醉植物大麻素。CB1的负变构调节剂（不产生欣快感）。多靶点药理学：TRPV1激动剂、5-HT1A部分激动剂、GPR55拮抗剂、FAAH抑制剂。FDA批准为Epidiolex用于Dravet/Lennox-Gastaut癫痫。Devinsky et al. 2017。",
                ko: "대마(Cannabis sativa)의 비중독성 식물 카나비노이드. CB1의 음성 알로스테릭 조절제(취하지 않음). 다중 표적 약리학: TRPV1 작용제, 5-HT1A 부분 작용제, GPR55 길항제, FAAH 억제제. 드라벳/레녹스-가스토 간질에 대해 에피디올렉스로 FDA 승인. Devinsky et al. 2017.",
                ru: "Непсихоактивный фитоканнабиноид из Cannabis sativa. Негативный аллостерический модулятор CB1 (не вызывает опьянения). Мультитаргетная фармакология: агонист TRPV1, парциальный агонист 5-HT1A, антагонист GPR55, ингибитор FAAH. Одобрен FDA как Эпидиолекс для эпилепсии Драве/Леннокса-Гасто. Devinsky et al. 2017.",
                de: "Nicht-berauschender Phytocannabinoid aus Cannabis sativa. Negativer allosterischer Modulator am CB1 (erzeugt keinen Rausch). Multi-Target-Pharmakologie: TRPV1-Agonist, 5-HT1A-Partialagonist, GPR55-Antagonist, FAAH-Inhibitor. FDA-zugelassen als Epidiolex fur Dravet/Lennox-Gastaut-Epilepsie. Devinsky et al. 2017.",
                ar: "فيتوكانابينويد غير مسكر من القنب. معدل تفارغي سلبي في CB1 (لا ينتج نشوة). صيدلة متعددة الأهداف: ناهض TRPV1، ناهض جزئي 5-HT1A، مضاد GPR55، مثبط FAAH. معتمد من FDA كإبيديوليكس لصرع درافيت/لينوكس-غاستو. Devinsky et al. 2017."
            ),
            dexNumber: 29
        ),

        // MARK: #030 - Harmine (Beta-Carboline)

        PokeDrugSpecies(
            substanceId: "harmine",
            name: LocalizedString(en: "Harmine", fr: "Harmine", es: "Harmina", ja: "ハルミン", zh: "骆驼蓬碱", ko: "하르민", ru: "Гармин", de: "Harmin", ar: "هارمين"),
            primaryType: .serotonin,
            scaffold: .betaCarboline,
            stats: PokeDrugStats(
                hp: 3,      // TI ~15-20; tremorigenic at high doses
                attack: 3,  // MAO-A Ki ~5 nM (potent); 5-HT2A Ki ~300 nM (moderate)
                defense: 2, // t1/2 ~1-3h; rapid O-demethylation to harmol
                specialAttack: 3, // MAO-A selective (vs MAO-B >100x)
                specialDefense: 3, // Moderate; MAO recovery over days
                speed: 3    // Oral onset 20-40 min
            ),
            habitat: .tropicalJungle,
            flavorText: LocalizedString(
                en: "Beta-carboline alkaloid from Banisteriopsis caapi (ayahuasca vine). Potent reversible MAO-A inhibitor (Ki ~5 nM) enabling oral bioavailability of DMT in ayahuasca. Also binds 5-HT2A (Ki ~300 nM) and imidazoline receptors. The fluorescent compound that first revealed MAO enzymology. Buckholtz & Boggan 1977.",
                fr: "Alcaloide beta-carboline de Banisteriopsis caapi (liane d'ayahuasca). Puissant inhibiteur reversible de la MAO-A (Ki ~5 nM) permettant la biodisponibilite orale du DMT dans l'ayahuasca. Se lie aussi au 5-HT2A (Ki ~300 nM) et aux recepteurs imidazoline. Le compose fluorescent qui a revele l'enzymologie MAO. Buckholtz & Boggan 1977.",
                es: "Alcaloide beta-carbolina de Banisteriopsis caapi (liana de ayahuasca). Potente inhibidor reversible de MAO-A (Ki ~5 nM) que permite la biodisponibilidad oral del DMT en ayahuasca. Tambien se une a 5-HT2A (Ki ~300 nM) y receptores imidazolina. El compuesto fluorescente que primero revelo la enzimologia MAO. Buckholtz & Boggan 1977.",
                ja: "バニステリオプシス・カーピ（アヤワスカ蔓）由来のβ-カルボリンアルカロイド。強力な可逆的MAO-A阻害剤（Ki ~5 nM）で、アヤワスカ中のDMTの経口生体利用能を可能にする。5-HT2A（Ki ~300 nM）とイミダゾリン受容体にも結合。MAO酵素学を最初に明らかにした蛍光化合物。Buckholtz & Boggan 1977。",
                zh: "来自卡皮木（死藤水藤）的β-咔啉生物碱。强效可逆MAO-A抑制剂（Ki ~5 nM），使DMT在死藤水中的口服生物利用度成为可能。也结合5-HT2A（Ki ~300 nM）和咪唑啉受体。最先揭示MAO酶学的荧光化合物。Buckholtz & Boggan 1977。",
                ko: "바니스테리옵시스 카피(아야와스카 덩굴)의 β-카르볼린 알칼로이드. 강력한 가역적 MAO-A 억제제(Ki ~5 nM)로 아야와스카에서 DMT의 경구 생체이용률을 가능하게 함. 5-HT2A(Ki ~300 nM)와 이미다졸린 수용체에도 결합. MAO 효소학을 최초로 밝힌 형광 화합물. Buckholtz & Boggan 1977.",
                ru: "Бета-карболиновый алкалоид из Банистериопсиса каапи (лиана аяхуаски). Мощный обратимый ингибитор МАО-А (Ki ~5 нМ), обеспечивающий пероральную биодоступность ДМТ в аяхуаске. Также связывается с 5-HT2A (Ki ~300 нМ) и имидазолиновыми рецепторами. Флуоресцентное соединение, впервые раскрывшее энзимологию МАО. Buckholtz & Boggan 1977.",
                de: "Beta-Carbolin-Alkaloid aus Banisteriopsis caapi (Ayahuasca-Liane). Potenter reversibler MAO-A-Inhibitor (Ki ~5 nM), der die orale Bioverfugbarkeit von DMT in Ayahuasca ermoglicht. Bindet auch an 5-HT2A (Ki ~300 nM) und Imidazolin-Rezeptoren. Die fluoreszierende Verbindung, die erstmals die MAO-Enzymologie enthullte. Buckholtz & Boggan 1977.",
                ar: "قلويد بيتا-كربولين من بانيستيريوبسيس كابي (كرمة الأياواسكا). مثبط قوي قابل للعكس لـ MAO-A (Ki ~5 نانومول) يتيح التوافر الحيوي الفموي لـ DMT في الأياواسكا. يرتبط أيضاً بـ 5-HT2A (Ki ~300 نانومول) ومستقبلات الإميدازولين. المركب الفلوري الذي كشف أولاً عن إنزيمولوجيا MAO. Buckholtz & Boggan 1977."
            ),
            dexNumber: 30
        ),
    ]

    /// Look up a species by substance ID (case-insensitive).
    public static func species(for substanceId: String) -> PokeDrugSpecies? {
        knownSpecies.first { $0.substanceId == substanceId.lowercased() }
    }

    /// All species of a given PokeDrug type (primary or secondary).
    public static func species(ofType type: PokeDrugType) -> [PokeDrugSpecies] {
        knownSpecies.filter { $0.primaryType == type || $0.secondaryType == type }
    }

    /// All species built on a given molecular scaffold.
    public static func species(withScaffold scaffold: MolecularScaffold) -> [PokeDrugSpecies] {
        knownSpecies.filter { $0.scaffold == scaffold }
    }

    /// All species from a given habitat.
    public static func species(inHabitat habitat: PokeDrugHabitat) -> [PokeDrugSpecies] {
        knownSpecies.filter { $0.habitat == habitat }
    }
}
