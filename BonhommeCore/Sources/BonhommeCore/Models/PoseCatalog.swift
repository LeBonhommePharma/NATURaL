import Foundation

// MARK: - Supporting Types

/// Workout style / kind available in the app.
///
/// Historical name `YogaStyle` is kept for Codable raw-value stability and call-site
/// compatibility. Prefer the `WorkoutKind` typealias for new code.
///
/// New non-yoga cases (`matYoga`, `strength`, `cardio`, `mobility`, `meditation`,
/// `general`) are additive — existing encoded strings still decode.
public enum YogaStyle: String, Codable, Sendable, CaseIterable {
    // MARK: Yoga (legacy raw values preserved)
    case chairYoga
    case matYoga
    case vinyasa
    case hatha
    case yin
    case restorative
    case power
    case standingBalance
    case prenatal
    case pranayama
    // MARK: Non-yoga workout kinds
    case strength
    case cardio
    case mobility
    case meditation
    case general

    public var localizedName: LocalizedString {
        switch self {
        case .chairYoga:
            return LocalizedString(en: "Chair Yoga", fr: "Yoga sur chaise", es: "Yoga en silla", ja: "チェアヨガ", zh: "椅子瑜伽", ko: "의자 요가", ru: "Йога на стуле", de: "Stuhl-Yoga", ar: "يوغا الكرسي")
        case .matYoga:
            return LocalizedString(en: "Mat Yoga", fr: "Yoga sur tapis", es: "Yoga en esterilla", ja: "マットヨガ", zh: "垫上瑜伽", ko: "매트 요가", ru: "Йога на коврике", de: "Matten-Yoga", ar: "يوغا السجادة")
        case .vinyasa:
            return LocalizedString(en: "Vinyasa", fr: "Vinyasa", es: "Vinyasa", ja: "ヴィンヤサ", zh: "流瑜伽", ko: "빈야사", ru: "Виньяса", de: "Vinyasa", ar: "فينياسا")
        case .hatha:
            return LocalizedString(en: "Hatha", fr: "Hatha", es: "Hatha", ja: "ハタ", zh: "哈他瑜伽", ko: "하타", ru: "Хатха", de: "Hatha", ar: "هاثا")
        case .yin:
            return LocalizedString(en: "Yin", fr: "Yin", es: "Yin", ja: "陰ヨガ", zh: "阴瑜伽", ko: "음", ru: "Инь", de: "Yin", ar: "يين")
        case .restorative:
            return LocalizedString(en: "Restorative", fr: "Réparateur", es: "Restaurativo", ja: "リストラティブ", zh: "恢复性瑜伽", ko: "회복", ru: "Восстановительная", de: "Erholsam", ar: "استعادي")
        case .power:
            return LocalizedString(en: "Power", fr: "Power", es: "Power", ja: "パワー", zh: "力量瑜伽", ko: "파워", ru: "Силовая", de: "Power", ar: "قوة")
        case .standingBalance:
            return LocalizedString(en: "Standing Balance", fr: "Équilibre debout", es: "Equilibrio de pie", ja: "立位バランス", zh: "站立平衡", ko: "서서 균형", ru: "Баланс стоя", de: "Stehbalance", ar: "توازن الوقوف")
        case .prenatal:
            return LocalizedString(en: "Prenatal", fr: "Prénatal", es: "Prenatal", ja: "マタニティ", zh: "孕期瑜伽", ko: "산전", ru: "Пренатальная", de: "Pränatal", ar: "ما قبل الولادة")
        case .pranayama:
            return LocalizedString(en: "Pranayama", fr: "Pranayama", es: "Pranayama", ja: "プラナヤマ", zh: "呼吸法", ko: "호흡법", ru: "Пранаяма", de: "Pranayama", ar: "براناياما")
        case .strength:
            return LocalizedString(en: "Strength", fr: "Force", es: "Fuerza", ja: "筋トレ", zh: "力量训练", ko: "근력", ru: "Сила", de: "Kraft", ar: "قوة")
        case .cardio:
            return LocalizedString(en: "Cardio", fr: "Cardio", es: "Cardio", ja: "有酸素", zh: "有氧", ko: "유산소", ru: "Кардио", de: "Cardio", ar: "كارديو")
        case .mobility:
            return LocalizedString(en: "Mobility", fr: "Mobilité", es: "Movilidad", ja: "モビリティ", zh: "活动度", ko: "가동성", ru: "Мобильность", de: "Mobilität", ar: "حركية")
        case .meditation:
            return LocalizedString(en: "Meditation", fr: "Méditation", es: "Meditación", ja: "瞑想", zh: "冥想", ko: "명상", ru: "Медитация", de: "Meditation", ar: "تأمل")
        case .general:
            return LocalizedString(en: "General", fr: "Général", es: "General", ja: "総合", zh: "综合", ko: "일반", ru: "Общая", de: "Allgemein", ar: "عام")
        }
    }

    public var localizedDescription: LocalizedString {
        switch self {
        case .chairYoga:
            return LocalizedString(en: "Accessible yoga performed while seated in a chair, ideal for all fitness levels.", fr: "Yoga accessible pratiqué assis sur une chaise, idéal pour tous les niveaux de forme physique.")
        case .matYoga:
            return LocalizedString(en: "Floor-based yoga on a mat — flexible sequences for strength, stretch, and breath.", fr: "Yoga au sol sur un tapis — séquences flexibles pour force, étirement et respiration.")
        case .vinyasa:
            return LocalizedString(en: "A flowing style linking breath with movement through dynamic pose sequences.", fr: "Un style fluide reliant la respiration au mouvement à travers des séquences de postures dynamiques.")
        case .hatha:
            return LocalizedString(en: "A classical style focusing on physical postures and breathing techniques at a slower pace.", fr: "Un style classique axé sur les postures physiques et les techniques de respiration à un rythme plus lent.")
        case .yin:
            return LocalizedString(en: "Long-held passive poses targeting deep connective tissue for flexibility and relaxation.", fr: "Des postures passives tenues longtemps ciblant les tissus conjonctifs profonds pour la flexibilité et la relaxation.")
        case .restorative:
            return LocalizedString(en: "Deeply supported poses using props to promote full relaxation and stress relief.", fr: "Postures profondément soutenues utilisant des accessoires pour favoriser une relaxation totale et soulager le stress.")
        case .power:
            return LocalizedString(en: "A vigorous, fitness-based approach building strength, stamina, and flexibility.", fr: "Une approche vigoureuse basée sur la forme physique pour développer la force, l'endurance et la flexibilité.")
        case .standingBalance:
            return LocalizedString(en: "Standing poses that develop stability, coordination, and lower-body strength.", fr: "Postures debout qui développent la stabilité, la coordination et la force du bas du corps.")
        case .prenatal:
            return LocalizedString(en: "Gentle yoga adapted for pregnancy, supporting comfort, breath, and body awareness.", fr: "Yoga doux adapté à la grossesse, favorisant le confort, la respiration et la conscience corporelle.")
        case .pranayama:
            return LocalizedString(en: "Breathing exercises that regulate energy, calm the mind, and enhance focus.", fr: "Exercices de respiration qui régulent l'énergie, apaisent l'esprit et améliorent la concentration.")
        case .strength:
            return LocalizedString(en: "Resistance-focused sessions for muscular strength and endurance.", fr: "Séances axées sur la résistance pour la force et l'endurance musculaires.")
        case .cardio:
            return LocalizedString(en: "Elevated heart-rate intervals for cardiovascular conditioning.", fr: "Intervalles à fréquence cardiaque élevée pour le conditionnement cardiovasculaire.")
        case .mobility:
            return LocalizedString(en: "Joint range-of-motion and controlled movement prep for daily function.", fr: "Amplitude articulaire et mouvements contrôlés pour la fonction quotidienne.")
        case .meditation:
            return LocalizedString(en: "Stillness and breath-focused sessions for calm and awareness.", fr: "Séances de silence et de respiration pour le calme et la conscience.")
        case .general:
            return LocalizedString(en: "Mixed-modality workout when no specific style is selected.", fr: "Entraînement multi-modalités lorsqu'aucun style précis n'est sélectionné.")
        }
    }

    public var symbolName: String {
        switch self {
        case .chairYoga: return "figure.seated.side"
        case .matYoga: return "figure.yoga"
        case .vinyasa: return "figure.yoga"
        case .hatha: return "figure.flexibility"
        case .yin: return "moon.zzz"
        case .restorative: return "leaf.fill"
        case .power: return "bolt.fill"
        case .standingBalance: return "figure.stand"
        case .prenatal: return "heart.fill"
        case .pranayama: return "wind"
        case .strength: return "dumbbell.fill"
        case .cardio: return "figure.run"
        case .mobility: return "figure.cooldown"
        case .meditation: return "brain.head.profile"
        case .general: return "figure.mixed.cardio"
        }
    }

    public var accentHue: Double {
        switch self {
        case .chairYoga: return 0.55
        case .matYoga: return 0.58
        case .vinyasa: return 0.60
        case .hatha: return 0.35
        case .yin: return 0.75
        case .restorative: return 0.30
        case .power: return 0.05
        case .standingBalance: return 0.65
        case .prenatal: return 0.95
        case .pranayama: return 0.50
        case .strength: return 0.02
        case .cardio: return 0.98
        case .mobility: return 0.45
        case .meditation: return 0.70
        case .general: return 0.52
        }
    }

    // MARK: - Per-kind control defaults

    /// Nominal session BPM for Crooks work-feature origin (fractional BPM channel).
    /// Seated / meditative kinds stay near resting; cardio is higher so effort HR does
    /// not permanently trip grounding.
    public var nominalBPM: Double {
        switch self {
        case .chairYoga, .yin, .restorative, .prenatal, .pranayama, .meditation:
            return 85
        case .hatha, .matYoga, .standingBalance, .mobility:
            return 95
        case .vinyasa, .power, .general:
            return 110
        case .strength:
            return 120
        case .cardio:
            return 140
        }
    }

    /// Recovery tempo broadcast when heuristic σ_irr grounding fires.
    public var groundingBPM: Double {
        switch self {
        case .cardio:
            return 150
        case .strength:
            return 128
        case .vinyasa, .power, .general:
            return 118
        case .hatha, .matYoga, .standingBalance, .mobility:
            return 102
        case .chairYoga, .yin, .restorative, .prenatal, .pranayama, .meditation:
            return 92
        }
    }
}

/// Preferred name for workout style / kind (`YogaStyle` retained for Codable).
public typealias WorkoutKind = YogaStyle

/// A structured workout plan consisting of multiple poses.
public struct WorkoutPlan: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let name: LocalizedString
    public let description: LocalizedString
    public let style: YogaStyle
    public let poses: [Pose]
    /// Seconds between pose holds during which the cue for the next pose is shown.
    public let transitionSeconds: TimeInterval
    public let isFree: Bool

    public init(
        id: String,
        name: LocalizedString,
        description: LocalizedString,
        style: YogaStyle = .chairYoga,
        poses: [Pose],
        transitionSeconds: TimeInterval = 5,
        isFree: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.style = style
        self.poses = poses
        self.transitionSeconds = transitionSeconds
        self.isFree = isFree
    }

    public var poseCount: Int { poses.count }

    /// Total session time: sum of all pose durations plus transition intervals between them.
    public var totalDuration: TimeInterval {
        let poseDuration = poses.reduce(0) { $0 + $1.durationSeconds }
        let transitions = poses.count > 1 ? TimeInterval(poses.count - 1) * transitionSeconds : 0
        return poseDuration + transitions
    }
}

/// Central pose and workout plan registry aggregating all yoga styles.
///
/// Each style contributes its poses and plans via extensions in dedicated files
/// (PoseCatalog+ChairYoga.swift, PoseCatalog+Vinyasa.swift, etc.).
public enum PoseCatalog {

    // MARK: - Aggregated Collections

    public static let seatedMountain = Pose(
        id: "seated-mountain",
        name: LocalizedString(
            en: "Seated Mountain",
            fr: "Montagne assise",
            es: "Montaña sentada",
            ja: "座った山のポーズ",
            zh: "坐姿山式",
            ko: "앉은 산 자세",
            ru: "Поза горы сидя",
            de: "Sitzender Berg",
            ar: "وضعية الجبل جلوساً",
            it: "Montagna Seduta",
            pt: "Montanha Sentada"
        ),
        description: LocalizedString(
            en: "Sit tall at the front edge of your chair, feet hip-width apart and flat on the floor. Place hands on thighs, palms down. Roll shoulders back and down, lengthen through the crown of your head.",
            fr: "Assoyez-vous droit au bord avant de la chaise, pieds à la largeur des hanches bien à plat au sol. Placez les mains sur les cuisses, paumes vers le bas. Roulez les épaules vers l'arrière et vers le bas, allongez-vous à travers le sommet de la tête.",
            es: "Siéntese erguido en el borde delantero de la silla, con los pies separados al ancho de las caderas y apoyados en el suelo. Coloque las manos sobre los muslos, con las palmas hacia abajo. Lleve los hombros hacia atrás y hacia abajo, alargando la columna a través de la coronilla.",
            ja: "椅子の前端に背筋を伸ばして座り、足は腰幅に開いて床に平らにつけます。手を太ももの上に置き、手のひらを下に向けます。肩を後ろに引いて下げ、頭頂部を通して背筋を伸ばします。",
            zh: "挺直腰背坐在椅子前缘，双脚与臀同宽平放在地板上。双手放在大腿上，掌心朝下。肩膀向后向下转动，通过头顶延伸脊柱。",
            ko: "의자 앞쪽 가장자리에 허리를 펴고 앉아 발을 골반 너비로 벌려 바닥에 평평하게 놓습니다. 손을 허벅지 위에 올려 손바닥을 아래로 향하게 합니다. 어깨를 뒤로 돌려 내리고, 정수리를 통해 척추를 길게 늘입니다.",
            ru: "Сядьте прямо на переднем крае стула, стопы на ширине бёдер, ровно стоят на полу. Положите руки на бёдра ладонями вниз. Отведите плечи назад и вниз, вытягивайтесь через макушку головы.",
            de: "Setzen Sie sich aufrecht an die vordere Kante Ihres Stuhls, Füße hüftbreit auseinander und flach auf dem Boden. Legen Sie die Hände auf die Oberschenkel, Handflächen nach unten. Rollen Sie die Schultern zurück und nach unten, strecken Sie sich durch den Scheitel.",
            ar: "اجلس بشكل مستقيم على الحافة الأمامية للكرسي، والقدمان متباعدتان بعرض الوركين ومسطحتان على الأرض. ضع يديك على فخذيك وراحتاهما للأسفل. أدر كتفيك للخلف وللأسفل، واستطل عبر تاج رأسك."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .spine,
        imageName: "pose.seated.mountain",
        voiceCueText: LocalizedString(
            en: "Sit tall in Seated Mountain. Ground through your feet, lengthen your spine with each inhale.",
            fr: "Assoyez-vous bien droit en Montagne assise. Ancrez-vous à travers vos pieds, allongez la colonne à chaque inspiration.",
            es: "Siéntese erguido en Montaña sentada. Enraícese a través de los pies, alargue la columna con cada inhalación.",
            ja: "座った山のポーズで背筋を伸ばして座りましょう。足でしっかり地面を踏み、吸うたびに背骨を伸ばします。",
            zh: "在坐姿山式中挺直身体。双脚扎根地面，每次吸气时延伸脊柱。",
            ko: "앉은 산 자세로 허리를 펴고 앉으세요. 발로 바닥을 단단히 딛고, 들숨마다 척추를 길게 늘이세요.",
            ru: "Сядьте прямо в позе горы сидя. Укоренитесь через стопы, удлиняйте позвоночник с каждым вдохом.",
            de: "Sitzen Sie aufrecht im Sitzenden Berg. Verwurzeln Sie sich durch die Füße, verlängern Sie die Wirbelsäule mit jedem Einatmen.",
            ar: "اجلس بشكل مستقيم في وضعية الجبل جلوساً. ثبّت قدميك على الأرض، وأطِل عمودك الفقري مع كل شهيق."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a folded blanket under your feet if they don't reach the floor",
                 "Use a cushion behind your lower back for lumbar support"],
            fr: ["Placez une couverture pliée sous vos pieds s'ils ne touchent pas le sol",
                 "Utilisez un coussin derrière le bas du dos pour un soutien lombaire"],
            es: ["Coloque una manta doblada debajo de los pies si no llegan al suelo",
                 "Use un cojín detrás de la parte baja de la espalda para apoyo lumbar"],
            ja: ["足が床に届かない場合は、折りたたんだブランケットを足の下に置いてください",
                 "腰のサポートのために、背中の下部にクッションを置いてください"],
            zh: ["如果脚够不到地板，可以在脚下放一条折叠的毯子",
                 "在腰部后方放一个靠垫以支撑腰椎"],
            ko: ["발이 바닥에 닿지 않으면 접은 담요를 발 아래에 놓으세요",
                 "허리 지지를 위해 등 아래쪽에 쿠션을 놓으세요"],
            ru: ["Положите сложенное одеяло под стопы, если они не достают до пола",
                 "Используйте подушку за поясницей для поддержки"],
            de: ["Legen Sie eine gefaltete Decke unter die Füße, wenn sie den Boden nicht erreichen",
                 "Verwenden Sie ein Kissen hinter dem unteren Rücken zur Lendenstütze"],
            ar: ["ضع بطانية مطوية تحت قدميك إذا لم تصلا إلى الأرض",
                 "استخدم وسادة خلف أسفل ظهرك لدعم منطقة أسفل الظهر"]
        ),
        contraindications: LocalizedStringArray(en: [], fr: [], es: [], ja: [], zh: [], ko: [], ru: [], de: [], ar: []),
        breathingPattern: LocalizedString(
            en: "Natural deep breathing, 4 counts in, 4 counts out",
            fr: "Respiration profonde naturelle, 4 temps à l'inspiration, 4 temps à l'expiration",
            es: "Respiración profunda natural, 4 tiempos al inhalar, 4 tiempos al exhalar",
            ja: "自然な深い呼吸、4カウントで吸い、4カウントで吐く",
            zh: "自然深呼吸，吸气4拍，呼气4拍",
            ko: "자연스러운 깊은 호흡, 4박자 들이쉬고 4박자 내쉬기",
            ru: "Естественное глубокое дыхание, 4 счёта вдох, 4 счёта выдох",
            de: "Natürliche tiefe Atmung, 4 Zählzeiten einatmen, 4 Zählzeiten ausatmen",
            ar: "تنفس عميق طبيعي، 4 عدّات شهيق، 4 عدّات زفير"
        ),
        isFree: true
    )

