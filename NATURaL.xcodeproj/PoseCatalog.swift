import Foundation

/// Central catalog of yoga poses and workout plans.
public enum PoseCatalog {
    
    // MARK: - Sample Poses
    
    public static let seatedCatCow = YogaPose(
        name: LocalizedString(en: "Seated Cat-Cow", fr: "Chat-Vache assis"),
        durationSeconds: 60,
        category: .seated,
        instructions: LocalizedString(
            en: "Flow between arching and rounding your spine",
            fr: "Alternez entre arquer et arrondir votre colonne vertébrale"
        ),
        difficulty: .beginner,
        breathingPattern: .alternate
    )
    
    public static let mountainPose = YogaPose(
        name: LocalizedString(en: "Mountain Pose", fr: "Posture de la montagne"),
        durationSeconds: 30,
        category: .standing,
        instructions: LocalizedString(
            en: "Stand tall with feet together, arms at sides",
            fr: "Tenez-vous droit, pieds joints, bras le long du corps"
        ),
        difficulty: .beginner,
        breathingPattern: .continuous
    )
    
    public static let childsPose = YogaPose(
        name: LocalizedString(en: "Child's Pose", fr: "Posture de l'enfant"),
        durationSeconds: 90,
        category: .prone,
        instructions: LocalizedString(
            en: "Kneel and fold forward, arms extended or at sides",
            fr: "Agenouillez-vous et penchez-vous, bras étendus ou sur les côtés"
        ),
        difficulty: .beginner,
        breathingPattern: .continuous
    )
    
    public static let downwardDog = YogaPose(
        name: LocalizedString(en: "Downward Dog", fr: "Chien tête en bas"),
        durationSeconds: 45,
        category: .inverted,
        instructions: LocalizedString(
            en: "Form an inverted V-shape with your body",
            fr: "Formez un V inversé avec votre corps"
        ),
        difficulty: .beginner,
        breathingPattern: .continuous
    )
    
    public static let warriorI = YogaPose(
        name: LocalizedString(en: "Warrior I", fr: "Guerrier I"),
        durationSeconds: 30,
        category: .standing,
        instructions: LocalizedString(
            en: "Lunge forward with arms raised overhead",
            fr: "Fente avant avec les bras levés au-dessus de la tête"
        ),
        difficulty: .intermediate,
        breathingPattern: .continuous
    )
    
    public static let warriorII = YogaPose(
        name: LocalizedString(en: "Warrior II", fr: "Guerrier II"),
        durationSeconds: 30,
        category: .standing,
        instructions: LocalizedString(
            en: "Wide stance with arms extended, gaze over front hand",
            fr: "Position large avec bras étendus, regard vers la main avant"
        ),
        difficulty: .intermediate,
        breathingPattern: .continuous
    )
    
    public static let treePose = YogaPose(
        name: LocalizedString(en: "Tree Pose", fr: "Posture de l'arbre"),
        durationSeconds: 40,
        category: .balancing,
        instructions: LocalizedString(
            en: "Balance on one leg with foot on inner thigh",
            fr: "Équilibrez-vous sur une jambe avec le pied sur la cuisse intérieure"
        ),
        difficulty: .intermediate,
        breathingPattern: .continuous
    )
    
    public static let seatedForwardBend = YogaPose(
        name: LocalizedString(en: "Seated Forward Bend", fr: "Flexion avant assise"),
        durationSeconds: 60,
        category: .seated,
        instructions: LocalizedString(
            en: "Fold forward over extended legs",
            fr: "Penchez-vous vers l'avant sur les jambes étendues"
        ),
        difficulty: .beginner,
        breathingPattern: .continuous
    )
    
    public static let corpse = YogaPose(
        name: LocalizedString(en: "Corpse Pose (Savasana)", fr: "Posture du cadavre (Savasana)"),
        durationSeconds: 120,
        category: .supine,
        instructions: LocalizedString(
            en: "Lie flat on your back, arms at sides, palms up",
            fr: "Allongez-vous à plat sur le dos, bras sur les côtés, paumes vers le haut"
        ),
        difficulty: .beginner,
        breathingPattern: .continuous
    )
    
    public static let deepBreathing = YogaPose(
        name: LocalizedString(en: "Deep Breathing", fr: "Respiration profonde"),
        durationSeconds: 60,
        category: .breathing,
        instructions: LocalizedString(
            en: "Breathe deeply and slowly through your nose",
            fr: "Respirez profondément et lentement par le nez"
        ),
        difficulty: .beginner,
        breathingPattern: .continuous
    )
    
    public static let cobrapose = YogaPose(
        name: LocalizedString(en: "Cobra Pose", fr: "Posture du cobra"),
        durationSeconds: 30,
        category: .prone,
        instructions: LocalizedString(
            en: "Lift chest off the ground with hands under shoulders",
            fr: "Soulevez la poitrine du sol avec les mains sous les épaules"
        ),
        difficulty: .beginner,
        breathingPattern: .inhale
    )
    
