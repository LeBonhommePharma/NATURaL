import Foundation

// MARK: - Chair Yoga Poses & Plans

extension PoseCatalog {

    // MARK: - Beginner Poses (Free)

    public static let seatedMountain = Pose(
        id: "seated-mountain",
        name: LocalizedString(
            en: "Seated Mountain",
            fr: "Montagne assise"
        ),
        description: LocalizedString(
            en: "Sit tall at the front edge of your chair, feet hip-width apart and flat on the floor. Place hands on thighs, palms down. Roll shoulders back and down, lengthen through the crown of your head.",
            fr: "Assoyez-vous droit au bord avant de la chaise, pieds à la largeur des hanches bien à plat au sol. Placez les mains sur les cuisses, paumes vers le bas. Roulez les épaules vers l'arrière et vers le bas, allongez-vous à travers le sommet de la tête."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .spine,
        imageName: "pose.seated.mountain",
        voiceCueText: LocalizedString(
            en: "Sit tall in Seated Mountain. Ground through your feet, lengthen your spine with each inhale.",
            fr: "Assoyez-vous bien droit en Montagne assise. Ancrez-vous à travers vos pieds, allongez la colonne à chaque inspiration."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a folded blanket under your feet if they don't reach the floor",
                 "Use a cushion behind your lower back for lumbar support"],
            fr: ["Placez une couverture pliée sous vos pieds s'ils ne touchent pas le sol",
                 "Utilisez un coussin derrière le bas du dos pour un soutien lombaire"]
        ),
        contraindications: LocalizedStringArray(en: [], fr: []),
        breathingPattern: LocalizedString(
            en: "Natural deep breathing, 4 counts in, 4 counts out",
            fr: "Respiration profonde naturelle, 4 temps à l'inspiration, 4 temps à l'expiration"
        ),
        isFree: true
    )

