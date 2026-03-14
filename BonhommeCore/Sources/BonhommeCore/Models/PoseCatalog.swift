import Foundation

/// Built-in chair yoga pose library with bilingual content (EN / FR-CA).
/// Poses are refined for accuracy, safety, and accessibility.
public enum PoseCatalog {

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

    // MARK: - Pose Collections

    public static let allPoses: [Pose] = [
        seatedMountain,
        seatedCatCow,
        seatedSpinalTwist,
        seatedForwardFold,
        neckRolls,
        shoulderRolls,
        seatedMeditation,
        seatedEagleArms,
        seatedPigeon,
        seatedWarriorII,
        seatedSideBend,
        seatedHeartOpener,
        seatedAnklesToKnees,
        seatedExtendedSideBend,
        seatedSunSalutation,
        seatedTreePose,
    ]

    public static let freePoses: [Pose] = allPoses.filter(\.isFree)
    public static let premiumPoses: [Pose] = allPoses.filter { !$0.isFree }

    // MARK: - Workout Plans

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
        poses: freePoses,
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
        poses: allPoses,
        transitionSeconds: 5,
        isFree: false
    )

    public static let allPlans: [WorkoutPlan] = [
        beginnerFlow,
        morningWakeUp,
        hipOpener,
        fullBody,
    ]
}