    public static let seatedCatCow = Pose(
        id: "seated-cat-cow",
        name: LocalizedString(
            en: "Seated Cat-Cow",
            fr: "Chat-Vache assis",
            es: "Gato-Vaca sentado",
            ja: "座ったキャット・カウ",
            zh: "坐姿猫牛式",
            ko: "앉은 고양이-소 자세",
            ru: "Кошка-Корова сидя",
            de: "Sitzende Katze-Kuh",
            ar: "وضعية القطة-البقرة جلوساً"
        ),
        description: LocalizedString(
            en: "Place hands on knees. On the inhale, arch your back, lift your chest and gaze slightly up (Cow). On the exhale, round your spine, tuck your chin and draw your navel in (Cat). Flow smoothly between the two.",
            fr: "Placez les mains sur les genoux. À l'inspiration, cambrez le dos, soulevez la poitrine et regardez légèrement vers le haut (Vache). À l'expiration, arrondissez la colonne, rentrez le menton et tirez le nombril vers l'intérieur (Chat). Alternez en douceur.",
            es: "Coloque las manos sobre las rodillas. Al inhalar, arquee la espalda, levante el pecho y mire ligeramente hacia arriba (Vaca). Al exhalar, redondee la columna, meta la barbilla y lleve el ombligo hacia adentro (Gato). Fluya suavemente entre ambos.",
            ja: "手を膝の上に置きます。吸う息で背中を反らし、胸を持ち上げ、やや上を見ます（カウ）。吐く息で背骨を丸め、あごを引き、おへそを引き込みます（キャット）。二つの動きをなめらかに繰り返します。",
            zh: "双手放在膝盖上。吸气时弓起背部，抬起胸部，目光微微向上（牛式）。呼气时弓圆脊柱，收下巴，将肚脐向内收（猫式）。在两者之间流畅地转换。",
            ko: "손을 무릎 위에 놓습니다. 들숨에 등을 젖히고 가슴을 들어 올리며 시선을 살짝 위로 향합니다(소 자세). 날숨에 척추를 둥글게 말고 턱을 당기며 배꼽을 안으로 끌어당깁니다(고양이 자세). 두 자세를 부드럽게 번갈아 수행합니다.",
            ru: "Положите руки на колени. На вдохе прогните спину, поднимите грудную клетку и слегка посмотрите вверх (Корова). На выдохе скруглите позвоночник, прижмите подбородок и подтяните пупок (Кошка). Плавно чередуйте оба положения.",
            de: "Legen Sie die Hände auf die Knie. Beim Einatmen den Rücken durchstrecken, die Brust heben und leicht nach oben schauen (Kuh). Beim Ausatmen die Wirbelsäule runden, das Kinn einziehen und den Nabel nach innen ziehen (Katze). Fließend zwischen beiden wechseln.",
            ar: "ضع يديك على ركبتيك. عند الشهيق، قوّس ظهرك وارفع صدرك وانظر قليلاً للأعلى (البقرة). عند الزفير، دوّر عمودك الفقري واثنِ ذقنك واسحب سرّتك للداخل (القطة). انتقل بسلاسة بين الوضعيتين."
        ),
        durationSeconds: 45,
        difficulty: .beginner,
        category: .spine,
        imageName: "pose.seated.cat.cow",
        voiceCueText: LocalizedString(
            en: "Inhale, open your chest for Cow. Exhale, round your back for Cat. Let the breath guide the movement.",
            fr: "Inspirez, ouvrez la poitrine pour la Vache. Expirez, arrondissez le dos pour le Chat. Laissez le souffle guider le mouvement.",
            es: "Inhale, abra el pecho para la Vaca. Exhale, redondee la espalda para el Gato. Deje que la respiración guíe el movimiento.",
            ja: "吸って、胸を開いてカウのポーズ。吐いて、背中を丸めてキャットのポーズ。呼吸に動きを委ねましょう。",
            zh: "吸气，打开胸部做牛式。呼气，弓圆背部做猫式。让呼吸引导动作。",
            ko: "들숨에 가슴을 열어 소 자세. 날숨에 등을 둥글게 말아 고양이 자세. 호흡이 움직임을 이끌도록 하세요.",
            ru: "Вдох — раскройте грудную клетку для Коровы. Выдох — скруглите спину для Кошки. Пусть дыхание направляет движение.",
            de: "Einatmen, öffnen Sie die Brust für die Kuh. Ausatmen, runden Sie den Rücken für die Katze. Lassen Sie den Atem die Bewegung führen.",
            ar: "استنشق وافتح صدرك لوضعية البقرة. ازفر ودوّر ظهرك لوضعية القطة. دع النَّفَس يقود الحركة."
        ),
        modifications: LocalizedStringArray(
            en: ["Reduce the range of motion if you feel discomfort in the lower back",
                 "Place hands on the tops of thighs instead of knees"],
            fr: ["Réduisez l'amplitude du mouvement si vous ressentez un inconfort au bas du dos",
                 "Placez les mains sur le dessus des cuisses plutôt que sur les genoux"],
            es: ["Reduzca el rango de movimiento si siente molestias en la parte baja de la espalda",
                 "Coloque las manos en la parte superior de los muslos en lugar de las rodillas"],
            ja: ["腰に不快感がある場合は、動きの範囲を小さくしてください",
                 "膝の代わりに太ももの上に手を置いてください"],
            zh: ["如果感到腰部不适，请减小动作幅度",
                 "将手放在大腿上部而非膝盖上"],
            ko: ["허리에 불편함을 느끼면 동작 범위를 줄이세요",
                 "무릎 대신 허벅지 위에 손을 놓으세요"],
            ru: ["Уменьшите амплитуду движения при дискомфорте в пояснице",
                 "Положите руки на верхнюю часть бёдер вместо коленей"],
            de: ["Verringern Sie den Bewegungsumfang bei Beschwerden im unteren Rücken",
                 "Legen Sie die Hände auf die Oberschenkel statt auf die Knie"],
            ar: ["قلّل نطاق الحركة إذا شعرت بعدم راحة في أسفل الظهر",
                 "ضع يديك على أعلى الفخذين بدلاً من الركبتين"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid deep backbend if you have a herniated disc"],
            fr: ["Évitez la cambrure prononcée en cas de hernie discale"],
            es: ["Evite la flexión profunda hacia atrás si tiene una hernia de disco"],
            ja: ["椎間板ヘルニアがある場合は、深い後屈を避けてください"],
            zh: ["如有椎间盘突出，请避免深度后弯"],
            ko: ["추간판 탈출증이 있으면 깊은 후굴을 피하세요"],
            ru: ["Избегайте глубокого прогиба при грыже межпозвоночного диска"],
            de: ["Vermeiden Sie eine tiefe Rückbeuge bei einem Bandscheibenvorfall"],
            ar: ["تجنب الانحناء العميق للخلف إذا كنت تعاني من انزلاق غضروفي"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale for Cow, exhale for Cat — one full breath per cycle",
            fr: "Inspirez pour la Vache, expirez pour le Chat — un souffle complet par cycle",
            es: "Inhale para la Vaca, exhale para el Gato — una respiración completa por ciclo",
            ja: "カウで吸い、キャットで吐く — 1サイクルにつき1呼吸",
            zh: "牛式吸气，猫式呼气——每个循环一次完整呼吸",
            ko: "소 자세에서 들이쉬고, 고양이 자세에서 내쉬기 — 한 주기에 한 호흡",
            ru: "Вдох для Коровы, выдох для Кошки — один полный вдох-выдох за цикл",
            de: "Einatmen für die Kuh, ausatmen für die Katze — ein voller Atemzug pro Zyklus",
            ar: "شهيق لوضعية البقرة، زفير لوضعية القطة — نَفَس كامل واحد لكل دورة"
        ),
        isFree: true
    )

    public static let seatedSpinalTwist = Pose(
        id: "seated-twist",
        name: LocalizedString(
            en: "Seated Spinal Twist",
            fr: "Torsion vertébrale assise",
            es: "Torsión espinal sentada",
            ja: "座ったねじりのポーズ",
            zh: "坐姿脊柱扭转",
            ko: "앉은 척추 비틀기",
            ru: "Скручивание позвоночника сидя",
            de: "Sitzende Wirbelsäulendrehung",
            ar: "لفّ العمود الفقري جلوساً"
        ),
        description: LocalizedString(
            en: "Sit tall, place your left hand on your right knee and your right hand behind you on the chair seat or back. On an exhale, gently rotate your torso to the right, keeping both hips facing forward. Hold for several breaths, then switch sides.",
            fr: "Assoyez-vous bien droit, placez la main gauche sur le genou droit et la main droite derrière vous sur le siège ou le dossier de la chaise. À l'expiration, tournez doucement le torse vers la droite en gardant les deux hanches vers l'avant. Maintenez pendant plusieurs respirations, puis changez de côté.",
            es: "Siéntese erguido, coloque la mano izquierda sobre la rodilla derecha y la mano derecha detrás de usted sobre el asiento o el respaldo de la silla. Al exhalar, gire suavemente el torso hacia la derecha, manteniendo ambas caderas hacia adelante. Mantenga durante varias respiraciones, luego cambie de lado.",
            ja: "背筋を伸ばして座り、左手を右膝の上に、右手を椅子の座面または背もたれの後ろに置きます。吐く息で、両方の腰を正面に向けたまま、上体をゆっくり右にねじります。数回呼吸してから、反対側に切り替えます。",
            zh: "挺直腰背坐好，左手放在右膝上，右手放在身后椅座或椅背上。呼气时，保持双臀朝前，轻轻将躯干向右旋转。保持数次呼吸，然后换另一侧。",
            ko: "허리를 펴고 앉아 왼손을 오른쪽 무릎 위에, 오른손을 뒤쪽 의자 좌석이나 등받이 위에 놓습니다. 날숨에 양쪽 골반을 앞으로 향한 채 상체를 부드럽게 오른쪽으로 돌립니다. 여러 번 호흡하며 유지한 후 반대쪽으로 바꿉니다.",
            ru: "Сядьте прямо, положите левую руку на правое колено, а правую — за спину на сиденье или спинку стула. На выдохе мягко поверните корпус вправо, удерживая оба бедра направленными вперёд. Задержитесь на несколько вдохов, затем поменяйте сторону.",
            de: "Setzen Sie sich aufrecht, legen Sie die linke Hand auf das rechte Knie und die rechte Hand hinter sich auf die Sitzfläche oder Rückenlehne. Beim Ausatmen drehen Sie den Oberkörper sanft nach rechts, wobei beide Hüften nach vorne zeigen. Halten Sie einige Atemzüge, dann wechseln Sie die Seite.",
            ar: "اجلس بشكل مستقيم، ضع يدك اليسرى على ركبتك اليمنى ويدك اليمنى خلفك على مقعد الكرسي أو ظهره. عند الزفير، أدر جذعك برفق نحو اليمين مع إبقاء الوركين متجهين للأمام. استمر لعدة أنفاس، ثم بدّل الجانب."
        ),
        durationSeconds: 40,
        difficulty: .beginner,
        category: .spine,
        imageName: "pose.seated.twist",
        voiceCueText: LocalizedString(
            en: "Twist gently to the right. Grow taller on the inhale, deepen the twist on the exhale. Keep your shoulders relaxed.",
            fr: "Tournez doucement vers la droite. Grandissez-vous à l'inspiration, approfondissez la torsion à l'expiration. Gardez les épaules détendues.",
            es: "Gire suavemente hacia la derecha. Crézcase al inhalar, profundice el giro al exhalar. Mantenga los hombros relajados.",
            ja: "右にゆっくりねじります。吸う息で背を伸ばし、吐く息でねじりを深めます。肩の力を抜きましょう。",
            zh: "轻轻向右扭转。吸气时伸展身体，呼气时加深扭转。保持肩膀放松。",
            ko: "오른쪽으로 부드럽게 비틀어 줍니다. 들숨에 키를 늘이고, 날숨에 비틀기를 깊게 합니다. 어깨를 편안하게 유지하세요.",
            ru: "Мягко поверните корпус вправо. На вдохе вытянитесь выше, на выдохе углубите скручивание. Расслабьте плечи.",
            de: "Drehen Sie sich sanft nach rechts. Werden Sie beim Einatmen größer, vertiefen Sie die Drehung beim Ausatmen. Halten Sie die Schultern entspannt.",
            ar: "أدر جسمك برفق نحو اليمين. استطل مع الشهيق، وعمّق اللفّ مع الزفير. حافظ على استرخاء كتفيك."
        ),
        modifications: LocalizedStringArray(
            en: ["Use the chair back to gently assist the twist",
                 "Twist only as far as comfortable — never force"],
            fr: ["Utilisez le dossier de la chaise pour accompagner doucement la torsion",
                 "Ne tournez que jusqu'où c'est confortable — ne forcez jamais"],
            es: ["Use el respaldo de la silla para ayudar suavemente en el giro",
                 "Gire solo hasta donde sea cómodo — nunca fuerce"],
            ja: ["椅子の背もたれを使って、ねじりを優しくサポートしてください",
                 "心地よいところまでだけねじってください — 決して無理をしないで"],
            zh: ["借助椅背轻轻辅助扭转",
                 "只扭转到舒适的程度——切勿勉强"],
            ko: ["의자 등받이를 이용해 부드럽게 비틀기를 도와주세요",
                 "편안한 범위까지만 비트세요 — 절대 무리하지 마세요"],
            ru: ["Используйте спинку стула для мягкой помощи в скручивании",
                 "Поворачивайтесь только до комфортного положения — не форсируйте"],
            de: ["Nutzen Sie die Stuhllehne zur sanften Unterstützung der Drehung",
                 "Drehen Sie sich nur so weit, wie es bequem ist — niemals erzwingen"],
            ar: ["استخدم ظهر الكرسي للمساعدة برفق في اللفّ",
                 "لفّ فقط بالقدر المريح — لا تُجبر نفسك أبداً"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a recent spinal injury or acute back pain"],
            fr: ["Évitez en cas de blessure récente à la colonne vertébrale ou de douleur aiguë au dos"],
            es: ["Evite si tiene una lesión espinal reciente o dolor agudo de espalda"],
            ja: ["最近の脊椎の怪我や急性の腰痛がある場合は避けてください"],
            zh: ["如有近期脊柱损伤或急性背痛，请避免此动作"],
            ko: ["최근 척추 부상이나 급성 허리 통증이 있으면 피하세요"],
            ru: ["Избегайте при недавней травме позвоночника или острой боли в спине"],
            de: ["Vermeiden Sie dies bei einer kürzlichen Wirbelsäulenverletzung oder akuten Rückenschmerzen"],
            ar: ["تجنب هذه الوضعية إذا كنت تعاني من إصابة حديثة في العمود الفقري أو ألم حاد في الظهر"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen, exhale to deepen the twist",
            fr: "Inspirez pour allonger, expirez pour approfondir la torsion",
            es: "Inhale para alargarse, exhale para profundizar el giro",
            ja: "吸って伸び、吐いてねじりを深める",
            zh: "吸气延伸，呼气加深扭转",
            ko: "들숨에 늘이고, 날숨에 비틀기를 깊게",
            ru: "Вдох для удлинения, выдох для углубления скручивания",
            de: "Einatmen zum Verlängern, ausatmen zum Vertiefen der Drehung",
            ar: "استنشق للاستطالة، وازفر لتعميق اللفّ"
        ),
        isFree: true
    )

    public static let seatedForwardFold = Pose(
        id: "seated-forward-fold",
        name: LocalizedString(
            en: "Seated Forward Fold",
            fr: "Flexion avant assise",
            es: "Flexión hacia adelante sentada",
            ja: "座った前屈のポーズ",
            zh: "坐姿前屈",
            ko: "앉은 전굴 자세",
            ru: "Наклон вперёд сидя",
            de: "Sitzende Vorbeuge",
            ar: "الانحناء للأمام جلوساً"
        ),
        description: LocalizedString(
            en: "Sit at the edge of the chair, feet flat on the floor. On an exhale, hinge at the hips and slowly fold your torso forward over your thighs. Let your arms dangle toward the floor or rest on your shins. Keep a slight bend in the knees. Release the head and neck completely.",
            fr: "Assoyez-vous au bord de la chaise, pieds à plat au sol. À l'expiration, penchez-vous à partir des hanches et pliez lentement le torse vers l'avant par-dessus les cuisses. Laissez les bras pendre vers le sol ou reposer sur les tibias. Gardez une légère flexion aux genoux. Relâchez complètement la tête et le cou.",
            es: "Siéntese al borde de la silla, con los pies apoyados en el suelo. Al exhalar, flexione desde las caderas y pliegue lentamente el torso hacia adelante sobre los muslos. Deje que los brazos cuelguen hacia el suelo o descansen sobre las espinillas. Mantenga una ligera flexión en las rodillas. Relaje completamente la cabeza y el cuello.",
            ja: "椅子の端に座り、足を床に平らにつけます。吐く息で、腰から前に折り曲げ、上体をゆっくり太ももの上に倒します。腕を床に向けてぶら下げるか、すねの上に置きます。膝を軽く曲げたままにします。頭と首を完全にリラックスさせます。",
            zh: "坐在椅子边缘，双脚平放在地板上。呼气时，从髋部折叠，缓慢地将躯干向前弯曲靠在大腿上。让双臂自然垂向地面或放在小腿上。膝盖保持微弯。完全放松头部和颈部。",
            ko: "의자 가장자리에 앉아 발을 바닥에 평평하게 놓습니다. 날숨에 골반에서 접으며 상체를 천천히 허벅지 위로 앞으로 숙입니다. 팔을 바닥 쪽으로 늘어뜨리거나 정강이 위에 올려놓습니다. 무릎은 살짝 구부린 상태를 유지합니다. 머리와 목을 완전히 이완합니다.",
            ru: "Сядьте на край стула, стопы ровно на полу. На выдохе наклонитесь от бёдер и медленно опустите корпус вперёд на бёдра. Пусть руки свисают к полу или лежат на голенях. Сохраняйте лёгкий сгиб в коленях. Полностью расслабьте голову и шею.",
            de: "Setzen Sie sich an den Rand des Stuhls, Füße flach auf dem Boden. Beim Ausatmen beugen Sie sich aus der Hüfte und falten den Oberkörper langsam nach vorne über die Oberschenkel. Lassen Sie die Arme zum Boden hängen oder auf den Schienbeinen ruhen. Halten Sie eine leichte Beugung in den Knien. Lassen Sie Kopf und Nacken vollständig los.",
            ar: "اجلس على حافة الكرسي، والقدمان مسطحتان على الأرض. عند الزفير، انحنِ من الوركين واطوِ جذعك ببطء للأمام فوق فخذيك. اترك ذراعيك تتدليان نحو الأرض أو ضعهما على ساقيك. حافظ على انثناء خفيف في الركبتين. أرخِ رأسك ورقبتك تماماً."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .spine,
        imageName: "pose.seated.forward.fold",
        voiceCueText: LocalizedString(
            en: "Fold forward gently from the hips. Let gravity draw you down. Soften your neck and breathe deeply.",
            fr: "Penchez-vous vers l'avant doucement à partir des hanches. Laissez la gravité vous attirer vers le bas. Relâchez le cou et respirez profondément.",
            es: "Pliegue suavemente hacia adelante desde las caderas. Deje que la gravedad lo lleve hacia abajo. Relaje el cuello y respire profundamente.",
            ja: "腰からゆっくり前に折り曲げます。重力に身を委ねましょう。首をリラックスさせ、深く呼吸してください。",
            zh: "从髋部轻轻向前折叠。让重力将您带向下方。放松颈部，深呼吸。",
            ko: "골반에서 부드럽게 앞으로 접습니다. 중력이 몸을 이끌도록 하세요. 목을 부드럽게 하고 깊이 호흡하세요.",
            ru: "Мягко наклонитесь вперёд от бёдер. Позвольте гравитации притянуть вас вниз. Расслабьте шею и дышите глубоко.",
            de: "Beugen Sie sich sanft aus der Hüfte nach vorne. Lassen Sie die Schwerkraft Sie nach unten ziehen. Entspannen Sie den Nacken und atmen Sie tief.",
            ar: "انحنِ للأمام برفق من الوركين. دع الجاذبية تسحبك للأسفل. أرخِ رقبتك وتنفّس بعمق."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a pillow on your lap to fold onto for support",
                 "Widen your knees to make space for your belly"],
            fr: ["Placez un oreiller sur vos cuisses pour vous y appuyer",
                 "Écartez les genoux pour faire de la place à votre ventre"],
            es: ["Coloque una almohada en su regazo para apoyarse al plegarse",
                 "Separe las rodillas para hacer espacio para su abdomen"],
            ja: ["サポートのために膝の上に枕を置いて、その上に体を倒してください",
                 "お腹のスペースを作るために膝を広げてください"],
            zh: ["在大腿上放一个枕头，前屈时可以倚靠以获得支撑",
                 "将膝盖分开，为腹部腾出空间"],
            ko: ["지지를 위해 무릎 위에 베개를 놓고 그 위로 접으세요",
                 "배를 위한 공간을 만들기 위해 무릎을 벌리세요"],
            ru: ["Положите подушку на колени и опирайтесь на неё при наклоне",
                 "Разведите колени, чтобы освободить место для живота"],
            de: ["Legen Sie ein Kissen auf den Schoß, um sich beim Vorbeugen darauf zu stützen",
                 "Spreizen Sie die Knie, um Platz für den Bauch zu schaffen"],
            ar: ["ضع وسادة على حِجرك للاتكاء عليها عند الانحناء",
                 "وسّع ركبتيك لإفساح المجال لبطنك"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute low back pain or recent abdominal surgery",
                 "Use caution with high blood pressure — keep the head above the heart"],
            fr: ["Évitez en cas de douleur aiguë au bas du dos ou de chirurgie abdominale récente",
                 "Prudence en cas d'hypertension — gardez la tête au-dessus du cœur"],
            es: ["Evite con dolor agudo en la parte baja de la espalda o cirugía abdominal reciente",
                 "Precaución con presión arterial alta — mantenga la cabeza por encima del corazón"],
            ja: ["急性の腰痛や最近の腹部手術がある場合は避けてください",
                 "高血圧の方は注意してください — 頭を心臓より上に保ってください"],
            zh: ["急性腰痛或近期腹部手术者请避免",
                 "高血压患者请谨慎——保持头部高于心脏"],
            ko: ["급성 허리 통증이나 최근 복부 수술이 있으면 피하세요",
                 "고혈압이 있으면 주의하세요 — 머리를 심장보다 높게 유지하세요"],
            ru: ["Избегайте при острой боли в пояснице или недавней операции на брюшной полости",
                 "Соблюдайте осторожность при высоком давлении — голова должна быть выше сердца"],
            de: ["Vermeiden bei akuten Schmerzen im unteren Rücken oder kürzlicher Bauchoperation",
                 "Vorsicht bei hohem Blutdruck — Kopf über dem Herzen halten"],
            ar: ["تجنب هذه الوضعية مع ألم حاد في أسفل الظهر أو جراحة بطنية حديثة",
                 "توخَّ الحذر مع ارتفاع ضغط الدم — أبقِ الرأس فوق مستوى القلب"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to fold deeper, inhale to create space",
            fr: "Expirez pour plier plus profondément, inspirez pour créer de l'espace",
            es: "Exhale para plegarse más profundo, inhale para crear espacio",
            ja: "吐いてさらに深く折り、吸ってスペースを作る",
            zh: "呼气加深前屈，吸气创造空间",
            ko: "날숨에 더 깊이 접고, 들숨에 공간을 만드세요",
            ru: "Выдох для углубления наклона, вдох для создания пространства",
            de: "Ausatmen zum tieferen Beugen, einatmen zum Schaffen von Raum",
            ar: "ازفر للانحناء أعمق، واستنشق لخلق مساحة"
        ),
        isFree: true
    )

    public static let neckRolls = Pose(
        id: "neck-rolls",
        name: LocalizedString(
            en: "Gentle Neck Rolls",
            fr: "Cercles du cou en douceur",
            es: "Giros suaves del cuello",
            ja: "やさしい首回し",
            zh: "轻柔颈部环绕",
            ko: "부드러운 목 돌리기",
            ru: "Мягкие круговые движения шеей",
            de: "Sanfte Nackenkreise",
            ar: "دوران الرقبة بلطف"
        ),
        description: LocalizedString(
            en: "Drop your right ear toward your right shoulder. Slowly roll your chin down toward your chest, then continue to the left shoulder. Reverse direction. Move slowly and never roll the head all the way back.",
            fr: "Inclinez l'oreille droite vers l'épaule droite. Roulez lentement le menton vers la poitrine, puis continuez vers l'épaule gauche. Inversez la direction. Bougez lentement et ne renversez jamais complètement la tête vers l'arrière.",
            es: "Incline la oreja derecha hacia el hombro derecho. Ruede lentamente la barbilla hacia el pecho, luego continúe hacia el hombro izquierdo. Invierta la dirección. Muévase despacio y nunca incline la cabeza completamente hacia atrás.",
            ja: "右耳を右肩の方に傾けます。ゆっくりあごを胸に向けて転がし、左肩まで続けます。方向を逆にします。ゆっくり動き、頭を完全に後ろに倒さないでください。",
            zh: "将右耳朝右肩倾斜。慢慢将下巴向胸部方向滚动，然后继续到左肩。反方向重复。缓慢移动，切勿将头完全向后仰。",
            ko: "오른쪽 귀를 오른쪽 어깨 쪽으로 기울입니다. 천천히 턱을 가슴 쪽으로 굴린 다음 왼쪽 어깨 쪽으로 계속합니다. 방향을 바꿉니다. 천천히 움직이고 머리를 완전히 뒤로 젖히지 마세요.",
            ru: "Наклоните правое ухо к правому плечу. Медленно опустите подбородок к груди, затем продолжите к левому плечу. Поменяйте направление. Двигайтесь медленно и никогда не запрокидывайте голову назад полностью.",
            de: "Neigen Sie das rechte Ohr zur rechten Schulter. Rollen Sie das Kinn langsam zur Brust, dann weiter zur linken Schulter. Ändern Sie die Richtung. Bewegen Sie sich langsam und rollen Sie den Kopf niemals ganz nach hinten.",
            ar: "أمِل أذنك اليمنى نحو كتفك الأيمن. أدر ذقنك ببطء نحو صدرك، ثم تابع نحو الكتف الأيسر. اعكس الاتجاه. تحرّك ببطء ولا تُمِل رأسك للخلف بالكامل أبداً."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .neck,
        imageName: "pose.neck.rolls",
        voiceCueText: LocalizedString(
            en: "Roll your neck slowly in a half circle. Breathe into any areas of tension. Keep the movement gentle.",
            fr: "Roulez le cou lentement en demi-cercle. Respirez dans les zones de tension. Gardez le mouvement doux.",
            es: "Gire el cuello lentamente en semicírculo. Respire hacia las áreas de tensión. Mantenga el movimiento suave.",
            ja: "首をゆっくり半円を描くように回します。緊張のある部分に呼吸を送りましょう。動きを穏やかに保ちます。",
            zh: "缓慢地将颈部做半圆运动。向紧张的区域呼吸。保持动作轻柔。",
            ko: "목을 천천히 반원으로 돌립니다. 긴장된 부위에 호흡을 보내세요. 움직임을 부드럽게 유지하세요.",
            ru: "Медленно вращайте шею полукругом. Дышите в области напряжения. Сохраняйте мягкость движения.",
            de: "Rollen Sie den Nacken langsam im Halbkreis. Atmen Sie in verspannte Bereiche hinein. Halten Sie die Bewegung sanft.",
            ar: "أدر رقبتك ببطء في نصف دائرة. تنفّس في مناطق التوتر. حافظ على لطف الحركة."
        ),
        modifications: LocalizedStringArray(
            en: ["Pause on any tight spots and breathe into the stretch",
                 "Skip the roll and do simple ear-to-shoulder tilts"],
            fr: ["Faites une pause sur les points tendus et respirez dans l'étirement",
                 "Laissez tomber le cercle et faites de simples inclinaisons oreille-épaule"],
            es: ["Haga una pausa en los puntos tensos y respire hacia el estiramiento",
                 "Omita el giro y haga simples inclinaciones de oreja a hombro"],
            ja: ["硬い部分で止まり、ストレッチに呼吸を送ってください",
                 "回す動きを省略して、耳を肩に傾ける簡単な動きにしてください"],
            zh: ["在紧绷的位置暂停，向拉伸处呼吸",
                 "跳过环绕动作，做简单的耳朵向肩膀倾斜"],
            ko: ["뻣뻣한 부분에서 멈추고 스트레칭 부위에 호흡을 보내세요",
                 "돌리기를 건너뛰고 간단한 귀-어깨 기울이기를 하세요"],
            ru: ["Задерживайтесь на напряжённых участках и дышите в растяжку",
                 "Пропустите вращение и делайте простые наклоны ухом к плечу"],
            de: ["Verweilen Sie an verspannten Stellen und atmen Sie in die Dehnung",
                 "Lassen Sie das Rollen weg und machen Sie einfache Ohr-zu-Schulter-Neigungen"],
            ar: ["توقّف عند النقاط المشدودة وتنفّس في الإطالة",
                 "تخطَّ الدوران وقم بإمالات بسيطة من الأذن إلى الكتف"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid full backward head tilt if you have cervical issues"],
            fr: ["Évitez de pencher complètement la tête vers l'arrière en cas de problèmes cervicaux"],
            es: ["Evite inclinar completamente la cabeza hacia atrás si tiene problemas cervicales"],
            ja: ["頸椎に問題がある場合は、頭を完全に後ろに倒すのを避けてください"],
            zh: ["如有颈椎问题，请避免头部完全后仰"],
            ko: ["경추 문제가 있으면 머리를 완전히 뒤로 젖히지 마세요"],
            ru: ["Избегайте полного запрокидывания головы при проблемах с шейным отделом"],
            de: ["Vermeiden Sie ein vollständiges Zurückneigen des Kopfes bei Halswirbelproblemen"],
            ar: ["تجنب إمالة الرأس للخلف بالكامل إذا كنت تعاني من مشاكل في الفقرات العنقية"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow steady breathing throughout",
            fr: "Respiration lente et régulière tout au long",
            es: "Respiración lenta y constante durante todo el ejercicio",
            ja: "全体を通してゆっくり安定した呼吸",
            zh: "全程缓慢而平稳地呼吸",
            ko: "전체 동작 동안 느리고 안정적인 호흡",
            ru: "Медленное ровное дыхание на протяжении всего упражнения",
            de: "Langsame, gleichmäßige Atmung durchgehend",
            ar: "تنفس بطيء ومنتظم طوال التمرين"
        ),
        isFree: true
    )

    public static let shoulderRolls = Pose(
        id: "shoulder-rolls",
        name: LocalizedString(
            en: "Shoulder Rolls",
            fr: "Cercles des épaules",
            es: "Giros de hombros",
            ja: "肩回し",
            zh: "肩部环绕",
            ko: "어깨 돌리기",
            ru: "Вращение плечами",
            de: "Schulterkreise",
            ar: "دوران الكتفين"
        ),
        description: LocalizedString(
            en: "Sit tall with arms relaxed at your sides. Lift both shoulders up toward your ears, roll them back, squeeze the shoulder blades together, then roll them down and forward. Complete several circles, then reverse direction.",
            fr: "Assoyez-vous droit, bras détendus le long du corps. Montez les deux épaules vers les oreilles, roulez-les vers l'arrière, serrez les omoplates ensemble, puis roulez-les vers le bas et vers l'avant. Effectuez plusieurs cercles, puis inversez la direction.",
            es: "Siéntese erguido con los brazos relajados a los lados. Levante ambos hombros hacia las orejas, gírelos hacia atrás, junte los omóplatos, luego gírelos hacia abajo y hacia adelante. Complete varios círculos, luego invierta la dirección.",
            ja: "腕を体の横にリラックスさせて背筋を伸ばして座ります。両肩を耳に向けて持ち上げ、後ろに回し、肩甲骨を寄せてから、下に向かって前に回します。数回円を描いてから、逆方向に回します。",
            zh: "挺直腰背坐好，双臂自然放松于身体两侧。将双肩向耳朵方向抬起，向后转动，夹紧肩胛骨，然后向下向前转动。做数圈后换方向。",
            ko: "팔을 양옆에 편안히 놓고 허리를 펴고 앉습니다. 양 어깨를 귀 쪽으로 들어 올린 후 뒤로 돌리고, 견갑골을 함께 조인 다음 아래로 앞으로 돌립니다. 여러 번 원을 그린 후 방향을 바꿉니다.",
            ru: "Сядьте прямо, руки расслаблены вдоль тела. Поднимите оба плеча к ушам, отведите назад, сведите лопатки, затем опустите вниз и вперёд. Выполните несколько кругов, затем поменяйте направление.",
            de: "Setzen Sie sich aufrecht, Arme entspannt an den Seiten. Heben Sie beide Schultern zu den Ohren, rollen Sie sie zurück, drücken Sie die Schulterblätter zusammen, dann rollen Sie sie nach unten und vorne. Machen Sie mehrere Kreise, dann wechseln Sie die Richtung.",
            ar: "اجلس بشكل مستقيم مع إرخاء الذراعين على جانبيك. ارفع كلا الكتفين نحو أذنيك، أدرهما للخلف، اضغط لوحي الكتف معاً، ثم أدرهما للأسفل وللأمام. أكمل عدة دوائر، ثم اعكس الاتجاه."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .shoulders,
        imageName: "pose.shoulder.rolls",
        voiceCueText: LocalizedString(
            en: "Roll your shoulders back and down. Release tension with each circle. Breathe naturally.",
            fr: "Roulez les épaules vers l'arrière et vers le bas. Relâchez la tension à chaque cercle. Respirez naturellement.",
            es: "Gire los hombros hacia atrás y hacia abajo. Libere tensión con cada círculo. Respire naturalmente.",
            ja: "肩を後ろに回して下ろします。一回ごとに緊張を解放しましょう。自然に呼吸してください。",
            zh: "将肩膀向后向下转动。每次画圈时释放紧张。自然呼吸。",
            ko: "어깨를 뒤로 아래로 돌립니다. 매 원마다 긴장을 풀어주세요. 자연스럽게 호흡하세요.",
            ru: "Вращайте плечи назад и вниз. Отпускайте напряжение с каждым кругом. Дышите естественно.",
            de: "Rollen Sie die Schultern zurück und nach unten. Lösen Sie Spannung mit jedem Kreis. Atmen Sie natürlich.",
            ar: "أدر كتفيك للخلف وللأسفل. حرّر التوتر مع كل دائرة. تنفّس بشكل طبيعي."
        ),
        modifications: LocalizedStringArray(
            en: ["Make smaller circles if you have limited shoulder mobility"],
            fr: ["Faites de plus petits cercles si votre mobilité d'épaule est limitée"],
            es: ["Haga círculos más pequeños si tiene movilidad de hombro limitada"],
            ja: ["肩の可動域が制限されている場合は、より小さな円を描いてください"],
            zh: ["如果肩部活动范围有限，可以画更小的圈"],
            ko: ["어깨 가동 범위가 제한되어 있으면 더 작은 원을 그리세요"],
            ru: ["Делайте круги меньшего размера при ограниченной подвижности плеч"],
            de: ["Machen Sie kleinere Kreise bei eingeschränkter Schulterbeweglichkeit"],
            ar: ["اصنع دوائر أصغر إذا كانت حركة كتفك محدودة"]
        ),
        contraindications: LocalizedStringArray(en: [], fr: [], es: [], ja: [], zh: [], ko: [], ru: [], de: [], ar: []),
        breathingPattern: LocalizedString(
            en: "Inhale as shoulders rise, exhale as they roll back and down",
            fr: "Inspirez quand les épaules montent, expirez quand elles descendent",
            es: "Inhale cuando los hombros suban, exhale cuando bajen hacia atrás",
            ja: "肩が上がるとき吸い、後ろに下がるとき吐く",
            zh: "肩膀上升时吸气，向后向下转动时呼气",
            ko: "어깨가 올라갈 때 들이쉬고, 뒤로 아래로 내려갈 때 내쉬세요",
            ru: "Вдох при подъёме плеч, выдох при опускании назад и вниз",
            de: "Einatmen wenn die Schultern steigen, ausatmen wenn sie zurück und nach unten rollen",
            ar: "استنشق عندما ترتفع الكتفان، وازفر عندما تدوران للخلف وللأسفل"
        ),
        isFree: true
    )

    public static let seatedMeditation = Pose(
        id: "seated-meditation",
        name: LocalizedString(
            en: "Seated Meditation",
            fr: "Méditation assise",
            es: "Meditación sentada",
            ja: "座った瞑想",
            zh: "坐姿冥想",
            ko: "앉은 명상",
            ru: "Медитация сидя",
            de: "Sitzende Meditation",
            ar: "التأمل جلوساً"
        ),
        description: LocalizedString(
            en: "Sit comfortably with your feet flat on the floor, hands resting gently on your lap or thighs. Close your eyes or soften your gaze. Focus on the natural rhythm of your breath, observing each inhale and exhale without trying to change it.",
            fr: "Assoyez-vous confortablement, pieds à plat au sol, mains posées doucement sur les cuisses ou les genoux. Fermez les yeux ou adoucissez le regard. Concentrez-vous sur le rythme naturel de votre respiration, en observant chaque inspiration et expiration sans essayer de la modifier.",
            es: "Siéntese cómodamente con los pies apoyados en el suelo, las manos descansando suavemente en el regazo o los muslos. Cierre los ojos o suavice la mirada. Concéntrese en el ritmo natural de su respiración, observando cada inhalación y exhalación sin tratar de cambiarla.",
            ja: "足を床に平らにつけ、手を膝か太ももの上に軽く置いて、楽な姿勢で座ります。目を閉じるか、視線を柔らかくします。呼吸の自然なリズムに意識を向け、変えようとせずに各呼吸を観察します。",
            zh: "舒适地坐好，双脚平放在地板上，双手轻轻放在膝上或大腿上。闭上眼睛或柔化目光。专注于呼吸的自然节奏，观察每一次吸气和呼气，不要试图改变它。",
            ko: "발을 바닥에 평평하게 놓고 손을 무릎이나 허벅지 위에 가볍게 올려 편안하게 앉습니다. 눈을 감거나 시선을 부드럽게 합니다. 호흡의 자연스러운 리듬에 집중하며, 바꾸려 하지 말고 각 들숨과 날숨을 관찰합니다.",
            ru: "Сядьте удобно, стопы ровно на полу, руки мягко лежат на коленях или бёдрах. Закройте глаза или смягчите взгляд. Сосредоточьтесь на естественном ритме дыхания, наблюдая каждый вдох и выдох, не пытаясь его изменить.",
            de: "Setzen Sie sich bequem hin, Füße flach auf dem Boden, Hände ruhen sanft auf dem Schoß oder den Oberschenkeln. Schließen Sie die Augen oder lassen Sie den Blick weich werden. Konzentrieren Sie sich auf den natürlichen Atemrhythmus und beobachten Sie jedes Ein- und Ausatmen, ohne es zu verändern.",
            ar: "اجلس بشكل مريح مع وضع قدميك بشكل مسطح على الأرض، ويداك مستريحتان بلطف على حِجرك أو فخذيك. أغلق عينيك أو ليّن نظرتك. ركّز على الإيقاع الطبيعي لتنفسك، مراقباً كل شهيق وزفير دون محاولة تغييره."
        ),
        durationSeconds: 60,
        difficulty: .beginner,
        category: .breathing,
        imageName: "pose.seated.meditation",
        voiceCueText: LocalizedString(
            en: "Close your eyes. Breathe naturally. Observe each breath. Let each exhale release a little more tension.",
            fr: "Fermez les yeux. Respirez naturellement. Observez chaque souffle. Laissez chaque expiration relâcher un peu plus de tension.",
            es: "Cierre los ojos. Respire naturalmente. Observe cada respiración. Deje que cada exhalación libere un poco más de tensión.",
            ja: "目を閉じてください。自然に呼吸しましょう。一呼吸ずつ観察します。吐くたびに少しずつ緊張を手放しましょう。",
            zh: "闭上眼睛。自然呼吸。观察每一次呼吸。让每次呼气释放更多的紧张。",
            ko: "눈을 감으세요. 자연스럽게 호흡하세요. 각 호흡을 관찰하세요. 날숨마다 긴장을 조금씩 더 풀어주세요.",
            ru: "Закройте глаза. Дышите естественно. Наблюдайте каждый вдох. Пусть каждый выдох отпускает ещё немного напряжения.",
            de: "Schließen Sie die Augen. Atmen Sie natürlich. Beobachten Sie jeden Atemzug. Lassen Sie mit jedem Ausatmen etwas mehr Spannung los.",
            ar: "أغلق عينيك. تنفّس بشكل طبيعي. راقب كل نَفَس. دع كل زفير يُطلق مزيداً من التوتر."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep eyes slightly open with a soft downward gaze if closing them feels uncomfortable",
                 "Place a hand on your belly to feel the breath"],
            fr: ["Gardez les yeux légèrement ouverts avec un regard doux vers le bas si les fermer est inconfortable",
                 "Placez une main sur le ventre pour ressentir le souffle"],
            es: ["Mantenga los ojos ligeramente abiertos con una mirada suave hacia abajo si cerrarlos es incómodo",
                 "Coloque una mano sobre el abdomen para sentir la respiración"],
            ja: ["目を閉じるのが不快な場合は、下を向いた柔らかい視線で目を少し開けておいてください",
                 "呼吸を感じるために手をお腹の上に置いてください"],
            zh: ["如果闭眼不舒服，可以微微睁开眼睛，目光柔和地向下看",
                 "将一只手放在腹部感受呼吸"],
            ko: ["눈을 감는 것이 불편하면 부드러운 하향 시선으로 눈을 살짝 뜨고 있으세요",
                 "호흡을 느끼기 위해 손을 배 위에 놓으세요"],
            ru: ["Если закрывать глаза некомфортно, держите их слегка приоткрытыми с мягким взглядом вниз",
                 "Положите руку на живот, чтобы чувствовать дыхание"],
            de: ["Halten Sie die Augen leicht geöffnet mit sanftem Blick nach unten, wenn das Schließen unangenehm ist",
                 "Legen Sie eine Hand auf den Bauch, um den Atem zu spüren"],
            ar: ["أبقِ عينيك مفتوحتين قليلاً مع نظرة ناعمة للأسفل إذا كان إغلاقهما غير مريح",
                 "ضع يداً على بطنك لتشعر بالتنفس"]
        ),
        contraindications: LocalizedStringArray(en: [], fr: [], es: [], ja: [], zh: [], ko: [], ru: [], de: [], ar: []),
        breathingPattern: LocalizedString(
            en: "Natural breathing — observe without controlling",
            fr: "Respiration naturelle — observez sans contrôler",
            es: "Respiración natural — observe sin controlar",
            ja: "自然な呼吸 — コントロールせずに観察する",
            zh: "自然呼吸——观察而不控制",
            ko: "자연스러운 호흡 — 조절하지 말고 관찰하기",
            ru: "Естественное дыхание — наблюдайте, не контролируя",
            de: "Natürliche Atmung — beobachten ohne zu kontrollieren",
            ar: "تنفس طبيعي — راقب دون تحكّم"
        ),
        isFree: true
    )

    // MARK: - Intermediate Poses (Premium)

    public static let seatedEagleArms = Pose(
        id: "seated-eagle-arms",
        name: LocalizedString(
            en: "Seated Eagle Arms",
            fr: "Bras de l'aigle assis",
            es: "Brazos de águila sentado",
            ja: "座ったイーグルアームズ",
            zh: "坐姿鹰式手臂",
            ko: "앉은 독수리 팔 자세",
            ru: "Руки орла сидя",
            de: "Sitzende Adlerarme",
            ar: "وضعية ذراعي النسر جلوساً"
        ),
        description: LocalizedString(
            en: "Extend both arms forward. Cross the right arm under the left at the elbows. Bend both elbows and try to bring the palms together (or backs of hands). Lift the elbows to shoulder height while keeping the shoulders down. Hold, then switch sides.",
            fr: "Étendez les deux bras devant vous. Croisez le bras droit sous le gauche au niveau des coudes. Pliez les deux coudes et essayez de joindre les paumes (ou le dos des mains). Soulevez les coudes à la hauteur des épaules en gardant les épaules basses. Maintenez, puis changez de côté.",
            es: "Extienda ambos brazos hacia adelante. Cruce el brazo derecho por debajo del izquierdo a la altura de los codos. Doble ambos codos e intente juntar las palmas (o el dorso de las manos). Levante los codos a la altura de los hombros manteniendo los hombros abajo. Mantenga, luego cambie de lado.",
            ja: "両腕を前に伸ばします。右腕を左腕の下で肘のところで交差させます。両肘を曲げ、手のひらを合わせるようにします（または手の甲同士）。肩を下げたまま肘を肩の高さまで持ち上げます。キープし、反対側に切り替えます。",
            zh: "双臂向前伸展。右臂从左臂下方在肘部交叉。弯曲双肘，尝试让掌心合拢（或手背相对）。保持肩膀下沉，将肘部抬至肩膀高度。保持，然后换边。",
            ko: "두 팔을 앞으로 뻗으세요. 오른팔을 왼팔 아래로 팔꿈치에서 교차시킵니다. 두 팔꿈치를 구부려 손바닥을 맞대보세요 (또는 손등끼리). 어깨를 내린 채 팔꿈치를 어깨 높이까지 올립니다. 유지한 후 반대쪽으로 바꿉니다.",
            ru: "Вытяните обе руки вперёд. Скрестите правую руку под левой в области локтей. Согните оба локтя и попробуйте соединить ладони (или тыльные стороны кистей). Поднимите локти до уровня плеч, удерживая плечи внизу. Задержитесь, затем поменяйте сторону.",
            de: "Strecken Sie beide Arme nach vorne. Kreuzen Sie den rechten Arm unter dem linken an den Ellbogen. Beugen Sie beide Ellbogen und versuchen Sie, die Handflächen zusammenzubringen (oder die Handrücken). Heben Sie die Ellbogen auf Schulterhöhe, während die Schultern unten bleiben. Halten Sie, dann wechseln Sie die Seite.",
            ar: "مدّ كلا الذراعين للأمام. اعبر الذراع اليمنى تحت اليسرى عند المرفقين. اثنِ كلا المرفقين وحاول ضم الكفين معاً (أو ظهر اليدين). ارفع المرفقين إلى مستوى الكتفين مع إبقاء الكتفين منخفضين. حافظ على الوضع، ثم بدّل الجانب."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .shoulders,
        imageName: "pose.seated.eagle.arms",
        voiceCueText: LocalizedString(
            en: "Wrap your arms into Eagle. Lift your elbows, drop your shoulders. Breathe into the space between your shoulder blades.",
            fr: "Enroulez vos bras en Aigle. Soulevez les coudes, abaissez les épaules. Respirez dans l'espace entre les omoplates.",
            es: "Enrolle los brazos en Águila. Levante los codos, baje los hombros. Respire en el espacio entre los omóplatos.",
            ja: "腕をイーグルに巻きつけましょう。肘を持ち上げ、肩を下ろします。肩甲骨の間に息を送りましょう。",
            zh: "将手臂缠绕成鹰式。抬起肘部，放下肩膀。将呼吸送入肩胛骨之间的空间。",
            ko: "팔을 독수리 자세로 감으세요. 팔꿈치를 올리고 어깨를 내리세요. 견갑골 사이 공간으로 호흡하세요.",
            ru: "Оберните руки в позу Орла. Поднимите локти, опустите плечи. Дышите в пространство между лопатками.",
            de: "Wickeln Sie Ihre Arme in den Adler. Heben Sie die Ellbogen, senken Sie die Schultern. Atmen Sie in den Raum zwischen den Schulterblättern.",
            ar: "لفّ ذراعيك في وضعية النسر. ارفع مرفقيك، وأنزل كتفيك. تنفّس في المساحة بين لوحي الكتف."
        ),
        modifications: LocalizedStringArray(
            en: ["Hug yourself with opposite hands on shoulders if wrapping is too difficult",
                 "Use a strap between hands if palms don't touch"],
            fr: ["Serrez-vous dans vos bras, mains sur les épaules opposées, si l'enroulement est trop difficile",
                 "Utilisez une sangle entre les mains si les paumes ne se touchent pas"],
            es: ["Abrácese con las manos en los hombros opuestos si el cruce es demasiado difícil",
                 "Use una correa entre las manos si las palmas no se tocan"],
            ja: ["腕を巻きつけるのが難しい場合は、反対の手を肩に置いて自分を抱きしめてください",
                 "手のひらが合わない場合は、手の間にストラップを使ってください"],
            zh: ["如果缠绕太困难，可以双手交叉放在对侧肩膀上拥抱自己",
                 "如果掌心无法合拢，可以在双手间使用一条带子"],
            ko: ["감는 것이 너무 어려우면 반대쪽 손을 어깨에 놓고 자신을 안아주세요",
                 "손바닥이 닿지 않으면 손 사이에 스트랩을 사용하세요"],
            ru: ["Обнимите себя, положив руки на противоположные плечи, если обвивание слишком сложно",
                 "Используйте ремень между руками, если ладони не соприкасаются"],
            de: ["Umarmen Sie sich mit den Händen auf den gegenüberliegenden Schultern, wenn das Wickeln zu schwierig ist",
                 "Verwenden Sie einen Gurt zwischen den Händen, wenn die Handflächen sich nicht berühren"],
            ar: ["احتضن نفسك بوضع اليدين على الكتفين المعاكسين إذا كان اللف صعباً جداً",
                 "استخدم حزاماً بين اليدين إذا لم تتلامس الكفّان"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a shoulder injury or recent shoulder surgery"],
            fr: ["Évitez en cas de blessure à l'épaule ou de chirurgie récente de l'épaule"],
            es: ["Evite si tiene una lesión en el hombro o una cirugía reciente del hombro"],
            ja: ["肩の怪我や最近の肩の手術がある場合は避けてください"],
            zh: ["如有肩部损伤或近期做过肩部手术，请避免此动作"],
            ko: ["어깨 부상이나 최근 어깨 수술을 받은 경우 피하세요"],
            ru: ["Избегайте при травме плеча или недавней операции на плече"],
            de: ["Vermeiden Sie diese Übung bei Schulterverletzungen oder kürzlicher Schulteroperation"],
            ar: ["تجنّب هذا التمرين في حالة إصابة الكتف أو جراحة كتف حديثة"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady breathing, inhale to lift elbows, exhale to soften shoulders",
            fr: "Respiration régulière, inspirez pour lever les coudes, expirez pour relâcher les épaules",
            es: "Respiración constante, inhale para levantar los codos, exhale para relajar los hombros",
            ja: "安定した呼吸、吸って肘を上げ、吐いて肩をリラックスさせる",
            zh: "平稳呼吸，吸气抬起肘部，呼气放松肩膀",
            ko: "안정적인 호흡, 들숨에 팔꿈치를 올리고, 날숨에 어깨를 부드럽게",
            ru: "Ровное дыхание, вдох — поднимаем локти, выдох — расслабляем плечи",
            de: "Gleichmäßige Atmung, einatmen um die Ellbogen zu heben, ausatmen um die Schultern zu lösen",
            ar: "تنفس ثابت، استنشق لرفع المرفقين، وازفر لإرخاء الكتفين"
        ),
        isFree: true
    )

    public static let seatedPigeon = Pose(
        id: "seated-pigeon",
        name: LocalizedString(
            en: "Seated Pigeon",
            fr: "Pigeon assis",
            es: "Paloma sentada",
            ja: "座った鳩のポーズ",
            zh: "坐姿鸽子式",
            ko: "앉은 비둘기 자세",
            ru: "Поза голубя сидя",
            de: "Sitzende Taube",
            ar: "وضعية الحمامة جلوساً"
        ),
        description: LocalizedString(
            en: "Sit tall and place your right ankle on top of your left knee, forming a figure 4. Flex your right foot to protect the knee. Keep your spine straight and gently press the right knee down with your hand. For a deeper stretch, hinge forward from the hips. Hold, then switch legs.",
            fr: "Assoyez-vous bien droit et placez la cheville droite sur le genou gauche, formant un 4. Fléchissez le pied droit pour protéger le genou. Gardez la colonne droite et appuyez doucement le genou droit vers le bas avec la main. Pour un étirement plus profond, penchez-vous vers l'avant à partir des hanches. Maintenez, puis changez de jambe.",
            es: "Siéntese erguido y coloque el tobillo derecho sobre la rodilla izquierda, formando un 4. Flexione el pie derecho para proteger la rodilla. Mantenga la columna recta y presione suavemente la rodilla derecha hacia abajo con la mano. Para un estiramiento más profundo, inclínese hacia adelante desde las caderas. Mantenga, luego cambie de pierna.",
            ja: "背筋を伸ばして座り、右足首を左膝の上に置いて数字の4を作ります。膝を保護するために右足を曲げます。背骨をまっすぐに保ち、手で右膝を優しく押し下げます。より深いストレッチのためには、腰から前に傾けます。キープし、脚を入れ替えます。",
            zh: "挺直腰背坐好，将右脚踝放在左膝上方，形成数字4的形状。弯曲右脚以保护膝盖。保持脊柱挺直，用手轻轻将右膝向下按。要加深拉伸，可以从臀部向前倾。保持，然后换腿。",
            ko: "허리를 펴고 앉아 오른쪽 발목을 왼쪽 무릎 위에 올려 숫자 4 모양을 만듭니다. 무릎을 보호하기 위해 오른발을 굽힙니다. 척추를 곧게 유지하고 손으로 오른쪽 무릎을 부드럽게 아래로 누릅니다. 더 깊은 스트레칭을 위해 골반에서 앞으로 기울입니다. 유지한 후 다리를 바꿉니다.",
            ru: "Сядьте прямо и положите правую лодыжку на левое колено, образуя цифру 4. Согните правую стопу для защиты колена. Держите позвоночник прямым и мягко надавливайте рукой на правое колено вниз. Для более глубокой растяжки наклонитесь вперёд от бёдер. Задержитесь, затем поменяйте ноги.",
            de: "Setzen Sie sich aufrecht und legen Sie den rechten Knöchel auf das linke Knie, um eine 4 zu formen. Beugen Sie den rechten Fuß, um das Knie zu schützen. Halten Sie die Wirbelsäule gerade und drücken Sie das rechte Knie sanft mit der Hand nach unten. Für eine tiefere Dehnung neigen Sie sich von den Hüften nach vorne. Halten Sie, dann wechseln Sie die Beine.",
            ar: "اجلس بشكل مستقيم وضع كاحلك الأيمن فوق ركبتك اليسرى مكوّناً شكل الرقم 4. اثنِ قدمك اليمنى لحماية الركبة. حافظ على استقامة عمودك الفقري واضغط برفق على الركبة اليمنى للأسفل بيدك. لتمدد أعمق، انحنِ للأمام من الوركين. حافظ على الوضع، ثم بدّل الساقين."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .hips,
        imageName: "pose.seated.pigeon",
        voiceCueText: LocalizedString(
            en: "Cross your ankle over the opposite knee. Keep the top foot flexed. Breathe into the stretch in your outer hip.",
            fr: "Croisez la cheville sur le genou opposé. Gardez le pied du dessus fléchi. Respirez dans l'étirement de la hanche extérieure.",
            es: "Cruce el tobillo sobre la rodilla opuesta. Mantenga el pie de arriba flexionado. Respire hacia el estiramiento en la cadera externa.",
            ja: "足首を反対の膝の上に乗せます。上の足を曲げた状態に保ちます。外側の股関節のストレッチに呼吸を送りましょう。",
            zh: "将脚踝交叉放在对侧膝盖上。保持上方脚掌回勾。将呼吸送入臀部外侧的拉伸处。",
            ko: "발목을 반대쪽 무릎 위에 올립니다. 위쪽 발을 굽힌 상태로 유지하세요. 바깥쪽 골반의 스트레칭에 호흡을 보내세요.",
            ru: "Положите лодыжку на противоположное колено. Удерживайте верхнюю стопу согнутой. Дышите в растяжку внешней стороны бедра.",
            de: "Legen Sie den Knöchel über das gegenüberliegende Knie. Halten Sie den oberen Fuß gebeugt. Atmen Sie in die Dehnung der äußeren Hüfte.",
            ar: "ضع كاحلك فوق الركبة المقابلة. أبقِ القدم العلوية مثنية. تنفّس في منطقة تمدد الورك الخارجي."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the crossed ankle lower on the shin instead of the knee",
                 "Skip the forward fold if the hip stretch alone is enough"],
            fr: ["Gardez la cheville croisée plus bas sur le tibia plutôt que sur le genou",
                 "Laissez tomber la flexion avant si l'étirement de la hanche suffit"],
            es: ["Mantenga el tobillo cruzado más abajo en la espinilla en lugar de la rodilla",
                 "Omita la flexión hacia adelante si el estiramiento de cadera solo es suficiente"],
            ja: ["交差した足首を膝ではなくすねの低い位置に置いてください",
                 "股関節のストレッチだけで十分なら、前屈を省いてください"],
            zh: ["将交叉的脚踝放低到小腿上而非膝盖上",
                 "如果仅髋部拉伸就足够了，可以跳过前屈"],
            ko: ["교차한 발목을 무릎이 아닌 정강이 아래쪽에 놓으세요",
                 "골반 스트레칭만으로 충분하면 전굴을 생략하세요"],
            ru: ["Держите скрещённую лодыжку ниже на голени вместо колена",
                 "Пропустите наклон вперёд, если растяжки бедра достаточно"],
            de: ["Halten Sie den gekreuzten Knöchel tiefer am Schienbein statt am Knie",
                 "Überspringen Sie die Vorbeuge, wenn die Hüftdehnung allein ausreicht"],
            ar: ["أبقِ الكاحل المتقاطع أسفل على الساق بدلاً من الركبة",
                 "تخطَّ الانحناء للأمام إذا كان تمدد الورك وحده كافياً"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a knee injury on either leg",
                 "Skip if you have had a recent hip replacement"],
            fr: ["Évitez en cas de blessure au genou sur l'une ou l'autre jambe",
                 "Laissez tomber en cas de remplacement récent de la hanche"],
            es: ["Evite si tiene una lesión de rodilla en cualquier pierna",
                 "Omita si ha tenido un reemplazo de cadera reciente"],
            ja: ["どちらかの脚に膝の怪我がある場合は避けてください",
                 "最近人工股関節置換術を受けた場合は省いてください"],
            zh: ["任一腿有膝盖损伤时请避免",
                 "如近期做过髋关节置换手术，请跳过此动作"],
            ko: ["어느 쪽 다리든 무릎 부상이 있으면 피하세요",
                 "최근 고관절 치환술을 받았다면 건너뛰세요"],
            ru: ["Избегайте при травме колена на любой ноге",
                 "Пропустите при недавнем эндопротезировании тазобедренного сустава"],
            de: ["Vermeiden Sie dies bei einer Knieverletzung an beiden Beinen",
                 "Überspringen Sie die Übung bei kürzlichem Hüftgelenkersatz"],
            ar: ["تجنب إذا كنت تعاني من إصابة في الركبة في أي من الساقين",
                 "تخطَّ إذا خضعت لاستبدال مفصل الورك مؤخراً"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow exhales to release into the hip stretch",
            fr: "Expirations lentes pour se relâcher dans l'étirement de la hanche",
            es: "Exhalaciones lentas para liberar hacia el estiramiento de cadera",
            ja: "ゆっくり吐いて股関節のストレッチに身を委ねる",
            zh: "缓慢呼气，放松进入髋部拉伸",
            ko: "느린 날숨으로 골반 스트레칭에 몸을 맡기세요",
            ru: "Медленные выдохи для расслабления в растяжке бедра",
            de: "Langsames Ausatmen, um in die Hüftdehnung loszulassen",
            ar: "زفير بطيء للاسترخاء في تمدد الورك"
        ),
        isFree: true
    )

    public static let seatedWarriorII = Pose(
        id: "seated-warrior-2",
        name: LocalizedString(
            en: "Seated Warrior II",
            fr: "Guerrier II assis",
            es: "Guerrero II sentado",
            ja: "座った戦士のポーズII",
            zh: "坐姿战士二式",
            ko: "앉은 전사 자세 II",
            ru: "Воин II сидя",
            de: "Sitzender Krieger II",
            ar: "وضعية المحارب الثاني جلوساً"
        ),
        description: LocalizedString(
            en: "Sit sideways on the chair with your right thigh on the seat and your left leg extended behind you, toes on the floor. Open your arms wide, right arm forward and left arm back, palms down. Gaze over your front fingertips. Keep your torso upright and centred. Hold, then turn and switch sides.",
            fr: "Assoyez-vous de côté sur la chaise, la cuisse droite sur le siège et la jambe gauche étendue derrière vous, orteils au sol. Ouvrez les bras largement, bras droit devant et bras gauche derrière, paumes vers le bas. Regardez par-dessus le bout de vos doigts avant. Gardez le torse droit et centré. Maintenez, puis tournez-vous et changez de côté.",
            es: "Siéntese de lado en la silla con el muslo derecho sobre el asiento y la pierna izquierda extendida detrás, con los dedos del pie en el suelo. Abra los brazos ampliamente, brazo derecho hacia adelante y brazo izquierdo hacia atrás, palmas hacia abajo. Mire sobre las puntas de los dedos delanteros. Mantenga el torso erguido y centrado. Mantenga, luego gire y cambie de lado.",
            ja: "椅子に横向きに座り、右太ももを座面に置き、左脚を後ろに伸ばしてつま先を床につけます。両腕を大きく広げ、右腕を前に、左腕を後ろに、手のひらを下に向けます。前の指先の向こうを見つめます。上体をまっすぐ中心に保ちます。キープし、向きを変えて反対側を行います。",
            zh: "侧坐在椅子上，右大腿放在座面上，左腿向后伸展，脚趾触地。双臂大幅展开，右臂向前，左臂向后，掌心朝下。目光越过前方指尖。保持躯干挺直居中。保持，然后转身换边。",
            ko: "의자에 옆으로 앉아 오른쪽 허벅지를 좌석에 놓고 왼쪽 다리를 뒤로 뻗어 발가락을 바닥에 놓습니다. 두 팔을 넓게 벌려 오른팔은 앞으로, 왼팔은 뒤로, 손바닥을 아래로 향합니다. 앞쪽 손끝 너머를 바라봅니다. 상체를 곧고 중심에 유지합니다. 유지한 후 돌아서 반대쪽을 수행합니다.",
            ru: "Сядьте боком на стул, правое бедро на сиденье, левая нога вытянута назад, пальцы ног на полу. Разведите руки широко, правая рука вперёд, левая назад, ладони вниз. Смотрите поверх пальцев передней руки. Держите корпус прямо и по центру. Задержитесь, затем развернитесь и поменяйте сторону.",
            de: "Setzen Sie sich seitlich auf den Stuhl, rechter Oberschenkel auf der Sitzfläche, linkes Bein nach hinten gestreckt, Zehen auf dem Boden. Öffnen Sie die Arme weit, rechter Arm nach vorne, linker nach hinten, Handflächen nach unten. Blicken Sie über die vorderen Fingerspitzen. Halten Sie den Oberkörper aufrecht und zentriert. Halten Sie, dann drehen Sie sich und wechseln die Seite.",
            ar: "اجلس جانبياً على الكرسي مع وضع فخذك الأيمن على المقعد ومدّ ساقك اليسرى خلفك وأصابع القدم على الأرض. افتح ذراعيك على نطاق واسع، الذراع اليمنى للأمام واليسرى للخلف، والكفّان للأسفل. انظر فوق أطراف أصابعك الأمامية. حافظ على جذعك مستقيماً ومتوسطاً. استمر، ثم استدر وبدّل الجانب."
        ),
        durationSeconds: 40,
        difficulty: .intermediate,
        category: .fullBody,
        imageName: "pose.seated.warrior2",
        voiceCueText: LocalizedString(
            en: "Open into Warrior Two. Reach through both fingertips. Feel strong and grounded through your seat.",
            fr: "Ouvrez-vous en Guerrier Deux. Étirez-vous à travers les deux bouts des doigts. Sentez-vous fort et ancré à travers votre siège.",
            es: "Ábrase en Guerrero Dos. Extiéndase a través de ambas puntas de los dedos. Siéntase fuerte y enraizado a través de su asiento.",
            ja: "ウォーリアー・ツーに開きましょう。両方の指先を通して伸ばします。座面を通して力強く安定していると感じてください。",
            zh: "展开进入战士二式。双手指尖向两端延伸。通过坐姿感受力量和稳定。",
            ko: "전사 자세 II로 열어줍니다. 양쪽 손끝까지 뻗으세요. 좌석을 통해 강하고 안정적으로 느끼세요.",
            ru: "Раскройтесь в Воина Два. Тянитесь через кончики пальцев обеих рук. Почувствуйте силу и устойчивость через сиденье.",
            de: "Öffnen Sie sich in Krieger Zwei. Strecken Sie sich durch beide Fingerspitzen. Fühlen Sie sich stark und geerdet durch Ihren Sitz.",
            ar: "افتح جسمك في وضعية المحارب الثاني. امتدّ عبر أطراف أصابع كلتا اليدين. اشعر بالقوة والثبات من خلال مقعدك."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep both feet on the floor for balance",
                 "Rest the back hand on the chair back for stability"],
            fr: ["Gardez les deux pieds au sol pour l'équilibre",
                 "Appuyez la main arrière sur le dossier de la chaise pour la stabilité"],
            es: ["Mantenga ambos pies en el suelo para el equilibrio",
                 "Apoye la mano trasera en el respaldo de la silla para estabilidad"],
            ja: ["バランスのために両足を床につけておいてください",
                 "安定のために後ろの手を椅子の背もたれに置いてください"],
            zh: ["双脚保持在地板上以保持平衡",
                 "将后方的手放在椅背上以保持稳定"],
            ko: ["균형을 위해 양발을 바닥에 유지하세요",
                 "안정을 위해 뒤쪽 손을 의자 등받이에 놓으세요"],
            ru: ["Держите обе стопы на полу для равновесия",
                 "Положите заднюю руку на спинку стула для устойчивости"],
            de: ["Halten Sie beide Füße auf dem Boden für das Gleichgewicht",
                 "Legen Sie die hintere Hand auf die Stuhllehne für Stabilität"],
            ar: ["أبقِ كلتا القدمين على الأرض للتوازن",
                 "ضع اليد الخلفية على ظهر الكرسي من أجل الثبات"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have hip pain that worsens with external rotation"],
            fr: ["Évitez si vous avez une douleur à la hanche qui empire avec la rotation externe"],
            es: ["Evite si tiene dolor de cadera que empeora con la rotación externa"],
            ja: ["外旋で悪化する股関節の痛みがある場合は避けてください"],
            zh: ["如果髋部疼痛在外旋时加重，请避免此动作"],
            ko: ["외회전 시 악화되는 골반 통증이 있으면 피하세요"],
            ru: ["Избегайте при боли в тазобедренном суставе, усиливающейся при наружной ротации"],
            de: ["Vermeiden Sie dies bei Hüftschmerzen, die sich bei Außenrotation verschlimmern"],
            ar: ["تجنب إذا كنت تعاني من ألم في الورك يزداد سوءاً مع الدوران الخارجي"]
        ),
        breathingPattern: LocalizedString(
            en: "Strong steady breaths, inhale to lengthen, exhale to ground",
            fr: "Respirations fortes et régulières, inspirez pour allonger, expirez pour ancrer",
            es: "Respiraciones fuertes y constantes, inhale para alargarse, exhale para enraizarse",
            ja: "力強く安定した呼吸、吸って伸び、吐いて安定する",
            zh: "有力而平稳的呼吸，吸气延伸，呼气扎根",
            ko: "강하고 안정적인 호흡, 들숨에 늘이고, 날숨에 안정감을",
            ru: "Сильное ровное дыхание, вдох для удлинения, выдох для заземления",
            de: "Starke gleichmäßige Atemzüge, einatmen zum Verlängern, ausatmen zum Erden",
            ar: "أنفاس قوية وثابتة، استنشق للاستطالة، وازفر للثبات"
        ),
        isFree: true
    )

    public static let seatedSideBend = Pose(
        id: "seated-side-bend",
        name: LocalizedString(
            en: "Seated Side Bend",
            fr: "Flexion latérale assise",
            es: "Flexión lateral sentada",
            ja: "座った側屈",
            zh: "坐姿侧弯",
            ko: "앉은 옆으로 굽히기",
            ru: "Боковой наклон сидя",
            de: "Sitzende Seitenbeuge",
            ar: "الانحناء الجانبي جلوساً"
        ),
        description: LocalizedString(
            en: "Sit tall with feet flat on the floor. Raise your right arm overhead. On an exhale, lean to the left, reaching the right arm over and to the left. Keep both sit bones grounded on the chair. The left hand rests on the seat or armrest. Hold, then switch sides.",
            fr: "Assoyez-vous droit, pieds à plat au sol. Levez le bras droit au-dessus de la tête. À l'expiration, penchez-vous vers la gauche en étirant le bras droit vers la gauche. Gardez les deux ischions bien ancrés sur la chaise. La main gauche repose sur le siège ou l'accoudoir. Maintenez, puis changez de côté.",
            es: "Siéntese erguido con los pies planos en el suelo. Levante el brazo derecho por encima de la cabeza. Al exhalar, inclínese hacia la izquierda, extendiendo el brazo derecho hacia arriba y hacia la izquierda. Mantenga ambos isquiones apoyados en la silla. La mano izquierda descansa en el asiento o el reposabrazos. Sostenga, luego cambie de lado.",
            ja: "足を床に平らにつけて背筋を伸ばして座ります。右腕を頭上に上げます。息を吐きながら左に傾き、右腕を上から左に伸ばします。両方の坐骨を椅子にしっかりつけたままにします。左手は座面またはアームレストに置きます。キープし、反対側も行います。",
            zh: "挺直腰背坐好，双脚平放在地板上。将右臂举过头顶。呼气时向左倾斜，右臂越过头顶向左伸展。保持双侧坐骨稳固地落在椅子上。左手放在座面或扶手上。保持，然后换边。",
            ko: "발을 바닥에 평평하게 놓고 허리를 펴고 앉습니다. 오른팔을 머리 위로 올립니다. 날숨에 왼쪽으로 기울이며 오른팔을 위로 넘겨 왼쪽으로 뻗습니다. 양쪽 좌골을 의자에 단단히 붙인 채로 유지합니다. 왼손은 좌석이나 팔걸이에 놓습니다. 유지한 후 반대쪽을 합니다.",
            ru: "Сядьте прямо, стопы ровно на полу. Поднимите правую руку над головой. На выдохе наклонитесь влево, протягивая правую руку вверх и влево. Держите обе седалищные кости на стуле. Левая рука лежит на сиденье или подлокотнике. Задержитесь, затем поменяйте сторону.",
            de: "Setzen Sie sich aufrecht, Füße flach auf dem Boden. Heben Sie den rechten Arm über den Kopf. Beim Ausatmen neigen Sie sich nach links und strecken den rechten Arm nach oben und nach links. Halten Sie beide Sitzknochen auf dem Stuhl geerdet. Die linke Hand ruht auf der Sitzfläche oder Armlehne. Halten Sie, dann wechseln Sie die Seite.",
            ar: "اجلس بشكل مستقيم مع وضع القدمين بشكل مسطح على الأرض. ارفع ذراعك اليمنى فوق رأسك. أثناء الزفير، مِل إلى اليسار مع مدّ الذراع اليمنى للأعلى وإلى اليسار. أبقِ كلتا عظمتي الجلوس مثبتتين على الكرسي. اليد اليسرى تستريح على المقعد أو مسند الذراع. استمر، ثم بدّل الجانب."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .spine,
        imageName: "pose.seated.side.bend",
        voiceCueText: LocalizedString(
            en: "Reach up and over. Breathe into the stretch along your ribcage. Keep both sit bones on the chair.",
            fr: "Étirez-vous vers le haut et par-dessus. Respirez dans l'étirement le long de la cage thoracique. Gardez les deux ischions sur la chaise.",
            es: "Estírese hacia arriba y hacia el lado. Respire hacia el estiramiento a lo largo de la caja torácica. Mantenga ambos isquiones en la silla.",
            ja: "上に伸びて横に倒れましょう。肋骨に沿ったストレッチに呼吸を送ります。両方の坐骨を椅子につけたままにしてください。",
            zh: "向上伸展并侧弯。将呼吸送入沿肋骨的拉伸处。保持双侧坐骨在椅子上。",
            ko: "위로 뻗어 옆으로 넘기세요. 갈비뼈를 따라 스트레칭에 호흡을 보내세요. 양쪽 좌골을 의자에 유지하세요.",
            ru: "Потянитесь вверх и в сторону. Дышите в растяжку вдоль рёбер. Держите обе седалищные кости на стуле.",
            de: "Strecken Sie sich hoch und zur Seite. Atmen Sie in die Dehnung entlang des Brustkorbs. Halten Sie beide Sitzknochen auf dem Stuhl.",
            ar: "امتد للأعلى ثم للجانب. تنفّس في منطقة التمدد على طول القفص الصدري. أبقِ كلتا عظمتي الجلوس على الكرسي."
        ),
        modifications: LocalizedStringArray(
            en: ["Rest the lower hand on the chair seat for support",
                 "Bend the raised elbow if full extension is too intense"],
            fr: ["Appuyez la main du bas sur le siège de la chaise pour du soutien",
                 "Pliez le coude levé si l'extension complète est trop intense"],
            es: ["Apoye la mano inferior en el asiento de la silla para soporte",
                 "Doble el codo levantado si la extensión completa es demasiado intensa"],
            ja: ["サポートのために下の手を椅子の座面に置いてください",
                 "完全な伸展がきつすぎる場合は上げた肘を曲げてください"],
            zh: ["将下方的手放在椅子座面上以获得支撑",
                 "如果完全伸展太强烈，可以弯曲抬起的肘部"],
            ko: ["지지를 위해 아래쪽 손을 의자 좌석에 놓으세요",
                 "완전한 신전이 너무 강하면 올린 팔꿈치를 구부리세요"],
            ru: ["Положите нижнюю руку на сиденье стула для опоры",
                 "Согните поднятый локоть, если полное разгибание слишком интенсивно"],
            de: ["Legen Sie die untere Hand zur Unterstützung auf die Sitzfläche",
                 "Beugen Sie den angehobenen Ellbogen, wenn die volle Streckung zu intensiv ist"],
            ar: ["ضع اليد السفلية على مقعد الكرسي للدعم",
                 "اثنِ المرفق المرفوع إذا كان التمدد الكامل شديداً جداً"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have pain on one side of the ribcage"],
            fr: ["Évitez en cas de douleur d'un côté de la cage thoracique"],
            es: ["Evite si tiene dolor en un lado de la caja torácica"],
            ja: ["肋骨の片側に痛みがある場合は避けてください"],
            zh: ["如果肋骨一侧有疼痛，请避免此动作"],
            ko: ["갈비뼈 한쪽에 통증이 있으면 피하세요"],
            ru: ["Избегайте при боли в одной стороне грудной клетки"],
            de: ["Vermeiden Sie dies bei Schmerzen auf einer Seite des Brustkorbs"],
            ar: ["تجنب إذا كنت تعاني من ألم في أحد جانبي القفص الصدري"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen, exhale to bend deeper",
            fr: "Inspirez pour allonger, expirez pour plier plus profondément",
            es: "Inhale para alargarse, exhale para flexionar más profundo",
            ja: "吸って伸び、吐いてさらに深く曲げる",
            zh: "吸气延伸，呼气加深弯曲",
            ko: "들숨에 늘이고, 날숨에 더 깊이 굽히세요",
            ru: "Вдох для удлинения, выдох для более глубокого наклона",
            de: "Einatmen zum Verlängern, ausatmen um tiefer zu beugen",
            ar: "استنشق للاستطالة، وازفر للانحناء أعمق"
        ),
        isFree: true
    )

    public static let seatedHeartOpener = Pose(
        id: "seated-heart-opener",
        name: LocalizedString(
            en: "Seated Heart Opener",
            fr: "Ouverture du cœur assise",
            es: "Apertura de corazón sentada",
            ja: "座ったハートオープナー",
            zh: "坐姿开胸式",
            ko: "앉은 가슴 열기",
            ru: "Раскрытие сердца сидя",
            de: "Sitzender Herzöffner",
            ar: "فتح الصدر جلوساً"
        ),
        description: LocalizedString(
            en: "Sit at the front of the chair. Reach both hands behind you and hold the chair back or seat edges. On an inhale, gently press your chest forward and up, drawing your shoulder blades together. Lift the sternum without compressing the lower back. Keep the neck long and neutral.",
            fr: "Assoyez-vous au bord avant de la chaise. Tendez les deux mains derrière vous et agrippez le dossier ou les rebords du siège. À l'inspiration, poussez doucement la poitrine vers l'avant et vers le haut en rapprochant les omoplates. Soulevez le sternum sans comprimer le bas du dos. Gardez le cou long et neutre.",
            es: "Siéntese al frente de la silla. Extienda ambas manos detrás de usted y agarre el respaldo o los bordes del asiento. Al inhalar, presione suavemente el pecho hacia adelante y hacia arriba, juntando los omóplatos. Levante el esternón sin comprimir la parte baja de la espalda. Mantenga el cuello largo y neutral.",
            ja: "椅子の前に座ります。両手を後ろに伸ばし、椅子の背もたれまたは座面の端をつかみます。吸う息で、胸をゆっくり前方と上方に押し出し、肩甲骨を寄せます。腰を圧迫せずに胸骨を持ち上げます。首を長くニュートラルに保ちます。",
            zh: "坐在椅子前端。双手向后伸，握住椅背或座面边缘。吸气时，轻轻将胸部向前向上推，夹紧肩胛骨。抬起胸骨，但不要压迫腰部。保持颈部伸展且中立。",
            ko: "의자 앞쪽에 앉습니다. 두 손을 뒤로 뻗어 의자 등받이나 좌석 가장자리를 잡습니다. 들숨에 가슴을 부드럽게 앞으로 위로 밀며 견갑골을 모읍니다. 허리를 압박하지 않으면서 흉골을 들어 올립니다. 목을 길고 중립으로 유지합니다.",
            ru: "Сядьте на переднюю часть стула. Заведите обе руки назад и возьмитесь за спинку или края сиденья. На вдохе мягко подайте грудную клетку вперёд и вверх, сводя лопатки вместе. Поднимите грудину, не сжимая поясницу. Держите шею длинной и нейтральной.",
            de: "Setzen Sie sich an die Vorderkante des Stuhls. Greifen Sie mit beiden Händen nach hinten und halten Sie die Stuhllehne oder Sitzkanten. Beim Einatmen drücken Sie sanft die Brust nach vorne und oben, ziehen Sie die Schulterblätter zusammen. Heben Sie das Brustbein, ohne den unteren Rücken zu komprimieren. Halten Sie den Nacken lang und neutral.",
            ar: "اجلس في مقدمة الكرسي. مدّ كلتا يديك خلفك وأمسك بظهر الكرسي أو حواف المقعد. عند الشهيق، ادفع صدرك برفق للأمام وللأعلى مع تقريب لوحي الكتف من بعضهما. ارفع عظمة القص دون ضغط أسفل الظهر. حافظ على رقبتك طويلة ومحايدة."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .spine,
        imageName: "pose.seated.heart.opener",
        voiceCueText: LocalizedString(
            en: "Press your chest forward and lift your heart. Squeeze the shoulder blades together. Breathe into the openness.",
            fr: "Poussez la poitrine vers l'avant et soulevez le cœur. Serrez les omoplates ensemble. Respirez dans l'ouverture.",
            es: "Empuje el pecho hacia adelante y levante el corazón. Junte los omóplatos. Respire hacia la apertura.",
            ja: "胸を前に押し出し、ハートを持ち上げましょう。肩甲骨を寄せます。開放感に呼吸を送りましょう。",
            zh: "将胸部向前推，抬起心口。夹紧肩胛骨。将呼吸送入这份开放中。",
            ko: "가슴을 앞으로 밀고 심장을 들어 올리세요. 견갑골을 함께 조이세요. 열린 느낌에 호흡을 보내세요.",
            ru: "Подайте грудь вперёд и поднимите сердце. Сведите лопатки. Дышите в это раскрытие.",
            de: "Drücken Sie die Brust nach vorne und heben Sie Ihr Herz. Drücken Sie die Schulterblätter zusammen. Atmen Sie in die Offenheit.",
            ar: "ادفع صدرك للأمام وارفع قلبك. اضغط لوحي الكتف معاً. تنفّس في هذا الانفتاح."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the movement small — stop if you feel lower back compression",
                 "Interlace fingers behind the back instead of gripping the chair"],
            fr: ["Gardez le mouvement petit — arrêtez si vous sentez une compression au bas du dos",
                 "Entrelacez les doigts derrière le dos au lieu d'agripper la chaise"],
            es: ["Mantenga el movimiento pequeño — deténgase si siente compresión en la parte baja de la espalda",
                 "Entrelace los dedos detrás de la espalda en lugar de agarrar la silla"],
            ja: ["動きを小さくしてください — 腰に圧迫を感じたら止めてください",
                 "椅子をつかむ代わりに、背中の後ろで指を組んでください"],
            zh: ["保持动作幅度小——如果感到腰部受压，请停止",
                 "在背后十指交叉，而非抓住椅子"],
            ko: ["동작을 작게 유지하세요 — 허리 압박을 느끼면 멈추세요",
                 "의자를 잡는 대신 등 뒤에서 손가락을 깍지 끼세요"],
            ru: ["Делайте движение небольшим — остановитесь при ощущении сжатия в пояснице",
                 "Сцепите пальцы за спиной вместо того, чтобы держаться за стул"],
            de: ["Halten Sie die Bewegung klein — hören Sie auf, wenn Sie eine Kompression im unteren Rücken spüren",
                 "Verschränken Sie die Finger hinter dem Rücken, anstatt den Stuhl zu greifen"],
            ar: ["أبقِ الحركة صغيرة — توقف إذا شعرت بضغط في أسفل الظهر",
                 "شبّك أصابعك خلف ظهرك بدلاً من الإمساك بالكرسي"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute lower back pain or spinal stenosis"],
            fr: ["Évitez en cas de douleur aiguë au bas du dos ou de sténose spinale"],
            es: ["Evite con dolor agudo en la parte baja de la espalda o estenosis espinal"],
            ja: ["急性の腰痛や脊柱管狭窄症がある場合は避けてください"],
            zh: ["急性腰痛或椎管狭窄者请避免"],
            ko: ["급성 허리 통증이나 척추관 협착증이 있으면 피하세요"],
            ru: ["Избегайте при острой боли в пояснице или стенозе позвоночного канала"],
            de: ["Vermeiden Sie dies bei akuten Schmerzen im unteren Rücken oder Spinalkanalstenose"],
            ar: ["تجنب مع ألم حاد في أسفل الظهر أو تضيّق القناة الشوكية"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to open, exhale to soften the effort",
            fr: "Inspirez pour ouvrir, expirez pour adoucir l'effort",
            es: "Inhale para abrir, exhale para suavizar el esfuerzo",
            ja: "吸って開き、吐いて力をゆるめる",
            zh: "吸气打开，呼气放松用力",
            ko: "들숨에 열고, 날숨에 힘을 부드럽게",
            ru: "Вдох для раскрытия, выдох для смягчения усилия",
            de: "Einatmen zum Öffnen, ausatmen um die Anstrengung zu mildern",
            ar: "استنشق للانفتاح، وازفر لتخفيف الجهد"
        ),
        isFree: true
    )

    public static let seatedAnklesToKnees = Pose(
        id: "seated-ankles-to-knees",
        name: LocalizedString(
            en: "Seated Fire Log",
            fr: "Bûche de feu assise",
            es: "Tronco de fuego sentado",
            ja: "座った薪のポーズ",
            zh: "坐姿火木式",
            ko: "앉은 장작 자세",
            ru: "Поза бревна сидя",
            de: "Sitzender Holzscheit",
            ar: "وضعية جذع النار جلوساً"
        ),
        description: LocalizedString(
            en: "Sit tall. Place your left ankle on top of your right knee, and stack your left knee directly above your right ankle, forming parallel shins. Flex both feet. If this is too intense, simply cross your ankles beneath the chair. For more depth, hinge forward from the hips.",
            fr: "Assoyez-vous bien droit. Placez la cheville gauche sur le genou droit, et alignez le genou gauche directement au-dessus de la cheville droite, formant des tibias parallèles. Fléchissez les deux pieds. Si c'est trop intense, croisez simplement les chevilles sous la chaise. Pour plus de profondeur, penchez-vous vers l'avant à partir des hanches.",
            es: "Siéntese erguido. Coloque el tobillo izquierdo sobre la rodilla derecha y apile la rodilla izquierda directamente encima del tobillo derecho, formando espinillas paralelas. Flexione ambos pies. Si es demasiado intenso, simplemente cruce los tobillos debajo de la silla. Para más profundidad, inclínese hacia adelante desde las caderas.",
            ja: "背筋を伸ばして座ります。左足首を右膝の上に置き、左膝を右足首の真上に重ねて、平行なすねを作ります。両足を曲げます。きつすぎる場合は、椅子の下で足首を交差させてください。より深くするには、腰から前に傾けます。",
            zh: "挺直腰背坐好。将左脚踝放在右膝上方，左膝直接叠在右脚踝上方，形成平行的小腿。双脚勾起。如果太强烈，只需在椅子下方交叉脚踝。要加深拉伸，从臀部向前倾。",
            ko: "허리를 펴고 앉습니다. 왼쪽 발목을 오른쪽 무릎 위에 올리고, 왼쪽 무릎을 오른쪽 발목 바로 위에 쌓아 평행한 정강이를 만듭니다. 양발을 굽힙니다. 너무 강하면 의자 아래에서 발목을 교차하세요. 더 깊게 하려면 골반에서 앞으로 기울입니다.",
            ru: "Сядьте прямо. Положите левую лодыжку на правое колено и расположите левое колено прямо над правой лодыжкой, образуя параллельные голени. Согните обе стопы. Если это слишком интенсивно, просто скрестите лодыжки под стулом. Для большей глубины наклонитесь вперёд от бёдер.",
            de: "Setzen Sie sich aufrecht. Legen Sie den linken Knöchel auf das rechte Knie und stapeln Sie das linke Knie direkt über dem rechten Knöchel, sodass parallele Schienbeine entstehen. Beugen Sie beide Füße. Wenn es zu intensiv ist, kreuzen Sie einfach die Knöchel unter dem Stuhl. Für mehr Tiefe neigen Sie sich von den Hüften nach vorne.",
            ar: "اجلس بشكل مستقيم. ضع كاحلك الأيسر فوق ركبتك اليمنى، ورصّ ركبتك اليسرى مباشرة فوق كاحلك الأيمن لتشكيل ساقين متوازيتين. اثنِ كلا القدمين. إذا كان ذلك شديداً جداً، ببساطة اعقد كاحليك تحت الكرسي. لمزيد من العمق، انحنِ للأمام من الوركين."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .hips,
        imageName: "pose.seated.fire.log",
        voiceCueText: LocalizedString(
            en: "Stack your shins. Flex your feet. Breathe into the outer hips and sit tall.",
            fr: "Empilez vos tibias. Fléchissez les pieds. Respirez dans les hanches extérieures et tenez-vous droit.",
            es: "Apile las espinillas. Flexione los pies. Respire hacia las caderas externas y siéntese erguido.",
            ja: "すねを重ねましょう。足を曲げます。外側の股関節に呼吸を送り、背筋を伸ばして座りましょう。",
            zh: "将小腿叠放。勾起双脚。将呼吸送入外侧髋部，挺直坐好。",
            ko: "정강이를 쌓으세요. 발을 굽히세요. 바깥쪽 골반으로 호흡을 보내고 허리를 펴세요.",
            ru: "Сложите голени. Согните стопы. Дышите в наружные бёдра и сидите прямо.",
            de: "Stapeln Sie Ihre Schienbeine. Beugen Sie die Füße. Atmen Sie in die äußeren Hüften und sitzen Sie aufrecht.",
            ar: "رصّ ساقيك. اثنِ قدميك. تنفّس في منطقة الوركين الخارجيين واجلس بشكل مستقيم."
        ),
        modifications: LocalizedStringArray(
            en: ["Cross ankles under the chair if full stacking is too intense",
                 "Place a folded towel under the top knee for support"],
            fr: ["Croisez les chevilles sous la chaise si l'empilement complet est trop intense",
                 "Placez une serviette pliée sous le genou du dessus pour du soutien"],
            es: ["Cruce los tobillos debajo de la silla si apilar completamente es demasiado intenso",
                 "Coloque una toalla doblada debajo de la rodilla superior para soporte"],
            ja: ["完全に重ねるのがきつすぎる場合は椅子の下で足首を交差させてください",
                 "上の膝の下に折りたたんだタオルを置いてサポートにしてください"],
            zh: ["如果完全叠放太强烈，可在椅子下交叉脚踝",
                 "在上方膝盖下放一条折叠的毛巾以获得支撑"],
            ko: ["완전히 쌓는 것이 너무 강하면 의자 아래에서 발목을 교차하세요",
                 "지지를 위해 위쪽 무릎 아래에 접은 수건을 놓으세요"],
            ru: ["Скрестите лодыжки под стулом, если полное складывание слишком интенсивно",
                 "Положите сложенное полотенце под верхнее колено для поддержки"],
            de: ["Kreuzen Sie die Knöchel unter dem Stuhl, wenn das vollständige Stapeln zu intensiv ist",
                 "Legen Sie ein gefaltetes Handtuch unter das obere Knie zur Unterstützung"],
            ar: ["اعقد الكاحلين تحت الكرسي إذا كان الرصّ الكامل شديداً جداً",
                 "ضع منشفة مطوية تحت الركبة العلوية للدعم"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with knee injuries or recent knee surgery"],
            fr: ["Évitez en cas de blessure au genou ou de chirurgie récente du genou"],
            es: ["Evite con lesiones de rodilla o cirugía de rodilla reciente"],
            ja: ["膝の怪我や最近の膝の手術がある場合は避けてください"],
            zh: ["有膝盖损伤或近期膝盖手术者请避免"],
            ko: ["무릎 부상이나 최근 무릎 수술을 받은 경우 피하세요"],
            ru: ["Избегайте при травмах колена или недавней операции на колене"],
            de: ["Vermeiden Sie dies bei Knieverletzungen oder kürzlicher Knieoperation"],
            ar: ["تجنب في حالة إصابات الركبة أو جراحة ركبة حديثة"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow breaths, exhale to release into the hip stretch",
            fr: "Respirations lentes, expirez pour relâcher dans l'étirement de la hanche",
            es: "Respiraciones lentas, exhale para liberar hacia el estiramiento de cadera",
            ja: "ゆっくり呼吸し、吐いて股関節のストレッチに身を委ねる",
            zh: "缓慢呼吸，呼气时放松进入髋部拉伸",
            ko: "느린 호흡, 날숨으로 골반 스트레칭에 몸을 맡기세요",
            ru: "Медленное дыхание, выдох для расслабления в растяжке бедра",
            de: "Langsame Atemzüge, ausatmen um in die Hüftdehnung loszulassen",
            ar: "أنفاس بطيئة، ازفر للاسترخاء في تمدد الورك"
        ),
        isFree: true
    )

    public static let seatedExtendedSideBend = Pose(
        id: "seated-extended-side-angle",
        name: LocalizedString(
            en: "Seated Extended Side Angle",
            fr: "Angle latéral étendu assis",
            es: "Ángulo lateral extendido sentado",
            ja: "座った側角のポーズ",
            zh: "坐姿侧角伸展式",
            ko: "앉은 확장 측면 각도",
            ru: "Поза вытянутого бокового угла сидя",
            de: "Sitzender gestreckter Seitenwinkel",
            ar: "الزاوية الجانبية الممتدة جلوساً"
        ),
        description: LocalizedString(
            en: "Open your legs wide while seated. Turn your right foot out 90 degrees. Lean your torso to the right, placing your right forearm on your right thigh. Extend your left arm overhead alongside your ear. Feel the stretch through the left side body.",
            fr: "Ouvrez les jambes largement en position assise. Tournez le pied droit à 90 degrés vers l'extérieur. Penchez le torse vers la droite, en plaçant l'avant-bras droit sur la cuisse droite. Étendez le bras gauche au-dessus de la tête le long de l'oreille. Sentez l'étirement le long du côté gauche du corps.",
            es: "Abra las piernas ampliamente mientras está sentado. Gire el pie derecho 90 grados hacia afuera. Incline el torso hacia la derecha, colocando el antebrazo derecho sobre el muslo derecho. Extienda el brazo izquierdo por encima de la cabeza junto a la oreja. Sienta el estiramiento a lo largo del lado izquierdo del cuerpo.",
            ja: "座ったまま脚を大きく開きます。右足を90度外に向けます。上体を右に傾け、右前腕を右太ももに置きます。左腕を耳の横で頭上に伸ばします。左側の体全体のストレッチを感じてください。",
            zh: "坐姿中将双腿大幅打开。将右脚向外转90度。躯干向右倾斜，将右前臂放在右大腿上。左臂沿耳朵旁举过头顶。感受左侧身体的拉伸。",
            ko: "앉은 상태에서 다리를 넓게 벌립니다. 오른발을 90도 바깥으로 돌립니다. 상체를 오른쪽으로 기울여 오른쪽 전완을 오른쪽 허벅지에 놓습니다. 왼팔을 귀 옆으로 머리 위로 뻗습니다. 왼쪽 옆구리의 스트레칭을 느끼세요.",
            ru: "Широко раздвиньте ноги сидя. Разверните правую стопу наружу на 90 градусов. Наклоните корпус вправо, поместив правое предплечье на правое бедро. Вытяните левую руку над головой вдоль уха. Почувствуйте растяжку по левой стороне тела.",
            de: "Öffnen Sie die Beine weit im Sitzen. Drehen Sie den rechten Fuß 90 Grad nach außen. Neigen Sie den Oberkörper nach rechts und legen Sie den rechten Unterarm auf den rechten Oberschenkel. Strecken Sie den linken Arm neben dem Ohr über den Kopf. Spüren Sie die Dehnung durch die linke Körperseite.",
            ar: "افتح ساقيك على نطاق واسع أثناء الجلوس. أدر قدمك اليمنى 90 درجة للخارج. مِل بجذعك نحو اليمين واضعاً ساعدك الأيمن على فخذك الأيمن. مدّ ذراعك اليسرى فوق رأسك بمحاذاة أذنك. اشعر بالتمدد عبر الجانب الأيسر من الجسم."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .fullBody,
        imageName: "pose.seated.extended.side",
        voiceCueText: LocalizedString(
            en: "Lean to the side and reach long through the top arm. Open your chest toward the ceiling. Breathe deeply.",
            fr: "Penchez-vous sur le côté et allongez-vous à travers le bras du dessus. Ouvrez la poitrine vers le plafond. Respirez profondément.",
            es: "Inclínese hacia el lado y extiéndase a lo largo del brazo superior. Abra el pecho hacia el techo. Respire profundamente.",
            ja: "横に傾いて上の腕を長く伸ばしましょう。胸を天井に向けて開きます。深く呼吸してください。",
            zh: "向侧面倾斜，通过上方手臂长长地伸展。胸部朝天花板打开。深呼吸。",
            ko: "옆으로 기울여 위쪽 팔을 길게 뻗으세요. 가슴을 천장 쪽으로 여세요. 깊이 호흡하세요.",
            ru: "Наклонитесь в сторону и тянитесь верхней рукой. Раскройте грудь к потолку. Дышите глубоко.",
            de: "Neigen Sie sich zur Seite und strecken Sie sich lang durch den oberen Arm. Öffnen Sie die Brust zur Decke. Atmen Sie tief.",
            ar: "مِل إلى الجانب وامتد بطول الذراع العلوية. افتح صدرك نحو السقف. تنفّس بعمق."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the top arm on the hip if reaching overhead is too much",
                 "Don't lean as far — stay upright with a gentle tilt"],
            fr: ["Gardez le bras du dessus sur la hanche si le lever au-dessus est trop",
                 "Ne penchez pas autant — restez droit avec une légère inclinaison"],
            es: ["Mantenga el brazo superior en la cadera si estirarse hacia arriba es demasiado",
                 "No se incline tanto — manténgase erguido con una ligera inclinación"],
            ja: ["頭上に伸ばすのがきつすぎる場合は上の腕を腰に置いてください",
                 "あまり傾けないでください — 軽い傾きで上体を起こしたままにしてください"],
            zh: ["如果举过头顶太吃力，将上方手臂放在髋部",
                 "不要倾斜太多——保持直立，轻微倾斜即可"],
            ko: ["머리 위로 뻗는 것이 너무 힘들면 위쪽 팔을 골반에 놓으세요",
                 "너무 멀리 기울이지 마세요 — 가벼운 기울기로 곧게 유지하세요"],
            ru: ["Держите верхнюю руку на бедре, если тянуться вверх слишком сложно",
                 "Не наклоняйтесь так далеко — оставайтесь в вертикальном положении с лёгким наклоном"],
            de: ["Halten Sie den oberen Arm an der Hüfte, wenn das Strecken über den Kopf zu viel ist",
                 "Lehnen Sie sich nicht so weit — bleiben Sie aufrecht mit einer sanften Neigung"],
            ar: ["أبقِ الذراع العلوية على الورك إذا كان المد فوق الرأس مبالغاً فيه",
                 "لا تمِل بعيداً — ابقَ مستقيماً مع ميلان خفيف"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have groin or inner thigh injury"],
            fr: ["Évitez en cas de blessure à l'aine ou à l'intérieur de la cuisse"],
            es: ["Evite si tiene lesión en la ingle o en la parte interna del muslo"],
            ja: ["鼠径部や内ももの怪我がある場合は避けてください"],
            zh: ["如有腹股沟或大腿内侧损伤，请避免此动作"],
            ko: ["사타구니나 안쪽 허벅지 부상이 있으면 피하세요"],
            ru: ["Избегайте при травме паха или внутренней поверхности бедра"],
            de: ["Vermeiden Sie dies bei Leisten- oder Innenschenkelverletzungen"],
            ar: ["تجنب إذا كنت تعاني من إصابة في الفخذ الداخلي أو منطقة الأربية"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the side body, exhale to deepen",
            fr: "Inspirez pour allonger le côté du corps, expirez pour approfondir",
            es: "Inhale para alargar el costado, exhale para profundizar",
            ja: "吸って体側を伸ばし、吐いて深める",
            zh: "吸气延伸侧身，呼气加深",
            ko: "들숨에 옆구리를 늘이고, 날숨에 깊게",
            ru: "Вдох для удлинения боковой части тела, выдох для углубления",
            de: "Einatmen um die Körperseite zu verlängern, ausatmen um zu vertiefen",
            ar: "استنشق لإطالة جانب الجسم، وازفر للتعمق"
        ),
        isFree: true
    )

    // MARK: - Advanced Poses (Premium)

    public static let seatedSunSalutation = Pose(
        id: "seated-sun-salutation",
        name: LocalizedString(
            en: "Seated Sun Salutation",
            fr: "Salutation au soleil assise",
            es: "Saludo al sol sentado",
            ja: "座った太陽礼拝",
            zh: "坐姿拜日式",
            ko: "앉은 태양 경배",
            ru: "Приветствие солнцу сидя",
            de: "Sitzender Sonnengruß",
            ar: "تحية الشمس جلوساً"
        ),
        description: LocalizedString(
            en: "Begin in Seated Mountain. Inhale, sweep arms overhead with palms together. Exhale, forward fold over your legs. Inhale, rise halfway with a flat back, hands on shins. Exhale, fold again. Inhale, sweep arms out and up to return to start. This is one cycle.",
            fr: "Commencez en Montagne assise. Inspirez, balayez les bras au-dessus de la tête, paumes ensemble. Expirez, penchez-vous vers l'avant par-dessus les jambes. Inspirez, relevez-vous à mi-chemin avec le dos plat, mains sur les tibias. Expirez, repliez-vous. Inspirez, balayez les bras vers l'extérieur et vers le haut pour revenir au début. Ceci est un cycle.",
            es: "Comience en Montaña sentada. Inhale, lleve los brazos por encima de la cabeza con las palmas juntas. Exhale, pliegue hacia adelante sobre las piernas. Inhale, elévese a la mitad con la espalda plana, manos en las espinillas. Exhale, pliéguese de nuevo. Inhale, lleve los brazos hacia afuera y arriba para volver al inicio. Este es un ciclo.",
            ja: "座った山のポーズから始めます。息を吸い、手のひらを合わせて腕を頭上に振り上げます。吐きながら脚の上に前屈します。吸いながら背中を平らにして途中まで起き上がり、手をすねに置きます。吐いてもう一度折りたたみます。吸って腕を外側から上に振り上げ、最初に戻ります。これが1サイクルです。",
            zh: "从坐姿山式开始。吸气，双臂合掌举过头顶。呼气，向前折叠至双腿上方。吸气，背部平坦地起身一半，双手放在小腿上。呼气，再次折叠。吸气，双臂向外向上回到起始位置。这是一个循环。",
            ko: "앉은 산 자세에서 시작합니다. 들숨에 손바닥을 합장하고 팔을 머리 위로 올립니다. 날숨에 다리 위로 전굴합니다. 들숨에 등을 평평하게 하고 반만 일어나 손을 정강이에 놓습니다. 날숨에 다시 접습니다. 들숨에 팔을 바깥으로 위로 휘둘러 시작 자세로 돌아갑니다. 이것이 한 사이클입니다.",
            ru: "Начните в позе горы сидя. Вдох — поднимите руки над головой, ладони вместе. Выдох — наклон вперёд над ногами. Вдох — поднимитесь наполовину с прямой спиной, руки на голенях. Выдох — снова наклон. Вдох — разведите руки в стороны и вверх, вернувшись в начало. Это один цикл.",
            de: "Beginnen Sie im Sitzenden Berg. Einatmen, schwingen Sie die Arme mit zusammengelegten Handflächen über den Kopf. Ausatmen, Vorbeuge über die Beine. Einatmen, heben Sie sich mit flachem Rücken halb an, Hände auf den Schienbeinen. Ausatmen, wieder falten. Einatmen, schwingen Sie die Arme nach außen und oben zurück zum Start. Das ist ein Zyklus.",
            ar: "ابدأ في وضعية الجبل جلوساً. استنشق، وارفع الذراعين فوق الرأس مع ضم الكفين. ازفر، وانحنِ للأمام فوق ساقيك. استنشق، وارتفع نصف المسافة بظهر مسطح ويداك على ساقيك. ازفر، وانحنِ مجدداً. استنشق، وارفع الذراعين للخارج ثم للأعلى للعودة إلى البداية. هذه دورة واحدة."
        ),
        durationSeconds: 60,
        difficulty: .advanced,
        category: .fullBody,
        imageName: "pose.seated.sun.salutation",
        voiceCueText: LocalizedString(
            en: "Flow through each movement with your breath. One breath, one movement. Feel the warmth build.",
            fr: "Enchaînez chaque mouvement avec votre souffle. Un souffle, un mouvement. Sentez la chaleur monter.",
            es: "Fluya a través de cada movimiento con su respiración. Una respiración, un movimiento. Sienta cómo se acumula el calor.",
            ja: "呼吸に合わせて各動きを流しましょう。一呼吸、一動作。温かさが高まるのを感じてください。",
            zh: "随着呼吸流畅地做每个动作。一次呼吸，一个动作。感受温暖的积聚。",
            ko: "호흡에 맞춰 각 동작을 흘려보내세요. 한 호흡, 한 동작. 온기가 쌓이는 것을 느끼세요.",
            ru: "Плавно переходите от движения к движению вместе с дыханием. Один вдох — одно движение. Почувствуйте, как нарастает тепло.",
            de: "Fließen Sie mit Ihrem Atem durch jede Bewegung. Ein Atemzug, eine Bewegung. Spüren Sie, wie die Wärme aufbaut.",
            ar: "تدفّق خلال كل حركة مع نفسك. نَفَس واحد، حركة واحدة. اشعر بتراكم الدفء."
        ),
        modifications: LocalizedStringArray(
            en: ["Slow down the pace — take two breaths per movement if needed",
                 "Skip the halfway lift if back extension is uncomfortable"],
            fr: ["Ralentissez le rythme — prenez deux respirations par mouvement au besoin",
                 "Sautez le demi-relevé si l'extension du dos est inconfortable"],
            es: ["Reduzca el ritmo — tome dos respiraciones por movimiento si es necesario",
                 "Omita el medio levantamiento si la extensión de la espalda es incómoda"],
            ja: ["ペースを落としてください — 必要なら1つの動きに2呼吸かけてください",
                 "背中の伸展が不快な場合は中間のリフトを省いてください"],
            zh: ["放慢节奏——需要时每个动作做两次呼吸",
                 "如果背部伸展不舒服，可跳过半程抬起"],
            ko: ["속도를 늦추세요 — 필요하면 동작당 두 번 호흡하세요",
                 "등 신전이 불편하면 중간 들어올리기를 건너뛰세요"],
            ru: ["Замедлите темп — делайте два дыхания на движение при необходимости",
                 "Пропустите подъём наполовину, если разгибание спины некомфортно"],
            de: ["Verlangsamen Sie das Tempo — nehmen Sie bei Bedarf zwei Atemzüge pro Bewegung",
                 "Überspringen Sie das halbe Anheben, wenn die Rückenstreckung unangenehm ist"],
            ar: ["أبطئ الإيقاع — خذ نَفَسين لكل حركة إذا لزم الأمر",
                 "تخطَّ الرفع النصفي إذا كان تمديد الظهر غير مريح"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Move slowly if you have vertigo or blood pressure concerns"],
            fr: ["Bougez lentement en cas de vertige ou de problèmes de pression artérielle"],
            es: ["Muévase lentamente si tiene vértigo o problemas de presión arterial"],
            ja: ["めまいや血圧の問題がある場合はゆっくり動いてください"],
            zh: ["如有眩晕或血压问题，请缓慢移动"],
            ko: ["어지럼증이나 혈압 문제가 있으면 천천히 움직이세요"],
            ru: ["Двигайтесь медленно при головокружении или проблемах с давлением"],
            de: ["Bewegen Sie sich langsam bei Schwindel oder Blutdruckproblemen"],
            ar: ["تحرّك ببطء إذا كنت تعاني من الدوار أو مشاكل في ضغط الدم"]
        ),
        breathingPattern: LocalizedString(
            en: "One inhale or exhale per movement — coordinated breath-to-motion",
            fr: "Une inspiration ou expiration par mouvement — coordination souffle-mouvement",
            es: "Una inhalación o exhalación por movimiento — respiración coordinada con el movimiento",
            ja: "1つの動きに1回の吸気または呼気 — 呼吸と動きの連動",
            zh: "每个动作一次吸气或呼气——呼吸与动作协调配合",
            ko: "동작당 한 번 들숨 또는 날숨 — 호흡과 동작의 조화",
            ru: "Один вдох или выдох на движение — координация дыхания и движения",
            de: "Ein Einatmen oder Ausatmen pro Bewegung — koordinierte Atem-Bewegung",
            ar: "شهيق أو زفير واحد لكل حركة — تنسيق بين النَّفَس والحركة"
        ),
        isFree: true
    )

    public static let seatedTreePose = Pose(
        id: "seated-tree",
        name: LocalizedString(
            en: "Seated Tree Pose",
            fr: "Arbre assis",
            es: "Árbol sentado",
            ja: "座った木のポーズ",
            zh: "坐姿树式",
            ko: "앉은 나무 자세",
            ru: "Поза дерева сидя",
            de: "Sitzender Baum",
            ar: "وضعية الشجرة جلوساً"
        ),
        description: LocalizedString(
            en: "Sit tall at the edge of the chair. Plant your left foot firmly on the floor. Place the sole of your right foot against your left inner calf or thigh (never the knee). Bring your palms together at your heart or raise arms overhead. Focus on a fixed point for balance.",
            fr: "Assoyez-vous droit au bord de la chaise. Plantez le pied gauche fermement au sol. Placez la plante du pied droit contre l'intérieur du mollet ou de la cuisse gauche (jamais le genou). Joignez les paumes au niveau du cœur ou levez les bras au-dessus de la tête. Fixez un point pour l'équilibre.",
            es: "Siéntese erguido en el borde de la silla. Plante el pie izquierdo firmemente en el suelo. Coloque la planta del pie derecho contra la pantorrilla o el muslo interno izquierdo (nunca la rodilla). Junte las palmas a la altura del corazón o levante los brazos por encima de la cabeza. Enfóquese en un punto fijo para el equilibrio.",
            ja: "椅子の端に背筋を伸ばして座ります。左足をしっかり床に踏みつけます。右足の裏を左のふくらはぎまたは内ももに当てます（膝には絶対に当てないでください）。手のひらを胸の前で合わせるか、腕を頭上に上げます。バランスのために一点を見つめます。",
            zh: "挺直腰背坐在椅子边缘。左脚稳稳地踩在地板上。将右脚掌贴在左小腿内侧或大腿内侧（绝不要放在膝盖上）。双手合十于胸前或举过头顶。注视一个固定点以保持平衡。",
            ko: "의자 가장자리에 허리를 펴고 앉습니다. 왼발을 바닥에 단단히 딛습니다. 오른발 바닥을 왼쪽 안쪽 종아리나 허벅지에 대세요 (절대 무릎에 대지 마세요). 손바닥을 가슴 앞에서 합장하거나 팔을 머리 위로 올립니다. 균형을 위해 한 점을 응시하세요.",
            ru: "Сядьте прямо на краю стула. Твёрдо поставьте левую стопу на пол. Поместите подошву правой стопы на левую внутреннюю голень или бедро (никогда на колено). Сложите ладони у сердца или поднимите руки над головой. Сфокусируйтесь на неподвижной точке для равновесия.",
            de: "Setzen Sie sich aufrecht an die Stuhlkante. Stellen Sie den linken Fuß fest auf den Boden. Legen Sie die Sohle des rechten Fußes gegen die linke innere Wade oder den Oberschenkel (niemals das Knie). Bringen Sie die Handflächen am Herzen zusammen oder heben Sie die Arme über den Kopf. Fixieren Sie einen festen Punkt für das Gleichgewicht.",
            ar: "اجلس بشكل مستقيم على حافة الكرسي. ثبّت قدمك اليسرى بقوة على الأرض. ضع باطن قدمك اليمنى على ساقك اليسرى الداخلية أو فخذك الداخلي (وليس الركبة أبداً). ضم كفيك معاً عند القلب أو ارفع ذراعيك فوق رأسك. ركّز على نقطة ثابتة للتوازن."
        ),
        durationSeconds: 35,
        difficulty: .advanced,
        category: .balance,
        imageName: "pose.seated.tree",
        voiceCueText: LocalizedString(
            en: "Find your Tree Pose. Root through your grounded foot. Fix your gaze. Breathe steadily.",
            fr: "Trouvez votre posture de l'Arbre. Ancrez-vous à travers le pied au sol. Fixez votre regard. Respirez de façon régulière.",
            es: "Encuentre su postura del Árbol. Enraícese a través del pie apoyado. Fije la mirada. Respire de forma constante.",
            ja: "木のポーズを見つけましょう。地面についた足でしっかり根を張ります。視線を固定してください。安定して呼吸しましょう。",
            zh: "找到你的树式。通过接地的脚扎根。固定目光。稳定地呼吸。",
            ko: "나무 자세를 찾으세요. 바닥에 딛은 발로 뿌리를 내리세요. 시선을 고정하세요. 안정적으로 호흡하세요.",
            ru: "Найдите свою позу дерева. Укоренитесь через опорную стопу. Зафиксируйте взгляд. Дышите ровно.",
            de: "Finden Sie Ihre Baumpose. Verwurzeln Sie sich durch den geerdeten Fuß. Fixieren Sie Ihren Blick. Atmen Sie gleichmäßig.",
            ar: "جِد وضعية الشجرة. تجذّر عبر القدم المثبتة على الأرض. ثبّت نظرك. تنفّس بثبات."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the raised foot on the floor with heel against the opposite ankle",
                 "Hold the chair seat with one hand for stability"],
            fr: ["Gardez le pied levé au sol, talon contre la cheville opposée",
                 "Tenez le siège de la chaise d'une main pour la stabilité"],
            es: ["Mantenga el pie levantado en el suelo con el talón contra el tobillo opuesto",
                 "Sostenga el asiento de la silla con una mano para estabilidad"],
            ja: ["上げた足をかかとを反対の足首に当てて床に置いたままにしてください",
                 "安定のために片手で椅子の座面を持ってください"],
            zh: ["将抬起的脚保持在地板上，脚跟抵住对侧脚踝",
                 "用一只手扶住椅子座面以保持稳定"],
            ko: ["올린 발을 바닥에 놓고 발꿈치를 반대쪽 발목에 대세요",
                 "안정을 위해 한 손으로 의자 좌석을 잡으세요"],
            ru: ["Оставьте поднятую стопу на полу, пяткой к противоположной лодыжке",
                 "Держитесь одной рукой за сиденье стула для устойчивости"],
            de: ["Halten Sie den angehobenen Fuß mit der Ferse gegen den gegenüberliegenden Knöchel auf dem Boden",
                 "Halten Sie die Sitzfläche mit einer Hand für Stabilität"],
            ar: ["أبقِ القدم المرفوعة على الأرض مع وضع الكعب مقابل الكاحل المقابل",
                 "أمسك مقعد الكرسي بيد واحدة للثبات"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have significant balance disorders — keep one hand on the chair"],
            fr: ["Évitez en cas de troubles significatifs de l'équilibre — gardez une main sur la chaise"],
            es: ["Evite si tiene trastornos de equilibrio significativos — mantenga una mano en la silla"],
            ja: ["重度のバランス障害がある場合は避けてください — 片手を椅子に置いてください"],
            zh: ["如有严重平衡障碍请避免——将一只手放在椅子上"],
            ko: ["심각한 균형 장애가 있으면 피하세요 — 한 손을 의자에 두세요"],
            ru: ["Избегайте при значительных нарушениях равновесия — держите одну руку на стуле"],
            de: ["Vermeiden Sie dies bei erheblichen Gleichgewichtsstörungen — halten Sie eine Hand am Stuhl"],
            ar: ["تجنب إذا كنت تعاني من اضطرابات توازن كبيرة — أبقِ يداً واحدة على الكرسي"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady, calm breaths to maintain balance",
            fr: "Respirations régulières et calmes pour maintenir l'équilibre",
            es: "Respiraciones constantes y calmadas para mantener el equilibrio",
            ja: "バランスを保つための安定した穏やかな呼吸",
            zh: "平稳、平静的呼吸以保持平衡",
            ko: "균형을 유지하기 위한 안정적이고 차분한 호흡",
            ru: "Ровное спокойное дыхание для поддержания равновесия",
            de: "Gleichmäßige, ruhige Atemzüge zur Aufrechterhaltung des Gleichgewichts",
            ar: "أنفاس ثابتة وهادئة للحفاظ على التوازن"
        ),
        isFree: true
    )

    // MARK: - Additional Poses

    public static let seatedAnkleCircles = Pose(
        id: "seated-ankle-circles",
        name: LocalizedString(
            en: "Seated Ankle Circles",
            fr: "Cercles des chevilles assis",
            es: "Círculos de tobillo sentado",
            ja: "座った足首回し",
            zh: "坐姿踝关节画圈",
            ko: "앉은 발목 돌리기",
            ru: "Круги голеностопом сидя",
            de: "Sitzende Knöchelkreise",
            ar: "دوائر الكاحل جلوساً"
        ),
        description: LocalizedString(
            en: "Extend one leg forward, lifting the foot off the floor. Rotate the ankle slowly in circles, 5 times clockwise and 5 times counterclockwise. Switch legs.",
            fr: "Étendez une jambe devant vous en soulevant le pied du sol. Faites tourner la cheville lentement en cercles, 5 fois dans le sens horaire et 5 fois dans le sens antihoraire. Changez de jambe.",
            es: "Extienda una pierna hacia adelante, levantando el pie del suelo. Rote el tobillo lentamente en círculos, 5 veces en el sentido de las agujas del reloj y 5 veces en sentido contrario. Cambie de pierna.",
            ja: "片脚を前に伸ばし、足を床から持ち上げます。足首をゆっくり円を描くように回します。時計回りに5回、反時計回りに5回。脚を入れ替えます。",
            zh: "将一条腿向前伸展，脚离开地面。缓慢地转动脚踝画圈，顺时针5次，逆时针5次。换腿。",
            ko: "한쪽 다리를 앞으로 뻗어 발을 바닥에서 들어 올립니다. 발목을 천천히 원을 그리며 돌립니다. 시계 방향 5회, 반시계 방향 5회. 다리를 바꿉니다.",
            ru: "Вытяните одну ногу вперёд, подняв стопу от пола. Медленно вращайте голеностоп по кругу: 5 раз по часовой стрелке и 5 раз против. Поменяйте ноги.",
            de: "Strecken Sie ein Bein nach vorne und heben Sie den Fuß vom Boden ab. Drehen Sie den Knöchel langsam im Kreis, 5-mal im Uhrzeigersinn und 5-mal gegen den Uhrzeigersinn. Wechseln Sie das Bein.",
            ar: "مدّ ساقاً واحدة للأمام مع رفع القدم عن الأرض. أدر الكاحل ببطء في دوائر، 5 مرات باتجاه عقارب الساعة و5 مرات بعكسها. بدّل الساقين."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .balance,
        imageName: "pose.ankle.circles",
        voiceCueText: LocalizedString(
            en: "Circle your ankle slowly. Keep the rest of your leg still. This improves circulation.",
            fr: "Faites des cercles avec la cheville lentement. Gardez le reste de la jambe immobile. Cela améliore la circulation.",
            es: "Haga círculos con el tobillo lentamente. Mantenga el resto de la pierna quieta. Esto mejora la circulación.",
            ja: "足首をゆっくり回しましょう。脚の他の部分は動かさないでください。これは血行を改善します。",
            zh: "缓慢转动脚踝。保持腿的其余部分不动。这有助于改善血液循环。",
            ko: "발목을 천천히 돌리세요. 나머지 다리는 움직이지 마세요. 이것은 혈액순환을 개선합니다.",
            ru: "Медленно вращайте голеностоп. Остальная часть ноги неподвижна. Это улучшает кровообращение.",
            de: "Kreisen Sie den Knöchel langsam. Halten Sie den Rest des Beins still. Dies verbessert die Durchblutung.",
            ar: "أدر كاحلك ببطء. أبقِ بقية ساقك ثابتة. هذا يحسّن الدورة الدموية."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the heel on the floor and just lift the toes to make circles"],
            fr: ["Gardez le talon au sol et soulevez seulement les orteils pour faire des cercles"],
            es: ["Mantenga el talón en el suelo y solo levante los dedos para hacer círculos"],
            ja: ["かかとを床につけたまま、つま先だけ上げて円を描いてください"],
            zh: ["脚跟保持在地板上，只抬起脚趾画圈"],
            ko: ["발꿈치를 바닥에 두고 발가락만 들어 원을 그리세요"],
            ru: ["Оставьте пятку на полу и поднимайте только пальцы ног для кругов"],
            de: ["Halten Sie die Ferse auf dem Boden und heben Sie nur die Zehen, um Kreise zu machen"],
            ar: ["أبقِ الكعب على الأرض وارفع أصابع القدم فقط لرسم الدوائر"]
        ),
        contraindications: LocalizedStringArray(en: [], fr: [], es: [], ja: [], zh: [], ko: [], ru: [], de: [], ar: []),
        breathingPattern: LocalizedString(
            en: "Breathe naturally throughout",
            fr: "Respirez naturellement tout au long",
            es: "Respire naturalmente durante todo el ejercicio",
            ja: "全体を通して自然に呼吸してください",
            zh: "全程自然呼吸",
            ko: "운동 내내 자연스럽게 호흡하세요",
            ru: "Дышите естественно на протяжении всего упражнения",
            de: "Atmen Sie die ganze Zeit natürlich",
            ar: "تنفّس بشكل طبيعي طوال التمرين"
        ),
        isFree: true
    )

    public static let seatedWristStretches = Pose(
        id: "seated-wrist-stretches",
        name: LocalizedString(
            en: "Seated Wrist & Finger Stretches",
            fr: "Étirements des poignets et doigts assis",
            es: "Estiramientos de muñecas y dedos sentado",
            ja: "座った手首と指のストレッチ",
            zh: "坐姿手腕和手指拉伸",
            ko: "앉은 손목 및 손가락 스트레칭",
            ru: "Растяжка запястий и пальцев сидя",
            de: "Sitzende Hand- und Fingerdehnungen",
            ar: "تمدد المعصمين والأصابع جلوساً"
        ),
        description: LocalizedString(
            en: "Extend one arm forward, palm up. With the other hand, gently pull the fingers back toward you. Hold for a few breaths, then flip the palm down and press fingers toward the floor. Switch hands.",
            fr: "Étendez un bras devant vous, paume vers le haut. Avec l'autre main, tirez doucement les doigts vers vous. Maintenez quelques respirations, puis retournez la paume vers le bas et pressez les doigts vers le sol. Changez de main.",
            es: "Extienda un brazo hacia adelante, palma hacia arriba. Con la otra mano, tire suavemente de los dedos hacia usted. Mantenga durante algunas respiraciones, luego voltee la palma hacia abajo y presione los dedos hacia el suelo. Cambie de mano.",
            ja: "片腕を前に伸ばし、手のひらを上に向けます。もう一方の手で指をゆっくり手前に引きます。数呼吸キープし、手のひらを下に返して指を床に向けて押します。手を入れ替えます。",
            zh: "一只手臂向前伸展，掌心朝上。用另一只手轻轻将手指向自己方向拉。保持几次呼吸，然后翻转掌心朝下，将手指按向地板。换手。",
            ko: "한쪽 팔을 앞으로 뻗어 손바닥을 위로 향합니다. 다른 손으로 손가락을 자신 쪽으로 부드럽게 당깁니다. 몇 번 호흡 동안 유지한 후 손바닥을 아래로 뒤집어 손가락을 바닥 쪽으로 누릅니다. 손을 바꿉니다.",
            ru: "Вытяните одну руку вперёд ладонью вверх. Другой рукой мягко потяните пальцы на себя. Задержитесь на несколько вдохов, затем переверните ладонь вниз и надавите пальцами к полу. Поменяйте руки.",
            de: "Strecken Sie einen Arm nach vorne, Handfläche nach oben. Ziehen Sie mit der anderen Hand sanft die Finger zu sich zurück. Halten Sie einige Atemzüge, dann drehen Sie die Handfläche nach unten und drücken Sie die Finger zum Boden. Wechseln Sie die Hand.",
            ar: "مدّ ذراعاً واحدة للأمام بالكف للأعلى. باليد الأخرى، اسحب الأصابع برفق نحوك. استمر لعدة أنفاس، ثم اقلب الكف للأسفل واضغط الأصابع نحو الأرض. بدّل اليدين."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .shoulders,
        imageName: "pose.wrist.stretches",
        voiceCueText: LocalizedString(
            en: "Stretch your wrists gently. This is especially helpful if you work at a computer.",
            fr: "Étirez vos poignets doucement. C'est particulièrement utile si vous travaillez à l'ordinateur.",
            es: "Estire las muñecas suavemente. Esto es especialmente útil si trabaja en una computadora.",
            ja: "手首をやさしく伸ばしましょう。パソコンで仕事をする方に特に効果的です。",
            zh: "轻柔地拉伸手腕。如果您在电脑前工作，这特别有帮助。",
            ko: "손목을 부드럽게 스트레칭하세요. 컴퓨터에서 일하는 분에게 특히 도움이 됩니다.",
            ru: "Мягко растяните запястья. Это особенно полезно при работе за компьютером.",
            de: "Dehnen Sie Ihre Handgelenke sanft. Dies ist besonders hilfreich, wenn Sie am Computer arbeiten.",
            ar: "مدّد معصميك برفق. هذا مفيد بشكل خاص إذا كنت تعمل على الحاسوب."
        ),
        modifications: LocalizedStringArray(
            en: ["Make gentle fists and rotate the wrists instead of pulling fingers"],
            fr: ["Faites des poings légers et faites tourner les poignets au lieu de tirer les doigts"],
            es: ["Haga puños suaves y gire las muñecas en lugar de tirar de los dedos"],
            ja: ["指を引く代わりに軽く拳を握って手首を回してください"],
            zh: ["轻轻握拳并转动手腕，而不是拉手指"],
            ko: ["손가락을 당기는 대신 가볍게 주먹을 쥐고 손목을 돌리세요"],
            ru: ["Сожмите лёгкие кулаки и вращайте запястьями вместо того, чтобы тянуть пальцы"],
            de: ["Machen Sie sanfte Fäuste und drehen Sie die Handgelenke, anstatt die Finger zu ziehen"],
            ar: ["اصنع قبضتين خفيفتين وأدر المعصمين بدلاً من سحب الأصابع"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have carpal tunnel syndrome — keep the stretch very gentle"],
            fr: ["Évitez en cas de syndrome du canal carpien — gardez l'étirement très doux"],
            es: ["Evite si tiene síndrome del túnel carpiano — mantenga el estiramiento muy suave"],
            ja: ["手根管症候群がある場合は避けてください — ストレッチはとても優しくしてください"],
            zh: ["如有腕管综合征请避免——保持拉伸非常轻柔"],
            ko: ["손목 터널 증후군이 있으면 피하세요 — 스트레칭을 아주 부드럽게 하세요"],
            ru: ["Избегайте при синдроме запястного канала — растяжка должна быть очень мягкой"],
            de: ["Vermeiden Sie dies beim Karpaltunnelsyndrom — halten Sie die Dehnung sehr sanft"],
            ar: ["تجنب إذا كنت تعاني من متلازمة النفق الرسغي — أبقِ التمدد لطيفاً جداً"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow breathing, exhale as you deepen the stretch",
            fr: "Respiration lente, expirez en approfondissant l'étirement",
            es: "Respiración lenta, exhale al profundizar el estiramiento",
            ja: "ゆっくり呼吸し、吐きながらストレッチを深める",
            zh: "缓慢呼吸，呼气时加深拉伸",
            ko: "느린 호흡, 스트레칭을 깊게 할 때 날숨",
            ru: "Медленное дыхание, выдох при углублении растяжки",
            de: "Langsame Atmung, ausatmen während Sie die Dehnung vertiefen",
            ar: "تنفس بطيء، ازفر عند تعميق التمدد"
        ),
        isFree: true
    )

    public static let seatedHighKneeLifts = Pose(
        id: "seated-knee-lifts",
        name: LocalizedString(
            en: "Seated Knee Lifts",
            fr: "Levées de genoux assis",
            es: "Levantamiento de rodillas sentado",
            ja: "座った膝上げ",
            zh: "坐姿抬膝",
            ko: "앉은 무릎 올리기",
            ru: "Подъём коленей сидя",
            de: "Sitzende Kniehebungen",
            ar: "رفع الركبتين جلوساً"
        ),
        description: LocalizedString(
            en: "Sit tall with feet flat on the floor. On an exhale, lift your right knee toward your chest, hold briefly, then lower with control. Alternate legs. Keep your spine upright — do not lean back.",
            fr: "Assoyez-vous droit, pieds à plat au sol. À l'expiration, soulevez le genou droit vers la poitrine, maintenez brièvement, puis descendez avec contrôle. Alternez les jambes. Gardez la colonne droite — ne vous penchez pas vers l'arrière.",
            es: "Siéntese erguido con los pies planos en el suelo. Al exhalar, levante la rodilla derecha hacia el pecho, mantenga brevemente, luego baje con control. Alterne las piernas. Mantenga la columna erguida — no se incline hacia atrás.",
            ja: "足を床に平らにつけて背筋を伸ばして座ります。息を吐きながら右膝を胸に向けて持ち上げ、少しキープしてからコントロールしながら下ろします。脚を交互に行います。背骨をまっすぐに保ちましょう — 後ろに傾かないでください。",
            zh: "挺直腰背坐好，双脚平放在地板上。呼气时将右膝抬向胸部，短暂保持，然后有控制地放下。交替双腿。保持脊柱挺直——不要向后倾斜。",
            ko: "발을 바닥에 평평하게 놓고 허리를 펴고 앉습니다. 날숨에 오른쪽 무릎을 가슴 쪽으로 올리고, 잠시 유지한 후 조절하며 내립니다. 다리를 번갈아 합니다. 척추를 곧게 유지하세요 — 뒤로 기대지 마세요.",
            ru: "Сядьте прямо, стопы ровно на полу. На выдохе поднимите правое колено к груди, задержите на мгновение, затем опустите с контролем. Чередуйте ноги. Держите позвоночник прямо — не отклоняйтесь назад.",
            de: "Setzen Sie sich aufrecht, Füße flach auf dem Boden. Beim Ausatmen heben Sie das rechte Knie zur Brust, halten kurz und senken es kontrolliert ab. Wechseln Sie die Beine. Halten Sie die Wirbelsäule aufrecht — lehnen Sie sich nicht zurück.",
            ar: "اجلس بشكل مستقيم مع وضع القدمين بشكل مسطح على الأرض. عند الزفير، ارفع ركبتك اليمنى نحو صدرك، واستمر لفترة وجيزة، ثم أنزلها بتحكم. بدّل بين الساقين. حافظ على استقامة عمودك الفقري — لا تميل للخلف."
        ),
        durationSeconds: 40,
        difficulty: .beginner,
        category: .fullBody,
        imageName: "pose.knee.lifts",
        voiceCueText: LocalizedString(
            en: "Lift your knee, hold, and lower slowly. Keep your core engaged and your back tall.",
            fr: "Soulevez le genou, maintenez, et descendez lentement. Gardez le tronc engagé et le dos droit.",
            es: "Levante la rodilla, mantenga y baje lentamente. Mantenga el núcleo activo y la espalda erguida.",
            ja: "膝を上げて、キープし、ゆっくり下ろしましょう。体幹を引き締め、背中をまっすぐに保ちましょう。",
            zh: "抬起膝盖，保持，然后缓慢放下。保持核心收紧，背部挺直。",
            ko: "무릎을 올리고, 유지하고, 천천히 내리세요. 코어를 활성화하고 등을 곧게 유지하세요.",
            ru: "Поднимите колено, задержите и медленно опустите. Держите корпус напряжённым, а спину прямой.",
            de: "Heben Sie das Knie, halten Sie und senken Sie langsam. Halten Sie Ihren Rumpf aktiv und den Rücken aufrecht.",
            ar: "ارفع ركبتك، واستمر، ثم أنزلها ببطء. أبقِ عضلات الجذع مشدودة وظهرك مستقيماً."
        ),
        modifications: LocalizedStringArray(
            en: ["Hold the sides of the chair for support",
                 "Lift the knee only partway if full range is too difficult"],
            fr: ["Tenez les côtés de la chaise pour du soutien",
                 "Soulevez le genou seulement à mi-chemin si l'amplitude complète est trop difficile"],
            es: ["Sostenga los lados de la silla para apoyo",
                 "Levante la rodilla solo parcialmente si el rango completo es demasiado difícil"],
            ja: ["サポートのために椅子の側面を持ってください",
                 "全可動域が難しすぎる場合は膝を途中まで上げてください"],
            zh: ["双手扶住椅子两侧以获得支撑",
                 "如果全幅度太困难，只抬膝到一半"],
            ko: ["지지를 위해 의자 양쪽을 잡으세요",
                 "전체 범위가 너무 어려우면 무릎을 중간까지만 올리세요"],
            ru: ["Держитесь за боковые части стула для опоры",
                 "Поднимайте колено лишь частично, если полная амплитуда слишком сложна"],
            de: ["Halten Sie die Seiten des Stuhls zur Unterstützung",
                 "Heben Sie das Knie nur teilweise, wenn der volle Bewegungsumfang zu schwierig ist"],
            ar: ["أمسك جانبي الكرسي للدعم",
                 "ارفع الركبة جزئياً فقط إذا كان النطاق الكامل صعباً جداً"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have acute hip flexor pain"],
            fr: ["Évitez en cas de douleur aiguë aux fléchisseurs de la hanche"],
            es: ["Evite si tiene dolor agudo en los flexores de la cadera"],
            ja: ["股関節屈筋の急性痛がある場合は避けてください"],
            zh: ["如有急性髋屈肌疼痛请避免"],
            ko: ["급성 고관절 굴곡근 통증이 있으면 피하세요"],
            ru: ["Избегайте при острой боли в сгибателях бедра"],
            de: ["Vermeiden Sie dies bei akuten Hüftbeuger-Schmerzen"],
            ar: ["تجنب إذا كنت تعاني من ألم حاد في عضلات ثني الورك"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to lift, inhale to lower",
            fr: "Expirez pour lever, inspirez pour descendre",
            es: "Exhale para levantar, inhale para bajar",
            ja: "吐いて上げ、吸って下ろす",
            zh: "呼气抬起，吸气放下",
            ko: "날숨에 올리고, 들숨에 내리세요",
            ru: "Выдох для подъёма, вдох для опускания",
            de: "Ausatmen zum Heben, einatmen zum Senken",
            ar: "ازفر للرفع، واستنشق للإنزال"
        ),
        isFree: true
    )

    public static let seatedGoddess = Pose(
        id: "seated-goddess",
        name: LocalizedString(
            en: "Seated Goddess",
            fr: "Déesse assise",
            es: "Diosa sentada",
            ja: "座った女神のポーズ",
            zh: "坐姿女神式",
            ko: "앉은 여신 자세",
            ru: "Поза богини сидя",
            de: "Sitzende Göttin",
            ar: "وضعية الإلهة جلوساً"
        ),
        description: LocalizedString(
            en: "Sit at the edge of the chair with legs wide and feet turned out at 45 degrees. Place hands on inner thighs. Inhale to lengthen the spine, then gently press the thighs open with your hands. Lift the chest and gaze forward.",
            fr: "Assoyez-vous au bord de la chaise, jambes écartées et pieds tournés vers l'extérieur à 45 degrés. Placez les mains sur l'intérieur des cuisses. Inspirez pour allonger la colonne, puis appuyez doucement les cuisses vers l'extérieur avec les mains. Soulevez la poitrine et regardez devant vous.",
            es: "Siéntese en el borde de la silla con las piernas abiertas y los pies girados hacia afuera a 45 grados. Coloque las manos en los muslos internos. Inhale para alargar la columna, luego presione suavemente los muslos hacia afuera con las manos. Levante el pecho y mire hacia adelante.",
            ja: "椅子の端に座り、脚を大きく開いて足を45度外に向けます。手を内ももに置きます。息を吸って背骨を伸ばし、手で太ももをゆっくり外に押し開きます。胸を持ち上げて前方を見つめます。",
            zh: "坐在椅子边缘，双腿大幅张开，脚向外转45度。双手放在大腿内侧。吸气延伸脊柱，然后用双手轻轻将大腿向外推开。抬起胸部，目视前方。",
            ko: "의자 가장자리에 앉아 다리를 넓게 벌리고 발을 45도 바깥으로 돌립니다. 손을 안쪽 허벅지에 놓습니다. 들숨에 척추를 늘이고, 손으로 허벅지를 부드럽게 바깥으로 밀어 엽니다. 가슴을 들어 올리고 정면을 바라봅니다.",
            ru: "Сядьте на край стула, ноги широко, стопы развёрнуты наружу на 45 градусов. Положите руки на внутреннюю поверхность бёдер. Вдохните, удлиняя позвоночник, затем мягко раскройте бёдра руками. Поднимите грудь и смотрите вперёд.",
            de: "Setzen Sie sich an die Stuhlkante mit weit geöffneten Beinen und Füßen, die 45 Grad nach außen gedreht sind. Legen Sie die Hände auf die Innenseiten der Oberschenkel. Atmen Sie ein, um die Wirbelsäule zu verlängern, dann drücken Sie die Oberschenkel sanft mit den Händen auseinander. Heben Sie die Brust und blicken Sie nach vorne.",
            ar: "اجلس على حافة الكرسي مع فتح الساقين على نطاق واسع وتدوير القدمين للخارج بزاوية 45 درجة. ضع يديك على الفخذين الداخليين. استنشق لإطالة العمود الفقري، ثم ادفع الفخذين برفق للخارج بيديك. ارفع الصدر وانظر للأمام."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .hips,
        imageName: "pose.seated.goddess",
        voiceCueText: LocalizedString(
            en: "Open your legs wide in Goddess. Press the thighs open. Feel strong and expansive.",
            fr: "Ouvrez les jambes largement en Déesse. Poussez les cuisses vers l'extérieur. Sentez-vous fort et expansif.",
            es: "Abra las piernas ampliamente en Diosa. Presione los muslos hacia afuera. Siéntase fuerte y expansivo.",
            ja: "女神のポーズで脚を大きく開きましょう。太ももを外に押し開きます。力強く広がりを感じてください。",
            zh: "在女神式中将双腿大幅打开。将大腿向外推。感受力量和开阔。",
            ko: "여신 자세로 다리를 넓게 여세요. 허벅지를 밖으로 밀어 여세요. 강하고 확장되는 느낌을 받으세요.",
            ru: "Широко раскройте ноги в позе богини. Раздвиньте бёдра. Почувствуйте силу и широту.",
            de: "Öffnen Sie die Beine weit in der Göttin. Drücken Sie die Oberschenkel auseinander. Fühlen Sie sich stark und weit.",
            ar: "افتح ساقيك على نطاق واسع في وضعية الإلهة. ادفع الفخذين للانفتاح. اشعر بالقوة والاتساع."
        ),
        modifications: LocalizedStringArray(
            en: ["Don't press the thighs — let gravity create the stretch",
                 "Bring the feet closer together if the stretch is too intense"],
            fr: ["N'appuyez pas sur les cuisses — laissez la gravité créer l'étirement",
                 "Rapprochez les pieds si l'étirement est trop intense"],
            es: ["No presione los muslos — deje que la gravedad cree el estiramiento",
                 "Acerque los pies si el estiramiento es demasiado intenso"],
            ja: ["太ももを押さないでください — 重力にストレッチを任せましょう",
                 "ストレッチがきつすぎる場合は足を近づけてください"],
            zh: ["不要按压大腿——让重力自然产生拉伸",
                 "如果拉伸太强烈，将双脚靠拢一些"],
            ko: ["허벅지를 누르지 마세요 — 중력이 스트레칭을 만들게 하세요",
                 "스트레칭이 너무 강하면 발을 더 가까이 모으세요"],
            ru: ["Не давите на бёдра — пусть растяжку создаёт сила тяжести",
                 "Сведите стопы ближе друг к другу, если растяжка слишком интенсивна"],
            de: ["Drücken Sie nicht auf die Oberschenkel — lassen Sie die Schwerkraft die Dehnung erzeugen",
                 "Bringen Sie die Füße näher zusammen, wenn die Dehnung zu intensiv ist"],
            ar: ["لا تضغط على الفخذين — دع الجاذبية تخلق التمدد",
                 "قرّب القدمين من بعضهما إذا كان التمدد شديداً جداً"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have groin or inner thigh injury"],
            fr: ["Évitez en cas de blessure à l'aine ou à l'intérieur de la cuisse"],
            es: ["Evite si tiene lesión en la ingle o en la parte interna del muslo"],
            ja: ["鼠径部や内ももの怪我がある場合は避けてください"],
            zh: ["如有腹股沟或大腿内侧损伤，请避免"],
            ko: ["사타구니나 안쪽 허벅지 부상이 있으면 피하세요"],
            ru: ["Избегайте при травме паха или внутренней поверхности бедра"],
            de: ["Vermeiden Sie dies bei Leisten- oder Innenschenkelverletzungen"],
            ar: ["تجنب إذا كنت تعاني من إصابة في منطقة الأربية أو الفخذ الداخلي"]
        ),
        breathingPattern: LocalizedString(
            en: "Deep belly breaths, exhale to open wider",
            fr: "Respirations profondes du ventre, expirez pour ouvrir plus largement",
            es: "Respiraciones profundas abdominales, exhale para abrir más",
            ja: "深い腹式呼吸、吐いてさらに広く開く",
            zh: "深腹式呼吸，呼气时更大幅度地打开",
            ko: "깊은 복식 호흡, 날숨에 더 넓게 열기",
            ru: "Глубокое брюшное дыхание, выдох для большего раскрытия",
            de: "Tiefe Bauchatmung, ausatmen um weiter zu öffnen",
            ar: "أنفاس بطنية عميقة، ازفر لتفتح أوسع"
        ),
        isFree: true
    )

    public static let seatedReverseWarrior = Pose(
        id: "seated-reverse-warrior",
        name: LocalizedString(
            en: "Seated Reverse Warrior",
            fr: "Guerrier inversé assis",
            es: "Guerrero inverso sentado",
            ja: "座ったリバースウォーリアー",
            zh: "坐姿反转战士式",
            ko: "앉은 역전사 자세",
            ru: "Обратный воин сидя",
            de: "Sitzender umgekehrter Krieger",
            ar: "المحارب المعكوس جلوساً"
        ),
        description: LocalizedString(
            en: "From Seated Warrior II, keep the front knee bent. On an inhale, reach your front arm up and back overhead while the back hand slides down the back leg. Create a long arc through the side body. Gaze up toward the raised hand.",
            fr: "À partir du Guerrier II assis, gardez le genou avant plié. À l'inspiration, levez le bras avant vers le haut et vers l'arrière au-dessus de la tête tandis que la main arrière glisse le long de la jambe arrière. Créez un long arc le long du côté du corps. Regardez vers la main levée.",
            es: "Desde el Guerrero II sentado, mantenga la rodilla delantera flexionada. Al inhalar, lleve el brazo delantero hacia arriba y hacia atrás por encima de la cabeza mientras la mano trasera se desliza por la pierna trasera. Cree un arco largo a través del costado del cuerpo. Mire hacia la mano levantada.",
            ja: "座ったウォーリアーIIから、前の膝を曲げたまま保ちます。息を吸いながら前の腕を頭上に上げて後ろに伸ばし、後ろの手は後ろの脚に沿って滑らせます。体の側面に長いアーチを作ります。上げた手の方を見上げます。",
            zh: "从坐姿战士二式开始，保持前膝弯曲。吸气时，将前臂向上向后举过头顶，同时后手沿后腿滑下。在体侧形成一条长弧线。目光向上看向举起的手。",
            ko: "앉은 전사 자세 II에서 앞쪽 무릎을 구부린 채 유지합니다. 들숨에 앞쪽 팔을 위로 뒤로 머리 위로 뻗으며 뒤쪽 손은 뒤쪽 다리를 따라 미끄러뜨립니다. 옆구리를 통해 긴 호를 만듭니다. 올린 손을 향해 위를 바라봅니다.",
            ru: "Из позы воина II сидя, сохраняйте переднее колено согнутым. На вдохе потянитесь передней рукой вверх и назад над головой, а задняя рука скользит вниз по задней ноге. Создайте длинную дугу через боковую часть тела. Смотрите вверх на поднятую руку.",
            de: "Aus dem Sitzenden Krieger II, halten Sie das vordere Knie gebeugt. Beim Einatmen strecken Sie den vorderen Arm nach oben und hinten über den Kopf, während die hintere Hand am hinteren Bein hinuntergleitet. Erzeugen Sie einen langen Bogen durch die Körperseite. Blicken Sie zur erhobenen Hand hoch.",
            ar: "من وضعية المحارب الثاني جلوساً، أبقِ الركبة الأمامية مثنية. عند الشهيق، مدّ ذراعك الأمامية للأعلى وللخلف فوق الرأس بينما تنزلق اليد الخلفية على الساق الخلفية. أنشئ قوساً طويلاً عبر جانب الجسم. انظر للأعلى نحو اليد المرفوعة."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .fullBody,
        imageName: "pose.seated.reverse.warrior",
        voiceCueText: LocalizedString(
            en: "Reach up and back. Open through the side body. Feel the stretch from hip to fingertips.",
            fr: "Étirez-vous vers le haut et vers l'arrière. Ouvrez le côté du corps. Sentez l'étirement de la hanche jusqu'au bout des doigts.",
            es: "Estírese hacia arriba y hacia atrás. Abra a través del costado del cuerpo. Sienta el estiramiento desde la cadera hasta las puntas de los dedos.",
            ja: "上に後ろに伸ばしましょう。体側を開きます。股関節から指先までのストレッチを感じてください。",
            zh: "向上向后伸展。打开体侧。感受从髋部到指尖的拉伸。",
            ko: "위로 뒤로 뻗으세요. 옆구리를 열어주세요. 골반에서 손끝까지의 스트레칭을 느끼세요.",
            ru: "Тянитесь вверх и назад. Раскройте боковую часть тела. Почувствуйте растяжку от бедра до кончиков пальцев.",
            de: "Strecken Sie sich nach oben und hinten. Öffnen Sie die Körperseite. Spüren Sie die Dehnung von der Hüfte bis zu den Fingerspitzen.",
            ar: "امتد للأعلى وللخلف. افتح جانب الجسم. اشعر بالتمدد من الورك إلى أطراف الأصابع."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the raised arm bent if full extension is too much",
                 "Place the back hand on the chair seat instead of the leg"],
            fr: ["Gardez le bras levé plié si l'extension complète est trop",
                 "Placez la main arrière sur le siège au lieu de la jambe"],
            es: ["Mantenga el brazo levantado doblado si la extensión completa es demasiado",
                 "Coloque la mano trasera en el asiento de la silla en lugar de la pierna"],
            ja: ["完全な伸展がきつすぎる場合は上げた腕を曲げてください",
                 "脚の代わりに後ろの手を椅子の座面に置いてください"],
            zh: ["如果完全伸展太过分，保持抬起的手臂弯曲",
                 "将后方的手放在椅子座面上而不是腿上"],
            ko: ["완전한 신전이 너무 힘들면 올린 팔을 구부린 상태로 유지하세요",
                 "뒤쪽 손을 다리 대신 의자 좌석에 놓으세요"],
            ru: ["Держите поднятую руку согнутой, если полное разгибание слишком интенсивно",
                 "Положите заднюю руку на сиденье стула вместо ноги"],
            de: ["Halten Sie den erhobenen Arm gebeugt, wenn die volle Streckung zu viel ist",
                 "Legen Sie die hintere Hand auf die Sitzfläche statt auf das Bein"],
            ar: ["أبقِ الذراع المرفوعة مثنية إذا كان التمدد الكامل مبالغاً فيه",
                 "ضع اليد الخلفية على مقعد الكرسي بدلاً من الساق"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid deep backbend if you have spinal issues"],
            fr: ["Évitez la cambrure profonde en cas de problèmes vertébraux"],
            es: ["Evite la flexión profunda hacia atrás si tiene problemas de columna"],
            ja: ["脊柱の問題がある場合は深い後屈を避けてください"],
            zh: ["如有脊柱问题，避免深度后弯"],
            ko: ["척추 문제가 있으면 깊은 후굴을 피하세요"],
            ru: ["Избегайте глубокого прогиба назад при проблемах с позвоночником"],
            de: ["Vermeiden Sie tiefe Rückbeugen bei Wirbelsäulenproblemen"],
            ar: ["تجنب الانحناء العميق للخلف إذا كنت تعاني من مشاكل في العمود الفقري"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to reach, exhale to settle deeper",
            fr: "Inspirez pour vous étirer, expirez pour vous installer plus profondément",
            es: "Inhale para estirarse, exhale para asentarse más profundo",
            ja: "吸って伸び、吐いてより深く沈む",
            zh: "吸气伸展，呼气更深地沉入",
            ko: "들숨에 뻗고, 날숨에 더 깊이 자리 잡으세요",
            ru: "Вдох для вытяжения, выдох для более глубокого погружения",
            de: "Einatmen zum Strecken, ausatmen um tiefer einzusinken",
            ar: "استنشق للامتداد، وازفر للاستقرار أعمق"
        ),
        isFree: true
    )

    public static let seatedCrescentMoon = Pose(
        id: "seated-crescent-moon",
        name: LocalizedString(
            en: "Seated Crescent Moon",
            fr: "Croissant de lune assis",
            es: "Media luna sentada",
            ja: "座った三日月のポーズ",
            zh: "坐姿新月式",
            ko: "앉은 초승달 자세",
            ru: "Поза полумесяца сидя",
            de: "Sitzende Mondsichel",
            ar: "وضعية الهلال جلوساً"
        ),
        description: LocalizedString(
            en: "Interlace your fingers and press your palms toward the ceiling. On an exhale, lean to the right, creating a C-shape with your torso. Keep both sit bones on the chair and both arms framing your head. Hold, then switch sides.",
            fr: "Entrelacez les doigts et poussez les paumes vers le plafond. À l'expiration, penchez-vous vers la droite en créant un C avec le torse. Gardez les deux ischions sur la chaise et les deux bras encadrant la tête. Maintenez, puis changez de côté.",
            es: "Entrelace los dedos y presione las palmas hacia el techo. Al exhalar, inclínese hacia la derecha, creando una forma de C con el torso. Mantenga ambos isquiones en la silla y ambos brazos enmarcando la cabeza. Sostenga, luego cambie de lado.",
            ja: "指を組み、手のひらを天井に向けて押し上げます。息を吐きながら右に傾き、上体でC字を作ります。両方の坐骨を椅子につけたまま、両腕で頭を挟むようにします。キープし、反対側も行います。",
            zh: "十指交扣，掌心向天花板推。呼气时向右倾斜，躯干形成C形。保持双侧坐骨在椅子上，双臂框住头部。保持，然后换边。",
            ko: "손가락을 깍지 끼고 손바닥을 천장을 향해 밀어 올립니다. 날숨에 오른쪽으로 기울여 상체로 C자 모양을 만듭니다. 양쪽 좌골을 의자에 유지하고 양팔로 머리를 감쌉니다. 유지한 후 반대쪽을 합니다.",
            ru: "Сцепите пальцы и надавите ладонями к потолку. На выдохе наклонитесь вправо, создавая С-образный изгиб корпусом. Держите обе седалищные кости на стуле, а руки обрамляют голову. Задержитесь, затем поменяйте сторону.",
            de: "Verschränken Sie die Finger und drücken Sie die Handflächen zur Decke. Beim Ausatmen neigen Sie sich nach rechts und erzeugen eine C-Form mit dem Oberkörper. Halten Sie beide Sitzknochen auf dem Stuhl und beide Arme den Kopf umrahmend. Halten Sie, dann wechseln Sie die Seite.",
            ar: "شبّك أصابعك وادفع كفيك نحو السقف. عند الزفير، مِل إلى اليمين مكوّناً شكل حرف C بجذعك. أبقِ كلتا عظمتي الجلوس على الكرسي وكلا الذراعين تُحيطان برأسك. استمر، ثم بدّل الجانب."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .spine,
        imageName: "pose.seated.crescent.moon",
        voiceCueText: LocalizedString(
            en: "Reach up and lean to the side. Create a crescent shape. Breathe into the long side of your body.",
            fr: "Étirez-vous vers le haut et penchez-vous sur le côté. Créez une forme de croissant. Respirez dans le côté long du corps.",
            es: "Estírese hacia arriba e inclínese hacia el lado. Cree una forma de media luna. Respire hacia el lado largo de su cuerpo.",
            ja: "上に伸びて横に傾きましょう。三日月の形を作ります。体の長い側に呼吸を送りましょう。",
            zh: "向上伸展并向侧面倾斜。创造新月形状。将呼吸送入身体的伸展侧。",
            ko: "위로 뻗고 옆으로 기울이세요. 초승달 모양을 만드세요. 몸의 긴 쪽으로 호흡을 보내세요.",
            ru: "Потянитесь вверх и наклонитесь в сторону. Создайте форму полумесяца. Дышите в длинную сторону тела.",
            de: "Strecken Sie sich hoch und neigen Sie sich zur Seite. Erzeugen Sie eine Mondsichelform. Atmen Sie in die lange Seite Ihres Körpers.",
            ar: "امتد للأعلى ومِل إلى الجانب. أنشئ شكل هلال. تنفّس في الجانب الطويل من جسمك."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep one hand on the chair seat for support",
                 "Don't interlace — just reach one arm up"],
            fr: ["Gardez une main sur le siège pour du soutien",
                 "N'entrelacez pas — levez simplement un bras"],
            es: ["Mantenga una mano en el asiento de la silla para apoyo",
                 "No entrelace — simplemente levante un brazo"],
            ja: ["サポートのために片手を椅子の座面に置いてください",
                 "指を組まないでください — 片腕だけ上げてください"],
            zh: ["将一只手放在椅子座面上以获得支撑",
                 "不必交扣——只需举起一只手臂"],
            ko: ["지지를 위해 한 손을 의자 좌석에 놓으세요",
                 "깍지를 끼지 마세요 — 한 팔만 올리세요"],
            ru: ["Оставьте одну руку на сиденье стула для опоры",
                 "Не сцепляйте пальцы — просто поднимите одну руку вверх"],
            de: ["Halten Sie eine Hand zur Unterstützung auf der Sitzfläche",
                 "Verschränken Sie nicht — strecken Sie einfach einen Arm nach oben"],
            ar: ["أبقِ يداً واحدة على مقعد الكرسي للدعم",
                 "لا تشبّك — فقط ارفع ذراعاً واحدة"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have acute rib or intercostal pain"],
            fr: ["Évitez en cas de douleur aiguë aux côtes ou intercostale"],
            es: ["Evite si tiene dolor agudo en las costillas o intercostal"],
            ja: ["急性の肋骨痛や肋間痛がある場合は避けてください"],
            zh: ["如有急性肋骨或肋间疼痛请避免"],
            ko: ["급성 갈비뼈 또는 늑간 통증이 있으면 피하세요"],
            ru: ["Избегайте при острой боли в рёбрах или межрёберной боли"],
            de: ["Vermeiden Sie dies bei akuten Rippen- oder Interkostalschmerzen"],
            ar: ["تجنب إذا كنت تعاني من ألم حاد في الأضلاع أو ألم بين الأضلاع"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen up, exhale to bend to the side",
            fr: "Inspirez pour allonger vers le haut, expirez pour plier sur le côté",
            es: "Inhale para alargarse hacia arriba, exhale para inclinarse hacia el lado",
            ja: "吸って上に伸び、吐いて横に曲げる",
            zh: "吸气向上延伸，呼气向侧面弯曲",
            ko: "들숨에 위로 늘이고, 날숨에 옆으로 굽히세요",
            ru: "Вдох для удлинения вверх, выдох для наклона в сторону",
            de: "Einatmen zum Hochstrecken, ausatmen zum Seitenbeugen",
            ar: "استنشق للاستطالة للأعلى، وازفر للانحناء إلى الجانب"
        ),
        isFree: true
    )

    public static let seatedChestExpansion = Pose(
        id: "seated-chest-expansion",
        name: LocalizedString(
            en: "Seated Chest Expansion",
            fr: "Expansion de la poitrine assise",
            es: "Expansión de pecho sentada",
            ja: "座った胸の拡張",
            zh: "坐姿扩胸式",
            ko: "앉은 가슴 확장",
            ru: "Раскрытие грудной клетки сидя",
            de: "Sitzende Brustöffnung",
            ar: "توسيع الصدر جلوساً"
        ),
        description: LocalizedString(
            en: "Sit at the front of the chair. Interlace your hands behind your back. On an inhale, straighten your arms and lift them away from your back, squeezing the shoulder blades together. Open the chest and gaze slightly upward.",
            fr: "Assoyez-vous au bord avant de la chaise. Entrelacez les mains derrière le dos. À l'inspiration, tendez les bras et soulevez-les loin du dos en serrant les omoplates ensemble. Ouvrez la poitrine et regardez légèrement vers le haut.",
            es: "Siéntese en el borde delantero de la silla. Entrelace las manos detrás de la espalda. Al inhalar, estire los brazos y levántelos alejándolos de la espalda, apretando los omóplatos. Abra el pecho y mire ligeramente hacia arriba.",
            ja: "椅子の前端に座ります。背中の後ろで手を組みます。息を吸いながら腕をまっすぐにし、背中から離すように持ち上げ、肩甲骨を寄せます。胸を開き、やや上を見つめます。",
            zh: "坐在椅子前缘。在背后十指交扣。吸气时伸直手臂并将其抬离背部，夹紧肩胛骨。打开胸部，目光略微向上。",
            ko: "의자 앞쪽 가장자리에 앉습니다. 등 뒤에서 손을 깍지 끼세요. 들숨에 팔을 펴고 등에서 멀리 들어 올리며 견갑골을 모읍니다. 가슴을 열고 시선을 약간 위로 향합니다.",
            ru: "Сядьте на переднюю часть стула. Сцепите руки за спиной. На вдохе выпрямите руки и поднимите их от спины, сводя лопатки вместе. Раскройте грудь и слегка поднимите взгляд.",
            de: "Setzen Sie sich an die Vorderkante des Stuhls. Verschränken Sie die Hände hinter dem Rücken. Beim Einatmen strecken Sie die Arme und heben sie vom Rücken weg, während Sie die Schulterblätter zusammendrücken. Öffnen Sie die Brust und blicken Sie leicht nach oben.",
            ar: "اجلس في مقدمة الكرسي. شبّك يديك خلف ظهرك. عند الشهيق، افرد ذراعيك وارفعهما بعيداً عن ظهرك مع ضغط لوحي الكتف معاً. افتح الصدر وانظر قليلاً للأعلى."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .shoulders,
        imageName: "pose.seated.chest.expansion",
        voiceCueText: LocalizedString(
            en: "Clasp your hands behind you and lift. Open your chest wide. Breathe into the front of your body.",
            fr: "Joignez les mains derrière vous et soulevez. Ouvrez la poitrine largement. Respirez dans l'avant de votre corps.",
            es: "Junte las manos detrás de usted y levante. Abra el pecho ampliamente. Respire hacia el frente de su cuerpo.",
            ja: "背中の後ろで手を組んで持ち上げましょう。胸を大きく開きます。体の前面に呼吸を送りましょう。",
            zh: "在背后握紧双手并抬起。大幅打开胸部。将呼吸送入身体前侧。",
            ko: "뒤에서 손을 잡고 들어 올리세요. 가슴을 크게 여세요. 몸 앞쪽으로 호흡을 보내세요.",
            ru: "Сцепите руки за спиной и поднимите. Широко раскройте грудь. Дышите в переднюю часть тела.",
            de: "Verschränken Sie die Hände hinter sich und heben Sie. Öffnen Sie die Brust weit. Atmen Sie in die Vorderseite Ihres Körpers.",
            ar: "شبّك يديك خلفك وارفعهما. افتح صدرك على نطاق واسع. تنفّس في الجانب الأمامي من جسمك."
        ),
        modifications: LocalizedStringArray(
            en: ["Hold a strap or towel between your hands if they don't reach",
                 "Keep arms bent if straightening is too intense"],
            fr: ["Tenez une sangle ou serviette entre les mains si elles ne se rejoignent pas",
                 "Gardez les bras pliés si les tendre est trop intense"],
            es: ["Sostenga una correa o toalla entre las manos si no llegan a tocarse",
                 "Mantenga los brazos doblados si estirarlos es demasiado intenso"],
            ja: ["手が届かない場合はストラップやタオルを手の間に持ってください",
                 "まっすぐにするのがきつすぎる場合は腕を曲げたままにしてください"],
            zh: ["如果双手够不到，可以在手间握一条带子或毛巾",
                 "如果伸直太强烈，保持手臂弯曲"],
            ko: ["손이 닿지 않으면 스트랩이나 수건을 손 사이에 잡으세요",
                 "팔을 펴는 것이 너무 강하면 팔을 구부린 상태로 유지하세요"],
            ru: ["Если руки не достают друг до друга, возьмите ремень или полотенце между ними",
                 "Держите руки согнутыми, если выпрямление слишком интенсивно"],
            de: ["Halten Sie einen Gurt oder ein Handtuch zwischen den Händen, wenn sie sich nicht erreichen",
                 "Halten Sie die Arme gebeugt, wenn das Strecken zu intensiv ist"],
            ar: ["أمسك حزاماً أو منشفة بين يديك إذا لم تصلا لبعضهما",
                 "أبقِ الذراعين مثنيتين إذا كان فردهما شديداً جداً"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with rotator cuff injuries or frozen shoulder"],
            fr: ["Évitez en cas de blessure à la coiffe des rotateurs ou d'épaule gelée"],
            es: ["Evite con lesiones del manguito rotador o hombro congelado"],
            ja: ["回旋筋腱板の怪我や五十肩がある場合は避けてください"],
            zh: ["肩袖损伤或冻结肩者请避免"],
            ko: ["회전근개 부상이나 오십견이 있으면 피하세요"],
            ru: ["Избегайте при травмах вращательной манжеты или замороженном плече"],
            de: ["Vermeiden Sie dies bei Rotatorenmanschetten-Verletzungen oder Schultersteife"],
            ar: ["تجنب في حالة إصابات الكفة المدورة أو الكتف المتجمد"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift and expand, exhale to release",
            fr: "Inspirez pour lever et ouvrir, expirez pour relâcher",
            es: "Inhale para levantar y expandir, exhale para soltar",
            ja: "吸って持ち上げて広げ、吐いて解放する",
            zh: "吸气抬起并扩展，呼气释放",
            ko: "들숨에 들어 올리고 확장하고, 날숨에 놓으세요",
            ru: "Вдох для подъёма и расширения, выдох для расслабления",
            de: "Einatmen zum Heben und Erweitern, ausatmen zum Lösen",
            ar: "استنشق للرفع والتوسع، وازفر للإرخاء"
        ),
        isFree: true
    )

    public static let seatedThreadTheNeedle = Pose(
        id: "seated-thread-needle",
        name: LocalizedString(
            en: "Seated Thread the Needle",
            fr: "Enfiler l'aiguille assis",
            es: "Enhebrar la aguja sentado",
            ja: "座った針の糸通し",
            zh: "坐姿穿针式",
            ko: "앉은 바늘 꿰기",
            ru: "Вдевание нитки в иглу сидя",
            de: "Sitzender Nadelfaden",
            ar: "تمرير الخيط في الإبرة جلوساً"
        ),
        description: LocalizedString(
            en: "Sit tall and extend both arms to the sides. Thread your right arm under your left arm, rotating your torso to the left. Rest the right shoulder toward your left knee. The left hand can press against the chair for a deeper twist. Switch sides.",
            fr: "Assoyez-vous bien droit et étendez les deux bras sur les côtés. Passez le bras droit sous le bras gauche en tournant le torse vers la gauche. Reposez l'épaule droite vers le genou gauche. La main gauche peut s'appuyer sur la chaise pour une torsion plus profonde. Changez de côté.",
            es: "Siéntese erguido y extienda ambos brazos a los lados. Pase el brazo derecho por debajo del brazo izquierdo, rotando el torso hacia la izquierda. Descanse el hombro derecho hacia la rodilla izquierda. La mano izquierda puede presionar contra la silla para una torsión más profunda. Cambie de lado.",
            ja: "背筋を伸ばして座り、両腕を横に伸ばします。右腕を左腕の下に通し、上体を左に回転させます。右肩を左膝に向けて下ろします。左手を椅子に押しつけてより深いねじりにすることができます。反対側も行います。",
            zh: "挺直腰背坐好，双臂向两侧伸展。将右臂穿过左臂下方，躯干向左旋转。右肩靠向左膝。左手可以按在椅子上以加深扭转。换边。",
            ko: "허리를 펴고 앉아 양팔을 옆으로 뻗습니다. 오른팔을 왼팔 아래로 통과시키며 상체를 왼쪽으로 회전합니다. 오른쪽 어깨를 왼쪽 무릎 쪽으로 내립니다. 왼손을 의자에 눌러 더 깊은 비틀기를 할 수 있습니다. 반대쪽을 합니다.",
            ru: "Сядьте прямо и разведите обе руки в стороны. Проведите правую руку под левой, поворачивая корпус влево. Опустите правое плечо к левому колену. Левая рука может упираться в стул для более глубокого скручивания. Поменяйте стороны.",
            de: "Setzen Sie sich aufrecht und strecken Sie beide Arme zur Seite. Führen Sie den rechten Arm unter dem linken hindurch und drehen Sie den Oberkörper nach links. Senken Sie die rechte Schulter zum linken Knie. Die linke Hand kann für eine tiefere Drehung gegen den Stuhl drücken. Wechseln Sie die Seite.",
            ar: "اجلس بشكل مستقيم ومدّ كلا الذراعين إلى الجانبين. مرّر ذراعك اليمنى تحت ذراعك اليسرى مع تدوير الجذع نحو اليسار. أرح الكتف اليمنى نحو الركبة اليسرى. يمكن لليد اليسرى الضغط على الكرسي لتعميق اللفّ. بدّل الجانبين."
        ),
        durationSeconds: 35,
        difficulty: .advanced,
        category: .spine,
        imageName: "pose.seated.thread.needle",
        voiceCueText: LocalizedString(
            en: "Thread your arm through and twist. Feel the rotation through your mid-back. Breathe into the twist.",
            fr: "Passez le bras à travers et tournez. Sentez la rotation dans le milieu du dos. Respirez dans la torsion.",
            es: "Pase el brazo a través y gire. Sienta la rotación a través de la espalda media. Respire hacia la torsión.",
            ja: "腕を通してねじりましょう。背中の中間の回旋を感じてください。ねじりに呼吸を送りましょう。",
            zh: "将手臂穿过并扭转。感受中背部的旋转。将呼吸送入扭转中。",
            ko: "팔을 통과시키고 비틀으세요. 등 중간의 회전을 느끼세요. 비틀기에 호흡을 보내세요.",
            ru: "Проденьте руку и скрутитесь. Почувствуйте вращение в середине спины. Дышите в скручивание.",
            de: "Fädeln Sie den Arm durch und drehen Sie sich. Spüren Sie die Rotation durch die Mitte des Rückens. Atmen Sie in die Drehung.",
            ar: "مرّر ذراعك وأدِر جسمك. اشعر بالدوران في منتصف ظهرك. تنفّس في اللفّة."
        ),
        modifications: LocalizedStringArray(
            en: ["Don't thread as deeply — just twist with both hands on knees",
                 "Place a pillow on your lap for the threading arm to rest on"],
            fr: ["Ne passez pas aussi profondément — tournez simplement avec les mains sur les genoux",
                 "Placez un coussin sur vos cuisses pour que le bras repose dessus"],
            es: ["No enhebr tan profundamente — simplemente gire con ambas manos en las rodillas",
                 "Coloque una almohada en su regazo para que el brazo descanse"],
            ja: ["あまり深く通さないでください — 両手を膝に置いてねじるだけにしてください",
                 "腕を休ませるために膝の上にクッションを置いてください"],
            zh: ["不要穿得太深——只需双手放在膝盖上扭转",
                 "在大腿上放一个枕头让穿过的手臂休息"],
            ko: ["너무 깊이 통과하지 마세요 — 양손을 무릎에 놓고 비틀기만 하세요",
                 "통과하는 팔이 쉴 수 있도록 무릎 위에 베개를 놓으세요"],
            ru: ["Не продевайте руку слишком глубоко — просто скручивайтесь с обеими руками на коленях",
                 "Положите подушку на колени, чтобы продетая рука могла на ней отдыхать"],
            de: ["Fädeln Sie nicht so tief — drehen Sie sich einfach mit beiden Händen auf den Knien",
                 "Legen Sie ein Kissen auf Ihren Schoß, auf dem der durchgefädelte Arm ruhen kann"],
            ar: ["لا تمرّر بعمق كبير — فقط أدِر الجسم مع وضع اليدين على الركبتين",
                 "ضع وسادة على حجرك ليستريح عليها الذراع الممرّر"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute spinal conditions or recent back surgery"],
            fr: ["Évitez en cas de conditions spinales aiguës ou de chirurgie récente du dos"],
            es: ["Evite con afecciones agudas de la columna o cirugía de espalda reciente"],
            ja: ["急性の脊柱疾患や最近の背中の手術がある場合は避けてください"],
            zh: ["急性脊柱疾病或近期背部手术者请避免"],
            ko: ["급성 척추 질환이나 최근 등 수술을 받은 경우 피하세요"],
            ru: ["Избегайте при острых заболеваниях позвоночника или недавней операции на спине"],
            de: ["Vermeiden Sie dies bei akuten Wirbelsäulenerkrankungen oder kürzlicher Rückenoperation"],
            ar: ["تجنب في حالة أمراض العمود الفقري الحادة أو جراحة الظهر الحديثة"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to thread deeper, inhale to create space",
            fr: "Expirez pour passer plus profondément, inspirez pour créer de l'espace",
            es: "Exhale para enhebrar más profundo, inhale para crear espacio",
            ja: "吐いてより深く通し、吸ってスペースを作る",
            zh: "呼气加深穿入，吸气创造空间",
            ko: "날숨에 더 깊이 통과하고, 들숨에 공간을 만드세요",
            ru: "Выдох для более глубокого вдевания, вдох для создания пространства",
            de: "Ausatmen um tiefer zu fädeln, einatmen um Raum zu schaffen",
            ar: "ازفر للتمرير أعمق، واستنشق لخلق مساحة"
        ),
        isFree: true
    )

    public static let seatedBreathOfJoy = Pose(
        id: "seated-breath-of-joy",
        name: LocalizedString(
            en: "Seated Breath of Joy",
            fr: "Souffle de joie assis",
            es: "Respiración de alegría sentado",
            ja: "座った歓びの呼吸",
            zh: "坐姿喜悦呼吸",
            ko: "앉은 기쁨의 호흡",
            ru: "Дыхание радости сидя",
            de: "Sitzender Freudenatmen",
            ar: "نَفَس الفرح جلوساً"
        ),
        description: LocalizedString(
            en: "This is a three-part energizing breath with movement. Inhale 1/3: sweep arms forward to shoulder height. Inhale 2/3: open arms wide to the sides. Inhale 3/3: sweep arms overhead. Exhale fully: fold forward and let arms swing down. Repeat rhythmically.",
            fr: "C'est un souffle énergisant en trois parties avec mouvement. Inspiration 1/3 : balayez les bras vers l'avant à la hauteur des épaules. Inspiration 2/3 : ouvrez les bras largement sur les côtés. Inspiration 3/3 : balayez les bras au-dessus de la tête. Expirez complètement : penchez-vous vers l'avant et laissez les bras descendre. Répétez de façon rythmique.",
            es: "Esta es una respiración energizante de tres partes con movimiento. Inhalación 1/3: lleve los brazos hacia adelante a la altura de los hombros. Inhalación 2/3: abra los brazos ampliamente a los lados. Inhalación 3/3: lleve los brazos por encima de la cabeza. Exhale completamente: pliegue hacia adelante y deje que los brazos caigan. Repita rítmicamente.",
            ja: "これは動きを伴う3段階のエネルギー活性化呼吸です。1/3吸気：腕を肩の高さまで前に振り上げます。2/3吸気：腕を横に大きく開きます。3/3吸気：腕を頭上に振り上げます。完全に吐く：前に折りたたんで腕を下に振り下ろします。リズミカルに繰り返します。",
            zh: "这是一种带有动作的三段式激活呼吸。吸气1/3：双臂向前摆至肩高。吸气2/3：双臂向两侧大幅展开。吸气3/3：双臂摆过头顶。完全呼气：向前折叠，让双臂自然下垂。有节奏地重复。",
            ko: "이것은 움직임을 동반한 3단계 활력 호흡법입니다. 들숨 1/3: 팔을 어깨 높이까지 앞으로 올립니다. 들숨 2/3: 팔을 양옆으로 넓게 벌립니다. 들숨 3/3: 팔을 머리 위로 올립니다. 완전히 내쉬기: 앞으로 접으며 팔을 아래로 내립니다. 리드미컬하게 반복합니다.",
            ru: "Это трёхчастное энергизирующее дыхание с движением. Вдох 1/3: руки вперёд на уровень плеч. Вдох 2/3: руки широко в стороны. Вдох 3/3: руки вверх над головой. Полный выдох: наклон вперёд, руки свободно опускаются. Повторяйте ритмично.",
            de: "Dies ist eine dreiteilige energetisierende Atemübung mit Bewegung. Einatmen 1/3: Arme nach vorne auf Schulterhöhe schwingen. Einatmen 2/3: Arme weit zu den Seiten öffnen. Einatmen 3/3: Arme über den Kopf schwingen. Vollständig ausatmen: nach vorne falten und die Arme nach unten schwingen lassen. Rhythmisch wiederholen.",
            ar: "هذا تمرين تنفس منشّط من ثلاثة أجزاء مع حركة. شهيق 1/3: ارفع الذراعين للأمام إلى ارتفاع الكتفين. شهيق 2/3: افتح الذراعين على نطاق واسع إلى الجانبين. شهيق 3/3: ارفع الذراعين فوق الرأس. ازفر بالكامل: انحنِ للأمام ودع الذراعين تتأرجحان للأسفل. كرّر بإيقاع."
        ),
        durationSeconds: 45,
        difficulty: .advanced,
        category: .breathing,
        imageName: "pose.breath.of.joy",
        voiceCueText: LocalizedString(
            en: "Three quick inhales with arm sweeps, then a full exhale and fold. Feel the energy build!",
            fr: "Trois inspirations rapides avec des mouvements de bras, puis une expiration complète et pliez. Sentez l'énergie monter!",
            es: "Tres inhalaciones rápidas con movimientos de brazos, luego una exhalación completa y pliegue. Sienta cómo crece la energía.",
            ja: "3回の素早い吸気と腕の動き、そして完全な呼気と前屈。エネルギーが高まるのを感じましょう！",
            zh: "三次快速吸气伴随手臂挥动，然后完全呼气并前屈。感受能量的积聚！",
            ko: "팔 휘두르기와 함께 세 번 빠르게 들이쉬고, 완전히 내쉬며 접으세요. 에너지가 쌓이는 것을 느끼세요!",
            ru: "Три быстрых вдоха с движениями рук, затем полный выдох и наклон. Почувствуйте, как нарастает энергия!",
            de: "Drei schnelle Einatmungen mit Armschwüngen, dann ein vollständiges Ausatmen und Falten. Spüren Sie, wie die Energie aufbaut!",
            ar: "ثلاث شهقات سريعة مع حركات الذراعين، ثم زفير كامل وانحناء. اشعر بتراكم الطاقة!"
        ),
        modifications: LocalizedStringArray(
            en: ["Make smaller arm movements if full sweeps cause dizziness",
                 "Stay upright on the exhale instead of folding forward"],
            fr: ["Faites de plus petits mouvements de bras si les grands mouvements causent des étourdissements",
                 "Restez droit à l'expiration au lieu de plier vers l'avant"],
            es: ["Haga movimientos de brazos más pequeños si los completos causan mareo",
                 "Quédese erguido al exhalar en lugar de plegarse hacia adelante"],
            ja: ["大きな動きでめまいがする場合は腕の動きを小さくしてください",
                 "前に折りたたむ代わりに呼気時にまっすぐ座ったままにしてください"],
            zh: ["如果大幅度挥臂导致头晕，可缩小手臂动作",
                 "呼气时保持直立，不要向前折叠"],
            ko: ["큰 동작이 어지러움을 유발하면 팔 동작을 작게 하세요",
                 "앞으로 접는 대신 날숨에 곧게 앉아 있으세요"],
            ru: ["Делайте меньшие движения руками, если полные взмахи вызывают головокружение",
                 "Оставайтесь в вертикальном положении на выдохе вместо наклона вперёд"],
            de: ["Machen Sie kleinere Armbewegungen, wenn die vollen Schwünge Schwindel verursachen",
                 "Bleiben Sie beim Ausatmen aufrecht, anstatt sich nach vorne zu falten"],
            ar: ["اجعل حركات الذراعين أصغر إذا تسببت الحركات الكاملة بالدوار",
                 "ابقَ مستقيماً عند الزفير بدلاً من الانحناء للأمام"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have uncontrolled blood pressure or feel dizzy",
                 "Not recommended during migraine episodes"],
            fr: ["Évitez en cas de pression artérielle non contrôlée ou d'étourdissements",
                 "Non recommandé pendant les épisodes de migraine"],
            es: ["Evite si tiene presión arterial no controlada o se siente mareado",
                 "No recomendado durante episodios de migraña"],
            ja: ["制御されていない血圧がある場合やめまいを感じる場合は避けてください",
                 "偏頭痛の発作中は推奨されません"],
            zh: ["如有未控制的血压或感到头晕请避免",
                 "偏头痛发作期间不推荐"],
            ko: ["조절되지 않는 혈압이 있거나 어지러우면 피하세요",
                 "편두통 발작 중에는 권장되지 않습니다"],
            ru: ["Избегайте при неконтролируемом артериальном давлении или головокружении",
                 "Не рекомендуется во время приступов мигрени"],
            de: ["Vermeiden Sie dies bei unkontrolliertem Blutdruck oder Schwindel",
                 "Nicht empfohlen während Migräneepisoden"],
            ar: ["تجنب إذا كنت تعاني من ضغط دم غير منضبط أو تشعر بالدوار",
                 "غير موصى به أثناء نوبات الصداع النصفي"]
        ),
        breathingPattern: LocalizedString(
            en: "Three staccato inhales through the nose, one full exhale through the mouth",
            fr: "Trois inspirations staccato par le nez, une expiration complète par la bouche",
            es: "Tres inhalaciones staccato por la nariz, una exhalación completa por la boca",
            ja: "鼻からの3回のスタッカート吸気、口からの1回の完全な呼気",
            zh: "通过鼻子进行三次断续吸气，通过嘴进行一次完整呼气",
            ko: "코로 세 번 끊어서 들이쉬고, 입으로 한 번 완전히 내쉬세요",
            ru: "Три отрывистых вдоха через нос, один полный выдох через рот",
            de: "Drei Stakkato-Einatmungen durch die Nase, eine vollständige Ausatmung durch den Mund",
            ar: "ثلاث شهقات متقطعة من الأنف، وزفير كامل واحد من الفم"
        ),
        isFree: true
    )

    public static let seatedHalfMoon = Pose(
        id: "seated-half-moon",
        name: LocalizedString(
            en: "Seated Half Moon Balance",
            fr: "Demi-lune en équilibre assis",
            es: "Media luna en equilibrio sentado",
            ja: "座った半月バランス",
            zh: "坐姿半月平衡式",
            ko: "앉은 반달 균형 자세",
            ru: "Баланс полумесяца сидя",
            de: "Sitzende Halbmond-Balance",
            ar: "توازن نصف القمر جلوساً"
        ),
        description: LocalizedString(
            en: "Sit at the edge of the chair. Extend your right leg straight to the side with toes on the floor. Raise your left arm overhead and lean to the right, creating a long line from left hand to left hip. The right hand rests on the right thigh or the chair. Focus on balance and length.",
            fr: "Assoyez-vous au bord de la chaise. Étendez la jambe droite sur le côté, orteils au sol. Levez le bras gauche au-dessus de la tête et penchez-vous vers la droite, créant une longue ligne de la main gauche à la hanche gauche. La main droite repose sur la cuisse droite ou la chaise. Concentrez-vous sur l'équilibre et la longueur.",
            es: "Siéntese en el borde de la silla. Extienda la pierna derecha recta hacia el lado con los dedos de los pies en el suelo. Levante el brazo izquierdo por encima de la cabeza e inclínese hacia la derecha, creando una línea larga desde la mano izquierda hasta la cadera izquierda. La mano derecha descansa sobre el muslo derecho o la silla. Concéntrese en el equilibrio y la longitud.",
            ja: "椅子の端に座ります。右脚をまっすぐ横に伸ばし、つま先を床につけます。左腕を頭上に上げて右に傾き、左手から左腰までの長い線を作ります。右手は右太ももか椅子の上に置きます。バランスと伸びに集中します。",
            zh: "坐在椅子边缘。将右腿向侧面伸直，脚趾触地。举起左臂过头顶，向右倾斜，从左手到左髋形成一条长线。右手放在右大腿或椅子上。专注于平衡和延伸。",
            ko: "의자 가장자리에 앉습니다. 오른쪽 다리를 옆으로 곧게 뻗어 발가락을 바닥에 댑니다. 왼팔을 머리 위로 올리고 오른쪽으로 기울여 왼손에서 왼쪽 골반까지 긴 선을 만듭니다. 오른손은 오른쪽 허벅지나 의자에 놓습니다. 균형과 길이에 집중하세요.",
            ru: "Сядьте на край стула. Вытяните правую ногу прямо в сторону, пальцы ног на полу. Поднимите левую руку над головой и наклонитесь вправо, создавая длинную линию от левой руки до левого бедра. Правая рука лежит на правом бедре или стуле. Сосредоточьтесь на равновесии и вытяжении.",
            de: "Setzen Sie sich an die Stuhlkante. Strecken Sie das rechte Bein gerade zur Seite, Zehen auf dem Boden. Heben Sie den linken Arm über den Kopf und neigen Sie sich nach rechts, sodass eine lange Linie von der linken Hand zur linken Hüfte entsteht. Die rechte Hand ruht auf dem rechten Oberschenkel oder dem Stuhl. Konzentrieren Sie sich auf Gleichgewicht und Länge.",
            ar: "اجلس على حافة الكرسي. مدّ ساقك اليمنى مستقيمة إلى الجانب مع وضع أصابع القدم على الأرض. ارفع ذراعك اليسرى فوق رأسك ومِل إلى اليمين، مكوّناً خطاً طويلاً من اليد اليسرى إلى الورك الأيسر. اليد اليمنى تستريح على الفخذ الأيمن أو الكرسي. ركّز على التوازن والاستطالة."
        ),
        durationSeconds: 30,
        difficulty: .advanced,
        category: .balance,
        imageName: "pose.seated.half.moon",
        voiceCueText: LocalizedString(
            en: "Extend your leg and reach overhead. Create one long line through your body. Find your balance.",
            fr: "Étendez la jambe et étirez-vous au-dessus de la tête. Créez une longue ligne à travers le corps. Trouvez votre équilibre.",
            es: "Extienda la pierna y estírese por encima de la cabeza. Cree una línea larga a través del cuerpo. Encuentre su equilibrio.",
            ja: "脚を伸ばして頭上に手を伸ばしましょう。体を通して一本の長い線を作ります。バランスを見つけてください。",
            zh: "伸展你的腿，向头顶上方伸手。通过身体创造一条长线。找到你的平衡。",
            ko: "다리를 뻗고 머리 위로 손을 뻗으세요. 몸을 통해 하나의 긴 선을 만드세요. 균형을 찾으세요.",
            ru: "Вытяните ногу и тянитесь над головой. Создайте одну длинную линию через тело. Найдите своё равновесие.",
            de: "Strecken Sie das Bein und greifen Sie über den Kopf. Erzeugen Sie eine lange Linie durch Ihren Körper. Finden Sie Ihr Gleichgewicht.",
            ar: "مدّ ساقك وامتد فوق رأسك. أنشئ خطاً طويلاً واحداً عبر جسمك. جِد توازنك."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the extended leg bent with foot on the floor",
                 "Hold the chair with the lower hand for stability"],
            fr: ["Gardez la jambe étendue pliée avec le pied au sol",
                 "Tenez la chaise avec la main du bas pour la stabilité"],
            es: ["Mantenga la pierna extendida doblada con el pie en el suelo",
                 "Sostenga la silla con la mano inferior para estabilidad"],
            ja: ["伸ばした脚を曲げて足を床につけたままにしてください",
                 "安定のために下の手で椅子を持ってください"],
            zh: ["将伸展的腿保持弯曲，脚放在地板上",
                 "用下方的手扶住椅子以保持稳定"],
            ko: ["뻗은 다리를 구부린 채 발을 바닥에 놓으세요",
                 "안정을 위해 아래쪽 손으로 의자를 잡으세요"],
            ru: ["Держите вытянутую ногу согнутой, стопой на полу",
                 "Держитесь нижней рукой за стул для устойчивости"],
            de: ["Halten Sie das gestreckte Bein gebeugt mit dem Fuß auf dem Boden",
                 "Halten Sie den Stuhl mit der unteren Hand für Stabilität"],
            ar: ["أبقِ الساق الممدودة مثنية مع القدم على الأرض",
                 "أمسك الكرسي باليد السفلية للثبات"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have severe balance issues without chair support"],
            fr: ["Évitez en cas de troubles graves de l'équilibre sans soutien de la chaise"],
            es: ["Evite si tiene problemas de equilibrio graves sin apoyo de la silla"],
            ja: ["椅子のサポートなしで重度のバランス障害がある場合は避けてください"],
            zh: ["如无椅子支撑且有严重平衡问题，请避免"],
            ko: ["의자 지지 없이 심각한 균형 문제가 있으면 피하세요"],
            ru: ["Избегайте при серьёзных проблемах с равновесием без опоры на стул"],
            de: ["Vermeiden Sie dies bei schweren Gleichgewichtsproblemen ohne Stuhlunterstützung"],
            ar: ["تجنب إذا كنت تعاني من مشاكل توازن حادة بدون دعم الكرسي"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady breaths to maintain balance — exhale to extend further",
            fr: "Respirations régulières pour maintenir l'équilibre — expirez pour vous étendre davantage",
            es: "Respiraciones constantes para mantener el equilibrio — exhale para extenderse más",
            ja: "バランスを保つための安定した呼吸 — 吐いてさらに伸ばす",
            zh: "平稳呼吸以保持平衡——呼气时进一步伸展",
            ko: "균형을 유지하기 위한 안정적인 호흡 — 날숨에 더 멀리 뻗으세요",
            ru: "Ровное дыхание для поддержания равновесия — выдох для дальнейшего вытяжения",
            de: "Gleichmäßige Atemzüge zur Aufrechterhaltung des Gleichgewichts — ausatmen um weiter zu strecken",
            ar: "أنفاس ثابتة للحفاظ على التوازن — ازفر للامتداد أبعد"
        ),
        isFree: true
    )

    // MARK: - Workout Plan Collections

    public static let chairYogaPlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "chair-gentle-flow",
            name: LocalizedString(
                en: "Gentle Chair Flow", fr: "Flux doux sur chaise",
                es: "Flujo suave en silla", ja: "やさしいチェアフロー", zh: "温和椅上流动",
                ko: "부드러운 체어 플로우", ru: "Мягкий поток на стуле", de: "Sanfter Stuhl-Fluss",
                ar: "تدفق لطيف على الكرسي", it: "Flusso dolce sulla sedia", pt: "Fluxo suave na cadeira"
            ),
            description: LocalizedString(
                en: "A gentle full-body warm-up perfect for beginners.", fr: "Un échauffement doux complet parfait pour les débutants.",
                es: "Un calentamiento suave de todo el cuerpo perfecto para principiantes.", ja: "初心者に最適な全身の優しいウォームアップ。", zh: "适合初学者的温和全身热身。",
                ko: "초보자에게 완벽한 부드러운 전신 워밍업.", ru: "Мягкая разминка всего тела, идеальная для начинающих.", de: "Ein sanftes Ganzkörper-Aufwärmen, perfekt für Anfänger.",
                ar: "إحماء لطيف لكامل الجسم مثالي للمبتدئين.", it: "Un riscaldamento dolce per tutto il corpo, perfetto per principianti.", pt: "Um aquecimento suave de corpo inteiro perfeito para iniciantes."
            ),
            style: .chairYoga,
            poses: [seatedMountain, neckRolls, shoulderRolls, seatedCatCow, seatedAnkleCircles, seatedWristStretches, seatedMeditation],
            transitionSeconds: 5,
            isFree: true
        ),
        WorkoutPlan(
            id: "chair-full-body",
            name: LocalizedString(
                en: "Full Body Chair Yoga", fr: "Yoga sur chaise complet",
                es: "Yoga en silla completo", ja: "全身チェアヨガ", zh: "全身椅上瑜伽",
                ko: "전신 체어 요가", ru: "Йога на стуле для всего тела", de: "Ganzkörper-Stuhl-Yoga",
                ar: "يوغا الكرسي لكامل الجسم", it: "Yoga sulla sedia per tutto il corpo", pt: "Yoga na cadeira para todo o corpo"
            ),
            description: LocalizedString(
                en: "A comprehensive session covering all major muscle groups.", fr: "Une séance complète couvrant tous les groupes musculaires.",
                es: "Una sesión completa que cubre todos los grupos musculares principales.", ja: "すべての主要な筋群をカバーする包括的なセッション。", zh: "涵盖所有主要肌肉群的综合课程。",
                ko: "모든 주요 근육군을 다루는 종합 세션.", ru: "Комплексное занятие, охватывающее все основные группы мышц.", de: "Eine umfassende Einheit, die alle wichtigen Muskelgruppen abdeckt.",
                ar: "جلسة شاملة تغطي جميع مجموعات العضلات الرئيسية.", it: "Una sessione completa che copre tutti i principali gruppi muscolari.", pt: "Uma sessão abrangente cobrindo todos os principais grupos musculares."
            ),
            style: .chairYoga,
            poses: [seatedMountain, seatedCatCow, seatedSpinalTwist, seatedForwardFold, seatedSideBend, seatedHeartOpener, seatedEagleArms, seatedMeditation],
            transitionSeconds: 5,
            isFree: true
        ),
        WorkoutPlan(
            id: "chair-energizer",
            name: LocalizedString(
                en: "Energizing Chair Flow", fr: "Flux énergisant sur chaise",
                es: "Flujo energizante en silla", ja: "エネルギーチェアフロー", zh: "活力椅上流动",
                ko: "활기찬 체어 플로우", ru: "Энергичный поток на стуле", de: "Energievoller Stuhl-Fluss",
                ar: "تدفق منشط على الكرسي", it: "Flusso energizzante sulla sedia", pt: "Fluxo energizante na cadeira"
            ),
            description: LocalizedString(
                en: "An uplifting sequence to boost energy and focus.", fr: "Une séquence revigorante pour augmenter l'énergie et la concentration.",
                es: "Una secuencia estimulante para aumentar la energía y la concentración.", ja: "エネルギーと集中力を高めるアップリフティングなシークエンス。", zh: "提升活力与专注力的振奋序列。",
                ko: "에너지와 집중력을 높이는 활기찬 시퀀스.", ru: "Бодрящая последовательность для повышения энергии и концентрации.", de: "Eine aufbauende Sequenz zur Steigerung von Energie und Fokus.",
                ar: "تسلسل منشط لتعزيز الطاقة والتركيز.", it: "Una sequenza stimolante per aumentare energia e concentrazione.", pt: "Uma sequência estimulante para aumentar energia e foco."
            ),
            style: .chairYoga,
            poses: [seatedMountain, seatedHighKneeLifts, seatedChestExpansion, seatedCrescentMoon, seatedGoddess, seatedBreathOfJoy, seatedMeditation],
            transitionSeconds: 4,
            isFree: true
        ),
        WorkoutPlan(
            id: "lower-back-relief",
            name: LocalizedString(
                en: "Lower Back Relief", fr: "Soulagement du bas du dos",
                es: "Alivio de la espalda baja", ja: "腰痛緩和", zh: "下背部舒缓",
                ko: "허리 통증 완화", ru: "Облегчение поясницы", de: "Linderung des unteren Rückens",
                ar: "تخفيف آلام أسفل الظهر", it: "Sollievo per la parte bassa della schiena", pt: "Alívio para a lombar"
            ),
            description: LocalizedString(
                en: "A soothing sequence focused on relieving tension in the lower back.",
                fr: "Une séquence apaisante axée sur le soulagement de la tension dans le bas du dos.",
                es: "Una secuencia calmante enfocada en aliviar la tensión en la parte baja de la espalda.",
                ja: "腰の緊張を和らげることに焦点を当てたリラックスシークエンス。",
                zh: "专注于缓解下背部紧张的舒缓序列。",
                ko: "허리 긴장 완화에 초점을 맞춘 편안한 시퀀스.",
                ru: "Успокаивающая последовательность для снятия напряжения в пояснице.",
                de: "Eine beruhigende Sequenz zur Linderung von Verspannungen im unteren Rücken.",
                ar: "تسلسل مهدئ يركز على تخفيف التوتر في أسفل الظهر.",
                it: "Una sequenza rilassante focalizzata sul sollievo della tensione nella parte bassa della schiena.",
                pt: "Uma sequência suave focada em aliviar a tensão na lombar."
            ),
            style: .chairYoga,
            poses: [seatedMountain, seatedCatCow, seatedSpinalTwist, seatedForwardFold, seatedSideBend, seatedThreadTheNeedle, seatedMeditation],
            transitionSeconds: 6,
            isFree: true
        ),
    ]

    public static let vinyasaPlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "seated-vinyasa-flow",
            name: LocalizedString(
                en: "Seated Vinyasa Flow", fr: "Flux vinyasa assis",
                es: "Flujo Vinyasa sentado", ja: "シーテッド・ヴィンヤサフロー", zh: "坐式流瑜伽",
                ko: "앉아서 하는 빈야사 플로우", ru: "Виньяса-флоу сидя", de: "Vinyasa-Fluss im Sitzen",
                ar: "تدفق فينياسا جالساً", it: "Flusso Vinyasa da seduti", pt: "Fluxo Vinyasa sentado"
            ),
            description: LocalizedString(
                en: "A flowing sequence linking breath with movement.", fr: "Une séquence fluide liant la respiration au mouvement.",
                es: "Una secuencia fluida que une la respiración con el movimiento.", ja: "呼吸と動きを結ぶ流れるようなシークエンス。", zh: "将呼吸与动作连贯的流动序列。",
                ko: "호흡과 움직임을 연결하는 유연한 시퀀스.", ru: "Текучая последовательность, связывающая дыхание с движением.", de: "Eine fließende Sequenz, die Atem mit Bewegung verbindet.",
                ar: "تسلسل متدفق يربط التنفس بالحركة.", it: "Una sequenza fluida che unisce respiro e movimento.", pt: "Uma sequência fluida que une respiração e movimento."
            ),
            style: .vinyasa,
            poses: [seatedMountain, seatedCatCow, seatedWarriorII, seatedReverseWarrior, seatedSideBend, seatedCrescentMoon, seatedForwardFold, seatedMeditation],
            transitionSeconds: 4,
            isFree: true
        ),
        WorkoutPlan(
            id: "seated-power-vinyasa",
            name: LocalizedString(
                en: "Power Vinyasa", fr: "Vinyasa dynamique",
                es: "Vinyasa poderoso", ja: "パワーヴィンヤサ", zh: "力量流瑜伽",
                ko: "파워 빈야사", ru: "Силовая виньяса", de: "Power-Vinyasa",
                ar: "فينياسا القوة", it: "Vinyasa Potente", pt: "Vinyasa de Poder"
            ),
            description: LocalizedString(
                en: "An intense seated flow building strength and heat.", fr: "Un flux assis intense développant force et chaleur.",
                es: "Un flujo intenso sentado que desarrolla fuerza y calor.", ja: "筋力と熱を作る激しいシーテッドフロー。", zh: "增强力量与热量的高强度坐式流动。",
                ko: "근력과 열을 만드는 강렬한 시티드 플로우.", ru: "Интенсивный сидячий поток для развития силы и тепла.", de: "Ein intensiver sitzender Fluss, der Kraft und Wärme aufbaut.",
                ar: "تدفق جالس مكثف يبني القوة والحرارة.", it: "Un flusso intenso da seduti che sviluppa forza e calore.", pt: "Um fluxo sentado intenso que desenvolve força e calor."
            ),
            style: .vinyasa,
            poses: [seatedSunSalutation, seatedWarriorII, seatedGoddess, seatedCrescentMoon, seatedReverseWarrior, seatedChestExpansion, seatedBreathOfJoy, seatedMeditation],
            transitionSeconds: 3,
            isFree: true
        ),
    ]

    public static let hathaPlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "hatha-chair-basics",
            name: LocalizedString(
                en: "Hatha Chair Basics", fr: "Hatha sur chaise — Bases",
                es: "Hatha en silla — Básico", ja: "ハタ・チェアヨガ基本", zh: "哈他椅上基础",
                ko: "하타 체어 요가 기초", ru: "Хатха на стуле — Основы", de: "Hatha-Stuhl-Grundlagen",
                ar: "هاذا على الكرسي — الأساسيات", it: "Hatha sulla sedia — Basi", pt: "Hatha na cadeira — Básico"
            ),
            description: LocalizedString(
                en: "Classic Hatha postures adapted for the chair.", fr: "Postures classiques de Hatha adaptées sur chaise.",
                es: "Posturas clásicas de Hatha adaptadas para la silla.", ja: "椅子用にアレンジされたクラシックなハタのポーズ。", zh: "为椅子改编的经典哈他体式。",
                ko: "의자에 맞게 개작된 클래식 하타 자세.", ru: "Классические позы хатхи, адаптированные для стула.", de: "Klassische Hatha-Positionen, angepasst für den Stuhl.",
                ar: "وضعيات هاذا الكلاسيكية معدلة للكرسي.", it: "Posizioni classiche Hatha adattate per la sedia.", pt: "Posturas clássicas de Hatha adaptadas para a cadeira."
            ),
            style: .hatha,
            poses: [seatedMountain, seatedCatCow, seatedSpinalTwist, seatedForwardFold, seatedSideBend, seatedExtendedSideBend, seatedHeartOpener, seatedTreePose, seatedMeditation],
            transitionSeconds: 5,
            isFree: true
        ),
        // Free starter for sparse kind coverage
        genericBuilder(
            id: "hatha-starter",
            kind: .hatha,
            name: LocalizedString(en: "Hatha Starter", fr: "Hatha — Démarrage"),
            description: LocalizedString(
                en: "A short seated Hatha intro: breath, spinal mobility, and stillness.",
                fr: "Courte intro Hatha assise : souffle, mobilité spinale et silence."
            ),
            poses: [seatedMountain, seatedCatCow, seatedForwardFold, seatedSpinalTwist, seatedMeditation]
        ),
    ]

    public static let yinPlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "yin-chair-holds",
            name: LocalizedString(
                en: "Yin Chair Holds", fr: "Postures Yin sur chaise",
                es: "Sostenimientos Yin en silla", ja: "イン・チェアホールド", zh: "阴椅保持",
                ko: "인 체어 홀드", ru: "Инь на стуле — Удержания", de: "Yin-Stuhl-Haltungen",
                ar: "وضعيات يِن على الكرسي", it: "Posizioni Yin sulla sedia", pt: "Posturas Yin na cadeira"
            ),
            description: LocalizedString(
                en: "Deep, long-held stretches for connective tissue release.", fr: "Étirements profonds et prolongés pour libérer les tissus conjonctifs.",
                es: "Estiramientos profundos y prolongados para liberar el tejido conjuntivo.", ja: "結合組織の解放のための深く長いストレッチ。", zh: "深度长时间伸展以释放结缔组织。",
                ko: "결합 조직 해소를 위한 깊고 긴 스트레칭.", ru: "Глубокие длительные растяжки для освобождения соединительной ткани.", de: "Tiefe, lang gehaltene Dehnungen zur Lösung des Bindegewebes.",
                ar: "تمددات عميقة وطويلة لتحرير الأنسجة الضامة.", it: "Allungamenti profondi e prolungati per il rilascio del tessuto connettivo.", pt: "Alongamentos profundos e prolongados para liberação do tecido conjuntivo."
            ),
            style: .yin,
            poses: [seatedForwardFold, seatedSpinalTwist, seatedPigeon, seatedAnklesToKnees, seatedThreadTheNeedle, seatedMeditation],
            transitionSeconds: 8,
            isFree: true
        ),
        genericBuilder(
            id: "yin-starter",
            kind: .yin,
            name: LocalizedString(en: "Yin Starter Holds", fr: "Yin — Maintiens de démarrage"),
            description: LocalizedString(
                en: "Gentle long holds to open hips and spine from the chair.",
                fr: "Maintiens doux et longs pour ouvrir hanches et colonne depuis la chaise."
            ),
            poses: [seatedForwardFold, seatedSpinalTwist, seatedAnklesToKnees, seatedMeditation],
            transitionSeconds: 8
        ),
    ]

    public static let restorativePlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "restorative-chair",
            name: LocalizedString(
                en: "Restorative Chair Session", fr: "Séance restaurative sur chaise",
                es: "Sesión restaurativa en silla", ja: "リストラティブ・チェアセッション", zh: "修复椅上课程",
                ko: "리스토러티브 체어 세션", ru: "Восстановительное занятие на стуле", de: "Restorative Stuhl-Sitzung",
                ar: "جلسة استشفائية على الكرسي", it: "Sessione restaurativa sulla sedia", pt: "Sessão restaurativa na cadeira"
            ),
            description: LocalizedString(
                en: "Gentle, supported poses for deep relaxation.", fr: "Postures douces et soutenues pour une relaxation profonde.",
                es: "Posturas suaves y apoyadas para una relajación profunda.", ja: "深いリラクゼーションのための優しくサポートされたポーズ。", zh: "温和、有支撑的体式，用于深度放松。",
                ko: "깊은 이완을 위한 부드럽고 지지된 자세.", ru: "Мягкие, поддерживаемые позы для глубокого расслабления.", de: "Sanfte, gestützte Positionen für tiefe Entspannung.",
                ar: "وضعيات لطيفة ومدعومة للاسترخاء العميق.", it: "Posizioni dolci e sostenute per un rilassamento profondo.", pt: "Posturas suaves e apoiadas para relaxamento profundo."
            ),
            style: .restorative,
            poses: [seatedMountain, neckRolls, shoulderRolls, seatedForwardFold, seatedThreadTheNeedle, seatedMeditation],
            transitionSeconds: 8,
            isFree: true
        ),
        WorkoutPlan(
            id: "restorative-evening-wind-down",
            name: LocalizedString(
                en: "Evening Wind Down", fr: "Décompression du soir",
                es: "Descompresión nocturna", ja: "イブニング・ワインドダウン", zh: "晚间放松",
                ko: "저녁 마무리", ru: "Вечерняя релаксация", de: "Abendlicher Rückzug",
                ar: "الاسترخاء المسائي", it: "Relax serale", pt: "Descompressão noturna"
            ),
            description: LocalizedString(
                en: "A calming sequence to prepare for restful sleep.", fr: "Une séquence apaisante pour préparer un sommeil réparateur.",
                es: "Una secuencia calmante para preparar un sueño reparador.", ja: "安眠のためのリラックスシークエンス。", zh: "助眠的平静序列。",
                ko: "편안한 수면을 준비하는 차분한 시퀀스.", ru: "Успокаивающая последовательность для подготовки к крепкому сну.", de: "Eine beruhigende Sequenz zur Vorbereitung auf erholsamen Schlaf.",
                ar: "تسلسل مهدئ للتحضير لنوم مريح.", it: "Una sequenza calmante per preparare un sonno ristoratore.", pt: "Uma sequência calmante para preparar um sono reparador."
            ),
            style: .restorative,
            poses: [seatedMountain, seatedCatCow, seatedSpinalTwist, seatedPigeon, seatedAnklesToKnees, seatedForwardFold, seatedMeditation],
            transitionSeconds: 10,
            isFree: true
        ),
    ]

    public static let powerPlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "power-chair-strength",
            name: LocalizedString(
                en: "Power Chair Strength", fr: "Force et puissance sur chaise",
                es: "Fuerza y potencia en silla", ja: "パワー・チェアストレングス", zh: "力量椅上强化",
                ko: "파워 체어 스트렝스", ru: "Сила и мощь на стуле", de: "Kraftvolles Stuhl-Training",
                ar: "القوة على الكرسي", it: "Forza e potenza sulla sedia", pt: "Força e poder na cadeira"
            ),
            description: LocalizedString(
                en: "Build strength and endurance with challenging seated poses.", fr: "Développez force et endurance avec des postures assises stimulantes.",
                es: "Desarrolle fuerza y resistencia con posturas sentadas desafiantes.", ja: "挑戦的なシーテッドポーズで筋力と持久力を構築。", zh: "通过有挑战性的坐式体式增强力量与耐力。",
                ko: "도전적인 앉은 자세로 근력과 지구력을 기르세요.", ru: "Развивайте силу и выносливость с помощью сложных сидячих поз.", de: "Aufbau von Kraft und Ausdauer mit anspruchsvollen Sitz-Positionen.",
                ar: "بناء القوة والتحمل بوضعيات جلوس تحفيزية.", it: "Sviluppa forza e resistenza con posizioni sedute stimolanti.", pt: "Desenvolva força e resistência com posturas sentadas desafiadoras."
            ),
            style: .power,
            poses: [seatedSunSalutation, seatedWarriorII, seatedGoddess, seatedHighKneeLifts, seatedChestExpansion, seatedHalfMoon, seatedBreathOfJoy],
            transitionSeconds: 3,
            isFree: true
        ),
        // Free starter — sparse kind was single-plan only
        genericBuilder(
            id: "power-starter",
            kind: .power,
            name: LocalizedString(en: "Power Starter Blast", fr: "Power — Départ explosif"),
            description: LocalizedString(
                en: "A short free power burst: heat, legs, and breath of joy.",
                fr: "Courte salve power gratuite : chaleur, jambes et souffle de joie."
            ),
            poses: [seatedMountain, seatedHighKneeLifts, seatedWarriorII, seatedBreathOfJoy, seatedMeditation],
            transitionSeconds: 3
        ),
    ]

    public static let standingBalancePlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "balance-stability",
            name: LocalizedString(
                en: "Balance & Stability", fr: "Équilibre et stabilité",
                es: "Equilibrio y estabilidad", ja: "バランス＆スタビリティ", zh: "平衡与稳定",
                ko: "균형과 안정성", ru: "Равновесие и стабильность", de: "Balance & Stabilität",
                ar: "التوازن والثبات", it: "Equilibrio e stabilità", pt: "Equilíbrio e estabilidade"
            ),
            description: LocalizedString(
                en: "Improve balance and proprioception from a seated base.", fr: "Améliorez l'équilibre et la proprioception depuis une base assise.",
                es: "Mejore el equilibrio y la propiocepción desde una base sentada.", ja: "座位からバランスと固有感覚を向上させましょう。", zh: "从坐姿基础改善平衡与本体感觉。",
                ko: "앉은 자세에서 균형과 고유수용감각을 향상시키세요.", ru: "Улучшите равновесие и проприоцепцию из сидячего положения.", de: "Verbessern Sie Balance und Propriozeption aus sitzender Basis.",
                ar: "حسّن التوازن والإحساس العميق من وضعية الجلوس.", it: "Migliora equilibrio e propriocettività da una base seduta.", pt: "Melhore o equilíbrio e a propriocepção a partir de uma base sentada."
            ),
            style: .standingBalance,
            poses: [seatedMountain, seatedTreePose, seatedHighKneeLifts, seatedEagleArms, seatedHalfMoon, seatedMeditation],
            transitionSeconds: 5,
            isFree: true
        ),
        genericBuilder(
            id: "standing-balance-starter",
            kind: .standingBalance,
            name: LocalizedString(en: "Balance Starter", fr: "Équilibre — Démarrage"),
            description: LocalizedString(
                en: "Seated stability drills to wake up ankles, core, and focus.",
                fr: "Exercices de stabilité assis pour réveiller chevilles, centre et focus."
            ),
            poses: [seatedMountain, seatedAnkleCircles, seatedTreePose, seatedHighKneeLifts, seatedMeditation]
        ),
    ]

    public static let prenatalPlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "prenatal-gentle",
            name: LocalizedString(
                en: "Prenatal Gentle Flow", fr: "Flux prénatal doux",
                es: "Flujo prenatal suave", ja: "プレナタル・ジェントルフロー", zh: "孕期温和流动",
                ko: "산전 부드러운 플로우", ru: "Мягкий пренатальный поток", de: "Sanfter pränataler Fluss",
                ar: "تدفق لطيف قبل الولادة", it: "Flusso prenatale dolce", pt: "Fluxo suave pré-natal"
            ),
            description: LocalizedString(
                en: "Safe, gentle movements for expectant mothers.", fr: "Mouvements doux et sécuritaires pour les futures mamans.",
                es: "Movimientos seguros y suaves para futuras mamás.", ja: "妊婦向けの安全で優しい動き。", zh: "为准妈妈设计的安全温和动作。",
                ko: "임산부를 위한 안전하고 부드러운 움직임.", ru: "Безопасные, мягкие движения для будущих мам.", de: "Sichere, sanfte Bewegungen für werdende Mütter.",
                ar: "حركات آمنة ولطيفة للأمهات الحوامل.", it: "Movimenti sicuri e dolci per le future mamme.", pt: "Movimentos seguros e suaves para gestantes."
            ),
            style: .prenatal,
            poses: [seatedMountain, seatedCatCow, neckRolls, shoulderRolls, seatedSideBend, seatedAnkleCircles, seatedMeditation],
            transitionSeconds: 6,
            isFree: true
        ),
        genericBuilder(
            id: "prenatal-starter",
            kind: .prenatal,
            name: LocalizedString(en: "Prenatal Starter Comfort", fr: "Prénatal — Confort de démarrage"),
            description: LocalizedString(
                en: "Very gentle free sequence for comfort, breath, and circulation.",
                fr: "Séquence gratuite très douce pour le confort, le souffle et la circulation."
            ),
            poses: [seatedMountain, neckRolls, shoulderRolls, seatedCatCow, seatedAnkleCircles, seatedMeditation],
            transitionSeconds: 6
        ),
    ]

    public static let pranayamaPlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "breath-meditation",
            name: LocalizedString(
                en: "Breath & Meditation", fr: "Respiration et méditation",
                es: "Respiración y meditación", ja: "呼吸とメディテーション", zh: "呼吸与冥想",
                ko: "호흡과 명상", ru: "Дыхание и медитация", de: "Atem & Meditation",
                ar: "التنفس والتأمل", it: "Respiro e meditazione", pt: "Respiração e meditação"
            ),
            description: LocalizedString(
                en: "Focused breathing techniques and guided meditation.", fr: "Techniques de respiration focalisée et méditation guidée.",
                es: "Técnicas de respiración enfocada y meditación guiada.", ja: "集中した呼吸法とガイド付き瞑想。", zh: "专注呼吸技巧与引导冥想。",
                ko: "집중 호흡 기법과 가이드 명상.", ru: "Техники концентрированного дыхания и управляемая медитация.", de: "Fokussierte Atemtechniken und geführte Meditation.",
                ar: "تقنيات تنفس مركزة وتأمل موجه.", it: "Tecniche di respirazione focalizzata e meditazione guidata.", pt: "Técnicas de respiração focada e meditação guiada."
            ),
            style: .pranayama,
            poses: [seatedMountain, seatedCatCow, seatedSpinalTwist, seatedMeditation],
            transitionSeconds: 6,
            isFree: true
        ),
        genericBuilder(
            id: "pranayama-starter",
            kind: .pranayama,
            name: LocalizedString(en: "Breath Starter", fr: "Respiration — Démarrage"),
            description: LocalizedString(
                en: "A short free pranayama settle: posture, breath, and stillness.",
                fr: "Courte assise pranayama gratuite : posture, souffle et silence."
            ),
            poses: [seatedMountain, seatedCatCow, seatedMeditation],
            transitionSeconds: 6
        ),
    ]

    // MARK: - Non-yoga sample plans (reuse pose catalog as movement blocks)

    public static let matYogaPlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "mat-foundations",
            name: LocalizedString(
                en: "Mat Foundations", fr: "Fondations sur tapis",
                es: "Fundamentos en esterilla", ja: "マット基礎", zh: "垫上基础",
                ko: "매트 기초", ru: "Основы на коврике", de: "Matten-Grundlagen",
                ar: "أساسيات السجادة", it: "Fondamenta sul tappetino", pt: "Fundamentos no tapete"
            ),
            description: LocalizedString(
                en: "A grounded mat sequence blending breath, stretch, and gentle strength.", fr: "Une séquence au sol mêlant respiration, étirement et force douce."
            ),
            style: .matYoga,
            poses: [seatedMountain, seatedCatCow, seatedForwardFold, seatedSideBend, seatedWarriorII, seatedMeditation],
            transitionSeconds: 5,
            isFree: true
        ),
        genericBuilder(
            id: "mat-starter",
            kind: .matYoga,
            name: LocalizedString(en: "Mat Starter Flow", fr: "Tapis — Flux de démarrage"),
            description: LocalizedString(
                en: "Free short mat-style sequence for breath and stretch.",
                fr: "Courte séquence gratuite style tapis pour souffle et étirement."
            ),
            poses: [seatedMountain, seatedCatCow, seatedForwardFold, seatedMeditation]
        ),
    ]

    public static let strengthPlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "strength-chair-power",
            name: LocalizedString(
                en: "Chair Strength Circuit", fr: "Circuit de force sur chaise",
                es: "Circuito de fuerza en silla", ja: "チェア・ストレングス", zh: "椅上力量循环",
                ko: "체어 스트렝스 서킷", ru: "Силовой круг на стуле", de: "Stuhl-Kraftzirkel",
                ar: "دائرة قوة على الكرسي", it: "Circuito di forza in sedia", pt: "Circuito de força na cadeira"
            ),
            description: LocalizedString(
                en: "Seated strength blocks for legs, core, and upper body.", fr: "Blocs de force assis pour jambes, centre et haut du corps."
            ),
            style: .strength,
            poses: [seatedHighKneeLifts, seatedWarriorII, seatedGoddess, seatedChestExpansion, seatedBreathOfJoy, seatedMountain],
            transitionSeconds: 4,
            isFree: true
        ),
        genericBuilder(
            id: "strength-starter",
            kind: .strength,
            name: LocalizedString(en: "Strength Starter", fr: "Force — Démarrage"),
            description: LocalizedString(
                en: "Free intro circuit for seated strength and posture.",
                fr: "Circuit d'intro gratuit pour force assise et posture."
            ),
            poses: [seatedMountain, seatedHighKneeLifts, seatedGoddess, seatedChestExpansion],
            transitionSeconds: 4
        ),
    ]

    public static let cardioPlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "cardio-seated-intervals",
            name: LocalizedString(
                en: "Seated Cardio Intervals", fr: "Intervalles cardio assis",
                es: "Intervalos cardio sentados", ja: "シーテッド・カーディオ", zh: "坐姿有氧间歇",
                ko: "앉은 유산소 인터벌", ru: "Сидячие кардио-интервалы", de: "Sitzende Cardio-Intervalle",
                ar: "فترات كارديو جلوساً", it: "Intervalli cardio da seduti", pt: "Intervalos cardio sentados"
            ),
            description: LocalizedString(
                en: "Short elevated-effort intervals with recovery breaths.", fr: "Courts intervalles d'effort avec respirations de récupération."
            ),
            style: .cardio,
            poses: [seatedBreathOfJoy, seatedHighKneeLifts, seatedSunSalutation, seatedReverseWarrior, seatedMeditation],
            transitionSeconds: 3,
            isFree: true
        ),
        genericBuilder(
            id: "cardio-starter",
            kind: .cardio,
            name: LocalizedString(en: "Cardio Starter", fr: "Cardio — Démarrage"),
            description: LocalizedString(
                en: "Free short seated intervals to raise heart rate gently.",
                fr: "Courts intervalles assis gratuits pour élever le rythme en douceur."
            ),
            poses: [seatedBreathOfJoy, seatedHighKneeLifts, seatedMeditation],
            transitionSeconds: 3
        ),
    ]

    public static let mobilityPlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "mobility-daily-reset",
            name: LocalizedString(
                en: "Daily Mobility Reset", fr: "Reset mobilité quotidien",
                es: "Reinicio de movilidad diario", ja: "デイリー・モビリティ", zh: "每日活动度重置",
                ko: "데일리 모빌리티 리셋", ru: "Ежедневный сброс мобильности", de: "Täglicher Mobilitäts-Reset",
                ar: "إعادة ضبط الحركية اليومية", it: "Reset mobilità quotidiano", pt: "Reset diário de mobilidade"
            ),
            description: LocalizedString(
                en: "Joint-friendly mobility for neck, shoulders, spine, and hips.", fr: "Mobilité articulaire pour cou, épaules, colonne et hanches."
            ),
            style: .mobility,
            poses: [neckRolls, shoulderRolls, seatedCatCow, seatedSpinalTwist, seatedAnkleCircles, seatedWristStretches, seatedAnklesToKnees],
            transitionSeconds: 5,
            isFree: true
        ),
        genericBuilder(
            id: "mobility-starter",
            kind: .mobility,
            name: LocalizedString(en: "Mobility Starter", fr: "Mobilité — Démarrage"),
            description: LocalizedString(
                en: "Free joint warm-up for neck, shoulders, and spine.",
                fr: "Échauffement articulaire gratuit pour cou, épaules et colonne."
            ),
            poses: [neckRolls, shoulderRolls, seatedCatCow, seatedWristStretches, seatedAnkleCircles]
        ),
    ]

    public static let meditationPlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "meditation-stillness",
            name: LocalizedString(
                en: "Stillness Practice", fr: "Pratique du silence",
                es: "Práctica de quietud", ja: "静寂のプラクティス", zh: "静心练习",
                ko: "고요함 수련", ru: "Практика тишины", de: "Stille-Praxis",
                ar: "ممارسة السكون", it: "Pratica della quiete", pt: "Prática de quietude"
            ),
            description: LocalizedString(
                en: "Breath-led stillness with light postural anchors.", fr: "Silence guidé par le souffle avec ancrages posturaux légers."
            ),
            style: .meditation,
            poses: [seatedMountain, seatedCatCow, seatedMeditation, seatedForwardFold, seatedMeditation],
            transitionSeconds: 8,
            isFree: true
        ),
        genericBuilder(
            id: "meditation-starter",
            kind: .meditation,
            name: LocalizedString(en: "Meditation Starter", fr: "Méditation — Démarrage"),
            description: LocalizedString(
                en: "Free short settle into breath and stillness.",
                fr: "Courte assise gratuite pour le souffle et le silence."
            ),
            poses: [seatedMountain, seatedMeditation],
            transitionSeconds: 8
        ),
    ]

    public static let generalPlans: [WorkoutPlan] = [
        WorkoutPlan(
            id: "general-full-body",
            name: LocalizedString(
                en: "Full-Body Reset", fr: "Reset corps entier",
                es: "Reinicio de cuerpo completo", ja: "全身リセット", zh: "全身重置",
                ko: "전신 리셋", ru: "Полный сброс тела", de: "Ganzkörper-Reset",
                ar: "إعادة ضبط الجسم بالكامل", it: "Reset a corpo intero", pt: "Reset de corpo inteiro"
            ),
            description: LocalizedString(
                en: "A balanced mix of mobility, strength, and calm for any day.", fr: "Un mélange équilibré de mobilité, force et calme pour chaque jour."
            ),
            style: .general,
            poses: [seatedMountain, neckRolls, seatedCatCow, seatedHighKneeLifts, seatedSideBend, seatedMeditation],
            transitionSeconds: 5,
            isFree: true
        ),
        genericBuilder(
            id: "general-starter",
            kind: .general,
            name: LocalizedString(en: "General Starter", fr: "Général — Démarrage"),
            description: LocalizedString(
                en: "Free all-purpose short session for any day.",
                fr: "Courte séance gratuite polyvalente pour chaque jour."
            )
        ),
    ]

    /// Default beginner chair yoga plan
    public static var beginnerFlow: WorkoutPlan {
        chairYogaPlans.first ?? WorkoutPlan(
            id: "beginner-flow",
            name: LocalizedString(
                en: "Beginner Flow", fr: "Flux débutant",
                es: "Flujo para principiantes", ja: "ビギナーフロー", zh: "初学者流动",
                ko: "초보자 플로우", ru: "Поток для начинающих", de: "Anfänger-Fluss",
                ar: "تدفق للمبتدئين", it: "Flusso per principianti", pt: "Fluxo para iniciantes"
            ),
            description: LocalizedString(
                en: "Gentle introduction to chair yoga", fr: "Introduction douce au yoga sur chaise",
                es: "Introducción suave al yoga en silla", ja: "チェアヨガへの優しい入門。", zh: "椅上瑜伽温和入门。",
                ko: "체어 요가에 대한 부드러운 입문", ru: "Мягкое введение в йогу на стуле", de: "Sanfte Einführung in Stuhl-Yoga",
                ar: "مقدمة لطيفة ليوغا الكرسي", it: "Dolce introduzione allo yoga sulla sedia", pt: "Introdução suave ao yoga na cadeira"
            ),
            style: .chairYoga,
            poses: [seatedMountain, neckRolls, shoulderRolls, seatedCatCow, seatedAnkleCircles, seatedWristStretches, seatedMeditation],
            transitionSeconds: 5,
            isFree: true
        )
    }

    // MARK: - Pose Collections

    public static let allPoses: [Pose] = [
        // Beginner (Free)
        seatedMountain,
        seatedCatCow,
        seatedSpinalTwist,
        seatedForwardFold,
        neckRolls,
        shoulderRolls,
        seatedAnkleCircles,
        seatedWristStretches,
        seatedHighKneeLifts,
        seatedMeditation,
        // Intermediate (Premium)
        seatedEagleArms,
        seatedPigeon,
        seatedWarriorII,
        seatedSideBend,
        seatedHeartOpener,
        seatedAnklesToKnees,
        seatedExtendedSideBend,
        seatedGoddess,
        seatedReverseWarrior,
        seatedCrescentMoon,
        seatedChestExpansion,
        // Advanced (Premium)
        seatedSunSalutation,
        seatedTreePose,
        seatedThreadTheNeedle,
        seatedBreathOfJoy,
        seatedHalfMoon,
    ]

    public static let freePoses: [Pose] = allPoses.filter(\.isFree)
    public static let premiumPoses: [Pose] = allPoses.filter { !$0.isFree }

    /// Returns all workout plans for a given style / kind.
    public static func plans(for style: YogaStyle) -> [WorkoutPlan] {
        switch style {
        case .chairYoga:       return chairYogaPlans
        case .matYoga:         return matYogaPlans
        case .vinyasa:         return vinyasaPlans
        case .hatha:           return hathaPlans
        case .yin:             return yinPlans
        case .restorative:     return restorativePlans
        case .power:           return powerPlans
        case .standingBalance: return standingBalancePlans
        case .prenatal:        return prenatalPlans
        case .pranayama:       return pranayamaPlans
        case .strength:        return strengthPlans
        case .cardio:          return cardioPlans
        case .mobility:        return mobilityPlans
        case .meditation:      return meditationPlans
        case .general:         return generalPlans
        }
    }

    /// All workout plans across every style / kind.
    public static let allPlans: [WorkoutPlan] = {
        YogaStyle.allCases.flatMap { plans(for: $0) }
    }()

    /// Number of plans for a given style / kind.
    public static func planCount(for style: YogaStyle) -> Int {
        plans(for: style).count
    }

    /// Build a lightweight free plan for any kind using common free poses.
    public static func genericBuilder(
        id: String,
        kind: WorkoutKind,
        name: LocalizedString,
        description: LocalizedString,
        poses: [Pose]? = nil,
        transitionSeconds: TimeInterval = 5
    ) -> WorkoutPlan {
        let blocks = poses ?? [seatedMountain, neckRolls, seatedCatCow, seatedMeditation]
        return WorkoutPlan(
            id: id,
            name: name,
            description: description,
            style: kind,
            poses: blocks,
            transitionSeconds: transitionSeconds,
            isFree: true
        )
    }
}
