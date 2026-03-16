import Foundation

// MARK: - Prenatal Yoga Poses & Plans

extension PoseCatalog {

    // MARK: - Free Poses

    public static let prenatalCatCow = Pose(
        id: "prenatal-cat-cow",
        name: LocalizedString(
            en: "Cat-Cow",
            fr: "Chat-Vache"
        ),
        description: LocalizedString(
            en: "Begin on all fours with wrists under shoulders and knees under hips. On the inhale, drop your belly, lift your tailbone and gaze upward (Cow). On the exhale, round your spine, tuck your chin and draw the baby toward your spine (Cat). Move slowly and rhythmically with each breath.",
            fr: "Placez-vous à quatre pattes, poignets sous les épaules et genoux sous les hanches. À l'inspiration, laissez le ventre descendre, soulevez le coccyx et regardez vers le haut (Vache). À l'expiration, arrondissez la colonne, rentrez le menton et rapprochez le bébé vers la colonne (Chat). Bougez lentement et rythmiquement avec chaque respiration."
        ),
        durationSeconds: 45,
        difficulty: .beginner,
        category: .spine,
        position: .kneeling,
        imageName: "pose.prenatal.catcow",
        voiceCueText: LocalizedString(
            en: "Flow between Cat and Cow with your breath. Inhale, open the heart. Exhale, round and protect. Let the movement soothe your back.",
            fr: "Alternez entre Chat et Vache au rythme de votre souffle. Inspirez, ouvrez le cœur. Expirez, arrondissez et protégez. Laissez le mouvement apaiser votre dos."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a folded blanket under your knees for extra cushioning",
                 "Reduce the range of motion if your belly feels compressed"],
            fr: ["Placez une couverture pliée sous vos genoux pour plus de confort",
                 "Réduisez l'amplitude du mouvement si votre ventre se sent comprimé"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you experience wrist pain — use fists or forearms instead",
                 "Stop if you feel dizziness or nausea"],
            fr: ["Évitez en cas de douleur aux poignets — utilisez les poings ou les avant-bras",
                 "Arrêtez si vous ressentez des étourdissements ou des nausées"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale for Cow, exhale for Cat — one full breath per cycle, 4 counts each",
            fr: "Inspirez pour la Vache, expirez pour le Chat — un souffle complet par cycle, 4 temps chacun"
        ),
        isFree: true
    )

