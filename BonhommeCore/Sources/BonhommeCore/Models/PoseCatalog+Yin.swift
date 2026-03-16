import Foundation

// MARK: - Yin Yoga Poses & Plans

extension PoseCatalog {

    // MARK: - Beginner Poses (Free)

    public static let yinButterfly = Pose(
        id: "yin-butterfly",
        name: LocalizedString(
            en: "Butterfly",
            fr: "Papillon"
        ),
        description: LocalizedString(
            en: "Bring the soles of your feet together and slide them forward away from your hips, creating a diamond shape with your legs. Allow your spine to gently round as you fold forward, letting gravity draw your head toward your feet. Release all muscular effort and surrender into the stretch through your inner thighs and lower back.",
            fr: "Joignez les plantes de vos pieds ensemble et glissez-les vers l'avant, loin de vos hanches, en formant un losange avec vos jambes. Laissez votre colonne s'arrondir doucement en vous penchant vers l'avant, permettant à la gravité d'attirer votre tête vers vos pieds. Relâchez tout effort musculaire et abandonnez-vous dans l'étirement à travers l'intérieur des cuisses et le bas du dos."
        ),
        durationSeconds: 90,
        difficulty: .beginner,
        category: .hips,
        position: .seated,
        imageName: "pose.yin.butterfly",
        voiceCueText: LocalizedString(
            en: "Fold forward softly into Butterfly. Let gravity do the work. Breathe into your hips and inner thighs.",
            fr: "Penchez-vous doucement vers l'avant en Papillon. Laissez la gravité faire le travail. Respirez dans vos hanches et l'intérieur de vos cuisses."
        ),
        modifications: LocalizedStringArray(
            en: ["Sit on a folded blanket to tilt your pelvis forward and ease lower back tension",
                 "Place blocks or cushions under your knees for support if the stretch is too intense"],
            fr: ["Assoyez-vous sur une couverture pliée pour basculer le bassin vers l'avant et soulager le bas du dos",
                 "Placez des blocs ou des coussins sous vos genoux pour du soutien si l'étirement est trop intense"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a groin or inner knee injury"],
            fr: ["Évitez en cas de blessure à l'aine ou à l'intérieur du genou"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, deep belly breaths — inhale to create space, exhale to soften deeper",
            fr: "Respirations abdominales lentes et profondes — inspirez pour créer de l'espace, expirez pour vous relâcher davantage"
        ),
        isFree: true
    )

    public static let yinHalfButterfly = Pose(
        id: "yin-half-butterfly",
        name: LocalizedString(
            en: "Half Butterfly",
            fr: "Demi-papillon"
        ),
        description: LocalizedString(
            en: "Extend your right leg forward and tuck your left foot against your inner right thigh. Fold forward over the extended leg, allowing your spine to round naturally. Let your hands rest wherever they land — on your shin, foot, or the floor — without pulling yourself deeper. Repeat on the other side.",
            fr: "Étendez la jambe droite vers l'avant et placez le pied gauche contre l'intérieur de la cuisse droite. Penchez-vous vers l'avant sur la jambe étendue en laissant votre colonne s'arrondir naturellement. Laissez vos mains reposer là où elles tombent — sur le tibia, le pied ou le sol — sans vous tirer plus profondément. Répétez de l'autre côté."
        ),
        durationSeconds: 90,
        difficulty: .beginner,
        category: .hips,
        position: .seated,
        imageName: "pose.yin.half.butterfly",
        voiceCueText: LocalizedString(
            en: "Fold gently over your extended leg. There's no goal to reach. Just breathe and let go.",
            fr: "Penchez-vous doucement sur votre jambe étendue. Il n'y a pas d'objectif à atteindre. Respirez et laissez aller."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a bolster or pillow on your extended leg and rest your torso on it",
                 "Bend the extended knee slightly if you feel strain behind the knee"],
            fr: ["Placez un traversin ou un oreiller sur votre jambe étendue et reposez votre torse dessus",
                 "Pliez légèrement le genou de la jambe étendue si vous ressentez une tension derrière le genou"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with hamstring tears or acute sciatica"],
            fr: ["Évitez en cas de déchirure des ischio-jambiers ou de sciatique aiguë"]
        ),
        breathingPattern: LocalizedString(
            en: "Long, slow breaths — exhale to melt a little deeper each time",
            fr: "Respirations longues et lentes — expirez pour fondre un peu plus profondément chaque fois"
        ),
        isFree: true
    )

    public static let yinDragonfly = Pose(
        id: "yin-dragonfly",
        name: LocalizedString(
            en: "Dragonfly",
            fr: "Libellule"
        ),
        description: LocalizedString(
            en: "Sit with your legs spread wide apart in a straddle position. Allow your spine to round forward, walking your hands ahead of you on the floor. Rest your weight into your hands or forearms and let gravity gradually deepen the stretch through your inner thighs, hamstrings, and groin. Stay passive and breathe into any areas of sensation.",
            fr: "Assoyez-vous avec les jambes écartées en grand. Laissez votre colonne s'arrondir vers l'avant en avançant vos mains sur le sol devant vous. Reposez votre poids sur vos mains ou avant-bras et laissez la gravité approfondir graduellement l'étirement dans l'intérieur des cuisses, les ischio-jambiers et l'aine. Restez passif et respirez dans les zones de sensation."
        ),
        durationSeconds: 120,
        difficulty: .intermediate,
        category: .hips,
        position: .seated,
        imageName: "pose.yin.dragonfly",
        voiceCueText: LocalizedString(
            en: "Open your legs wide in Dragonfly. Fold forward and release into gravity. Let the fascia of your inner legs slowly open.",
            fr: "Ouvrez grand vos jambes en Libellule. Penchez-vous vers l'avant et abandonnez-vous à la gravité. Laissez les fascias de l'intérieur de vos jambes s'ouvrir lentement."
        ),
        modifications: LocalizedStringArray(
            en: ["Sit on a folded blanket to ease the forward fold",
                 "Place a bolster in front of you and rest your chest and head on it"],
            fr: ["Assoyez-vous sur une couverture pliée pour faciliter la flexion avant",
                 "Placez un traversin devant vous et reposez votre poitrine et votre tête dessus"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with groin or hamstring injuries",
                 "Use caution if you have sciatica symptoms"],
            fr: ["Évitez en cas de blessure à l'aine ou aux ischio-jambiers",
                 "Soyez prudent si vous avez des symptômes de sciatique"]
        ),
        breathingPattern: LocalizedString(
            en: "Deep diaphragmatic breaths — imagine sending breath into your inner thighs",
            fr: "Respirations diaphragmatiques profondes — imaginez envoyer le souffle dans l'intérieur de vos cuisses"
        ),
        isFree: true
    )

    public static let yinSleepingSwan = Pose(
        id: "yin-sleeping-swan",
        name: LocalizedString(
            en: "Sleeping Swan",
            fr: "Cygne endormi"
        ),
        description: LocalizedString(
            en: "From a kneeling position, slide your right knee forward and angle your right shin across your mat. Extend your left leg straight behind you. Walk your hands forward and lower your torso over your front shin, resting on your forearms or a bolster. Allow the weight of your body to passively open the hip of the front leg. Repeat on the other side.",
            fr: "À partir d'une position à genoux, glissez le genou droit vers l'avant et placez le tibia droit en diagonale sur votre tapis. Étendez la jambe gauche vers l'arrière. Avancez vos mains et abaissez votre torse sur le tibia avant en vous reposant sur vos avant-bras ou un traversin. Laissez le poids de votre corps ouvrir passivement la hanche de la jambe avant. Répétez de l'autre côté."
        ),
        durationSeconds: 120,
        difficulty: .intermediate,
        category: .hips,
        position: .kneeling,
        imageName: "pose.yin.sleeping.swan",
        voiceCueText: LocalizedString(
            en: "Lower into Sleeping Swan. Surrender your weight over the front leg. Let the hip release with each exhale.",
            fr: "Descendez en Cygne endormi. Abandonnez votre poids sur la jambe avant. Laissez la hanche se relâcher à chaque expiration."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a blanket or block under the hip of the front leg for support",
                 "Keep your torso upright instead of folding forward if the stretch is intense enough"],
            fr: ["Placez une couverture ou un bloc sous la hanche de la jambe avant pour du soutien",
                 "Gardez votre torse droit au lieu de vous pencher vers l'avant si l'étirement est assez intense"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a knee injury on the front leg side",
                 "Use caution with sacroiliac joint issues"],
            fr: ["Évitez en cas de blessure au genou du côté de la jambe avant",
                 "Soyez prudent avec les problèmes de l'articulation sacro-iliaque"]
        ),
        breathingPattern: LocalizedString(
            en: "Soft, yielding breaths — exhale to let the hip sink deeper into the floor",
            fr: "Respirations douces et cédantes — expirez pour laisser la hanche s'enfoncer plus profondément vers le sol"
        ),
        isFree: true
    )

    public static let yinDragon = Pose(
        id: "yin-dragon",
        name: LocalizedString(
            en: "Dragon",
            fr: "Dragon"
        ),
        description: LocalizedString(
            en: "Step your right foot forward into a low lunge, placing both hands on the floor inside the front foot. Lower your back knee to the mat and allow your hips to sink toward the ground under their own weight. Feel the deep stretch through the hip flexor and psoas of the back leg. Repeat on the other side.",
            fr: "Avancez le pied droit dans une fente basse en plaçant les deux mains au sol à l'intérieur du pied avant. Abaissez le genou arrière sur le tapis et laissez vos hanches descendre vers le sol sous leur propre poids. Ressentez l'étirement profond à travers le fléchisseur de la hanche et le psoas de la jambe arrière. Répétez de l'autre côté."
        ),
        durationSeconds: 90,
        difficulty: .intermediate,
        category: .hips,
        position: .kneeling,
        imageName: "pose.yin.dragon",
        voiceCueText: LocalizedString(
            en: "Sink into Dragon pose. Let gravity pull your hips earthward. Breathe space into the hip flexor of your back leg.",
            fr: "Enfoncez-vous dans la posture du Dragon. Laissez la gravité tirer vos hanches vers la terre. Respirez de l'espace dans le fléchisseur de la hanche de votre jambe arrière."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a blanket under your back knee for cushioning",
                 "Rest your forearms on blocks instead of the floor to reduce intensity"],
            fr: ["Placez une couverture sous le genou arrière pour du coussin",
                 "Reposez vos avant-bras sur des blocs au lieu du sol pour réduire l'intensité"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute knee or hip flexor injuries"],
            fr: ["Évitez en cas de blessure aiguë au genou ou au fléchisseur de la hanche"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady, deep breaths — imagine your exhale melting the hip flexor",
            fr: "Respirations profondes et régulières — imaginez votre expiration qui fait fondre le fléchisseur de la hanche"
        ),
        isFree: true
    )

    public static let yinSphinx = Pose(
        id: "yin-sphinx",
        name: LocalizedString(
            en: "Sphinx",
            fr: "Sphinx"
        ),
        description: LocalizedString(
            en: "Lie face down and prop yourself up on your forearms with your elbows directly under or slightly ahead of your shoulders. Let your lower back relax completely, allowing a gentle compression in the lumbar spine. Keep your legs soft and your glutes relaxed — the goal is a passive, sustained backbend that nourishes the spinal discs.",
            fr: "Allongez-vous sur le ventre et relevez-vous sur vos avant-bras avec les coudes directement sous ou légèrement devant vos épaules. Laissez votre bas du dos se relâcher complètement, permettant une compression douce de la colonne lombaire. Gardez vos jambes souples et vos fessiers détendus — l'objectif est une extension passive et soutenue qui nourrit les disques vertébraux."
        ),
        durationSeconds: 90,
        difficulty: .beginner,
        category: .spine,
        position: .prone,
        imageName: "pose.yin.sphinx",
        voiceCueText: LocalizedString(
            en: "Rest on your forearms in Sphinx. Let your belly be soft and your lower back relaxed. Breathe gently into the curve of your spine.",
            fr: "Reposez-vous sur vos avant-bras en Sphinx. Gardez le ventre mou et le bas du dos détendu. Respirez doucement dans la courbe de votre colonne."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a blanket under your elbows for comfort",
                 "Lower onto a bolster under your chest if the backbend is too strong"],
            fr: ["Placez une couverture sous vos coudes pour plus de confort",
                 "Descendez sur un traversin sous votre poitrine si l'extension est trop forte"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with herniated lumbar discs or acute lower back pain"],
            fr: ["Évitez en cas de hernie discale lombaire ou de douleur aiguë au bas du dos"]
        ),
        breathingPattern: LocalizedString(
            en: "Natural, relaxed breathing — let the belly expand into the floor on each inhale",
            fr: "Respiration naturelle et détendue — laissez le ventre se gonfler contre le sol à chaque inspiration"
        ),
        isFree: true
    )

    public static let yinCaterpillar = Pose(
        id: "yin-caterpillar",
        name: LocalizedString(
            en: "Caterpillar",
            fr: "Chenille"
        ),
        description: LocalizedString(
            en: "Sit with both legs extended straight in front of you. Allow your spine to round forward, draping your torso over your legs. Let your hands rest beside your legs or on your feet without pulling. Release your neck and let your head hang heavy. This passive forward fold gently stresses the ligaments along the entire back body.",
            fr: "Assoyez-vous avec les deux jambes étendues devant vous. Laissez votre colonne s'arrondir vers l'avant, drapant votre torse sur vos jambes. Laissez vos mains reposer le long de vos jambes ou sur vos pieds sans tirer. Relâchez le cou et laissez la tête pendre lourdement. Cette flexion avant passive stimule doucement les ligaments de toute la chaîne postérieure."
        ),
        durationSeconds: 120,
        difficulty: .beginner,
        category: .back,
        position: .seated,
        imageName: "pose.yin.caterpillar",
        voiceCueText: LocalizedString(
            en: "Fold forward in Caterpillar. Round your spine completely and let everything hang. Breathe into the stretch along your entire back.",
            fr: "Penchez-vous vers l'avant en Chenille. Arrondissez complètement votre colonne et laissez tout pendre. Respirez dans l'étirement le long de tout votre dos."
        ),
        modifications: LocalizedStringArray(
            en: ["Sit on a folded blanket to reduce strain on the hamstrings",
                 "Place a bolster on your legs and rest your torso on it for a gentler stretch"],
            fr: ["Assoyez-vous sur une couverture pliée pour réduire la tension sur les ischio-jambiers",
                 "Placez un traversin sur vos jambes et reposez votre torse dessus pour un étirement plus doux"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute disc herniation or severe sciatica"],
            fr: ["Évitez en cas de hernie discale aiguë ou de sciatique sévère"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow breaths into the back of the ribcage — feel the back body expand with each inhale",
            fr: "Respirations lentes dans l'arrière de la cage thoracique — sentez le dos s'élargir à chaque inspiration"
        ),
        isFree: true
    )

    // MARK: - Intermediate / Advanced Poses (Premium)

    public static let yinSeal = Pose(
        id: "yin-seal",
        name: LocalizedString(
            en: "Seal",
            fr: "Phoque"
        ),
        description: LocalizedString(
            en: "Lie face down and press up onto your hands with arms straight, positioning your hands farther ahead than in Cobra. Let your hips and legs stay heavy on the floor. This deeper backbend creates a stronger compression in the lumbar spine, targeting the connective tissue along the front body and the spinal ligaments.",
            fr: "Allongez-vous sur le ventre et poussez-vous sur vos mains avec les bras tendus, en plaçant vos mains plus loin devant que dans le Cobra. Laissez vos hanches et vos jambes rester lourdes au sol. Cette extension plus profonde crée une compression plus forte dans la colonne lombaire, ciblant les tissus conjonctifs le long du devant du corps et les ligaments vertébraux."
        ),
        durationSeconds: 90,
        difficulty: .intermediate,
        category: .spine,
        position: .prone,
        imageName: "pose.yin.seal",
        voiceCueText: LocalizedString(
            en: "Press up into Seal with straight arms. Let your lower body be completely passive. Breathe into the arch of your spine.",
            fr: "Poussez-vous en Phoque avec les bras tendus. Laissez le bas du corps complètement passif. Respirez dans l'arc de votre colonne."
        ),
        modifications: LocalizedStringArray(
            en: ["Stay on your forearms in Sphinx if full Seal is too intense for your lower back",
                 "Place your hands wider apart to reduce the depth of the backbend"],
            fr: ["Restez sur vos avant-bras en Sphinx si le Phoque complet est trop intense pour votre bas du dos",
                 "Placez vos mains plus écartées pour réduire la profondeur de l'extension"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with herniated discs, spinal stenosis, or acute lower back pain"],
            fr: ["Évitez en cas de hernie discale, de sténose spinale ou de douleur aiguë au bas du dos"]
        ),
        breathingPattern: LocalizedString(
            en: "Soft, easy breathing — avoid holding the breath even as the backbend deepens",
            fr: "Respiration douce et facile — évitez de retenir le souffle même lorsque l'extension s'approfondit"
        ),
        isFree: false
    )

    public static let yinSnail = Pose(
        id: "yin-snail",
        name: LocalizedString(
            en: "Snail",
            fr: "Escargot"
        ),
        description: LocalizedString(
            en: "Lie on your back and swing your legs overhead, allowing your feet to move toward the floor behind your head. Support your lower back with your hands or let your arms rest on the ground. This deep spinal flexion compresses the front body and stretches the entire posterior chain from neck to sacrum. Come out slowly.",
            fr: "Allongez-vous sur le dos et balancez les jambes par-dessus la tête, permettant aux pieds de se diriger vers le sol derrière votre tête. Soutenez le bas du dos avec vos mains ou laissez les bras reposer au sol. Cette flexion spinale profonde comprime le devant du corps et étire toute la chaîne postérieure du cou au sacrum. Sortez lentement."
        ),
        durationSeconds: 90,
        difficulty: .advanced,
        category: .spine,
        position: .supine,
        imageName: "pose.yin.snail",
        voiceCueText: LocalizedString(
            en: "Roll into Snail gently. Support your back and breathe into the entire length of your spine. If there is any neck pain, come out immediately.",
            fr: "Roulez doucement en Escargot. Soutenez votre dos et respirez dans toute la longueur de votre colonne. En cas de douleur au cou, sortez immédiatement."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep your hands on your lower back for support rather than reaching the floor",
                 "Place a stack of blankets behind you so your feet land on a raised surface"],
            fr: ["Gardez les mains sur le bas du dos pour du soutien plutôt que de chercher à toucher le sol",
                 "Placez une pile de couvertures derrière vous pour que vos pieds atterrissent sur une surface surélevée"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with neck injuries, cervical disc issues, or high blood pressure",
                 "Not recommended during pregnancy"],
            fr: ["Évitez en cas de blessure au cou, de problèmes de disques cervicaux ou d'hypertension",
                 "Non recommandé pendant la grossesse"]
        ),
        breathingPattern: LocalizedString(
            en: "Short, gentle breaths — the compressed position limits lung capacity, so breathe lightly",
            fr: "Respirations courtes et douces — la position comprimée limite la capacité pulmonaire, alors respirez légèrement"
        ),
        isFree: false
    )

    public static let yinBanana = Pose(
        id: "yin-banana",
        name: LocalizedString(
            en: "Banana",
            fr: "Banane"
        ),
        description: LocalizedString(
            en: "Lie on your back and shift both legs to the right, crossing your left ankle over your right. Walk your upper body to the right as well, creating a crescent shape with your entire body. Reach your arms overhead and clasp your elbows. This lateral stretch targets the side body fascia, intercostal muscles, and the IT band. Repeat on the other side.",
            fr: "Allongez-vous sur le dos et déplacez les deux jambes vers la droite en croisant la cheville gauche sur la droite. Déplacez aussi le haut du corps vers la droite, créant une forme de croissant avec tout votre corps. Étirez les bras au-dessus de la tête et agrippez vos coudes. Cet étirement latéral cible les fascias latéraux, les muscles intercostaux et la bandelette ilio-tibiale. Répétez de l'autre côté."
        ),
        durationSeconds: 90,
        difficulty: .beginner,
        category: .spine,
        position: .supine,
        imageName: "pose.yin.banana",
        voiceCueText: LocalizedString(
            en: "Curve into Banana shape. Feel a long stretch from your fingertips to your outer ankle. Let gravity open the entire side body.",
            fr: "Courbez-vous en forme de Banane. Sentez un long étirement du bout des doigts jusqu'à la cheville extérieure. Laissez la gravité ouvrir tout le côté du corps."
        ),
        modifications: LocalizedStringArray(
            en: ["Don't cross the ankles if it strains the lower back — just shift legs to the side",
                 "Place a pillow under your head if your neck feels strained"],
            fr: ["Ne croisez pas les chevilles si ça tire dans le bas du dos — déplacez simplement les jambes sur le côté",
                 "Placez un oreiller sous votre tête si votre cou est inconfortable"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a rib or intercostal injury"],
            fr: ["Évitez en cas de blessure aux côtes ou aux muscles intercostaux"]
        ),
        breathingPattern: LocalizedString(
            en: "Breathe into the stretched side — feel the ribs expand like an accordion",
            fr: "Respirez dans le côté étiré — sentez les côtes s'ouvrir comme un accordéon"
        ),
        isFree: false
    )

    public static let yinShoelace = Pose(
        id: "yin-shoelace",
        name: LocalizedString(
            en: "Shoelace",
            fr: "Lacet"
        ),
        description: LocalizedString(
            en: "Sit and stack your right knee directly on top of your left knee, drawing both feet toward the opposite hip. If the knees don't stack comfortably, simply cross the legs. Fold forward and let your spine round, resting your hands on the floor or on your feet. This pose deeply targets the outer hips and the IT band through passive, sustained compression.",
            fr: "Assoyez-vous et empilez le genou droit directement sur le genou gauche, en rapprochant les pieds des hanches opposées. Si les genoux ne s'empilent pas confortablement, croisez simplement les jambes. Penchez-vous vers l'avant et laissez votre colonne s'arrondir, les mains au sol ou sur vos pieds. Cette posture cible profondément les hanches externes et la bandelette ilio-tibiale par une compression passive et soutenue."
        ),
        durationSeconds: 120,
        difficulty: .intermediate,
        category: .hips,
        position: .seated,
        imageName: "pose.yin.shoelace",
        voiceCueText: LocalizedString(
            en: "Stack your knees in Shoelace and fold forward. Let your outer hips release slowly. There is no need to force anything.",
            fr: "Empilez vos genoux en Lacet et penchez-vous vers l'avant. Laissez vos hanches externes se relâcher lentement. Pas besoin de forcer quoi que ce soit."
        ),
        modifications: LocalizedStringArray(
            en: ["Sit on a blanket or block to elevate the hips if stacking knees is difficult",
                 "Simply cross the legs loosely if your knees protest — the hip stretch still works"],
            fr: ["Assoyez-vous sur une couverture ou un bloc pour surélever les hanches si l'empilement des genoux est difficile",
                 "Croisez simplement les jambes si vos genoux résistent — l'étirement des hanches fonctionne quand même"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with knee injuries or meniscus tears"],
            fr: ["Évitez en cas de blessures au genou ou de déchirures du ménisque"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, patient breaths — let each exhale invite a little more release in the outer hips",
            fr: "Respirations lentes et patientes — laissez chaque expiration inviter un peu plus de relâchement dans les hanches externes"
        ),
        isFree: false
    )

    public static let yinSquare = Pose(
        id: "yin-square",
        name: LocalizedString(
            en: "Square",
            fr: "Carré"
        ),
        description: LocalizedString(
            en: "Sit and place your right shin parallel to the front edge of your mat, then stack your left shin on top so both shins are parallel. Flex both feet gently to protect the knees. Fold forward with a rounded spine, walking your hands ahead of you. This pose creates a deep, passive opening through the outer hips and glutes.",
            fr: "Assoyez-vous et placez le tibia droit parallèle au bord avant de votre tapis, puis empilez le tibia gauche dessus pour que les deux tibias soient parallèles. Fléchissez doucement les pieds pour protéger les genoux. Penchez-vous vers l'avant en arrondissant la colonne, avançant les mains devant vous. Cette posture crée une ouverture profonde et passive des hanches externes et des fessiers."
        ),
        durationSeconds: 120,
        difficulty: .intermediate,
        category: .hips,
        position: .seated,
        imageName: "pose.yin.square",
        voiceCueText: LocalizedString(
            en: "Stack your shins in Square pose and fold forward. Let the weight of your torso create the opening. Breathe into the outer hips.",
            fr: "Empilez les tibias en posture du Carré et penchez-vous vers l'avant. Laissez le poids du torse créer l'ouverture. Respirez dans les hanches externes."
        ),
        modifications: LocalizedStringArray(
            en: ["If the top knee is high off the bottom shin, place a block or blanket between the shins",
                 "Keep your torso upright and just lean forward slightly if the fold is too intense"],
            fr: ["Si le genou du dessus est loin du tibia du dessous, placez un bloc ou une couverture entre les tibias",
                 "Gardez le torse droit et penchez-vous seulement légèrement vers l'avant si la flexion est trop intense"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have knee pain or ankle injuries"],
            fr: ["Évitez en cas de douleur au genou ou de blessure à la cheville"]
        ),
        breathingPattern: LocalizedString(
            en: "Calm, steady breaths — think of your breath as warm water softening the hip joints",
            fr: "Respirations calmes et régulières — pensez à votre souffle comme de l'eau chaude qui assouplit les articulations des hanches"
        ),
        isFree: false
    )

    public static let yinDeer = Pose(
        id: "yin-deer",
        name: LocalizedString(
            en: "Deer",
            fr: "Cerf"
        ),
        description: LocalizedString(
            en: "Sit with your right leg bent in front of you at roughly 90 degrees and your left leg bent behind you at 90 degrees, creating a windshield-wiper shape. Lean back slightly or fold forward over the front leg, depending on where you feel the stretch most. This pose simultaneously targets internal and external rotation of both hips.",
            fr: "Assoyez-vous avec la jambe droite pliée devant vous à environ 90 degrés et la jambe gauche pliée derrière vous à 90 degrés, en forme d'essuie-glace. Penchez-vous légèrement vers l'arrière ou vers l'avant sur la jambe avant, selon l'endroit où vous ressentez le plus l'étirement. Cette posture cible simultanément la rotation interne et externe des deux hanches."
        ),
        durationSeconds: 90,
        difficulty: .intermediate,
        category: .hips,
        position: .seated,
        imageName: "pose.yin.deer",
        voiceCueText: LocalizedString(
            en: "Settle into Deer pose. Feel both hips working differently — one opening outward, one inward. Breathe and soften.",
            fr: "Installez-vous dans la posture du Cerf. Sentez les deux hanches travailler différemment — l'une s'ouvre vers l'extérieur, l'autre vers l'intérieur. Respirez et ramollissez."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a blanket under the back knee for cushioning",
                 "Stay upright with hands behind you for support if folding forward is too intense"],
            fr: ["Placez une couverture sous le genou arrière pour du coussin",
                 "Restez droit avec les mains derrière vous pour du soutien si la flexion avant est trop intense"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with knee or meniscus injuries"],
            fr: ["Évitez en cas de blessures au genou ou au ménisque"]
        ),
        breathingPattern: LocalizedString(
            en: "Even, gentle breaths — visualize space opening in both hip sockets",
            fr: "Respirations égales et douces — visualisez l'espace qui s'ouvre dans les deux articulations de la hanche"
        ),
        isFree: false
    )

    public static let yinTwistedRoots = Pose(
        id: "yin-twisted-roots",
        name: LocalizedString(
            en: "Twisted Roots",
            fr: "Racines torsadées"
        ),
        description: LocalizedString(
            en: "Lie on your back with your knees bent. Cross your right thigh over your left like eagle legs, then let both knees fall to the left. Extend your arms out to the sides and turn your gaze to the right. Let the weight of your legs passively create a deep spinal twist, releasing tension in the lower back and outer hips.",
            fr: "Allongez-vous sur le dos avec les genoux pliés. Croisez la cuisse droite sur la gauche comme des jambes d'aigle, puis laissez les deux genoux tomber vers la gauche. Étendez les bras sur les côtés et tournez le regard vers la droite. Laissez le poids de vos jambes créer passivement une torsion spinale profonde, relâchant la tension dans le bas du dos et les hanches externes."
        ),
        durationSeconds: 90,
        difficulty: .intermediate,
        category: .spine,
        position: .supine,
        imageName: "pose.yin.twisted.roots",
        voiceCueText: LocalizedString(
            en: "Cross your legs and drop them to one side in Twisted Roots. Let gravity twist your spine. Breathe into the space between your shoulder blades.",
            fr: "Croisez vos jambes et laissez-les tomber d'un côté en Racines torsadées. Laissez la gravité tordre votre colonne. Respirez dans l'espace entre vos omoplates."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a bolster or pillow between your knees for support",
                 "Don't wrap the legs — simply drop bent knees to the side for a gentler twist"],
            fr: ["Placez un traversin ou un oreiller entre vos genoux pour du soutien",
                 "N'enroulez pas les jambes — laissez simplement tomber les genoux pliés sur le côté pour une torsion plus douce"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute spinal disc issues or sacroiliac joint dysfunction"],
            fr: ["Évitez en cas de problèmes discaux aigus ou de dysfonction de l'articulation sacro-iliaque"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to let the knees sink heavier, inhale to lengthen the spine",
            fr: "Expirez pour laisser les genoux s'alourdir, inspirez pour allonger la colonne"
        ),
        isFree: false
    )

    public static let yinReclinedButterfly = Pose(
        id: "yin-reclined-butterfly",
        name: LocalizedString(
            en: "Reclined Butterfly",
            fr: "Papillon couché"
        ),
        description: LocalizedString(
            en: "Lie on your back and bring the soles of your feet together, letting your knees fall open to the sides. Rest your arms wherever feels natural — by your sides or overhead. Let gravity passively open your inner thighs and hips. This gentle, restorative shape allows deep release in the groin and hip adductors.",
            fr: "Allongez-vous sur le dos et joignez les plantes de vos pieds, laissant vos genoux tomber ouverts sur les côtés. Reposez vos bras là où c'est naturel — le long du corps ou au-dessus de la tête. Laissez la gravité ouvrir passivement l'intérieur de vos cuisses et vos hanches. Cette posture douce et restauratrice permet un relâchement profond de l'aine et des adducteurs."
        ),
        durationSeconds: 120,
        difficulty: .beginner,
        category: .hips,
        position: .supine,
        imageName: "pose.yin.reclined.butterfly",
        voiceCueText: LocalizedString(
            en: "Open your knees in Reclined Butterfly and let gravity do everything. Soften your belly and breathe deeply.",
            fr: "Ouvrez vos genoux en Papillon couché et laissez la gravité tout faire. Ramollissez votre ventre et respirez profondément."
        ),
        modifications: LocalizedStringArray(
            en: ["Place blocks or pillows under each knee so they don't hang unsupported",
                 "Place a bolster lengthwise under your spine for a supported heart opener"],
            fr: ["Placez des blocs ou des oreillers sous chaque genou pour qu'ils ne pendent pas sans soutien",
                 "Placez un traversin dans le sens de la longueur sous votre colonne pour une ouverture du coeur soutenue"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have groin or inner knee injuries"],
            fr: ["Évitez en cas de blessure à l'aine ou à l'intérieur du genou"]
        ),
        breathingPattern: LocalizedString(
            en: "Deep belly breathing — let the abdomen rise and fall naturally",
            fr: "Respiration abdominale profonde — laissez l'abdomen monter et descendre naturellement"
        ),
        isFree: false
    )

    public static let yinSaddle = Pose(
        id: "yin-saddle",
        name: LocalizedString(
            en: "Saddle",
            fr: "Selle"
        ),
        description: LocalizedString(
            en: "Kneel and sit between your heels, then slowly lean back, supporting yourself on your hands, then forearms, and eventually lying all the way back if accessible. This deep quad and hip flexor stretch also creates a gentle backbend that compresses the lumbar spine. Stay at whatever depth your body allows.",
            fr: "Agenouillez-vous et assoyez-vous entre vos talons, puis penchez-vous lentement vers l'arrière en vous soutenant sur vos mains, puis vos avant-bras, et éventuellement en vous allongeant complètement si c'est accessible. Cet étirement profond des quadriceps et fléchisseurs de la hanche crée aussi une extension douce qui comprime la colonne lombaire. Restez à la profondeur que votre corps permet."
        ),
        durationSeconds: 90,
        difficulty: .intermediate,
        category: .legs,
        position: .kneeling,
        imageName: "pose.yin.saddle",
        voiceCueText: LocalizedString(
            en: "Lean back in Saddle pose. Go only as far as your knees and lower back allow. Breathe into the front of your thighs and hip flexors.",
            fr: "Penchez-vous vers l'arrière en posture de la Selle. Allez seulement aussi loin que vos genoux et votre bas du dos le permettent. Respirez dans le devant de vos cuisses et les fléchisseurs de la hanche."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a bolster behind you and recline onto it instead of going all the way to the floor",
                 "Do one leg at a time — extend the other leg forward for Half Saddle"],
            fr: ["Placez un traversin derrière vous et allongez-vous dessus au lieu d'aller jusqu'au sol",
                 "Faites une jambe à la fois — étendez l'autre jambe vers l'avant pour la Demi-selle"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with knee injuries or acute lower back pain",
                 "Not recommended if you have ankle pain in this position"],
            fr: ["Évitez en cas de blessure au genou ou de douleur aiguë au bas du dos",
                 "Non recommandé si vous avez mal aux chevilles dans cette position"]
        ),
        breathingPattern: LocalizedString(
            en: "Long exhales to release into the backbend — inhale gently to maintain space in the chest",
            fr: "Longues expirations pour se relâcher dans l'extension — inspirez doucement pour maintenir l'espace dans la poitrine"
        ),
        isFree: false
    )

    public static let yinMeltingHeart = Pose(
        id: "yin-melting-heart",
        name: LocalizedString(
            en: "Melting Heart",
            fr: "Coeur fondant"
        ),
        description: LocalizedString(
            en: "From a kneeling position, walk your hands forward and lower your chest toward the floor while keeping your hips stacked over your knees. Let your forehead or chin rest on the ground and allow your chest to melt downward. This pose creates a deep opening across the chest, shoulders, and thoracic spine through passive gravity.",
            fr: "À partir d'une position à genoux, avancez les mains et abaissez la poitrine vers le sol en gardant les hanches au-dessus des genoux. Laissez le front ou le menton reposer au sol et permettez à la poitrine de fondre vers le bas. Cette posture crée une ouverture profonde à travers la poitrine, les épaules et la colonne thoracique par la gravité passive."
        ),
        durationSeconds: 90,
        difficulty: .intermediate,
        category: .chest,
        position: .kneeling,
        imageName: "pose.yin.melting.heart",
        voiceCueText: LocalizedString(
            en: "Walk your hands forward in Melting Heart and let your chest drop toward the earth. Feel your heart space opening with each breath.",
            fr: "Avancez les mains en Coeur fondant et laissez votre poitrine descendre vers la terre. Sentez l'espace du coeur s'ouvrir à chaque souffle."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a bolster or blanket under your chest for support",
                 "Rest your forehead on a block if your chin on the floor strains the neck"],
            fr: ["Placez un traversin ou une couverture sous votre poitrine pour du soutien",
                 "Reposez votre front sur un bloc si le menton au sol force le cou"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with shoulder injuries or acute neck problems"],
            fr: ["Évitez en cas de blessure à l'épaule ou de problèmes aigus au cou"]
        ),
        breathingPattern: LocalizedString(
            en: "Breathe into the chest and upper back — feel the ribcage expand against the floor",
            fr: "Respirez dans la poitrine et le haut du dos — sentez la cage thoracique se gonfler contre le sol"
        ),
        isFree: false
    )

    public static let yinChildsPose = Pose(
        id: "yin-childs-pose",
        name: LocalizedString(
            en: "Child's Pose",
            fr: "Posture de l'enfant"
        ),
        description: LocalizedString(
            en: "Kneel and bring your big toes together, then widen your knees apart. Fold forward and extend your arms ahead of you or rest them alongside your body. Let your forehead touch the floor and allow your entire body to release into the ground. In yin, this pose is held passively to gently decompress the spine and calm the nervous system.",
            fr: "Agenouillez-vous et joignez vos gros orteils, puis écartez les genoux. Penchez-vous vers l'avant et étendez les bras devant vous ou le long du corps. Laissez votre front toucher le sol et permettez à tout votre corps de se relâcher vers le sol. En yin, cette posture est tenue passivement pour décompresser doucement la colonne et calmer le système nerveux."
        ),
        durationSeconds: 90,
        difficulty: .beginner,
        category: .relaxation,
        position: .kneeling,
        imageName: "pose.yin.childs.pose",
        voiceCueText: LocalizedString(
            en: "Rest in Child's Pose. Let every muscle soften. Feel the earth supporting you completely.",
            fr: "Reposez-vous dans la Posture de l'enfant. Laissez chaque muscle s'adoucir. Sentez la terre vous soutenir complètement."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a bolster between your thighs and drape your torso over it",
                 "Put a blanket under your knees or ankles if they are uncomfortable"],
            fr: ["Placez un traversin entre vos cuisses et drapez votre torse dessus",
                 "Mettez une couverture sous vos genoux ou chevilles s'ils sont inconfortables"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if kneeling causes knee pain even with modifications"],
            fr: ["Évitez si la position à genoux cause de la douleur au genou même avec des modifications"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, quiet breaths — breathe into the back of the body and feel the ribs expand",
            fr: "Respirations lentes et silencieuses — respirez dans l'arrière du corps et sentez les côtes s'élargir"
        ),
        isFree: false
    )

    public static let yinSavasana = Pose(
        id: "yin-savasana",
        name: LocalizedString(
            en: "Savasana",
            fr: "Savasana"
        ),
        description: LocalizedString(
            en: "Lie on your back with your legs extended and feet falling naturally apart. Rest your arms at your sides with palms facing up. Close your eyes and release all effort. In yin practice, this final integration allows the body to absorb the effects of the deep holds, letting the chi and energy flow freely through freshly opened tissues.",
            fr: "Allongez-vous sur le dos avec les jambes étendues et les pieds tombant naturellement sur les côtés. Reposez vos bras le long du corps, paumes vers le ciel. Fermez les yeux et relâchez tout effort. Dans la pratique yin, cette intégration finale permet au corps d'absorber les effets des maintiens profonds, laissant le chi et l'énergie circuler librement à travers les tissus fraîchement ouverts."
        ),
        durationSeconds: 180,
        difficulty: .beginner,
        category: .relaxation,
        position: .supine,
        imageName: "pose.yin.savasana",
        voiceCueText: LocalizedString(
            en: "Release into Savasana. Let go completely. Allow your body to integrate everything from your practice.",
            fr: "Relâchez-vous en Savasana. Lâchez prise complètement. Permettez à votre corps d'intégrer tout ce que la pratique a apporté."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a bolster under your knees to release the lower back",
                 "Cover yourself with a blanket for warmth — the body cools quickly in stillness"],
            fr: ["Placez un traversin sous vos genoux pour relâcher le bas du dos",
                 "Couvrez-vous d'une couverture pour la chaleur — le corps refroidit vite dans l'immobilité"]
        ),
        contraindications: LocalizedStringArray(en: [], fr: []),
        breathingPattern: LocalizedString(
            en: "Completely natural breathing — no control, no counting, just let the body breathe itself",
            fr: "Respiration complètement naturelle — aucun contrôle, aucun décompte, laissez simplement le corps respirer par lui-même"
        ),
        isFree: false
    )

    public static let yinSupportedFish = Pose(
        id: "yin-supported-fish",
        name: LocalizedString(
            en: "Supported Fish",
            fr: "Poisson soutenu"
        ),
        description: LocalizedString(
            en: "Place a bolster or rolled blanket lengthwise along your spine and lie back over it so your chest opens wide. Let your arms fall open to the sides with palms up. Your head can rest on the bolster or a pillow. Allow gravity to passively open the chest, shoulders, and front body, counteracting the forward-hunching patterns of daily life.",
            fr: "Placez un traversin ou une couverture roulée dans le sens de la longueur le long de votre colonne et allongez-vous dessus pour que la poitrine s'ouvre grand. Laissez vos bras tomber ouverts sur les côtés, paumes vers le ciel. Votre tête peut reposer sur le traversin ou un oreiller. Laissez la gravité ouvrir passivement la poitrine, les épaules et le devant du corps, contrant les postures voûtées du quotidien."
        ),
        durationSeconds: 120,
        difficulty: .beginner,
        category: .chest,
        position: .supine,
        imageName: "pose.yin.supported.fish",
        voiceCueText: LocalizedString(
            en: "Lie back over the support in Supported Fish. Open your arms wide and let your chest expand with every breath. Surrender to the opening.",
            fr: "Allongez-vous sur le support en Poisson soutenu. Ouvrez grand les bras et laissez votre poitrine se gonfler à chaque souffle. Abandonnez-vous à l'ouverture."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a thinner support like a folded blanket if the backbend feels too deep",
                 "Bend your knees with feet flat on the floor if your lower back is uncomfortable"],
            fr: ["Utilisez un support plus mince comme une couverture pliée si l'extension est trop profonde",
                 "Pliez les genoux avec les pieds à plat au sol si votre bas du dos est inconfortable"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute shoulder injuries or cervical spine issues"],
            fr: ["Évitez en cas de blessure aiguë à l'épaule ou de problèmes à la colonne cervicale"]
        ),
        breathingPattern: LocalizedString(
            en: "Wide, expansive breaths — feel the entire front body opening like a flower",
            fr: "Respirations amples et expansives — sentez tout le devant du corps s'ouvrir comme une fleur"
        ),
        isFree: false
    )

    // MARK: - Yin Yoga Pose Collection

    public static let yinPoses: [Pose] = [
        // Beginner (Free)
        yinButterfly,
        yinHalfButterfly,
        yinDragonfly,
        yinSleepingSwan,
        yinDragon,
        yinSphinx,
        yinCaterpillar,
        // Intermediate / Advanced (Premium)
        yinSeal,
        yinSnail,
        yinBanana,
        yinShoelace,
        yinSquare,
        yinDeer,
        yinTwistedRoots,
        yinReclinedButterfly,
        yinSaddle,
        yinMeltingHeart,
        yinChildsPose,
        yinSavasana,
        yinSupportedFish,
    ]

    // MARK: - Yin Yoga Plans

    public static let yinLowerBody = WorkoutPlan(
        id: "yin-lower-body",
        name: LocalizedString(
            en: "Lower Body Yin",
            fr: "Yin bas du corps"
        ),
        description: LocalizedString(
            en: "A gentle 13-minute yin sequence targeting the hips, inner thighs, and hamstrings with long passive holds.",
            fr: "Une séquence yin douce de 13 minutes ciblant les hanches, l'intérieur des cuisses et les ischio-jambiers avec de longs maintiens passifs."
        ),
        style: .yin,
        poses: [yinButterfly, yinHalfButterfly, yinDragon, yinSleepingSwan, yinDragonfly, yinCaterpillar, yinSavasana],
        transitionSeconds: 5,
        isFree: true
    )

    public static let yinUpperSpine = WorkoutPlan(
        id: "yin-upper-spine",
        name: LocalizedString(
            en: "Upper Body & Spine Yin",
            fr: "Yin haut du corps et colonne"
        ),
        description: LocalizedString(
            en: "A nourishing 14-minute yin session focused on the spine, chest, and shoulders through passive backbends and twists.",
            fr: "Une séance yin nourrissante de 14 minutes axée sur la colonne, la poitrine et les épaules à travers des extensions et torsions passives."
        ),
        style: .yin,
        poses: [yinSphinx, yinSeal, yinMeltingHeart, yinSupportedFish, yinBanana, yinTwistedRoots, yinChildsPose, yinSavasana],
        transitionSeconds: 5,
        isFree: false
    )

    public static let yinFullSurrender = WorkoutPlan(
        id: "yin-full-surrender",
        name: LocalizedString(
            en: "Full Yin Surrender",
            fr: "Abandon yin complet"
        ),
        description: LocalizedString(
            en: "A deep 35-minute yin practice flowing through all 20 poses for a complete surrender of body and mind.",
            fr: "Une pratique yin profonde de 35 minutes parcourant les 20 postures pour un abandon complet du corps et de l'esprit."
        ),
        style: .yin,
        poses: yinPoses,
        transitionSeconds: 5,
        isFree: false
    )

    public static let yinPlans: [WorkoutPlan] = [
        yinLowerBody,
        yinUpperSpine,
        yinFullSurrender,
    ]
}