    public static let bridgePose = YogaPose(
        name: LocalizedString(en: "Bridge Pose", fr: "Posture du pont"),
        durationSeconds: 45,
        category: .supine,
        instructions: LocalizedString(
            en: "Lift hips while lying on your back, feet flat",
            fr: "Soulevez les hanches en étant allongé sur le dos, pieds à plat"
        ),
        difficulty: .beginner,
        breathingPattern: .continuous
    )
    
    // MARK: - Workout Plans
    
    public static let beginnerFlow = WorkoutPlan(
        name: LocalizedString(en: "Gentle Beginner Flow", fr: "Flux doux pour débutants"),
        description: LocalizedString(
            en: "A gentle introduction to yoga with basic poses and breathing",
            fr: "Une introduction douce au yoga avec des postures de base et la respiration"
        ),
        style: .hatha,
        poses: [
            deepBreathing,
            mountainPose,
            seatedCatCow,
            childsPose,
            corpse
        ],
        isFree: true
    )
    
    public static let morningEnergizer = WorkoutPlan(
        name: LocalizedString(en: "Morning Energizer", fr: "Énergisant matinal"),
        description: LocalizedString(
            en: "Wake up your body with flowing movements and sun salutations",
            fr: "Réveillez votre corps avec des mouvements fluides et des salutations au soleil"
        ),
        style: .vinyasa,
        poses: [
            mountainPose,
            downwardDog,
            cobrapose,
            downwardDog,
            mountainPose,
            childsPose
        ],
        isFree: true
    )
    
    public static let relaxationFlow = WorkoutPlan(
        name: LocalizedString(en: "Evening Relaxation", fr: "Relaxation du soir"),
        description: LocalizedString(
            en: "Gentle stretches and calming poses to wind down your day",
            fr: "Étirements doux et postures calmantes pour terminer votre journée"
        ),
        style: .restorative,
        poses: [
            seatedForwardBend,
            childsPose,
            bridgePose,
            corpse
        ],
        isFree: true
    )
    
    public static let balanceFocus = WorkoutPlan(
        name: LocalizedString(en: "Balance & Stability", fr: "Équilibre et stabilité"),
        description: LocalizedString(
            en: "Build strength and focus with balancing poses",
            fr: "Développez la force et la concentration avec des postures d'équilibre"
        ),
        style: .standingBalance,
        poses: [
            mountainPose,
            treePose,
            warriorI,
            warriorII,
            treePose,
            childsPose
        ],
        isFree: false
    )
    
    public static let strengthBuilder = WorkoutPlan(
        name: LocalizedString(en: "Strength Builder", fr: "Développement de force"),
        description: LocalizedString(
            en: "Dynamic flow to build muscle strength and endurance",
            fr: "Flux dynamique pour développer la force musculaire et l'endurance"
        ),
        style: .power,
        poses: [
            mountainPose,
            downwardDog,
            warriorI,
            warriorII,
            downwardDog,
            cobrapose,
            childsPose,
            corpse
        ],
        isFree: false
    )
    
    public static let chairYogaSession = WorkoutPlan(
        name: LocalizedString(en: "Gentle Chair Yoga", fr: "Yoga doux sur chaise"),
        description: LocalizedString(
            en: "Accessible yoga practice from the comfort of a chair",
            fr: "Pratique de yoga accessible depuis le confort d'une chaise"
        ),
        style: .chairYoga,
        poses: [
            seatedCatCow,
            seatedForwardBend,
            seatedCatCow
        ],
        isFree: true
    )
    
    public static let pranayamaSession = WorkoutPlan(
        name: LocalizedString(en: "Breathing Practice", fr: "Pratique de la respiration"),
        description: LocalizedString(
            en: "Focus on breath control and mindful breathing techniques",
            fr: "Concentrez-vous sur le contrôle de la respiration et les techniques de respiration consciente"
        ),
        style: .pranayama,
        poses: [
            deepBreathing,
            seatedCatCow,
            deepBreathing
        ],
        isFree: true
    )
    
    public static let yinSession = WorkoutPlan(
        name: LocalizedString(en: "Yin Deep Stretch", fr: "Étirement profond Yin"),
        description: LocalizedString(
            en: "Hold poses longer for deep connective tissue work",
            fr: "Maintenez les postures plus longtemps pour un travail profond des tissus conjonctifs"
        ),
        style: .yin,
        poses: [
            seatedForwardBend,
            childsPose,
            bridgePose,
            corpse
        ],
        isFree: false
    )
    
    // MARK: - Catalog Helpers
    
    /// All available workout plans.
    public static let allPlans: [WorkoutPlan] = [
        beginnerFlow,
        morningEnergizer,
        relaxationFlow,
        balanceFocus,
        strengthBuilder,
        chairYogaSession,
        pranayamaSession,
        yinSession
    ]
    
    /// Get all plans for a specific style.
    public static func plans(for style: YogaStyle) -> [WorkoutPlan] {
        allPlans.filter { $0.style == style }
    }
    
    /// Get the count of plans for a specific style.
    public static func planCount(for style: YogaStyle) -> Int {
        plans(for: style).count
    }
    
    /// Get a plan by ID.
    public static func plan(withID id: UUID) -> WorkoutPlan? {
        allPlans.first { $0.id == id }
    }
}