    public static let prenatalWarriorI = Pose(
        id: "prenatal-warrior-i",
        name: LocalizedString(
            en: "Modified Warrior I",
            fr: "Guerrier I modifié"
        ),
        description: LocalizedString(
            en: "Step your right foot forward into a lunge with your back foot angled at 45 degrees. Keep your stance wider than usual to accommodate your belly. Bend your front knee over the ankle while lifting both arms overhead. Focus on grounding through both feet and lengthening the spine upward.",
            fr: "Avancez le pied droit en fente avec le pied arrière à un angle de 45 degrés. Gardez votre position plus large que d'habitude pour accommoder votre ventre. Pliez le genou avant au-dessus de la cheville en levant les deux bras au-dessus de la tête. Concentrez-vous sur l'ancrage à travers les deux pieds et l'allongement de la colonne vers le haut."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .legs,
        position: .standing,
        imageName: "pose.prenatal.warrior.i",
        voiceCueText: LocalizedString(
            en: "Stand strong in Modified Warrior I. Widen your stance for stability. Lift through the crown of your head.",
            fr: "Tenez-vous fort en Guerrier I modifié. Élargissez votre position pour la stabilité. Soulevez-vous à travers le sommet de la tête."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep hands on hips instead of overhead if shoulders are fatigued",
                 "Use a wall or chair for balance support"],
            fr: ["Gardez les mains sur les hanches plutôt qu'au-dessus de la tête si les épaules sont fatiguées",
                 "Utilisez un mur ou une chaise pour le soutien de l'équilibre"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid deep lunging if you have pelvic girdle pain (PGP)",
                 "Consult your healthcare provider if you experience round ligament pain"],
            fr: ["Évitez les fentes profondes en cas de douleur à la ceinture pelvienne",
                 "Consultez votre professionnel de santé en cas de douleur du ligament rond"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady breath, inhale to lengthen, exhale to ground — 4 counts each",
            fr: "Respiration régulière, inspirez pour allonger, expirez pour ancrer — 4 temps chacun"
        ),
        isFree: true
    )

    public static let prenatalWarriorII = Pose(
        id: "prenatal-warrior-ii",
        name: LocalizedString(
            en: "Modified Warrior II",
            fr: "Guerrier II modifié"
        ),
        description: LocalizedString(
            en: "From a wide stance, turn your right foot out 90 degrees and bend the right knee over the ankle. Extend arms wide at shoulder height, gazing over the right fingertips. Keep your torso upright rather than leaning forward, creating space for your belly.",
            fr: "Depuis une position large, tournez le pied droit à 90 degrés et pliez le genou droit au-dessus de la cheville. Étendez les bras à la hauteur des épaules, regardant par-dessus les doigts droits. Gardez le torse droit plutôt que penché vers l'avant, créant de l'espace pour votre ventre."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .legs,
        position: .standing,
        imageName: "pose.prenatal.warrior.ii",
        voiceCueText: LocalizedString(
            en: "Open wide in Modified Warrior II. Feel strong and steady. Breathe space for you and baby.",
            fr: "Ouvrez-vous en Guerrier II modifié. Sentez-vous fort et stable. Respirez de l'espace pour vous et bébé."
        ),
        modifications: LocalizedStringArray(
            en: ["Shorten the stance if the stretch in the inner thighs feels too intense",
                 "Rest your front forearm on your thigh for additional support"],
            fr: ["Raccourcissez la position si l'étirement à l'intérieur des cuisses est trop intense",
                 "Posez l'avant-bras avant sur la cuisse pour un soutien supplémentaire"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have SPD (symphysis pubis dysfunction)",
                 "Reduce hold time if you feel fatigued or lightheaded"],
            fr: ["Évitez en cas de dysfonction de la symphyse pubienne",
                 "Réduisez le temps de maintien si vous vous sentez fatiguée ou étourdie"]
        ),
        breathingPattern: LocalizedString(
            en: "Deep, steady breaths — inhale strength, exhale release — 4 counts each",
            fr: "Respirations profondes et régulières — inspirez la force, expirez le relâchement — 4 temps chacun"
        ),
        isFree: true
    )

    public static let prenatalMalasana = Pose(
        id: "prenatal-malasana",
        name: LocalizedString(
            en: "Wide-Legged Squat",
            fr: "Squat jambes écartées"
        ),
        description: LocalizedString(
            en: "Stand with feet wider than hip-width, toes turned out. Slowly lower into a deep squat, keeping your heels on the floor. Bring palms together at your heart center and use your elbows to gently press your knees open. This pose opens the pelvis and strengthens the pelvic floor.",
            fr: "Debout, pieds plus larges que les hanches, orteils vers l'extérieur. Descendez lentement en squat profond en gardant les talons au sol. Joignez les paumes au centre du cœur et utilisez vos coudes pour presser doucement les genoux ouverts. Cette posture ouvre le bassin et renforce le plancher pelvien."
        ),
        durationSeconds: 45,
        difficulty: .beginner,
        category: .hips,
        position: .standing,
        imageName: "pose.prenatal.malasana",
        voiceCueText: LocalizedString(
            en: "Sink into your squat. Open your hips wide. This pose prepares your body beautifully for birth.",
            fr: "Descendez dans votre squat. Ouvrez vos hanches largement. Cette posture prépare magnifiquement votre corps pour l'accouchement."
        ),
        modifications: LocalizedStringArray(
            en: ["Sit on a block or bolster if your heels don't reach the floor",
                 "Hold onto a sturdy chair or wall for balance"],
            fr: ["Assoyez-vous sur un bloc ou un traversin si vos talons ne touchent pas le sol",
                 "Tenez-vous à une chaise solide ou un mur pour l'équilibre"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid after 36 weeks if baby is in breech position — consult your provider",
                 "Stop if you feel pressure or heaviness in the pelvic floor"],
            fr: ["Évitez après 36 semaines si le bébé est en position de siège — consultez votre professionnel",
                 "Arrêtez si vous ressentez une pression ou une lourdeur dans le plancher pelvien"]
        ),
        breathingPattern: LocalizedString(
            en: "Deep belly breaths, visualizing the pelvis opening with each exhale",
            fr: "Respirations abdominales profondes, visualisant le bassin qui s'ouvre à chaque expiration"
        ),
        isFree: true
    )

    public static let prenatalSideLyingSavasana = Pose(
        id: "prenatal-side-lying-savasana",
        name: LocalizedString(
            en: "Side-Lying Savasana",
            fr: "Savasana sur le côté"
        ),
        description: LocalizedString(
            en: "Lie on your left side with a pillow between your knees and another supporting your head. Place a bolster or pillow under your belly for support. Let your top arm rest on a pillow in front of you. Close your eyes and breathe deeply, releasing all tension from your body.",
            fr: "Allongez-vous sur le côté gauche avec un oreiller entre les genoux et un autre soutenant la tête. Placez un traversin ou un oreiller sous le ventre pour du soutien. Laissez le bras du dessus reposer sur un oreiller devant vous. Fermez les yeux et respirez profondément, relâchant toute tension du corps."
        ),
        durationSeconds: 180,
        difficulty: .beginner,
        category: .relaxation,
        position: .supine,
        imageName: "pose.prenatal.side.lying.savasana",
        voiceCueText: LocalizedString(
            en: "Rest deeply on your side. You are supported. Let every breath bring calm to you and your baby.",
            fr: "Reposez-vous profondément sur le côté. Vous êtes soutenue. Laissez chaque souffle apporter le calme à vous et votre bébé."
        ),
        modifications: LocalizedStringArray(
            en: ["Add extra pillows wherever you need more support",
                 "Try lying on the right side if the left side is uncomfortable"],
            fr: ["Ajoutez des oreillers supplémentaires là où vous avez besoin de plus de soutien",
                 "Essayez de vous allonger sur le côté droit si le côté gauche est inconfortable"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid lying flat on your back after the first trimester",
                 "Use left side lying to optimize blood flow to the placenta"],
            fr: ["Évitez de vous allonger à plat sur le dos après le premier trimestre",
                 "Utilisez le côté gauche pour optimiser le flux sanguin vers le placenta"]
        ),
        breathingPattern: LocalizedString(
            en: "Natural, effortless breathing — let each exhale be a complete release",
            fr: "Respiration naturelle et sans effort — laissez chaque expiration être un relâchement complet"
        ),
        isFree: true
    )

    public static let prenatalPigeon = Pose(
        id: "prenatal-pigeon",
        name: LocalizedString(
            en: "Modified Pigeon",
            fr: "Pigeon modifié"
        ),
        description: LocalizedString(
            en: "From all fours, slide your right knee forward toward your right wrist. Extend the left leg back. Use blocks under your right hip to keep the pelvis level and create space for your belly. Walk your hands forward and lower onto your forearms or a bolster.",
            fr: "Depuis quatre pattes, glissez le genou droit vers le poignet droit. Étendez la jambe gauche vers l'arrière. Utilisez des blocs sous la hanche droite pour garder le bassin de niveau et créer de l'espace pour votre ventre. Avancez les mains et descendez sur les avant-bras ou un traversin."
        ),
        durationSeconds: 45,
        difficulty: .beginner,
        category: .hips,
        position: .kneeling,
        imageName: "pose.prenatal.pigeon",
        voiceCueText: LocalizedString(
            en: "Ease into Modified Pigeon. Use props generously. Breathe into the deep hip opening.",
            fr: "Glissez doucement en Pigeon modifié. Utilisez les accessoires généreusement. Respirez dans l'ouverture profonde des hanches."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a bolster lengthwise under your torso for full support",
                 "Do this pose on a bed if the floor is too hard on your knees"],
            fr: ["Placez un traversin dans le sens de la longueur sous votre torse pour un soutien complet",
                 "Faites cette posture sur un lit si le sol est trop dur pour vos genoux"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have sciatica that worsens in this position",
                 "Skip if you experience knee pain on the bent-leg side"],
            fr: ["Évitez si vous avez une sciatique qui s'aggrave dans cette position",
                 "Passez si vous ressentez une douleur au genou du côté de la jambe pliée"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow breaths, directing the exhale toward the hip crease — 5 counts in, 5 counts out",
            fr: "Respirations lentes, dirigeant l'expiration vers le pli de la hanche — 5 temps à l'inspiration, 5 temps à l'expiration"
        ),
        isFree: true
    )

    public static let prenatalSeatedButterfly = Pose(
        id: "prenatal-seated-butterfly",
        name: LocalizedString(
            en: "Seated Butterfly",
            fr: "Papillon assis"
        ),
        description: LocalizedString(
            en: "Sit tall with the soles of your feet together, knees falling open to the sides. Hold your ankles or feet and gently press your knees toward the floor using your elbows. Keep your spine long and lifted. This pose opens the inner thighs and groin in preparation for labor.",
            fr: "Assoyez-vous bien droit avec les plantes des pieds jointes, genoux tombant ouverts sur les côtés. Tenez vos chevilles ou vos pieds et pressez doucement les genoux vers le sol avec vos coudes. Gardez la colonne longue et soulevée. Cette posture ouvre l'intérieur des cuisses et l'aine en préparation pour le travail."
        ),
        durationSeconds: 60,
        difficulty: .beginner,
        category: .hips,
        position: .seated,
        imageName: "pose.prenatal.seated.butterfly",
        voiceCueText: LocalizedString(
            en: "Sit tall in Butterfly. Let your knees soften open. Breathe into the space you're creating.",
            fr: "Assoyez-vous droit en Papillon. Laissez vos genoux s'ouvrir doucement. Respirez dans l'espace que vous créez."
        ),
        modifications: LocalizedStringArray(
            en: ["Sit on a folded blanket to elevate the hips",
                 "Place blocks under the knees for support if the stretch is too deep"],
            fr: ["Assoyez-vous sur une couverture pliée pour élever les hanches",
                 "Placez des blocs sous les genoux pour du soutien si l'étirement est trop profond"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid forcing the knees down — let gravity do the work",
                 "Stop if you feel sharp pain in the inner groin area"],
            fr: ["Évitez de forcer les genoux vers le bas — laissez la gravité faire le travail",
                 "Arrêtez si vous ressentez une douleur vive dans la zone de l'aine"]
        ),
        breathingPattern: LocalizedString(
            en: "Deep diaphragmatic breaths, visualizing the pelvis opening with each exhale",
            fr: "Respirations diaphragmatiques profondes, visualisant le bassin qui s'ouvre à chaque expiration"
        ),
        isFree: true
    )

    // MARK: - Premium Poses

    public static let prenatalTriangle = Pose(
        id: "prenatal-triangle",
        name: LocalizedString(
            en: "Modified Triangle",
            fr: "Triangle modifié"
        ),
        description: LocalizedString(
            en: "From a wide stance, turn the right foot out 90 degrees. Extend arms wide and hinge at the right hip, reaching the right hand toward the shin or a block. Extend the left arm upward. Keep the chest open and rotated toward the ceiling, creating space for your belly.",
            fr: "Depuis une position large, tournez le pied droit à 90 degrés. Étendez les bras et penchez-vous à la hanche droite, atteignant la main droite vers le tibia ou un bloc. Étendez le bras gauche vers le haut. Gardez la poitrine ouverte et tournée vers le plafond, créant de l'espace pour votre ventre."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .hips,
        position: .standing,
        imageName: "pose.prenatal.triangle",
        voiceCueText: LocalizedString(
            en: "Reach long in Modified Triangle. Open your heart skyward. Use a block to bring the floor closer.",
            fr: "Étendez-vous en Triangle modifié. Ouvrez le cœur vers le ciel. Utilisez un bloc pour rapprocher le sol."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a block under the bottom hand at any height",
                 "Shorten the stance for better balance as your belly grows"],
            fr: ["Utilisez un bloc sous la main du bas à n'importe quelle hauteur",
                 "Raccourcissez la position pour un meilleur équilibre au fur et à mesure que votre ventre grandit"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you experience round ligament pain during lateral stretches",
                 "Use caution in the third trimester as your center of gravity shifts"],
            fr: ["Évitez si vous ressentez une douleur du ligament rond pendant les étirements latéraux",
                 "Soyez prudente au troisième trimestre car votre centre de gravité se déplace"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady breaths, inhale to lengthen the spine, exhale to rotate open",
            fr: "Respirations régulières, inspirez pour allonger la colonne, expirez pour tourner ouvert"
        ),
        isFree: false
    )

    public static let prenatalExtendedSideAngle = Pose(
        id: "prenatal-extended-side-angle",
        name: LocalizedString(
            en: "Modified Extended Side Angle",
            fr: "Angle latéral étendu modifié"
        ),
        description: LocalizedString(
            en: "From Warrior II, place your right forearm on your right thigh. Extend your left arm overhead alongside your ear, creating a long line from left foot to left fingertips. Open your chest toward the ceiling. This creates a deep side stretch while keeping space for your baby.",
            fr: "Depuis le Guerrier II, placez l'avant-bras droit sur la cuisse droite. Étendez le bras gauche au-dessus de la tête le long de votre oreille, créant une longue ligne du pied gauche aux doigts gauches. Ouvrez la poitrine vers le plafond. Cela crée un étirement latéral profond tout en gardant de l'espace pour votre bébé."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .hips,
        position: .standing,
        imageName: "pose.prenatal.extended.side.angle",
        voiceCueText: LocalizedString(
            en: "Lengthen through Modified Extended Side Angle. Breathe into the long line of your body.",
            fr: "Allongez-vous en Angle latéral étendu modifié. Respirez dans la longue ligne de votre corps."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a block behind the front foot and bring the bottom hand to the block",
                 "Keep the top hand on the hip instead of extending overhead"],
            fr: ["Placez un bloc derrière le pied avant et amenez la main du bas sur le bloc",
                 "Gardez la main du dessus sur la hanche plutôt que de l'étendre au-dessus de la tête"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you experience diastasis recti or abdominal separation",
                 "Reduce depth if you feel compression in the lower belly"],
            fr: ["Évitez en cas de diastasis des grands droits ou de séparation abdominale",
                 "Réduisez la profondeur si vous ressentez une compression dans le bas du ventre"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen, exhale to deepen — 4 counts each direction",
            fr: "Inspirez pour allonger, expirez pour approfondir — 4 temps dans chaque direction"
        ),
        isFree: false
    )

    public static let prenatalGoddessSquat = Pose(
        id: "prenatal-goddess-squat",
        name: LocalizedString(
            en: "Goddess Squat (Supported)",
            fr: "Squat de la déesse (soutenu)"
        ),
        description: LocalizedString(
            en: "Stand with feet wide, toes turned out at 45 degrees. Bend your knees deeply, tracking over the toes. Bring palms together at heart center or rest hands on thighs. Keep the spine tall and tailbone dropping. This strengthens the legs and opens the pelvis.",
            fr: "Debout avec les pieds écartés, orteils tournés à 45 degrés. Pliez profondément les genoux, en suivant la direction des orteils. Joignez les paumes au centre du cœur ou posez les mains sur les cuisses. Gardez la colonne droite et le coccyx qui descend. Cela renforce les jambes et ouvre le bassin."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .legs,
        position: .standing,
        imageName: "pose.prenatal.goddess.squat",
        voiceCueText: LocalizedString(
            en: "Sink into Goddess Squat. Feel your inner strength. You are powerful.",
            fr: "Descendez en Squat de la déesse. Sentez votre force intérieure. Vous êtes puissante."
        ),
        modifications: LocalizedStringArray(
            en: ["Hold onto a chair back or countertop for balance",
                 "Don't go as deep — a slight bend is sufficient"],
            fr: ["Tenez-vous au dossier d'une chaise ou au comptoir pour l'équilibre",
                 "Ne descendez pas aussi bas — une légère flexion suffit"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have severe pelvic floor dysfunction",
                 "Stop if you feel pressure in the perineum or heaviness in the pelvis"],
            fr: ["Évitez en cas de dysfonction sévère du plancher pelvien",
                 "Arrêtez si vous ressentez une pression dans le périnée ou une lourdeur dans le bassin"]
        ),
        breathingPattern: LocalizedString(
            en: "Strong, empowering breaths — inhale power, exhale to sink deeper",
            fr: "Respirations fortes et stimulantes — inspirez la puissance, expirez pour descendre plus profondément"
        ),
        isFree: false
    )

    public static let prenatalChildsPose = Pose(
        id: "prenatal-childs-pose",
        name: LocalizedString(
            en: "Modified Child's Pose",
            fr: "Posture de l'enfant modifiée"
        ),
        description: LocalizedString(
            en: "Kneel with knees wide apart to make room for your belly. Sit back toward your heels and walk your hands forward, lowering your forehead toward the mat or a bolster. Keep your arms extended or rest them alongside your body. Allow your belly to hang freely between your thighs.",
            fr: "Agenouillez-vous avec les genoux écartés pour faire de la place pour votre ventre. Reculez vers vos talons et avancez les mains, abaissant le front vers le tapis ou un traversin. Gardez les bras étendus ou reposez-les le long du corps. Laissez votre ventre pendre librement entre vos cuisses."
        ),
        durationSeconds: 60,
        difficulty: .beginner,
        category: .relaxation,
        position: .kneeling,
        imageName: "pose.prenatal.childs.pose",
        voiceCueText: LocalizedString(
            en: "Rest in Modified Child's Pose. Knees wide, belly free. Let your whole body soften.",
            fr: "Reposez-vous en Posture de l'enfant modifiée. Genoux écartés, ventre libre. Laissez tout votre corps se détendre."
        ),
        modifications: LocalizedStringArray(
            en: ["Stack pillows or a bolster under your chest and head for elevated support",
                 "Place a folded blanket between your calves and thighs if knees are uncomfortable"],
            fr: ["Empilez des oreillers ou un traversin sous votre poitrine et tête pour un soutien surélevé",
                 "Placez une couverture pliée entre les mollets et les cuisses si les genoux sont inconfortables"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Use the wide-knee version only — traditional child's pose compresses the belly",
                 "Avoid if you have knee injuries that prevent deep flexion"],
            fr: ["Utilisez la version genoux écartés uniquement — la posture traditionnelle comprime le ventre",
                 "Évitez en cas de blessures au genou empêchant la flexion profonde"]
        ),
        breathingPattern: LocalizedString(
            en: "Gentle belly breaths, feeling the baby rock with each inhale and exhale",
            fr: "Respirations abdominales douces, sentant le bébé bercer à chaque inspiration et expiration"
        ),
        isFree: false
    )

    public static let prenatalBridge = Pose(
        id: "prenatal-bridge",
        name: LocalizedString(
            en: "Modified Bridge",
            fr: "Pont modifié"
        ),
        description: LocalizedString(
            en: "Lie on your back with knees bent and feet hip-width apart. Press into your feet to lift your hips gently off the mat. Keep the lift moderate — just enough to engage your glutes and open the hip flexors. Place a block under your sacrum for a supported variation.",
            fr: "Allongez-vous sur le dos avec les genoux pliés et les pieds à la largeur des hanches. Appuyez sur vos pieds pour soulever doucement les hanches du tapis. Gardez l'élévation modérée — juste assez pour engager les fessiers et ouvrir les fléchisseurs des hanches. Placez un bloc sous le sacrum pour une variante soutenue."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .back,
        position: .supine,
        imageName: "pose.prenatal.bridge",
        voiceCueText: LocalizedString(
            en: "Lift gently into Modified Bridge. Just a small lift is enough. Support with a block if you like.",
            fr: "Soulevez doucement en Pont modifié. Un petit soulèvement suffit. Soutenez avec un bloc si vous le souhaitez."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a block under the sacrum for a supported, passive hold",
                 "Keep the lift low if you feel any discomfort in the lower back"],
            fr: ["Utilisez un bloc sous le sacrum pour un maintien passif et soutenu",
                 "Gardez l'élévation basse si vous ressentez un inconfort dans le bas du dos"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid lying flat on your back for extended periods after 20 weeks",
                 "Keep this pose brief (under 1 minute) in the second and third trimester",
                 "Stop immediately if you feel dizzy or short of breath"],
            fr: ["Évitez de rester allongée sur le dos pendant de longues périodes après 20 semaines",
                 "Gardez cette posture brève (moins d'1 minute) au deuxième et troisième trimestre",
                 "Arrêtez immédiatement si vous vous sentez étourdie ou essoufflée"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift, exhale to hold steady — 3 counts up, hold 4, lower on 3",
            fr: "Inspirez pour soulever, expirez pour maintenir — 3 temps pour monter, maintenir 4, descendre sur 3"
        ),
        isFree: false
    )

    public static let prenatalPelvicTilts = Pose(
        id: "prenatal-pelvic-tilts",
        name: LocalizedString(
            en: "Pelvic Tilts",
            fr: "Bascules du bassin"
        ),
        description: LocalizedString(
            en: "Stand with your back against a wall, feet about a foot away. Gently tilt your pelvis to flatten your lower back against the wall, then release. This subtle movement strengthens the deep core, relieves lower back pressure, and helps with optimal fetal positioning.",
            fr: "Debout avec le dos contre un mur, pieds à environ 30 cm du mur. Basculez doucement le bassin pour aplatir le bas du dos contre le mur, puis relâchez. Ce mouvement subtil renforce le noyau profond, soulage la pression lombaire et aide au positionnement optimal du fœtus."
        ),
        durationSeconds: 45,
        difficulty: .beginner,
        category: .core,
        position: .standing,
        imageName: "pose.prenatal.pelvic.tilts",
        voiceCueText: LocalizedString(
            en: "Tilt your pelvis gently against the wall. Small movement, big benefit. Protect and strengthen your core.",
            fr: "Basculez doucement le bassin contre le mur. Petit mouvement, grand bénéfice. Protégez et renforcez votre noyau."
        ),
        modifications: LocalizedStringArray(
            en: ["Do this exercise on all fours if standing is uncomfortable",
                 "Perform while seated on a birth ball for added comfort"],
            fr: ["Faites cet exercice à quatre pattes si la position debout est inconfortable",
                 "Effectuez assis sur un ballon de naissance pour plus de confort"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have acute lower back pain that worsens with movement",
                 "Consult your provider if you have placenta previa"],
            fr: ["Évitez en cas de douleur lombaire aiguë qui s'aggrave avec le mouvement",
                 "Consultez votre professionnel en cas de placenta praevia"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to tilt and engage, inhale to release — slow and rhythmic",
            fr: "Expirez pour basculer et engager, inspirez pour relâcher — lent et rythmique"
        ),
        isFree: false
    )

    public static let prenatalSeatedTwist = Pose(
        id: "prenatal-seated-twist",
        name: LocalizedString(
            en: "Modified Seated Twist",
            fr: "Torsion assise modifiée"
        ),
        description: LocalizedString(
            en: "Sit tall on the floor or a chair. Place your right hand on your left knee and left hand behind you. Twist gently to the left, rotating only through the upper back and keeping the twist above the belly. The twist should feel like opening, not compressing.",
            fr: "Assoyez-vous droit sur le sol ou une chaise. Placez la main droite sur le genou gauche et la main gauche derrière vous. Tournez doucement vers la gauche, en tournant uniquement le haut du dos et en gardant la torsion au-dessus du ventre. La torsion devrait ressembler à une ouverture, pas à une compression."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .spine,
        position: .seated,
        imageName: "pose.prenatal.seated.twist",
        voiceCueText: LocalizedString(
            en: "Twist gently above your belly. Open, don't compress. Keep the rotation in your upper back.",
            fr: "Tournez doucement au-dessus de votre ventre. Ouvrez, ne comprimez pas. Gardez la rotation dans le haut du dos."
        ),
        modifications: LocalizedStringArray(
            en: ["Sit on a chair if getting down to the floor is difficult",
                 "Keep the twist very gentle — only turn as far as is comfortable"],
            fr: ["Assoyez-vous sur une chaise si descendre au sol est difficile",
                 "Gardez la torsion très douce — tournez seulement aussi loin que c'est confortable"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Never twist deeply through the abdomen during pregnancy",
                 "Avoid closed twists that compress the belly — only open twists are safe"],
            fr: ["Ne faites jamais de torsion profonde à travers l'abdomen pendant la grossesse",
                 "Évitez les torsions fermées qui compriment le ventre — seules les torsions ouvertes sont sûres"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale tall, exhale to gently rotate — never force the twist",
            fr: "Inspirez pour grandir, expirez pour tourner doucement — ne forcez jamais la torsion"
        ),
        isFree: false
    )

    public static let prenatalWideLeggedForwardFold = Pose(
        id: "prenatal-wide-legged-forward-fold",
        name: LocalizedString(
            en: "Supported Wide-Legged Forward Fold",
            fr: "Flexion avant jambes écartées soutenue"
        ),
        description: LocalizedString(
            en: "Stand with feet wide apart, toes pointing slightly inward. Hinge at the hips and fold forward, placing your hands on blocks or a chair seat. Keep a flat back and avoid rounding. The wide stance creates space for your belly as you fold.",
            fr: "Debout avec les pieds bien écartés, orteils pointant légèrement vers l'intérieur. Penchez-vous à partir des hanches et pliez vers l'avant, plaçant les mains sur des blocs ou le siège d'une chaise. Gardez le dos plat et évitez de l'arrondir. La position large crée de l'espace pour votre ventre pendant la flexion."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .hips,
        position: .standing,
        imageName: "pose.prenatal.wide.legged.fold",
        voiceCueText: LocalizedString(
            en: "Fold forward with a flat back. Use blocks to bring the floor closer. Let your belly hang free.",
            fr: "Penchez-vous avec un dos plat. Utilisez des blocs pour rapprocher le sol. Laissez votre ventre pendre librement."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a chair seat or wall for hand placement to keep the fold shallow",
                 "Bend the knees generously to protect the hamstrings"],
            fr: ["Utilisez le siège d'une chaise ou un mur pour placer les mains et garder la flexion peu profonde",
                 "Pliez généreusement les genoux pour protéger les ischio-jambiers"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you experience dizziness when bending forward",
                 "Rise up slowly to prevent blood pressure drops"],
            fr: ["Évitez si vous ressentez des étourdissements en vous penchant vers l'avant",
                 "Remontez lentement pour éviter les chutes de tension artérielle"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the spine, exhale to fold deeper — 4 counts each",
            fr: "Inspirez pour allonger la colonne, expirez pour approfondir la flexion — 4 temps chacun"
        ),
        isFree: false
    )

    public static let prenatalKegelIntegration = Pose(
        id: "prenatal-kegel-integration",
        name: LocalizedString(
            en: "Kegel Integration Pose",
            fr: "Posture d'intégration des Kegels"
        ),
        description: LocalizedString(
            en: "Sit comfortably on a cushion or chair with a tall spine. Close your eyes and bring awareness to your pelvic floor. On the exhale, gently draw the pelvic floor muscles upward as if stopping the flow of urine. Hold for 5 seconds, then release fully on the inhale. Repeat rhythmically.",
            fr: "Assoyez-vous confortablement sur un coussin ou une chaise avec la colonne droite. Fermez les yeux et portez votre attention sur le plancher pelvien. À l'expiration, tirez doucement les muscles du plancher pelvien vers le haut comme pour arrêter le flux d'urine. Maintenez 5 secondes, puis relâchez complètement à l'inspiration. Répétez rythmiquement."
        ),
        durationSeconds: 60,
        difficulty: .beginner,
        category: .core,
        position: .seated,
        imageName: "pose.prenatal.kegel.integration",
        voiceCueText: LocalizedString(
            en: "Engage your pelvic floor gently. Lift on the exhale, release on the inhale. Building strength for birth.",
            fr: "Engagez doucement votre plancher pelvien. Soulevez à l'expiration, relâchez à l'inspiration. Construire de la force pour l'accouchement."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a small ball between your inner thighs to help activate the pelvic floor",
                 "Lie on your side if seated is uncomfortable"],
            fr: ["Placez une petite balle entre l'intérieur de vos cuisses pour aider à activer le plancher pelvien",
                 "Allongez-vous sur le côté si la position assise est inconfortable"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have been diagnosed with a hypertonic pelvic floor",
                 "Consult your pelvic floor physiotherapist if unsure about technique"],
            fr: ["Évitez si on vous a diagnostiqué un plancher pelvien hypertonique",
                 "Consultez votre physiothérapeute du plancher pelvien si vous n'êtes pas sûre de la technique"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to engage and lift (5 counts), inhale to fully release (5 counts)",
            fr: "Expirez pour engager et soulever (5 temps), inspirez pour relâcher complètement (5 temps)"
        ),
        isFree: false
    )

    public static let prenatalCamel = Pose(
        id: "prenatal-camel",
        name: LocalizedString(
            en: "Modified Camel",
            fr: "Chameau modifié"
        ),
        description: LocalizedString(
            en: "Kneel with knees hip-width apart and toes tucked under. Place your hands on your lower back with fingers pointing down. Gently press your hips forward while lifting your chest toward the ceiling. Keep the backbend in the upper back only — do not compress the lower back.",
            fr: "Agenouillez-vous, genoux à la largeur des hanches et orteils repliés. Placez les mains sur le bas du dos avec les doigts pointant vers le bas. Pressez doucement les hanches vers l'avant en soulevant la poitrine vers le plafond. Gardez la cambrure dans le haut du dos uniquement — ne comprimez pas le bas du dos."
        ),
        durationSeconds: 20,
        difficulty: .intermediate,
        category: .chest,
        position: .kneeling,
        imageName: "pose.prenatal.camel",
        voiceCueText: LocalizedString(
            en: "Open your heart in Modified Camel. Hands support your lower back. Lift through the chest only.",
            fr: "Ouvrez le cœur en Chameau modifié. Les mains soutiennent le bas du dos. Soulevez uniquement par la poitrine."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep a very gentle bend — less is more during pregnancy",
                 "Place a bolster behind you to lean against for support"],
            fr: ["Gardez une flexion très douce — moins c'est plus pendant la grossesse",
                 "Placez un traversin derrière vous pour vous appuyer"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid deep backbends during pregnancy — keep this very gentle",
                 "Skip if you experience dizziness or nausea when arching back",
                 "Not recommended in the third trimester for most practitioners"],
            fr: ["Évitez les cambrures profondes pendant la grossesse — gardez cela très doux",
                 "Passez si vous ressentez des étourdissements ou des nausées en cambrant le dos",
                 "Non recommandé au troisième trimestre pour la plupart des pratiquantes"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift and open, exhale to hold gently — 3 counts each",
            fr: "Inspirez pour soulever et ouvrir, expirez pour maintenir doucement — 3 temps chacun"
        ),
        isFree: false
    )

    public static let prenatalSideLyingStretch = Pose(
        id: "prenatal-side-lying-stretch",
        name: LocalizedString(
            en: "Side-Lying Stretch",
            fr: "Étirement sur le côté"
        ),
        description: LocalizedString(
            en: "Lie on your left side with a pillow between your knees. Extend your left arm under your head and reach your right arm overhead, stretching the entire right side of your body. Breathe into the opening along your ribs and waist. Switch sides.",
            fr: "Allongez-vous sur le côté gauche avec un oreiller entre les genoux. Étendez le bras gauche sous la tête et atteignez le bras droit au-dessus de la tête, étirant tout le côté droit de votre corps. Respirez dans l'ouverture le long de vos côtes et de votre taille. Changez de côté."
        ),
        durationSeconds: 45,
        difficulty: .beginner,
        category: .spine,
        position: .supine,
        imageName: "pose.prenatal.side.lying.stretch",
        voiceCueText: LocalizedString(
            en: "Stretch long on your side. Breathe into the ribs. Creating space for you and baby.",
            fr: "Étirez-vous longuement sur le côté. Respirez dans les côtes. Créer de l'espace pour vous et bébé."
        ),
        modifications: LocalizedStringArray(
            en: ["Use extra pillows for head and belly support",
                 "Keep the top arm on your hip if the overhead reach is uncomfortable"],
            fr: ["Utilisez des oreillers supplémentaires pour soutenir la tête et le ventre",
                 "Gardez le bras du dessus sur la hanche si l'étirement au-dessus de la tête est inconfortable"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you experience shoulder impingement or rotator cuff issues",
                 "Stop if you feel numbness or tingling in the arm"],
            fr: ["Évitez en cas de conflit d'épaule ou de problèmes de coiffe des rotateurs",
                 "Arrêtez si vous ressentez des engourdissements ou des picotements dans le bras"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the side body, exhale to release — 5 counts each",
            fr: "Inspirez pour allonger le côté du corps, expirez pour relâcher — 5 temps chacun"
        ),
        isFree: false
    )

    public static let prenatalTree = Pose(
        id: "prenatal-tree",
        name: LocalizedString(
            en: "Modified Tree",
            fr: "Arbre modifié"
        ),
        description: LocalizedString(
            en: "Stand near a wall or chair for support. Shift your weight onto your left foot. Place your right foot on your left calf (not the knee). Bring your hands to heart center or hold the wall. Focus on a steady gaze point. Balance work during pregnancy improves proprioception and prepares for the changing center of gravity.",
            fr: "Debout près d'un mur ou d'une chaise pour du soutien. Transférez votre poids sur le pied gauche. Placez le pied droit sur le mollet gauche (pas sur le genou). Amenez les mains au centre du cœur ou tenez le mur. Concentrez-vous sur un point fixe. Le travail d'équilibre pendant la grossesse améliore la proprioception et prépare au changement de centre de gravité."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .balance,
        position: .standing,
        imageName: "pose.prenatal.tree",
        voiceCueText: LocalizedString(
            en: "Find your balance in Modified Tree. Use the wall proudly. Your body is doing incredible things.",
            fr: "Trouvez votre équilibre en Arbre modifié. Utilisez le mur fièrement. Votre corps fait des choses incroyables."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep your toes on the floor with heel against the ankle for a lighter variation",
                 "Hold onto a wall or chair with one hand at all times"],
            fr: ["Gardez les orteils au sol avec le talon contre la cheville pour une variante plus légère",
                 "Tenez un mur ou une chaise avec une main en tout temps"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Use wall support — fall risk increases as pregnancy progresses",
                 "Skip if you have severe balance issues or inner ear problems"],
            fr: ["Utilisez un mur de soutien — le risque de chute augmente au fil de la grossesse",
                 "Passez si vous avez des problèmes d'équilibre sévères ou des problèmes d'oreille interne"]
        ),
        breathingPattern: LocalizedString(
            en: "Calm, steady breaths — inhale to grow tall, exhale to root down",
            fr: "Respirations calmes et régulières — inspirez pour grandir, expirez pour vous enraciner"
        ),
        isFree: false
    )

    public static let prenatalSavasana = Pose(
        id: "prenatal-savasana",
        name: LocalizedString(
            en: "Prenatal Savasana",
            fr: "Savasana prénatal"
        ),
        description: LocalizedString(
            en: "Lie on your left side in a fully supported position. Place a pillow under your head, a bolster between your knees, and a small pillow under your belly. Cover yourself with a blanket. Close your eyes and release all effort. This is your time to connect deeply with your baby through breath and stillness.",
            fr: "Allongez-vous sur le côté gauche dans une position entièrement soutenue. Placez un oreiller sous la tête, un traversin entre les genoux et un petit oreiller sous le ventre. Couvrez-vous d'une couverture. Fermez les yeux et relâchez tout effort. C'est votre moment pour vous connecter profondément avec votre bébé à travers le souffle et l'immobilité."
        ),
        durationSeconds: 300,
        difficulty: .beginner,
        category: .relaxation,
        position: .supine,
        imageName: "pose.prenatal.savasana",
        voiceCueText: LocalizedString(
            en: "Surrender into Prenatal Savasana. You are held. You are safe. Breathe with your baby.",
            fr: "Abandonnez-vous dans le Savasana prénatal. Vous êtes soutenue. Vous êtes en sécurité. Respirez avec votre bébé."
        ),
        modifications: LocalizedStringArray(
            en: ["Try a semi-reclined position with bolsters behind you at a 45-degree angle",
                 "Use a weighted blanket for additional grounding and calm"],
            fr: ["Essayez une position semi-inclinée avec des traversins derrière vous à un angle de 45 degrés",
                 "Utilisez une couverture lestée pour un ancrage et un calme supplémentaires"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Never lie flat on your back after the first trimester — always use side-lying",
                 "Rise slowly from this position to avoid dizziness"],
            fr: ["Ne vous allongez jamais à plat sur le dos après le premier trimestre — utilisez toujours la position sur le côté",
                 "Levez-vous lentement de cette position pour éviter les étourdissements"]
        ),
        breathingPattern: LocalizedString(
            en: "Natural, effortless breathing — simply observe the breath flowing in and out",
            fr: "Respiration naturelle et sans effort — observez simplement le souffle entrer et sortir"
        ),
        isFree: false
    )

    // MARK: - Pose Collection

    public static let prenatalPoses: [Pose] = [
        prenatalCatCow,
        prenatalWarriorI,
        prenatalWarriorII,
        prenatalMalasana,
        prenatalSideLyingSavasana,
        prenatalPigeon,
        prenatalSeatedButterfly,
        prenatalTriangle,
        prenatalExtendedSideAngle,
        prenatalGoddessSquat,
        prenatalChildsPose,
        prenatalBridge,
        prenatalPelvicTilts,
        prenatalSeatedTwist,
        prenatalWideLeggedForwardFold,
        prenatalKegelIntegration,
        prenatalCamel,
        prenatalSideLyingStretch,
        prenatalTree,
        prenatalSavasana
    ]

    // MARK: - Prenatal Plans

    public static let prenatalEssentials = WorkoutPlan(
        id: "prenatal-essentials",
        name: LocalizedString(
            en: "Prenatal Essentials",
            fr: "Essentiels prénataux"
        ),
        description: LocalizedString(
            en: "A gentle, foundational practice with safe poses for all trimesters. Focuses on hip opening, back relief, and relaxation.",
            fr: "Une pratique douce et fondamentale avec des postures sûres pour tous les trimestres. Met l'accent sur l'ouverture des hanches, le soulagement du dos et la relaxation."
        ),
        style: .prenatal,
        poses: [
            prenatalCatCow,
            prenatalWarriorI,
            prenatalWarriorII,
            prenatalMalasana,
            prenatalSeatedButterfly,
            prenatalPigeon,
            prenatalSideLyingSavasana
        ],
        transitionSeconds: 10,
        isFree: true
    )

    public static let prenatalStrengthOpening = WorkoutPlan(
        id: "prenatal-strength-opening",
        name: LocalizedString(
            en: "Prenatal Strength & Opening",
            fr: "Force et ouverture prénatales"
        ),
        description: LocalizedString(
            en: "A complete prenatal session building strength in the legs and core while deeply opening the hips and pelvis. Includes pelvic floor work and relaxation.",
            fr: "Une séance prénatale complète développant la force des jambes et du noyau tout en ouvrant profondément les hanches et le bassin. Inclut un travail du plancher pelvien et de la relaxation."
        ),
        style: .prenatal,
        poses: [
            prenatalCatCow,
            prenatalWarriorI,
            prenatalWarriorII,
            prenatalTriangle,
            prenatalExtendedSideAngle,
            prenatalGoddessSquat,
            prenatalMalasana,
            prenatalPigeon,
            prenatalSeatedButterfly,
            prenatalPelvicTilts,
            prenatalKegelIntegration,
            prenatalChildsPose,
            prenatalSideLyingStretch,
            prenatalSavasana
        ],
        transitionSeconds: 10,
        isFree: false
    )

    public static let prenatalPlans: [WorkoutPlan] = [
        prenatalEssentials,
        prenatalStrengthOpening
    ]
}
