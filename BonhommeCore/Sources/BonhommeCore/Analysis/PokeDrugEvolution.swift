import Foundation

/// A single chemical modification step in an evolution chain.
///
/// Each step changes binding selectivity, potency, metabolic stability, or
/// BBB penetration — the pharmacological equivalent of gaining new abilities.
public struct EvolutionStep: Sendable {
    /// Substance ID of the precursor compound.
    public let fromSubstanceId: String

    /// Substance ID of the product compound.
    public let toSubstanceId: String

    /// The chemical modification performed (e.g., "N,N-dimethylation").
    public let modification: LocalizedString

    /// Pharmacological consequence of the modification.
    public let pharmacologicalEffect: LocalizedString

    public init(
        fromSubstanceId: String,
        toSubstanceId: String,
        modification: LocalizedString,
        pharmacologicalEffect: LocalizedString
    ) {
        self.fromSubstanceId = fromSubstanceId
        self.toSubstanceId = toSubstanceId
        self.modification = modification
        self.pharmacologicalEffect = pharmacologicalEffect
    }
}

/// A linear or branching evolution chain for a molecular scaffold.
public struct EvolutionChain: Sendable {
    /// The scaffold family this chain belongs to.
    public let scaffold: MolecularScaffold

    /// Display name for this chain.
    public let name: LocalizedString

    /// Ordered evolution steps.
    public let steps: [EvolutionStep]

    public init(scaffold: MolecularScaffold, name: LocalizedString, steps: [EvolutionStep]) {
        self.scaffold = scaffold
        self.name = name
        self.steps = steps
    }
}

// MARK: - Known Evolution Chains

extension EvolutionChain {