    public static let seatedCatCow = Pose(
        id: "seated-cat-cow",
        name: LocalizedString(
            en: "Seated Cat-Cow",
            fr: "Chat-Vache assis"
        ),
        description: LocalizedString(
            en: "Place hands on knees. On the inhale, arch your back, lift your chest and gaze slightly up (Cow). On the exhale, round your spine, tuck your chin and draw your navel in (Cat). Flow smoothly between the two.",
            fr: "Placez les mains sur les genoux. À l'inspiration, cambrez le dos, soulevez la poitrine et regardez légèrement vers le haut (Vache). À l'expiration, arrondissez la colonne, rentrez le menton et tirez le nombril vers l'intérieur (Chat). Alternez en douceur."
        ),
        durationSeconds: 45,
        difficulty: .beginner,
        category: .spine,
        imageName: "pose.seated.cat.cow",
        voiceCueText: LocalizedString(
            en: "Inhale, open your chest for Cow. Exhale, round your back for Cat. Let the breath guide the movement.",
            fr: "Inspirez, ouvrez la poitrine pour la Vache. Expirez, arrondissez le dos pour le Chat. Laissez le souffle guider le mouvement."
        ),
        modifications: LocalizedStringArray(
            en: ["Reduce the range of motion if you feel discomfort in the lower back",
                 "Place hands on the tops of thighs instead of knees"],
            fr: ["Réduisez l'amplitude du mouvement si vous ressentez un inconfort au bas du dos",
                 "Placez les mains sur le dessus des cuisses plutôt que sur les genoux"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid deep backbend if you have a herniated disc"],
            fr: ["Évitez la cambrure prononcée en cas de hernie discale"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale for Cow, exhale for Cat — one full breath per cycle",
            fr: "Inspirez pour la Vache, expirez pour le Chat — un souffle complet par cycle"
        ),
        isFree: true
    )

    public static let seatedSpinalTwist = Pose(
        id: "seated-twist",
        name: LocalizedString(
            en: "Seated Spinal Twist",
            fr: "Torsion vertébrale assise"
        ),
        description: LocalizedString(
            en: "Sit tall, place your left hand on your right knee and your right hand behind you on the chair seat or back. On an exhale, gently rotate your torso to the right, keeping both hips facing forward. Hold for several breaths, then switch sides.",
            fr: "Assoyez-vous bien droit, placez la main gauche sur le genou droit et la main droite derrière vous sur le siège ou le dossier de la chaise. À l'expiration, tournez doucement le torse vers la droite en gardant les deux hanches vers l'avant. Maintenez pendant plusieurs respirations, puis changez de côté."
        ),
        durationSeconds: 40,
        difficulty: .beginner,
        category: .spine,
        imageName: "pose.seated.twist",
        voiceCueText: LocalizedString(
            en: "Twist gently to the right. Grow taller on the inhale, deepen the twist on the exhale. Keep your shoulders relaxed.",
            fr: "Tournez doucement vers la droite. Grandissez-vous à l'inspiration, approfondissez la torsion à l'expiration. Gardez les épaules détendues."
        ),
        modifications: LocalizedStringArray(
            en: ["Use the chair back to gently assist the twist",
                 "Twist only as far as comfortable — never force"],
            fr: ["Utilisez le dossier de la chaise pour accompagner doucement la torsion",
                 "Ne tournez que jusqu'où c'est confortable — ne forcez jamais"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a recent spinal injury or acute back pain"],
            fr: ["Évitez en cas de blessure récente à la colonne vertébrale ou de douleur aiguë au dos"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen, exhale to deepen the twist",
            fr: "Inspirez pour allonger, expirez pour approfondir la torsion"
        ),
        isFree: true
    )

    public static let seatedForwardFold = Pose(
        id: "seated-forward-fold",
        name: LocalizedString(
            en: "Seated Forward Fold",
            fr: "Flexion avant assise"
        ),
        description: LocalizedString(
            en: "Sit at the edge of the chair, feet flat on the floor. On an exhale, hinge at the hips and slowly fold your torso forward over your thighs. Let your arms dangle toward the floor or rest on your shins. Keep a slight bend in the knees. Release the head and neck completely.",
            fr: "Assoyez-vous au bord de la chaise, pieds à plat au sol. À l'expiration, penchez-vous à partir des hanches et pliez lentement le torse vers l'avant par-dessus les cuisses. Laissez les bras pendre vers le sol ou reposer sur les tibias. Gardez une légère flexion aux genoux. Relâchez complètement la tête et le cou."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .spine,
        imageName: "pose.seated.forward.fold",
        voiceCueText: LocalizedString(
            en: "Fold forward gently from the hips. Let gravity draw you down. Soften your neck and breathe deeply.",
            fr: "Penchez-vous vers l'avant doucement à partir des hanches. Laissez la gravité vous attirer vers le bas. Relâchez le cou et respirez profondément."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a pillow on your lap to fold onto for support",
                 "Widen your knees to make space for your belly"],
            fr: ["Placez un oreiller sur vos cuisses pour vous y appuyer",
                 "Écartez les genoux pour faire de la place à votre ventre"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute low back pain or recent abdominal surgery",
                 "Use caution with high blood pressure — keep the head above the heart"],
            fr: ["Évitez en cas de douleur aiguë au bas du dos ou de chirurgie abdominale récente",
                 "Prudence en cas d'hypertension — gardez la tête au-dessus du cœur"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to fold deeper, inhale to create space",
            fr: "Expirez pour plier plus profondément, inspirez pour créer de l'espace"
        ),
        isFree: true
    )

    public static let neckRolls = Pose(
        id: "neck-rolls",
        name: LocalizedString(
            en: "Gentle Neck Rolls",
            fr: "Cercles du cou en douceur"
        ),
        description: LocalizedString(
            en: "Drop your right ear toward your right shoulder. Slowly roll your chin down toward your chest, then continue to the left shoulder. Reverse direction. Move slowly and never roll the head all the way back.",
            fr: "Inclinez l'oreille droite vers l'épaule droite. Roulez lentement le menton vers la poitrine, puis continuez vers l'épaule gauche. Inversez la direction. Bougez lentement et ne renversez jamais complètement la tête vers l'arrière."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .neck,
        imageName: "pose.neck.rolls",
        voiceCueText: LocalizedString(
            en: "Roll your neck slowly in a half circle. Breathe into any areas of tension. Keep the movement gentle.",
            fr: "Roulez le cou lentement en demi-cercle. Respirez dans les zones de tension. Gardez le mouvement doux."
        ),
        modifications: LocalizedStringArray(
            en: ["Pause on any tight spots and breathe into the stretch",
                 "Skip the roll and do simple ear-to-shoulder tilts"],
            fr: ["Faites une pause sur les points tendus et respirez dans l'étirement",
                 "Laissez tomber le cercle et faites de simples inclinaisons oreille-épaule"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid full backward head tilt if you have cervical issues"],
            fr: ["Évitez de pencher complètement la tête vers l'arrière en cas de problèmes cervicaux"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow steady breathing throughout",
            fr: "Respiration lente et régulière tout au long"
        ),
        isFree: true
    )

    public static let shoulderRolls = Pose(
        id: "shoulder-rolls",
        name: LocalizedString(
            en: "Shoulder Rolls",
            fr: "Cercles des épaules"
        ),
        description: LocalizedString(
            en: "Sit tall with arms relaxed at your sides. Lift both shoulders up toward your ears, roll them back, squeeze the shoulder blades together, then roll them down and forward. Complete several circles, then reverse direction.",
            fr: "Assoyez-vous droit, bras détendus le long du corps. Montez les deux épaules vers les oreilles, roulez-les vers l'arrière, serrez les omoplates ensemble, puis roulez-les vers le bas et vers l'avant. Effectuez plusieurs cercles, puis inversez la direction."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .shoulders,
        imageName: "pose.shoulder.rolls",
        voiceCueText: LocalizedString(
            en: "Roll your shoulders back and down. Release tension with each circle. Breathe naturally.",
            fr: "Roulez les épaules vers l'arrière et vers le bas. Relâchez la tension à chaque cercle. Respirez naturellement."
        ),
        modifications: LocalizedStringArray(
            en: ["Make smaller circles if you have limited shoulder mobility"],
            fr: ["Faites de plus petits cercles si votre mobilité d'épaule est limitée"]
        ),
        contraindications: LocalizedStringArray(en: [], fr: []),
        breathingPattern: LocalizedString(
            en: "Inhale as shoulders rise, exhale as they roll back and down",
            fr: "Inspirez quand les épaules montent, expirez quand elles descendent"
        ),
        isFree: true
    )

    public static let seatedMeditation = Pose(
        id: "seated-meditation",
        name: LocalizedString(
            en: "Seated Meditation",
            fr: "Méditation assise"
        ),
        description: LocalizedString(
            en: "Sit comfortably with your feet flat on the floor, hands resting gently on your lap or thighs. Close your eyes or soften your gaze. Focus on the natural rhythm of your breath, observing each inhale and exhale without trying to change it.",
            fr: "Assoyez-vous confortablement, pieds à plat au sol, mains posées doucement sur les cuisses ou les genoux. Fermez les yeux ou adoucissez le regard. Concentrez-vous sur le rythme naturel de votre respiration, en observant chaque inspiration et expiration sans essayer de la modifier."
        ),
        durationSeconds: 60,
        difficulty: .beginner,
        category: .breathing,
        imageName: "pose.seated.meditation",
        voiceCueText: LocalizedString(
            en: "Close your eyes. Breathe naturally. Observe each breath. Let each exhale release a little more tension.",
            fr: "Fermez les yeux. Respirez naturellement. Observez chaque souffle. Laissez chaque expiration relâcher un peu plus de tension."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep eyes slightly open with a soft downward gaze if closing them feels uncomfortable",
                 "Place a hand on your belly to feel the breath"],
            fr: ["Gardez les yeux légèrement ouverts avec un regard doux vers le bas si les fermer est inconfortable",
                 "Placez une main sur le ventre pour ressentir le souffle"]
        ),
        contraindications: LocalizedStringArray(en: [], fr: []),
        breathingPattern: LocalizedString(
            en: "Natural breathing — observe without controlling",
            fr: "Respiration naturelle — observez sans contrôler"
        ),
        isFree: true
    )

    // MARK: - Intermediate Poses (Premium)

    public static let seatedEagleArms = Pose(
        id: "seated-eagle-arms",
        name: LocalizedString(
            en: "Seated Eagle Arms",
            fr: "Bras de l'aigle assis"
        ),
        description: LocalizedString(
            en: "Extend both arms forward. Cross the right arm under the left at the elbows. Bend both elbows and try to bring the palms together (or backs of hands). Lift the elbows to shoulder height while keeping the shoulders down. Hold, then switch sides.",
            fr: "Étendez les deux bras devant vous. Croisez le bras droit sous le gauche au niveau des coudes. Pliez les deux coudes et essayez de joindre les paumes (ou le dos des mains). Soulevez les coudes à la hauteur des épaules en gardant les épaules basses. Maintenez, puis changez de côté."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .shoulders,
        imageName: "pose.seated.eagle.arms",
        voiceCueText: LocalizedString(
            en: "Wrap your arms into Eagle. Lift your elbows, drop your shoulders. Breathe into the space between your shoulder blades.",
            fr: "Enroulez vos bras en Aigle. Soulevez les coudes, abaissez les épaules. Respirez dans l'espace entre les omoplates."
        ),
        modifications: LocalizedStringArray(
            en: ["Hug yourself with opposite hands on shoulders if wrapping is too difficult",
                 "Use a strap between hands if palms don't touch"],
            fr: ["Serrez-vous dans vos bras, mains sur les épaules opposées, si l'enroulement est trop difficile",
                 "Utilisez une sangle entre les mains si les paumes ne se touchent pas"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a shoulder injury or recent shoulder surgery"],
            fr: ["Évitez en cas de blessure à l'épaule ou de chirurgie récente de l'épaule"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady breathing, inhale to lift elbows, exhale to soften shoulders",
            fr: "Respiration régulière, inspirez pour lever les coudes, expirez pour relâcher les épaules"
        ),
        isFree: false
    )

    public static let seatedPigeon = Pose(
        id: "seated-pigeon",
        name: LocalizedString(
            en: "Seated Pigeon",
            fr: "Pigeon assis"
        ),
        description: LocalizedString(
            en: "Sit tall and place your right ankle on top of your left knee, forming a figure 4. Flex your right foot to protect the knee. Keep your spine straight and gently press the right knee down with your hand. For a deeper stretch, hinge forward from the hips. Hold, then switch legs.",
            fr: "Assoyez-vous bien droit et placez la cheville droite sur le genou gauche, formant un 4. Fléchissez le pied droit pour protéger le genou. Gardez la colonne droite et appuyez doucement le genou droit vers le bas avec la main. Pour un étirement plus profond, penchez-vous vers l'avant à partir des hanches. Maintenez, puis changez de jambe."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .hips,
        imageName: "pose.seated.pigeon",
        voiceCueText: LocalizedString(
            en: "Cross your ankle over the opposite knee. Keep the top foot flexed. Breathe into the stretch in your outer hip.",
            fr: "Croisez la cheville sur le genou opposé. Gardez le pied du dessus fléchi. Respirez dans l'étirement de la hanche extérieure."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the crossed ankle lower on the shin instead of the knee",
                 "Skip the forward fold if the hip stretch alone is enough"],
            fr: ["Gardez la cheville croisée plus bas sur le tibia plutôt que sur le genou",
                 "Laissez tomber la flexion avant si l'étirement de la hanche suffit"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a knee injury on either leg",
                 "Skip if you have had a recent hip replacement"],
            fr: ["Évitez en cas de blessure au genou sur l'une ou l'autre jambe",
                 "Laissez tomber en cas de remplacement récent de la hanche"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow exhales to release into the hip stretch",
            fr: "Expirations lentes pour se relâcher dans l'étirement de la hanche"
        ),
        isFree: false
    )

    public static let seatedWarriorII = Pose(
        id: "seated-warrior-2",
        name: LocalizedString(
            en: "Seated Warrior II",
            fr: "Guerrier II assis"
        ),
        description: LocalizedString(
            en: "Sit sideways on the chair with your right thigh on the seat and your left leg extended behind you, toes on the floor. Open your arms wide, right arm forward and left arm back, palms down. Gaze over your front fingertips. Keep your torso upright and centred. Hold, then turn and switch sides.",
            fr: "Assoyez-vous de côté sur la chaise, la cuisse droite sur le siège et la jambe gauche étendue derrière vous, orteils au sol. Ouvrez les bras largement, bras droit devant et bras gauche derrière, paumes vers le bas. Regardez par-dessus le bout de vos doigts avant. Gardez le torse droit et centré. Maintenez, puis tournez-vous et changez de côté."
        ),
        durationSeconds: 40,
        difficulty: .intermediate,
        category: .fullBody,
        imageName: "pose.seated.warrior2",
        voiceCueText: LocalizedString(
            en: "Open into Warrior Two. Reach through both fingertips. Feel strong and grounded through your seat.",
            fr: "Ouvrez-vous en Guerrier Deux. Étirez-vous à travers les deux bouts des doigts. Sentez-vous fort et ancré à travers votre siège."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep both feet on the floor for balance",
                 "Rest the back hand on the chair back for stability"],
            fr: ["Gardez les deux pieds au sol pour l'équilibre",
                 "Appuyez la main arrière sur le dossier de la chaise pour la stabilité"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have hip pain that worsens with external rotation"],
            fr: ["Évitez si vous avez une douleur à la hanche qui empire avec la rotation externe"]
        ),
        breathingPattern: LocalizedString(
            en: "Strong steady breaths, inhale to lengthen, exhale to ground",
            fr: "Respirations fortes et régulières, inspirez pour allonger, expirez pour ancrer"
        ),
        isFree: false
    )

    public static let seatedSideBend = Pose(
        id: "seated-side-bend",
        name: LocalizedString(
            en: "Seated Side Bend",
            fr: "Flexion latérale assise"
        ),
        description: LocalizedString(
            en: "Sit tall with feet flat on the floor. Raise your right arm overhead. On an exhale, lean to the left, reaching the right arm over and to the left. Keep both sit bones grounded on the chair. The left hand rests on the seat or armrest. Hold, then switch sides.",
            fr: "Assoyez-vous droit, pieds à plat au sol. Levez le bras droit au-dessus de la tête. À l'expiration, penchez-vous vers la gauche en étirant le bras droit vers la gauche. Gardez les deux ischions bien ancrés sur la chaise. La main gauche repose sur le siège ou l'accoudoir. Maintenez, puis changez de côté."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .spine,
        imageName: "pose.seated.side.bend",
        voiceCueText: LocalizedString(
            en: "Reach up and over. Breathe into the stretch along your ribcage. Keep both sit bones on the chair.",
            fr: "Étirez-vous vers le haut et par-dessus. Respirez dans l'étirement le long de la cage thoracique. Gardez les deux ischions sur la chaise."
        ),
        modifications: LocalizedStringArray(
            en: ["Rest the lower hand on the chair seat for support",
                 "Bend the raised elbow if full extension is too intense"],
            fr: ["Appuyez la main du bas sur le siège de la chaise pour du soutien",
                 "Pliez le coude levé si l'extension complète est trop intense"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have pain on one side of the ribcage"],
            fr: ["Évitez en cas de douleur d'un côté de la cage thoracique"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen, exhale to bend deeper",
            fr: "Inspirez pour allonger, expirez pour plier plus profondément"
        ),
        isFree: false
    )

    public static let seatedHeartOpener = Pose(
        id: "seated-heart-opener",
        name: LocalizedString(
            en: "Seated Heart Opener",
            fr: "Ouverture du cœur assise"
        ),
        description: LocalizedString(
            en: "Sit at the front of the chair. Reach both hands behind you and hold the chair back or seat edges. On an inhale, gently press your chest forward and up, drawing your shoulder blades together. Lift the sternum without compressing the lower back. Keep the neck long and neutral.",
            fr: "Assoyez-vous au bord avant de la chaise. Tendez les deux mains derrière vous et agrippez le dossier ou les rebords du siège. À l'inspiration, poussez doucement la poitrine vers l'avant et vers le haut en rapprochant les omoplates. Soulevez le sternum sans comprimer le bas du dos. Gardez le cou long et neutre."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .spine,
        imageName: "pose.seated.heart.opener",
        voiceCueText: LocalizedString(
            en: "Press your chest forward and lift your heart. Squeeze the shoulder blades together. Breathe into the openness.",
            fr: "Poussez la poitrine vers l'avant et soulevez le cœur. Serrez les omoplates ensemble. Respirez dans l'ouverture."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the movement small — stop if you feel lower back compression",
                 "Interlace fingers behind the back instead of gripping the chair"],
            fr: ["Gardez le mouvement petit — arrêtez si vous sentez une compression au bas du dos",
                 "Entrelacez les doigts derrière le dos au lieu d'agripper la chaise"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute lower back pain or spinal stenosis"],
            fr: ["Évitez en cas de douleur aiguë au bas du dos ou de sténose spinale"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to open, exhale to soften the effort",
            fr: "Inspirez pour ouvrir, expirez pour adoucir l'effort"
        ),
        isFree: false
    )

    public static let seatedAnklesToKnees = Pose(
        id: "seated-ankles-to-knees",
        name: LocalizedString(
            en: "Seated Fire Log",
            fr: "Bûche de feu assise"
        ),
        description: LocalizedString(
            en: "Sit tall. Place your left ankle on top of your right knee, and stack your left knee directly above your right ankle, forming parallel shins. Flex both feet. If this is too intense, simply cross your ankles beneath the chair. For more depth, hinge forward from the hips.",
            fr: "Assoyez-vous bien droit. Placez la cheville gauche sur le genou droit, et alignez le genou gauche directement au-dessus de la cheville droite, formant des tibias parallèles. Fléchissez les deux pieds. Si c'est trop intense, croisez simplement les chevilles sous la chaise. Pour plus de profondeur, penchez-vous vers l'avant à partir des hanches."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .hips,
        imageName: "pose.seated.fire.log",
        voiceCueText: LocalizedString(
            en: "Stack your shins. Flex your feet. Breathe into the outer hips and sit tall.",
            fr: "Empilez vos tibias. Fléchissez les pieds. Respirez dans les hanches extérieures et tenez-vous droit."
        ),
        modifications: LocalizedStringArray(
            en: ["Cross ankles under the chair if full stacking is too intense",
                 "Place a folded towel under the top knee for support"],
            fr: ["Croisez les chevilles sous la chaise si l'empilement complet est trop intense",
                 "Placez une serviette pliée sous le genou du dessus pour du soutien"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with knee injuries or recent knee surgery"],
            fr: ["Évitez en cas de blessure au genou ou de chirurgie récente du genou"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow breaths, exhale to release into the hip stretch",
            fr: "Respirations lentes, expirez pour relâcher dans l'étirement de la hanche"
        ),
        isFree: false
    )

    public static let seatedExtendedSideBend = Pose(
        id: "seated-extended-side-angle",
        name: LocalizedString(
            en: "Seated Extended Side Angle",
            fr: "Angle latéral étendu assis"
        ),
        description: LocalizedString(
            en: "Open your legs wide while seated. Turn your right foot out 90 degrees. Lean your torso to the right, placing your right forearm on your right thigh. Extend your left arm overhead alongside your ear. Feel the stretch through the left side body.",
            fr: "Ouvrez les jambes largement en position assise. Tournez le pied droit à 90 degrés vers l'extérieur. Penchez le torse vers la droite, en plaçant l'avant-bras droit sur la cuisse droite. Étendez le bras gauche au-dessus de la tête le long de l'oreille. Sentez l'étirement le long du côté gauche du corps."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .fullBody,
        imageName: "pose.seated.extended.side",
        voiceCueText: LocalizedString(
            en: "Lean to the side and reach long through the top arm. Open your chest toward the ceiling. Breathe deeply.",
            fr: "Penchez-vous sur le côté et allongez-vous à travers le bras du dessus. Ouvrez la poitrine vers le plafond. Respirez profondément."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the top arm on the hip if reaching overhead is too much",
                 "Don't lean as far — stay upright with a gentle tilt"],
            fr: ["Gardez le bras du dessus sur la hanche si le lever au-dessus est trop",
                 "Ne penchez pas autant — restez droit avec une légère inclinaison"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have groin or inner thigh injury"],
            fr: ["Évitez en cas de blessure à l'aine ou à l'intérieur de la cuisse"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the side body, exhale to deepen",
            fr: "Inspirez pour allonger le côté du corps, expirez pour approfondir"
        ),
        isFree: false
    )

    // MARK: - Advanced Poses (Premium)

    public static let seatedSunSalutation = Pose(
        id: "seated-sun-salutation",
        name: LocalizedString(
            en: "Seated Sun Salutation",
            fr: "Salutation au soleil assise"
        ),
        description: LocalizedString(
            en: "Begin in Seated Mountain. Inhale, sweep arms overhead with palms together. Exhale, forward fold over your legs. Inhale, rise halfway with a flat back, hands on shins. Exhale, fold again. Inhale, sweep arms out and up to return to start. This is one cycle.",
            fr: "Commencez en Montagne assise. Inspirez, balayez les bras au-dessus de la tête, paumes ensemble. Expirez, penchez-vous vers l'avant par-dessus les jambes. Inspirez, relevez-vous à mi-chemin avec le dos plat, mains sur les tibias. Expirez, repliez-vous. Inspirez, balayez les bras vers l'extérieur et vers le haut pour revenir au début. Ceci est un cycle."
        ),
        durationSeconds: 60,
        difficulty: .advanced,
        category: .fullBody,
        imageName: "pose.seated.sun.salutation",
        voiceCueText: LocalizedString(
            en: "Flow through each movement with your breath. One breath, one movement. Feel the warmth build.",
            fr: "Enchaînez chaque mouvement avec votre souffle. Un souffle, un mouvement. Sentez la chaleur monter."
        ),
        modifications: LocalizedStringArray(
            en: ["Slow down the pace — take two breaths per movement if needed",
                 "Skip the halfway lift if back extension is uncomfortable"],
            fr: ["Ralentissez le rythme — prenez deux respirations par mouvement au besoin",
                 "Sautez le demi-relevé si l'extension du dos est inconfortable"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Move slowly if you have vertigo or blood pressure concerns"],
            fr: ["Bougez lentement en cas de vertige ou de problèmes de pression artérielle"]
        ),
        breathingPattern: LocalizedString(
            en: "One inhale or exhale per movement — coordinated breath-to-motion",
            fr: "Une inspiration ou expiration par mouvement — coordination souffle-mouvement"
        ),
        isFree: false
    )

    public static let seatedTreePose = Pose(
        id: "seated-tree",
        name: LocalizedString(
            en: "Seated Tree Pose",
            fr: "Arbre assis"
        ),
        description: LocalizedString(
            en: "Sit tall at the edge of the chair. Plant your left foot firmly on the floor. Place the sole of your right foot against your left inner calf or thigh (never the knee). Bring your palms together at your heart or raise arms overhead. Focus on a fixed point for balance.",
            fr: "Assoyez-vous droit au bord de la chaise. Plantez le pied gauche fermement au sol. Placez la plante du pied droit contre l'intérieur du mollet ou de la cuisse gauche (jamais le genou). Joignez les paumes au niveau du cœur ou levez les bras au-dessus de la tête. Fixez un point pour l'équilibre."
        ),
        durationSeconds: 35,
        difficulty: .advanced,
        category: .balance,
        imageName: "pose.seated.tree",
        voiceCueText: LocalizedString(
            en: "Find your Tree Pose. Root through your grounded foot. Fix your gaze. Breathe steadily.",
            fr: "Trouvez votre posture de l'Arbre. Ancrez-vous à travers le pied au sol. Fixez votre regard. Respirez de façon régulière."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the raised foot on the floor with heel against the opposite ankle",
                 "Hold the chair seat with one hand for stability"],
            fr: ["Gardez le pied levé au sol, talon contre la cheville opposée",
                 "Tenez le siège de la chaise d'une main pour la stabilité"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have significant balance disorders — keep one hand on the chair"],
            fr: ["Évitez en cas de troubles significatifs de l'équilibre — gardez une main sur la chaise"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady, calm breaths to maintain balance",
            fr: "Respirations régulières et calmes pour maintenir l'équilibre"
        ),
        isFree: false
    )

    // MARK: - Additional Poses

    public static let seatedAnkleCircles = Pose(
        id: "seated-ankle-circles",
        name: LocalizedString(
            en: "Seated Ankle Circles",
            fr: "Cercles des chevilles assis"
        ),
        description: LocalizedString(
            en: "Extend one leg forward, lifting the foot off the floor. Rotate the ankle slowly in circles, 5 times clockwise and 5 times counterclockwise. Switch legs.",
            fr: "Étendez une jambe devant vous en soulevant le pied du sol. Faites tourner la cheville lentement en cercles, 5 fois dans le sens horaire et 5 fois dans le sens antihoraire. Changez de jambe."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .balance,
        imageName: "pose.ankle.circles",
        voiceCueText: LocalizedString(
            en: "Circle your ankle slowly. Keep the rest of your leg still. This improves circulation.",
            fr: "Faites des cercles avec la cheville lentement. Gardez le reste de la jambe immobile. Cela améliore la circulation."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the heel on the floor and just lift the toes to make circles"],
            fr: ["Gardez le talon au sol et soulevez seulement les orteils pour faire des cercles"]
        ),
        contraindications: LocalizedStringArray(en: [], fr: []),
        breathingPattern: LocalizedString(
            en: "Breathe naturally throughout",
            fr: "Respirez naturellement tout au long"
        ),
        isFree: true
    )

    public static let seatedWristStretches = Pose(
        id: "seated-wrist-stretches",
        name: LocalizedString(
            en: "Seated Wrist & Finger Stretches",
            fr: "Étirements des poignets et doigts assis"
        ),
        description: LocalizedString(
            en: "Extend one arm forward, palm up. With the other hand, gently pull the fingers back toward you. Hold for a few breaths, then flip the palm down and press fingers toward the floor. Switch hands.",
            fr: "Étendez un bras devant vous, paume vers le haut. Avec l'autre main, tirez doucement les doigts vers vous. Maintenez quelques respirations, puis retournez la paume vers le bas et pressez les doigts vers le sol. Changez de main."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .shoulders,
        imageName: "pose.wrist.stretches",
        voiceCueText: LocalizedString(
            en: "Stretch your wrists gently. This is especially helpful if you work at a computer.",
            fr: "Étirez vos poignets doucement. C'est particulièrement utile si vous travaillez à l'ordinateur."
        ),
        modifications: LocalizedStringArray(
            en: ["Make gentle fists and rotate the wrists instead of pulling fingers"],
            fr: ["Faites des poings légers et faites tourner les poignets au lieu de tirer les doigts"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have carpal tunnel syndrome — keep the stretch very gentle"],
            fr: ["Évitez en cas de syndrome du canal carpien — gardez l'étirement très doux"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow breathing, exhale as you deepen the stretch",
            fr: "Respiration lente, expirez en approfondissant l'étirement"
        ),
        isFree: true
    )

    public static let seatedHighKneeLifts = Pose(
        id: "seated-knee-lifts",
        name: LocalizedString(
            en: "Seated Knee Lifts",
            fr: "Levées de genoux assis"
        ),
        description: LocalizedString(
            en: "Sit tall with feet flat on the floor. On an exhale, lift your right knee toward your chest, hold briefly, then lower with control. Alternate legs. Keep your spine upright — do not lean back.",
            fr: "Assoyez-vous droit, pieds à plat au sol. À l'expiration, soulevez le genou droit vers la poitrine, maintenez brièvement, puis descendez avec contrôle. Alternez les jambes. Gardez la colonne droite — ne vous penchez pas vers l'arrière."
        ),
        durationSeconds: 40,
        difficulty: .beginner,
        category: .fullBody,
        imageName: "pose.knee.lifts",
        voiceCueText: LocalizedString(
            en: "Lift your knee, hold, and lower slowly. Keep your core engaged and your back tall.",
            fr: "Soulevez le genou, maintenez, et descendez lentement. Gardez le tronc engagé et le dos droit."
        ),
        modifications: LocalizedStringArray(
            en: ["Hold the sides of the chair for support",
                 "Lift the knee only partway if full range is too difficult"],
            fr: ["Tenez les côtés de la chaise pour du soutien",
                 "Soulevez le genou seulement à mi-chemin si l'amplitude complète est trop difficile"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have acute hip flexor pain"],
            fr: ["Évitez en cas de douleur aiguë aux fléchisseurs de la hanche"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to lift, inhale to lower",
            fr: "Expirez pour lever, inspirez pour descendre"
        ),
        isFree: true
    )

    public static let seatedGoddess = Pose(
        id: "seated-goddess",
        name: LocalizedString(
            en: "Seated Goddess",
            fr: "Déesse assise"
        ),
        description: LocalizedString(
            en: "Sit at the edge of the chair with legs wide and feet turned out at 45 degrees. Place hands on inner thighs. Inhale to lengthen the spine, then gently press the thighs open with your hands. Lift the chest and gaze forward.",
            fr: "Assoyez-vous au bord de la chaise, jambes écartées et pieds tournés vers l'extérieur à 45 degrés. Placez les mains sur l'intérieur des cuisses. Inspirez pour allonger la colonne, puis appuyez doucement les cuisses vers l'extérieur avec les mains. Soulevez la poitrine et regardez devant vous."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .hips,
        imageName: "pose.seated.goddess",
        voiceCueText: LocalizedString(
            en: "Open your legs wide in Goddess. Press the thighs open. Feel strong and expansive.",
            fr: "Ouvrez les jambes largement en Déesse. Poussez les cuisses vers l'extérieur. Sentez-vous fort et expansif."
        ),
        modifications: LocalizedStringArray(
            en: ["Don't press the thighs — let gravity create the stretch",
                 "Bring the feet closer together if the stretch is too intense"],
            fr: ["N'appuyez pas sur les cuisses — laissez la gravité créer l'étirement",
                 "Rapprochez les pieds si l'étirement est trop intense"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have groin or inner thigh injury"],
            fr: ["Évitez en cas de blessure à l'aine ou à l'intérieur de la cuisse"]
        ),
        breathingPattern: LocalizedString(
            en: "Deep belly breaths, exhale to open wider",
            fr: "Respirations profondes du ventre, expirez pour ouvrir plus largement"
        ),
        isFree: false
    )

    public static let seatedReverseWarrior = Pose(
        id: "seated-reverse-warrior",
        name: LocalizedString(
            en: "Seated Reverse Warrior",
            fr: "Guerrier inversé assis"
        ),
        description: LocalizedString(
            en: "From Seated Warrior II, keep the front knee bent. On an inhale, reach your front arm up and back overhead while the back hand slides down the back leg. Create a long arc through the side body. Gaze up toward the raised hand.",
            fr: "À partir du Guerrier II assis, gardez le genou avant plié. À l'inspiration, levez le bras avant vers le haut et vers l'arrière au-dessus de la tête tandis que la main arrière glisse le long de la jambe arrière. Créez un long arc le long du côté du corps. Regardez vers la main levée."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .fullBody,
        imageName: "pose.seated.reverse.warrior",
        voiceCueText: LocalizedString(
            en: "Reach up and back. Open through the side body. Feel the stretch from hip to fingertips.",
            fr: "Étirez-vous vers le haut et vers l'arrière. Ouvrez le côté du corps. Sentez l'étirement de la hanche jusqu'au bout des doigts."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the raised arm bent if full extension is too much",
                 "Place the back hand on the chair seat instead of the leg"],
            fr: ["Gardez le bras levé plié si l'extension complète est trop",
                 "Placez la main arrière sur le siège au lieu de la jambe"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid deep backbend if you have spinal issues"],
            fr: ["Évitez la cambrure profonde en cas de problèmes vertébraux"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to reach, exhale to settle deeper",
            fr: "Inspirez pour vous étirer, expirez pour vous installer plus profondément"
        ),
        isFree: false
    )

    public static let seatedCrescentMoon = Pose(
        id: "seated-crescent-moon",
        name: LocalizedString(
            en: "Seated Crescent Moon",
            fr: "Croissant de lune assis"
        ),
        description: LocalizedString(
            en: "Interlace your fingers and press your palms toward the ceiling. On an exhale, lean to the right, creating a C-shape with your torso. Keep both sit bones on the chair and both arms framing your head. Hold, then switch sides.",
            fr: "Entrelacez les doigts et poussez les paumes vers le plafond. À l'expiration, penchez-vous vers la droite en créant un C avec le torse. Gardez les deux ischions sur la chaise et les deux bras encadrant la tête. Maintenez, puis changez de côté."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .spine,
        imageName: "pose.seated.crescent.moon",
        voiceCueText: LocalizedString(
            en: "Reach up and lean to the side. Create a crescent shape. Breathe into the long side of your body.",
            fr: "Étirez-vous vers le haut et penchez-vous sur le côté. Créez une forme de croissant. Respirez dans le côté long du corps."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep one hand on the chair seat for support",
                 "Don't interlace — just reach one arm up"],
            fr: ["Gardez une main sur le siège pour du soutien",
                 "N'entrelacez pas — levez simplement un bras"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have acute rib or intercostal pain"],
            fr: ["Évitez en cas de douleur aiguë aux côtes ou intercostale"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen up, exhale to bend to the side",
            fr: "Inspirez pour allonger vers le haut, expirez pour plier sur le côté"
        ),
        isFree: false
    )

    public static let seatedChestExpansion = Pose(
        id: "seated-chest-expansion",
        name: LocalizedString(
            en: "Seated Chest Expansion",
            fr: "Expansion de la poitrine assise"
        ),
        description: LocalizedString(
            en: "Sit at the front of the chair. Interlace your hands behind your back. On an inhale, straighten your arms and lift them away from your back, squeezing the shoulder blades together. Open the chest and gaze slightly upward.",
            fr: "Assoyez-vous au bord avant de la chaise. Entrelacez les mains derrière le dos. À l'inspiration, tendez les bras et soulevez-les loin du dos en serrant les omoplates ensemble. Ouvrez la poitrine et regardez légèrement vers le haut."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .shoulders,
        imageName: "pose.seated.chest.expansion",
        voiceCueText: LocalizedString(
            en: "Clasp your hands behind you and lift. Open your chest wide. Breathe into the front of your body.",
            fr: "Joignez les mains derrière vous et soulevez. Ouvrez la poitrine largement. Respirez dans l'avant de votre corps."
        ),
        modifications: LocalizedStringArray(
            en: ["Hold a strap or towel between your hands if they don't reach",
                 "Keep arms bent if straightening is too intense"],
            fr: ["Tenez une sangle ou serviette entre les mains si elles ne se rejoignent pas",
                 "Gardez les bras pliés si les tendre est trop intense"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with rotator cuff injuries or frozen shoulder"],
            fr: ["Évitez en cas de blessure à la coiffe des rotateurs ou d'épaule gelée"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift and expand, exhale to release",
            fr: "Inspirez pour lever et ouvrir, expirez pour relâcher"
        ),
        isFree: false
    )

    public static let seatedThreadTheNeedle = Pose(
        id: "seated-thread-needle",
        name: LocalizedString(
            en: "Seated Thread the Needle",
            fr: "Enfiler l'aiguille assis"
        ),
        description: LocalizedString(
            en: "Sit tall and extend both arms to the sides. Thread your right arm under your left arm, rotating your torso to the left. Rest the right shoulder toward your left knee. The left hand can press against the chair for a deeper twist. Switch sides.",
            fr: "Assoyez-vous bien droit et étendez les deux bras sur les côtés. Passez le bras droit sous le bras gauche en tournant le torse vers la gauche. Reposez l'épaule droite vers le genou gauche. La main gauche peut s'appuyer sur la chaise pour une torsion plus profonde. Changez de côté."
        ),
        durationSeconds: 35,
        difficulty: .advanced,
        category: .spine,
        imageName: "pose.seated.thread.needle",
        voiceCueText: LocalizedString(
            en: "Thread your arm through and twist. Feel the rotation through your mid-back. Breathe into the twist.",
            fr: "Passez le bras à travers et tournez. Sentez la rotation dans le milieu du dos. Respirez dans la torsion."
        ),
        modifications: LocalizedStringArray(
            en: ["Don't thread as deeply — just twist with both hands on knees",
                 "Place a pillow on your lap for the threading arm to rest on"],
            fr: ["Ne passez pas aussi profondément — tournez simplement avec les mains sur les genoux",
                 "Placez un coussin sur vos cuisses pour que le bras repose dessus"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute spinal conditions or recent back surgery"],
            fr: ["Évitez en cas de conditions spinales aiguës ou de chirurgie récente du dos"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to thread deeper, inhale to create space",
            fr: "Expirez pour passer plus profondément, inspirez pour créer de l'espace"
        ),
        isFree: false
    )

    public static let seatedBreathOfJoy = Pose(
        id: "seated-breath-of-joy",
        name: LocalizedString(
            en: "Seated Breath of Joy",
            fr: "Souffle de joie assis"
        ),
        description: LocalizedString(
            en: "This is a three-part energizing breath with movement. Inhale 1/3: sweep arms forward to shoulder height. Inhale 2/3: open arms wide to the sides. Inhale 3/3: sweep arms overhead. Exhale fully: fold forward and let arms swing down. Repeat rhythmically.",
            fr: "C'est un souffle énergisant en trois parties avec mouvement. Inspiration 1/3 : balayez les bras vers l'avant à la hauteur des épaules. Inspiration 2/3 : ouvrez les bras largement sur les côtés. Inspiration 3/3 : balayez les bras au-dessus de la tête. Expirez complètement : penchez-vous vers l'avant et laissez les bras descendre. Répétez de façon rythmique."
        ),
        durationSeconds: 45,
        difficulty: .advanced,
        category: .breathing,
        imageName: "pose.breath.of.joy",
        voiceCueText: LocalizedString(
            en: "Three quick inhales with arm sweeps, then a full exhale and fold. Feel the energy build!",
            fr: "Trois inspirations rapides avec des mouvements de bras, puis une expiration complète et pliez. Sentez l'énergie monter!"
        ),
        modifications: LocalizedStringArray(
            en: ["Make smaller arm movements if full sweeps cause dizziness",
                 "Stay upright on the exhale instead of folding forward"],
            fr: ["Faites de plus petits mouvements de bras si les grands mouvements causent des étourdissements",
                 "Restez droit à l'expiration au lieu de plier vers l'avant"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have uncontrolled blood pressure or feel dizzy",
                 "Not recommended during migraine episodes"],
            fr: ["Évitez en cas de pression artérielle non contrôlée ou d'étourdissements",
                 "Non recommandé pendant les épisodes de migraine"]
        ),
        breathingPattern: LocalizedString(
            en: "Three staccato inhales through the nose, one full exhale through the mouth",
            fr: "Trois inspirations staccato par le nez, une expiration complète par la bouche"
        ),
        isFree: false
    )

    public static let seatedHalfMoon = Pose(
        id: "seated-half-moon",
        name: LocalizedString(
            en: "Seated Half Moon Balance",
            fr: "Demi-lune en équilibre assis"
        ),
        description: LocalizedString(
            en: "Sit at the edge of the chair. Extend your right leg straight to the side with toes on the floor. Raise your left arm overhead and lean to the right, creating a long line from left hand to left hip. The right hand rests on the right thigh or the chair. Focus on balance and length.",
            fr: "Assoyez-vous au bord de la chaise. Étendez la jambe droite sur le côté, orteils au sol. Levez le bras gauche au-dessus de la tête et penchez-vous vers la droite, créant une longue ligne de la main gauche à la hanche gauche. La main droite repose sur la cuisse droite ou la chaise. Concentrez-vous sur l'équilibre et la longueur."
        ),
        durationSeconds: 30,
        difficulty: .advanced,
        category: .balance,
        imageName: "pose.seated.half.moon",
        voiceCueText: LocalizedString(
            en: "Extend your leg and reach overhead. Create one long line through your body. Find your balance.",
            fr: "Étendez la jambe et étirez-vous au-dessus de la tête. Créez une longue ligne à travers le corps. Trouvez votre équilibre."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the extended leg bent with foot on the floor",
                 "Hold the chair with the lower hand for stability"],
            fr: ["Gardez la jambe étendue pliée avec le pied au sol",
                 "Tenez la chaise avec la main du bas pour la stabilité"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have severe balance issues without chair support"],
            fr: ["Évitez en cas de troubles graves de l'équilibre sans soutien de la chaise"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady breaths to maintain balance — exhale to extend further",
            fr: "Respirations régulières pour maintenir l'équilibre — expirez pour vous étendre davantage"
        ),
        isFree: false
    )

    // MARK: - Chair Yoga Pose Collection

    public static let chairYogaPoses: [Pose] = [
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

    // MARK: - Chair Yoga Plans

    public static let beginnerFlow = WorkoutPlan(
        id: "beginner-chair-flow",
        name: LocalizedString(
            en: "Gentle Chair Flow",
            fr: "Enchaînement doux sur chaise"
        ),
        description: LocalizedString(
            en: "A calming 5-minute sequence perfect for beginners or a quick break at your desk.",
            fr: "Un enchaînement apaisant de 5 minutes, parfait pour les débutants ou une pause rapide au bureau."
        ),
        style: .chairYoga,
        poses: chairYogaPoses.filter(\.isFree),
        transitionSeconds: 5,
        isFree: true
    )

    public static let morningWakeUp = WorkoutPlan(
        id: "morning-wake-up",
        name: LocalizedString(
            en: "Morning Wake-Up Flow",
            fr: "Enchaînement réveil matinal"
        ),
        description: LocalizedString(
            en: "An energizing 8-minute sequence to start your day with gentle spinal movement and breath work.",
            fr: "Un enchaînement énergisant de 8 minutes pour commencer la journée avec des mouvements doux de la colonne et un travail du souffle."
        ),
        style: .chairYoga,
        poses: [seatedMountain, shoulderRolls, neckRolls, seatedCatCow, seatedSpinalTwist, seatedSideBend, seatedHeartOpener, seatedSunSalutation, seatedMeditation],
        transitionSeconds: 5,
        isFree: false
    )

    public static let hipOpener = WorkoutPlan(
        id: "hip-opener-flow",
        name: LocalizedString(
            en: "Hip Opening Flow",
            fr: "Enchaînement d'ouverture des hanches"
        ),
        description: LocalizedString(
            en: "A 10-minute session focused on releasing tension in the hips and lower body.",
            fr: "Une séance de 10 minutes axée sur le relâchement des tensions dans les hanches et le bas du corps."
        ),
        style: .chairYoga,
        poses: [seatedMountain, seatedCatCow, seatedPigeon, seatedAnklesToKnees, seatedWarriorII, seatedExtendedSideBend, seatedForwardFold, seatedMeditation],
        transitionSeconds: 5,
        isFree: false
    )

    public static let fullBody = WorkoutPlan(
        id: "full-body-chair-yoga",
        name: LocalizedString(
            en: "Full Body Chair Yoga",
            fr: "Yoga sur chaise corps complet"
        ),
        description: LocalizedString(
            en: "A comprehensive 15-minute session working through every major area of the body.",
            fr: "Une séance complète de 15 minutes travaillant toutes les zones principales du corps."
        ),
        style: .chairYoga,
        poses: chairYogaPoses,
        transitionSeconds: 5,
        isFree: false
    )

    public static let deskBreak = WorkoutPlan(
        id: "desk-break",
        name: LocalizedString(
            en: "Quick Desk Break",
            fr: "Pause bureau rapide"
        ),
        description: LocalizedString(
            en: "A focused 5-minute break targeting neck, shoulders, and wrists — perfect for office workers.",
            fr: "Une pause ciblée de 5 minutes pour le cou, les épaules et les poignets — parfaite pour les travailleurs de bureau."
        ),
        style: .chairYoga,
        poses: [seatedMountain, neckRolls, shoulderRolls, seatedWristStretches, seatedChestExpansion, seatedCrescentMoon, seatedMeditation],
        transitionSeconds: 3,
        isFree: false
    )

    public static let advancedFlow = WorkoutPlan(
        id: "advanced-chair-flow",
        name: LocalizedString(
            en: "Advanced Chair Yoga",
            fr: "Yoga sur chaise avancé"
        ),
        description: LocalizedString(
            en: "A challenging 12-minute session with dynamic breath work, balance poses, and deep twists.",
            fr: "Une séance stimulante de 12 minutes avec un travail dynamique du souffle, des postures d'équilibre et des torsions profondes."
        ),
        style: .chairYoga,
        poses: [seatedMountain, seatedSunSalutation, seatedWarriorII, seatedReverseWarrior, seatedTreePose, seatedThreadTheNeedle, seatedBreathOfJoy, seatedHalfMoon, seatedForwardFold, seatedMeditation],
        transitionSeconds: 5,
        isFree: false
    )

    public static let chairYogaPlans: [WorkoutPlan] = [
        beginnerFlow,
        deskBreak,
        morningWakeUp,
        hipOpener,
        fullBody,
        advancedFlow,
    ]
}