    /// All known evolution chains in the PokeDrug system.
    public static let knownChains: [EvolutionChain] = [

        // MARK: Tryptamine line: Tryptamine → DMT → Psilocin → Psilocybin

        EvolutionChain(
            scaffold: .tryptamine,
            name: LocalizedString(
                en: "Tryptamine Main Line",
                fr: "Ligne principale tryptamine",
                es: "Línea principal de triptamina",
                ja: "トリプタミン主系列",
                zh: "色胺主线",
                ko: "트립타민 주계열",
                ru: "Основная линия триптамина",
                de: "Tryptamin-Hauptlinie",
                ar: "خط التريبتامين الرئيسي"
            ),
            steps: [
                EvolutionStep(
                    fromSubstanceId: "tryptamine",
                    toSubstanceId: "dmt",
                    modification: LocalizedString(
                        en: "N,N-dimethylation",
                        fr: "N,N-dimethylation",
                        es: "N,N-dimetilación",
                        ja: "N,N-ジメチル化",
                        zh: "N,N-二甲基化",
                        ko: "N,N-디메틸화",
                        ru: "N,N-диметилирование",
                        de: "N,N-Dimethylierung",
                        ar: "ميثلة ثنائية على النيتروجين"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Adds MAO resistance, increases lipophilicity for rapid CNS penetration. Peak brain concentration in under 30 seconds (smoked).",
                        fr: "Ajoute la resistance aux MAO, augmente la lipophilie pour une penetration rapide du SNC. Concentration cerebrale maximale en moins de 30 secondes (fume).",
                        es: "Añade resistencia a la MAO, aumenta la lipofilia para una penetración rápida en el SNC. Concentración cerebral máxima en menos de 30 segundos (fumado).",
                        ja: "MAO耐性を付与し、脂溶性を高めて中枢神経系への迅速な移行を可能にする。喫煙時の脳内最高濃度到達は30秒未満。",
                        zh: "增加MAO抗性，提高亲脂性以实现快速中枢神经系统渗透。吸入时30秒内达到脑内峰浓度。",
                        ko: "MAO 저항성을 부여하고, 지용성을 높여 중추신경계로의 신속한 침투를 가능하게 함. 흡연 시 30초 이내에 뇌 내 최고 농도 도달.",
                        ru: "Добавляет устойчивость к МАО, повышает липофильность для быстрого проникновения в ЦНС. Пиковая концентрация в мозге менее чем за 30 секунд (при курении).",
                        de: "Verleiht MAO-Resistenz, erhöht die Lipophilie für schnelle ZNS-Penetration. Maximale Gehirnkonzentration in unter 30 Sekunden (geraucht).",
                        ar: "يضيف مقاومة لإنزيم أوكسيداز أحادي الأمين، ويزيد الألفة الدهنية لاختراق سريع للجهاز العصبي المركزي. يصل التركيز الدماغي الأقصى في أقل من 30 ثانية (عند التدخين)."
                    )
                ),
                EvolutionStep(
                    fromSubstanceId: "dmt",
                    toSubstanceId: "psilocin",
                    modification: LocalizedString(
                        en: "4-hydroxylation",
                        fr: "4-hydroxylation",
                        es: "4-hidroxilación",
                        ja: "4-ヒドロキシル化",
                        zh: "4-羟基化",
                        ko: "4-하이드록실화",
                        ru: "4-гидроксилирование",
                        de: "4-Hydroxylierung",
                        ar: "هدرلة في الموضع 4"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Enhances 5-HT2A selectivity via hydrogen bonding. Cleaner serotonergic profile than DMT's broader sigma-1/TAAR engagement.",
                        fr: "Ameliore la selectivite 5-HT2A par liaison hydrogene. Profil serotoninergique plus propre que l'engagement sigma-1/TAAR plus large du DMT.",
                        es: "Mejora la selectividad 5-HT2A mediante enlaces de hidrógeno. Perfil serotoninérgico más limpio que el compromiso más amplio sigma-1/TAAR del DMT.",
                        ja: "水素結合を介して5-HT2A選択性を向上させる。DMTのより広範なシグマ-1/TAAR関与に比べ、より選択的なセロトニン作動性プロファイルを示す。",
                        zh: "通过氢键增强5-HT2A选择性。比DMT更广泛的σ-1/TAAR结合具有更纯净的血清素能谱。",
                        ko: "수소 결합을 통해 5-HT2A 선택성을 향상시킴. DMT의 광범위한 시그마-1/TAAR 관여보다 더 깨끗한 세로토닌성 프로파일.",
                        ru: "Повышает селективность к 5-HT2A через водородные связи. Более чистый серотонинергический профиль по сравнению с более широким взаимодействием ДМТ с сигма-1/TAAR.",
                        de: "Verbessert die 5-HT2A-Selektivität durch Wasserstoffbrückenbindungen. Saubereres serotonerges Profil als DMTs breitere Sigma-1/TAAR-Beteiligung.",
                        ar: "يعزز الانتقائية لمستقبل 5-HT2A عبر الروابط الهيدروجينية. ملف سيروتونيني أنظف من ارتباط DMT الأوسع بمستقبلات سيغما-1/TAAR."
                    )
                ),
                EvolutionStep(
                    fromSubstanceId: "psilocin",
                    toSubstanceId: "psilocybin",
                    modification: LocalizedString(
                        en: "4-phosphorylation (prodrug)",
                        fr: "4-phosphorylation (prodrogue)",
                        es: "4-fosforilación (profármaco)",
                        ja: "4-リン酸化（プロドラッグ）",
                        zh: "4-磷酸化（前药）",
                        ko: "4-인산화 (전구약물)",
                        ru: "4-фосфорилирование (пролекарство)",
                        de: "4-Phosphorylierung (Prodrug)",
                        ar: "فسفرة في الموضع 4 (طليعة دوائية)"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Nature's prodrug strategy: phosphate ester adds water solubility and metabolic stability for oral dosing. Cleaved to active psilocin by alkaline phosphatase in vivo.",
                        fr: "Strategie de prodrogue de la nature: l'ester phosphate ajoute la solubilite dans l'eau et la stabilite metabolique pour le dosage oral. Clive en psilocine active par la phosphatase alcaline in vivo.",
                        es: "Estrategia de profármaco de la naturaleza: el éster fosfato añade solubilidad acuosa y estabilidad metabólica para la dosificación oral. Se escinde a psilocina activa por la fosfatasa alcalina in vivo.",
                        ja: "天然のプロドラッグ戦略：リン酸エステルが水溶性と代謝安定性を付与し、経口投与を可能にする。生体内でアルカリホスファターゼにより活性体のサイロシンに変換される。",
                        zh: "天然的前药策略：磷酸酯增加水溶性和代谢稳定性，适合口服给药。在体内由碱性磷酸酶裂解为活性成分裸盖菇素。",
                        ko: "자연의 전구약물 전략: 인산 에스터가 수용성과 대사 안정성을 부여하여 경구 투여를 가능하게 함. 생체 내에서 알칼리성 포스파타제에 의해 활성 실로신으로 절단됨.",
                        ru: "Стратегия пролекарства природы: фосфатный эфир добавляет водорастворимость и метаболическую стабильность для перорального приёма. Расщепляется до активного псилоцина щелочной фосфатазой in vivo.",
                        de: "Prodrug-Strategie der Natur: Phosphatester erhöht Wasserlöslichkeit und metabolische Stabilität für orale Dosierung. Wird in vivo durch alkalische Phosphatase zum aktiven Psilocin gespalten.",
                        ar: "استراتيجية الطليعة الدوائية في الطبيعة: إستر الفوسفات يضيف الذوبانية المائية والاستقرار الأيضي للجرعات الفموية. يُشطر إلى السيلوسين الفعّال بواسطة الفوسفاتاز القلوي في الجسم الحي."
                    )
                ),
            ]
        ),

        // MARK: Tryptamine → Ergoline branch (ring fusion)

        EvolutionChain(
            scaffold: .ergoline,
            name: LocalizedString(
                en: "Ergoline Branch (Ring Fusion)",
                fr: "Branche ergoline (fusion d'anneaux)",
                es: "Rama ergolina (fusión de anillos)",
                ja: "エルゴリン分岐（環縮合）",
                zh: "麦角灵分支（环融合）",
                ko: "에르골린 분기 (고리 융합)",
                ru: "Ветвь эрголина (конденсация колец)",
                de: "Ergolin-Zweig (Ringfusion)",
                ar: "فرع الإرغولين (اندماج الحلقات)"
            ),
            steps: [
                EvolutionStep(
                    fromSubstanceId: "tryptamine",
                    toSubstanceId: "lsd",
                    modification: LocalizedString(
                        en: "Tetracyclic ring fusion + diethylamide",
                        fr: "Fusion tetracyclique + diethylamide",
                        es: "Fusión de anillo tetracíclico + dietilamida",
                        ja: "四環式環縮合 + ジエチルアミド",
                        zh: "四环环融合 + 二乙酰胺",
                        ko: "사환 고리 융합 + 디에틸아미드",
                        ru: "Тетрациклическая конденсация колец + диэтиламид",
                        de: "Tetrazyklische Ringfusion + Diethylamid",
                        ar: "اندماج حلقي رباعي الحلقات + ثنائي إيثيل أميد"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Constrains tryptamine into optimal binding conformation. 100-1000x potency increase: LSD active at 20-100 ug vs psilocybin 10-30 mg. EL2 lid traps LSD for 8-12 hours.",
                        fr: "Contraint la tryptamine dans sa conformation de liaison optimale. Augmentation de puissance de 100-1000x: LSD actif a 20-100 ug vs psilocybine 10-30 mg. Le couvercle EL2 piege le LSD pendant 8-12 heures.",
                        es: "Restringe la triptamina a la conformación de unión óptima. Aumento de potencia de 100-1000x: LSD activo a 20-100 µg vs psilocibina 10-30 mg. La tapa EL2 atrapa el LSD durante 8-12 horas.",
                        ja: "トリプタミンを最適な結合配座に固定する。100〜1000倍の効力増大：LSDは20〜100 µgで活性（シロシビンは10〜30 mg）。EL2リッドがLSDを8〜12時間にわたり捕捉する。",
                        zh: "将色胺限制在最佳结合构象中。效力提高100-1000倍：LSD在20-100 µg时有活性，而裸盖菇素为10-30 mg。EL2盖结构将LSD捕获8-12小时。",
                        ko: "트립타민을 최적 결합 배좌로 제한함. 100-1000배 효력 증가: LSD는 20-100 µg에서 활성(실로시빈 10-30 mg 대비). EL2 뚜껑이 LSD를 8-12시간 동안 포획함.",
                        ru: "Фиксирует триптамин в оптимальной конформации связывания. Увеличение активности в 100–1000 раз: ЛСД активен при 20–100 мкг против 10–30 мг псилоцибина. Крышка EL2 удерживает ЛСД на 8–12 часов.",
                        de: "Fixiert Tryptamin in optimaler Bindungskonformation. 100-1000-fache Potenzsteigerung: LSD wirksam bei 20-100 µg vs. Psilocybin 10-30 mg. Der EL2-Deckel fängt LSD für 8-12 Stunden ein.",
                        ar: "يقيّد التريبتامين في التشكّل الأمثل للارتباط. زيادة في الفاعلية بمقدار 100-1000 ضعف: LSD فعّال عند 20-100 ميكروغرام مقابل السيلوسيبين 10-30 ملغ. غطاء EL2 يحتجز LSD لمدة 8-12 ساعة."
                    )
                ),
            ]
        ),

        // MARK: Morphinan line: Morphine → Codeine, Morphine → Heroin

        EvolutionChain(
            scaffold: .morphinan,
            name: LocalizedString(
                en: "Morphinan Main Line",
                fr: "Ligne principale morphinane",
                es: "Línea principal del morfinano",
                ja: "モルヒナン主系列",
                zh: "吗啡烷主线",
                ko: "모르피난 주계열",
                ru: "Основная линия морфинана",
                de: "Morphinan-Hauptlinie",
                ar: "خط المورفينان الرئيسي"
            ),
            steps: [
                EvolutionStep(
                    fromSubstanceId: "morphine",
                    toSubstanceId: "codeine",
                    modification: LocalizedString(
                        en: "3-O-methylation",
                        fr: "3-O-methylation",
                        es: "3-O-metilación",
                        ja: "3-O-メチル化",
                        zh: "3-O-甲基化",
                        ko: "3-O-메틸화",
                        ru: "3-O-метилирование",
                        de: "3-O-Methylierung",
                        ar: "ميثلة في الموضع 3-O"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Masks critical phenol pharmacophore, reducing MOR affinity ~10-fold. Converts to prodrug dependent on CYP2D6 O-demethylation.",
                        fr: "Masque le pharmacophore phenol critique, reduisant l'affinite MOR d'environ 10 fois. Convertit en prodrogue dependante de la O-demethylation par CYP2D6.",
                        es: "Enmascara el farmacóforo fenólico crítico, reduciendo la afinidad MOR aproximadamente 10 veces. Se convierte en profármaco dependiente de la O-desmetilación por CYP2D6.",
                        ja: "重要なフェノール性ファルマコフォアを遮蔽し、MOR親和性を約10分の1に低下させる。CYP2D6によるO-脱メチル化に依存するプロドラッグとなる。",
                        zh: "遮蔽关键酚基药效团，将MOR亲和力降低约10倍。转化为依赖CYP2D6 O-去甲基化的前药。",
                        ko: "핵심 페놀 약효단을 차폐하여 MOR 친화성을 약 10배 감소시킴. CYP2D6 O-탈메틸화에 의존하는 전구약물로 전환됨.",
                        ru: "Маскирует критический фенольный фармакофор, снижая аффинность к МОР приблизительно в 10 раз. Превращается в пролекарство, зависящее от O-деметилирования CYP2D6.",
                        de: "Maskiert das kritische Phenol-Pharmakophor und reduziert die MOR-Affinität ca. 10-fach. Wird zum Prodrug, abhängig von CYP2D6-O-Demethylierung.",
                        ar: "يحجب مجموعة الفارماكوفور الفينولية الحرجة، مما يقلل ألفة مستقبل MOR بنحو 10 أضعاف. يتحول إلى طليعة دوائية تعتمد على نزع الميثيل بواسطة إنزيم CYP2D6."
                    )
                ),
            ]
        ),

        // MARK: Morphinan N-substituent branch: agonist → antagonist

        EvolutionChain(
            scaffold: .morphinan,
            name: LocalizedString(
                en: "Morphinan N-Substituent Switch",
                fr: "Commutation N-substituant morphinane",
                es: "Cambio de N-sustituyente del morfinano",
                ja: "モルヒナンN-置換基スイッチ",
                zh: "吗啡烷N-取代基转换",
                ko: "모르피난 N-치환기 전환",
                ru: "Переключение N-заместителя морфинана",
                de: "Morphinan-N-Substituenten-Wechsel",
                ar: "تبديل المستبدل النيتروجيني للمورفينان"
            ),
            steps: [
                EvolutionStep(
                    fromSubstanceId: "morphine",
                    toSubstanceId: "naltrexone",
                    modification: LocalizedString(
                        en: "N-methyl → N-cyclopropylmethyl",
                        fr: "N-methyle → N-cyclopropylmethyle",
                        es: "N-metilo → N-ciclopropilmetilo",
                        ja: "N-メチル → N-シクロプロピルメチル",
                        zh: "N-甲基 → N-环丙甲基",
                        ko: "N-메틸 → N-시클로프로필메틸",
                        ru: "N-метил → N-циклопропилметил",
                        de: "N-Methyl → N-Cyclopropylmethyl",
                        ar: "N-ميثيل → N-سيكلوبروبيل ميثيل"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Bulky N-substituent sterically prevents receptor conformational change for G-protein coupling. Converts full agonist to pure antagonist.",
                        fr: "Le substituant N volumineux empeche steriquement le changement conformationnel du recepteur pour le couplage de la proteine G. Convertit un agoniste complet en antagoniste pur.",
                        es: "El voluminoso N-sustituyente impide estéricamente el cambio conformacional del receptor para el acoplamiento de proteína G. Convierte un agonista completo en antagonista puro.",
                        ja: "嵩高いN-置換基が立体的にGタンパク質共役に必要な受容体の構造変化を妨げる。完全アゴニストを純粋なアンタゴニストに変換する。",
                        zh: "体积庞大的N-取代基通过空间位阻阻止受体发生G蛋白偶联所需的构象变化。将完全激动剂转化为纯拮抗剂。",
                        ko: "부피가 큰 N-치환기가 입체적으로 G-단백질 커플링을 위한 수용체 구조 변화를 방해함. 완전 작용제를 순수 길항제로 전환함.",
                        ru: "Объёмный N-заместитель стерически препятствует конформационному изменению рецептора для сопряжения с G-белком. Превращает полный агонист в чистый антагонист.",
                        de: "Der sperrige N-Substituent verhindert sterisch die Rezeptor-Konformationsänderung für die G-Protein-Kopplung. Wandelt einen vollen Agonisten in einen reinen Antagonisten um.",
                        ar: "يمنع المستبدل النيتروجيني الضخم فراغياً التغير التشكّلي للمستقبل اللازم لاقتران البروتين G. يحوّل الناهض الكامل إلى مضاد صرف."
                    )
                ),
            ]
        ),

        // MARK: Phenethylamine line: PEA → Amphetamine → Methamphetamine

        EvolutionChain(
            scaffold: .phenethylamine,
            name: LocalizedString(
                en: "Phenethylamine Stimulant Line",
                fr: "Ligne stimulante phenethylamine",
                es: "Línea estimulante de fenetilamina",
                ja: "フェネチルアミン刺激薬系列",
                zh: "苯乙胺兴奋剂系列",
                ko: "페네틸아민 흥분제 계열",
                ru: "Стимуляторная линия фенэтиламина",
                de: "Phenethylamin-Stimulanzien-Linie",
                ar: "خط المنشطات من الفينيثيلامين"
            ),
            steps: [
                EvolutionStep(
                    fromSubstanceId: "phenethylamine",
                    toSubstanceId: "amphetamine",
                    modification: LocalizedString(
                        en: "Alpha-methylation",
                        fr: "Alpha-methylation",
                        es: "Alfa-metilación",
                        ja: "α-メチル化",
                        zh: "α-甲基化",
                        ko: "알파-메틸화",
                        ru: "Альфа-метилирование",
                        de: "Alpha-Methylierung",
                        ar: "ميثلة ألفا"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Blocks MAO metabolism (half-life: seconds → 10-13 hours), introduces chirality (S > R), enables reverse transport at DAT/NET.",
                        fr: "Bloque le metabolisme MAO (demi-vie: secondes → 10-13 heures), introduit la chiralite (S > R), permet le transport inverse au DAT/NET.",
                        es: "Bloquea el metabolismo por MAO (vida media: segundos → 10-13 horas), introduce quiralidad (S > R), permite el transporte inverso en DAT/NET.",
                        ja: "MAO代謝を遮断（半減期：秒単位 → 10〜13時間）、キラリティーを導入（S > R）、DAT/NETでの逆輸送を可能にする。",
                        zh: "阻断MAO代谢（半衰期：数秒 → 10-13小时），引入手性（S > R），实现DAT/NET的反向转运。",
                        ko: "MAO 대사를 차단 (반감기: 초 → 10-13시간), 키랄성 도입 (S > R), DAT/NET에서의 역수송을 가능하게 함.",
                        ru: "Блокирует метаболизм МАО (период полувыведения: секунды → 10–13 часов), вводит хиральность (S > R), обеспечивает обратный транспорт через DAT/NET.",
                        de: "Blockiert MAO-Metabolismus (Halbwertszeit: Sekunden → 10-13 Stunden), führt Chiralität ein (S > R), ermöglicht Rücktransport an DAT/NET.",
                        ar: "يحجب استقلاب إنزيم أوكسيداز أحادي الأمين (عمر النصف: ثوانٍ → 10-13 ساعة)، يُدخل الكيرالية (S > R)، ويُمكّن النقل العكسي عبر DAT/NET."
                    )
                ),
                EvolutionStep(
                    fromSubstanceId: "amphetamine",
                    toSubstanceId: "methamphetamine",
                    modification: LocalizedString(
                        en: "N-methylation",
                        fr: "N-methylation",
                        es: "N-metilación",
                        ja: "N-メチル化",
                        zh: "N-甲基化",
                        ko: "N-메틸화",
                        ru: "N-метилирование",
                        de: "N-Methylierung",
                        ar: "ميثلة على النيتروجين"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Further increases lipophilicity and CNS penetration, boosting stimulant potency 3-5x. Narrows safety margin.",
                        fr: "Augmente encore la lipophilie et la penetration du SNC, augmentant la puissance stimulante de 3-5x. Reduit la marge de securite.",
                        es: "Aumenta aún más la lipofilia y la penetración en el SNC, potenciando la potencia estimulante 3-5 veces. Reduce el margen de seguridad.",
                        ja: "脂溶性とCNS移行性をさらに高め、刺激薬としての効力を3〜5倍に増強する。安全域が狭くなる。",
                        zh: "进一步增加亲脂性和中枢神经系统渗透性，将兴奋剂效力提高3-5倍。安全范围缩窄。",
                        ko: "지용성과 중추신경계 침투력을 더욱 높여 흥분제 효력을 3-5배 증가시킴. 안전 범위가 좁아짐.",
                        ru: "Дополнительно повышает липофильность и проникновение в ЦНС, усиливая стимулирующую активность в 3–5 раз. Сужает терапевтический коридор безопасности.",
                        de: "Erhöht Lipophilie und ZNS-Penetration weiter, steigert die Stimulanzienpotenz um das 3-5-fache. Verengt die Sicherheitsmarge.",
                        ar: "يزيد من الألفة الدهنية واختراق الجهاز العصبي المركزي، مما يعزز فاعلية التنبيه 3-5 أضعاف. يُضيّق هامش الأمان."
                    )
                ),
            ]
        ),

        // MARK: Phenethylamine → Mescaline branch (type change to Serotonin)

        EvolutionChain(
            scaffold: .phenethylamine,
            name: LocalizedString(
                en: "Phenethylamine Psychedelic Branch",
                fr: "Branche psychedelique phenethylamine",
                es: "Rama psicodélica de fenetilamina",
                ja: "フェネチルアミン幻覚剤分岐",
                zh: "苯乙胺致幻分支",
                ko: "페네틸아민 환각제 분기",
                ru: "Психоделическая ветвь фенэтиламина",
                de: "Phenethylamin-Psychedelika-Zweig",
                ar: "فرع المُهلوسات من الفينيثيلامين"
            ),
            steps: [
                EvolutionStep(
                    fromSubstanceId: "phenethylamine",
                    toSubstanceId: "mescaline",
                    modification: LocalizedString(
                        en: "3,4,5-trimethoxylation",
                        fr: "3,4,5-trimethoxylation",
                        es: "3,4,5-trimetoxilación",
                        ja: "3,4,5-トリメトキシ化",
                        zh: "3,4,5-三甲氧基化",
                        ko: "3,4,5-트리메톡실화",
                        ru: "3,4,5-триметоксилирование",
                        de: "3,4,5-Trimethoxylierung",
                        ar: "ثلاثي ميثوكسلة في المواضع 3،4،5"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Complete type change from Dopamine to Serotonin. Redirects binding to 5-HT2A agonism (Ki ~3600-6400 nM, compensated by high dosing at 200-400 mg).",
                        fr: "Changement de type complet de Dopamine a Serotonine. Redirige la liaison vers l'agonisme 5-HT2A (Ki ~3600-6400 nM, compense par un dosage eleve a 200-400 mg).",
                        es: "Cambio de tipo completo de Dopamina a Serotonina. Redirige la unión hacia el agonismo 5-HT2A (Ki ~3600-6400 nM, compensado con dosis altas de 200-400 mg).",
                        ja: "ドーパミン型からセロトニン型への完全なタイプ変更。結合を5-HT2Aアゴニズムへ転換（Ki約3600〜6400 nM、200〜400 mgの高用量で補償）。",
                        zh: "从多巴胺型到血清素型的完全类型转换。将结合重定向至5-HT2A激动活性（Ki约3600-6400 nM，通过200-400 mg的高剂量补偿）。",
                        ko: "도파민에서 세로토닌으로의 완전한 타입 전환. 5-HT2A 작용제로 결합을 전환 (Ki ~3600-6400 nM, 200-400 mg 고용량으로 보상).",
                        ru: "Полная смена типа с Дофамина на Серотонин. Перенаправляет связывание на агонизм 5-HT2A (Ki ~3600–6400 нМ, компенсируется высокой дозировкой 200–400 мг).",
                        de: "Vollständiger Typwechsel von Dopamin zu Serotonin. Leitet die Bindung zum 5-HT2A-Agonismus um (Ki ~3600-6400 nM, kompensiert durch hohe Dosierung von 200-400 mg).",
                        ar: "تحوّل كامل في النوع من الدوبامين إلى السيروتونين. يعيد توجيه الارتباط نحو التنبيه الناهض لمستقبل 5-HT2A (Ki حوالي 3600-6400 نانومول، يُعوَّض بجرعات عالية من 200-400 ملغ)."
                    )
                ),
            ]
        ),

        // MARK: Benzodioxole line: PEA → MDA → MDMA

        EvolutionChain(
            scaffold: .benzodioxole,
            name: LocalizedString(
                en: "Benzodioxole Empathogen Line",
                fr: "Ligne empathogene benzodioxole",
                es: "Línea empatógena de benzodioxol",
                ja: "ベンゾジオキソール共感薬系列",
                zh: "苯并二氧杂环共情剂系列",
                ko: "벤조디옥솔 공감제 계열",
                ru: "Эмпатогенная линия бензодиоксола",
                de: "Benzodioxol-Empathogen-Linie",
                ar: "خط مولدات التعاطف من البنزوديوكسول"
            ),
            steps: [
                EvolutionStep(
                    fromSubstanceId: "phenethylamine",
                    toSubstanceId: "mda",
                    modification: LocalizedString(
                        en: "3,4-methylenedioxy + alpha-methyl",
                        fr: "3,4-methylenedioxy + alpha-methyle",
                        es: "3,4-metilendioxi + alfa-metilo",
                        ja: "3,4-メチレンジオキシ + α-メチル",
                        zh: "3,4-亚甲二氧基 + α-甲基",
                        ko: "3,4-메틸렌디옥시 + 알파-메틸",
                        ru: "3,4-метилендиокси + альфа-метил",
                        de: "3,4-Methylendioxy + Alpha-Methyl",
                        ar: "3،4-ميثيلين ديوكسي + ألفا-ميثيل"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Methylenedioxy shifts SERT selectivity. MDA has stronger 5-HT2A agonism and more hallucinogenic character (Serotonin/Empathogen dual-type).",
                        fr: "Le methylenedioxy deplace la selectivite SERT. Le MDA a un agonisme 5-HT2A plus fort et un caractere plus hallucinogene (double type Serotonine/Empathogene).",
                        es: "El metilendioxi desplaza la selectividad SERT. El MDA tiene un agonismo 5-HT2A más fuerte y un carácter más alucinógeno (tipo dual Serotonina/Empatógeno).",
                        ja: "メチレンジオキシ基がSERT選択性を変化させる。MDAはより強い5-HT2Aアゴニズムとより顕著な幻覚特性を持つ（セロトニン/エンパソーゲン二重型）。",
                        zh: "亚甲二氧基改变SERT选择性。MDA具有更强的5-HT2A激动活性和更显著的致幻特征（血清素/共情剂双重类型）。",
                        ko: "메틸렌디옥시가 SERT 선택성을 전환시킴. MDA는 더 강한 5-HT2A 작용성과 더 뚜렷한 환각 특성을 가짐 (세로토닌/공감제 이중 유형).",
                        ru: "Метилендиокси смещает селективность к SERT. МДА обладает более сильным агонизмом 5-HT2A и более выраженным галлюциногенным характером (двойной тип Серотонин/Эмпатоген).",
                        de: "Methylendioxy verschiebt die SERT-Selektivität. MDA hat stärkeren 5-HT2A-Agonismus und mehr halluzinogenen Charakter (Serotonin/Empathogen-Dualtyp).",
                        ar: "الميثيلين ديوكسي يُحوّل الانتقائية نحو ناقل السيروتونين (SERT). يمتلك MDA تنبيهاً ناهضاً أقوى لمستقبل 5-HT2A وطابعاً هلوسياً أكثر وضوحاً (نوع مزدوج سيروتونين/مولد تعاطف)."
                    )
                ),
                EvolutionStep(
                    fromSubstanceId: "mda",
                    toSubstanceId: "mdma",
                    modification: LocalizedString(
                        en: "N-methylation",
                        fr: "N-methylation",
                        es: "N-metilación",
                        ja: "N-メチル化",
                        zh: "N-甲基化",
                        ko: "N-메틸화",
                        ru: "N-метилирование",
                        de: "N-Methylierung",
                        ar: "ميثلة على النيتروجين"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Shifts to Empathogen type: SERT/DAT release ratio ~10:1, prosocial warmth, oxytocin release rather than hallucinogenic activity.",
                        fr: "Passe au type Empathogene: ratio de liberation SERT/DAT ~10:1, chaleur prosociale, liberation d'ocytocine plutot qu'activite hallucinogene.",
                        es: "Cambia al tipo Empatógeno: proporción de liberación SERT/DAT ~10:1, calidez prosocial, liberación de oxitocina en lugar de actividad alucinógena.",
                        ja: "エンパソーゲン型へ移行：SERT/DAT放出比約10:1、向社会的温かさ、幻覚作用ではなくオキシトシン放出。",
                        zh: "转变为共情剂类型：SERT/DAT释放比约10:1，亲社会温暖感，催产素释放而非致幻活性。",
                        ko: "공감제 유형으로 전환: SERT/DAT 방출 비율 ~10:1, 친사회적 온정, 환각 활성 대신 옥시토신 방출.",
                        ru: "Переход к типу Эмпатоген: соотношение высвобождения SERT/DAT ~10:1, просоциальное тепло, высвобождение окситоцина вместо галлюциногенной активности.",
                        de: "Wechsel zum Empathogen-Typ: SERT/DAT-Freisetzungsverhältnis ~10:1, prosoziale Wärme, Oxytocin-Freisetzung statt halluzinogener Aktivität.",
                        ar: "يتحول إلى نوع مولد التعاطف: نسبة إطلاق SERT/DAT حوالي 10:1، دفء اجتماعي إيجابي، إفراز الأوكسيتوسين بدلاً من النشاط الهلوسي."
                    )
                ),
            ]
        ),
    ]

    /// Look up evolution chains involving a given substance ID.
    public static func chains(involving substanceId: String) -> [EvolutionChain] {
        let id = substanceId.lowercased()
        return knownChains.filter { chain in
            chain.steps.contains { step in
                step.fromSubstanceId == id || step.toSubstanceId == id
            }
        }
    }
}
