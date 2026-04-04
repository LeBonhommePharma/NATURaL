import Foundation

// MARK: - Hatha Yoga Poses & Plans

extension PoseCatalog {

    // MARK: - Beginner Poses (Free)

    public static let hathaMountain = Pose(
        id: "hatha-mountain",
        name: LocalizedString(
            en: "Mountain Pose (Tadasana)",
            fr: "Posture de la montagne (Tadasana)"
        ),
        description: LocalizedString(
            en: "Stand with feet together or hip-width apart, grounding evenly through all four corners of each foot. Engage your thighs, lengthen your tailbone toward the floor, and lift through the crown of your head. Let your arms hang naturally with palms facing forward, shoulders relaxed away from the ears.",
            fr: "Tenez-vous debout, pieds joints ou à la largeur des hanches, en ancrant uniformément les quatre coins de chaque pied au sol. Engagez les cuisses, allongez le coccyx vers le sol et élevez-vous à travers le sommet de la tête. Laissez les bras pendre naturellement, paumes vers l'avant, épaules relâchées loin des oreilles."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .fullBody,
        position: .standing,
        imageName: "pose.hatha.mountain",
        voiceCueText: LocalizedString(
            en: "Stand tall in Mountain Pose. Root down through your feet and rise through the crown of your head.",
            fr: "Tenez-vous bien droit en posture de la montagne. Enracinez-vous à travers les pieds et élevez-vous par le sommet de la tête."
        ),
        modifications: LocalizedStringArray(
            en: ["Separate your feet hip-width apart for better stability",
                 "Stand with your back against a wall for alignment feedback"],
            fr: ["Écartez les pieds à la largeur des hanches pour plus de stabilité",
                 "Tenez-vous dos au mur pour mieux sentir l'alignement"]
        ),
        contraindications: LocalizedStringArray(
            en: ["If you feel dizzy, keep your eyes open and gaze at a fixed point"],
            fr: ["Si vous ressentez des étourdissements, gardez les yeux ouverts et fixez un point"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, steady breaths through the nose — inhale to lengthen, exhale to ground",
            fr: "Respirations lentes et régulières par le nez — inspirez pour allonger, expirez pour ancrer"
        ),
        isFree: true
    )

    public static let hathaTree = Pose(
        id: "hatha-tree",
        name: LocalizedString(
            en: "Tree Pose (Vrksasana)",
            fr: "Posture de l'arbre (Vrksasana)"
        ),
        description: LocalizedString(
            en: "Shift your weight onto your left foot and place the sole of your right foot on your inner left thigh or calf, avoiding the knee joint. Press the foot and leg into each other to create stability. Bring your hands to heart center or extend them overhead like branches.",
            fr: "Transférez le poids sur le pied gauche et placez la plante du pied droit sur l'intérieur de la cuisse ou du mollet gauche, en évitant le genou. Pressez le pied et la jambe l'un contre l'autre pour créer de la stabilité. Amenez les mains au centre du cœur ou étendez-les au-dessus de la tête comme des branches."
        ),
        durationSeconds: 35,
        difficulty: .beginner,
        category: .balance,
        position: .standing,
        imageName: "pose.hatha.tree",
        voiceCueText: LocalizedString(
            en: "Root down through your standing leg. Find a focal point and breathe steadily in Tree Pose.",
            fr: "Enracinez-vous dans la jambe d'appui. Trouvez un point focal et respirez régulièrement en posture de l'arbre."
        ),
        modifications: LocalizedStringArray(
            en: ["Place your foot on your ankle with toes on the floor for less challenge",
                 "Keep one hand on a wall or chair for balance support"],
            fr: ["Placez le pied sur la cheville avec les orteils au sol pour moins de difficulté",
                 "Gardez une main sur un mur ou une chaise pour vous aider à garder l'équilibre"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a recent ankle or knee injury on the standing leg"],
            fr: ["Évitez en cas de blessure récente à la cheville ou au genou de la jambe d'appui"]
        ),
        breathingPattern: LocalizedString(
            en: "Calm, even breaths — inhale to grow tall, exhale to find stillness",
            fr: "Respirations calmes et régulières — inspirez pour grandir, expirez pour trouver l'immobilité"
        ),
        isFree: true
    )

    public static let hathaWarriorI = Pose(
        id: "hatha-warrior-i",
        name: LocalizedString(
            en: "Warrior I (Virabhadrasana I)",
            fr: "Guerrier I (Virabhadrasana I)"
        ),
        description: LocalizedString(
            en: "Step your right foot forward into a lunge with the back foot turned out at 45 degrees. Bend the front knee to 90 degrees, stacking it over the ankle. Lift your arms overhead with palms facing each other, and gently draw the ribcage back to square the hips forward.",
            fr: "Avancez le pied droit en fente avec le pied arrière tourné à 45 degrés. Pliez le genou avant à 90 degrés en l'alignant au-dessus de la cheville. Levez les bras au-dessus de la tête, paumes face à face, et ramenez doucement la cage thoracique vers l'arrière pour aligner les hanches vers l'avant."
        ),
        durationSeconds: 35,
        difficulty: .beginner,
        category: .legs,
        position: .standing,
        imageName: "pose.hatha.warrior.i",
        voiceCueText: LocalizedString(
            en: "Sink into Warrior I. Ground the back heel and reach strongly through your fingertips.",
            fr: "Descendez dans le Guerrier I. Ancrez le talon arrière et étirez-vous puissamment à travers les doigts."
        ),
        modifications: LocalizedStringArray(
            en: ["Shorten your stance if the lunge feels too deep",
                 "Keep hands on hips instead of overhead if shoulders are tight"],
            fr: ["Raccourcissez la fente si elle semble trop profonde",
                 "Gardez les mains sur les hanches au lieu de les lever si les épaules sont tendues"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid deep bending with knee injuries — reduce the depth of the lunge",
                 "Use caution with high blood pressure when holding arms overhead"],
            fr: ["Évitez la flexion profonde en cas de blessures au genou — réduisez la profondeur de la fente",
                 "Soyez prudent en cas d'hypertension artérielle lorsque les bras sont levés"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift and lengthen, exhale to deepen the stance",
            fr: "Inspirez pour vous lever et allonger, expirez pour approfondir la posture"
        ),
        isFree: true
    )

    public static let hathaWarriorII = Pose(
        id: "hatha-warrior-ii",
        name: LocalizedString(
            en: "Warrior II (Virabhadrasana II)",
            fr: "Guerrier II (Virabhadrasana II)"
        ),
        description: LocalizedString(
            en: "From a wide stance, turn your right foot out 90 degrees and your left foot slightly in. Bend the right knee over the right ankle. Extend your arms out to the sides at shoulder height, gazing past your right fingertips. Keep your torso centered directly over your hips.",
            fr: "À partir d'une position large, tournez le pied droit à 90 degrés et le pied gauche légèrement vers l'intérieur. Pliez le genou droit au-dessus de la cheville droite. Étendez les bras sur les côtés à la hauteur des épaules, le regard au-delà des doigts droits. Gardez le torse centré directement au-dessus des hanches."
        ),
        durationSeconds: 35,
        difficulty: .beginner,
        category: .legs,
        position: .standing,
        imageName: "pose.hatha.warrior.ii",
        voiceCueText: LocalizedString(
            en: "Open into Warrior II. Extend energy through both arms equally. Settle the hips down.",
            fr: "Ouvrez-vous dans le Guerrier II. Étendez l'énergie à travers les deux bras également. Descendez les hanches."
        ),
        modifications: LocalizedStringArray(
            en: ["Widen your stance and reduce the bend if the knee feels strained",
                 "Rest your arms on your hips if holding them out is tiring"],
            fr: ["Élargissez la position et réduisez la flexion si le genou semble tendu",
                 "Posez les bras sur les hanches s'il est fatigant de les maintenir étendus"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a hip or groin injury",
                 "Do not let the front knee extend past the ankle"],
            fr: ["Évitez en cas de blessure à la hanche ou à l'aine",
                 "Ne laissez pas le genou avant dépasser la cheville"]
        ),
        breathingPattern: LocalizedString(
            en: "Breathe steadily — inhale to lengthen the spine, exhale to sink deeper",
            fr: "Respirez régulièrement — inspirez pour allonger la colonne, expirez pour descendre plus bas"
        ),
        isFree: true
    )

    public static let hathaTriangle = Pose(
        id: "hatha-triangle",
        name: LocalizedString(
            en: "Triangle Pose (Trikonasana)",
            fr: "Posture du triangle (Trikonasana)"
        ),
        description: LocalizedString(
            en: "From a wide stance with your right foot turned out, straighten both legs. Reach your right arm forward, then hinge at the right hip to lower the right hand to your shin, ankle, or a block. Extend the left arm straight up, stacking the shoulders. Open the chest toward the ceiling.",
            fr: "À partir d'une position large avec le pied droit tourné vers l'extérieur, tendez les deux jambes. Étirez le bras droit vers l'avant, puis basculez à la hanche droite pour descendre la main droite vers le tibia, la cheville ou un bloc. Étendez le bras gauche vers le haut, en empilant les épaules. Ouvrez la poitrine vers le plafond."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .legs,
        position: .standing,
        imageName: "pose.hatha.triangle",
        voiceCueText: LocalizedString(
            en: "Reach long into Triangle. Lengthen both sides of your torso and breathe into the stretch.",
            fr: "Étirez-vous longuement dans le triangle. Allongez les deux côtés du torse et respirez dans l'étirement."
        ),
        modifications: LocalizedStringArray(
            en: ["Place your lower hand on a block instead of the floor or shin",
                 "Bend the front knee slightly if your hamstrings are tight"],
            fr: ["Placez la main du bas sur un bloc au lieu du sol ou du tibia",
                 "Pliez légèrement le genou avant si les ischio-jambiers sont tendus"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have low blood pressure or migraines",
                 "Be cautious with neck injuries — look down instead of up"],
            fr: ["Évitez en cas d'hypotension ou de migraines",
                 "Soyez prudent en cas de blessures au cou — regardez vers le bas au lieu du haut"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the spine, exhale to rotate the chest open",
            fr: "Inspirez pour allonger la colonne, expirez pour ouvrir la poitrine en rotation"
        ),
        isFree: true
    )

    public static let hathaExtendedSideAngle = Pose(
        id: "hatha-extended-side-angle",
        name: LocalizedString(
            en: "Extended Side Angle (Parsvakonasana)",
            fr: "Angle latéral étendu (Parsvakonasana)"
        ),
        description: LocalizedString(
            en: "From Warrior II with the right knee bent, place your right forearm on your right thigh or your right hand on the floor outside the right foot. Extend your left arm over your left ear, creating one long line from the left heel to the left fingertips. Rotate your chest toward the ceiling.",
            fr: "À partir du Guerrier II avec le genou droit plié, placez l'avant-bras droit sur la cuisse droite ou la main droite au sol à l'extérieur du pied droit. Étendez le bras gauche au-dessus de l'oreille gauche, créant une longue ligne du talon gauche au bout des doigts gauches. Tournez la poitrine vers le plafond."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .fullBody,
        position: .standing,
        imageName: "pose.hatha.extended.side.angle",
        voiceCueText: LocalizedString(
            en: "Reach long from heel to fingertips in Extended Side Angle. Breathe into the open side body.",
            fr: "Étirez-vous du talon au bout des doigts dans l'angle latéral étendu. Respirez dans le côté ouvert du corps."
        ),
        modifications: LocalizedStringArray(
            en: ["Rest the forearm on the thigh instead of reaching to the floor",
                 "Use a block under the lower hand for more support"],
            fr: ["Appuyez l'avant-bras sur la cuisse au lieu d'aller vers le sol",
                 "Utilisez un bloc sous la main du bas pour plus de soutien"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute shoulder or neck injuries",
                 "Use caution if you have low blood pressure"],
            fr: ["Évitez en cas de blessures aiguës à l'épaule ou au cou",
                 "Soyez prudent en cas d'hypotension artérielle"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to extend through the upper arm, exhale to ground the back foot",
            fr: "Inspirez pour étendre le bras supérieur, expirez pour ancrer le pied arrière"
        ),
        isFree: true
    )

    public static let hathaStaff = Pose(
        id: "hatha-staff",
        name: LocalizedString(
            en: "Staff Pose (Dandasana)",
            fr: "Posture du bâton (Dandasana)"
        ),
        description: LocalizedString(
            en: "Sit on the floor with both legs extended straight in front of you, feet flexed and toes pointing up. Place your hands beside your hips, fingers pointing forward. Press down through your palms, lift your chest, and lengthen the spine from the tailbone to the crown of the head.",
            fr: "Assoyez-vous au sol avec les deux jambes étendues devant vous, pieds fléchis et orteils pointant vers le haut. Placez les mains à côté des hanches, doigts vers l'avant. Poussez dans les paumes, soulevez la poitrine et allongez la colonne vertébrale du coccyx au sommet de la tête."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .spine,
        position: .seated,
        imageName: "pose.hatha.staff",
        voiceCueText: LocalizedString(
            en: "Sit tall in Staff Pose. Press down to lift up. Flex your feet and engage your legs.",
            fr: "Assoyez-vous bien droit en posture du bâton. Poussez vers le bas pour vous élever. Fléchissez les pieds et engagez les jambes."
        ),
        modifications: LocalizedStringArray(
            en: ["Sit on a folded blanket to tilt the pelvis forward if your hamstrings are tight",
                 "Place your hands on blocks beside the hips for more lift"],
            fr: ["Assoyez-vous sur une couverture pliée pour basculer le bassin vers l'avant si les ischio-jambiers sont raides",
                 "Placez les mains sur des blocs à côté des hanches pour plus d'élévation"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a wrist injury — use fists or fingertips instead"],
            fr: ["Évitez en cas de blessure au poignet — utilisez les poings ou le bout des doigts"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the spine, exhale to maintain your tall posture",
            fr: "Inspirez pour allonger la colonne, expirez pour maintenir la posture droite"
        ),
        isFree: true
    )

    public static let hathaSeatedForwardFold = Pose(
        id: "hatha-seated-forward-fold",
        name: LocalizedString(
            en: "Seated Forward Fold (Paschimottanasana)",
            fr: "Pince assise (Paschimottanasana)"
        ),
        description: LocalizedString(
            en: "From Staff Pose, inhale and raise your arms overhead. On the exhale, hinge at the hips and fold forward over your legs, reaching for your shins, ankles, or feet. Keep the spine long rather than rounding the back. Let each exhale deepen the fold gently.",
            fr: "À partir de la posture du bâton, inspirez et levez les bras au-dessus de la tête. À l'expiration, basculez aux hanches et pliez-vous vers l'avant au-dessus des jambes, en attrapant les tibias, les chevilles ou les pieds. Gardez la colonne longue au lieu d'arrondir le dos. Laissez chaque expiration approfondir doucement la flexion."
        ),
        durationSeconds: 45,
        difficulty: .beginner,
        category: .back,
        position: .seated,
        imageName: "pose.hatha.seated.forward.fold",
        voiceCueText: LocalizedString(
            en: "Fold forward from the hips. Lead with the chest, not the head. Breathe into the back of the legs.",
            fr: "Pliez-vous vers l'avant à partir des hanches. Guidez avec la poitrine, pas la tête. Respirez dans l'arrière des jambes."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a strap around the feet if you cannot reach them",
                 "Bend your knees slightly to reduce hamstring tension"],
            fr: ["Utilisez une sangle autour des pieds si vous ne pouvez pas les atteindre",
                 "Pliez légèrement les genoux pour réduire la tension des ischio-jambiers"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with herniated disc or acute lower back pain",
                 "Be cautious if you have sciatica — keep knees bent"],
            fr: ["Évitez en cas de hernie discale ou de douleur aiguë au bas du dos",
                 "Soyez prudent en cas de sciatique — gardez les genoux pliés"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the spine, exhale to fold deeper",
            fr: "Inspirez pour allonger la colonne, expirez pour descendre plus profondément"
        ),
        isFree: true
    )

    // MARK: - Intermediate & Advanced Poses (Premium)

    public static let hathaHeadToKnee = Pose(
        id: "hatha-head-to-knee",
        name: LocalizedString(
            en: "Head-to-Knee Pose (Janu Sirsasana)",
            fr: "Posture tête au genou (Janu Sirsasana)"
        ),
        description: LocalizedString(
            en: "Sit with your left leg extended and bend your right knee, placing the sole of the right foot against the inner left thigh. Inhale to lengthen the spine, then exhale and fold forward over the extended leg, reaching for the foot or shin. Keep the extended leg active with the foot flexed.",
            fr: "Assoyez-vous avec la jambe gauche étendue et pliez le genou droit, en plaçant la plante du pied droit contre l'intérieur de la cuisse gauche. Inspirez pour allonger la colonne, puis expirez et pliez-vous vers l'avant au-dessus de la jambe étendue, en attrapant le pied ou le tibia. Gardez la jambe étendue active avec le pied fléchi."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .hips,
        position: .seated,
        imageName: "pose.hatha.head.to.knee",
        voiceCueText: LocalizedString(
            en: "Fold over the extended leg. Keep the spine long and breathe steadily into the stretch.",
            fr: "Pliez-vous au-dessus de la jambe étendue. Gardez la colonne longue et respirez régulièrement dans l'étirement."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a strap around the extended foot if you cannot reach it",
                 "Place a blanket under the bent knee for hip support"],
            fr: ["Utilisez une sangle autour du pied étendu si vous ne pouvez pas l'atteindre",
                 "Placez une couverture sous le genou plié pour soutenir la hanche"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with knee injuries on the bent leg side",
                 "Be cautious with lower back disc issues"],
            fr: ["Évitez en cas de blessure au genou du côté de la jambe pliée",
                 "Soyez prudent en cas de problèmes discaux lombaires"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen, exhale to fold deeper with each breath",
            fr: "Inspirez pour allonger, expirez pour descendre plus profondément à chaque respiration"
        ),
        isFree: false
    )

    public static let hathaBoundAngle = Pose(
        id: "hatha-bound-angle",
        name: LocalizedString(
            en: "Bound Angle Pose (Baddha Konasana)",
            fr: "Posture de l'angle lié (Baddha Konasana)"
        ),
        description: LocalizedString(
            en: "Sit on the floor and bring the soles of your feet together, letting the knees drop open to the sides. Hold your feet with both hands and sit tall, pressing the outer edges of the feet together. Gently encourage the knees toward the floor without forcing them down.",
            fr: "Assoyez-vous au sol et joignez les plantes des pieds, laissant les genoux s'ouvrir sur les côtés. Tenez les pieds avec les deux mains et assoyez-vous bien droit, en pressant les bords extérieurs des pieds l'un contre l'autre. Encouragez doucement les genoux vers le sol sans les forcer."
        ),
        durationSeconds: 45,
        difficulty: .beginner,
        category: .hips,
        position: .seated,
        imageName: "pose.hatha.bound.angle",
        voiceCueText: LocalizedString(
            en: "Open your hips in Bound Angle. Sit tall and let gravity gently draw the knees down.",
            fr: "Ouvrez les hanches dans la posture de l'angle lié. Assoyez-vous droit et laissez la gravité descendre doucement les genoux."
        ),
        modifications: LocalizedStringArray(
            en: ["Sit on a folded blanket to elevate the hips",
                 "Place blocks or cushions under the knees for support"],
            fr: ["Assoyez-vous sur une couverture pliée pour élever les hanches",
                 "Placez des blocs ou des coussins sous les genoux pour du soutien"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a groin or inner knee injury"],
            fr: ["Évitez en cas de blessure à l'aine ou à l'intérieur du genou"]
        ),
        breathingPattern: LocalizedString(
            en: "Breathe deeply — exhale to gently release the hips open",
            fr: "Respirez profondément — expirez pour relâcher doucement l'ouverture des hanches"
        ),
        isFree: false
    )

    public static let hathaCowFace = Pose(
        id: "hatha-cow-face",
        name: LocalizedString(
            en: "Cow Face Pose (Gomukhasana)",
            fr: "Posture de la tête de vache (Gomukhasana)"
        ),
        description: LocalizedString(
            en: "Sit and stack your right knee on top of the left, bringing both heels toward the opposite hip. Reach your right arm overhead, bend the elbow, and reach the left arm behind your back to clasp the hands. If the hands don't meet, use a strap between them. Sit tall and open the chest.",
            fr: "Assoyez-vous et empilez le genou droit sur le gauche, amenant les deux talons vers la hanche opposée. Levez le bras droit au-dessus de la tête, pliez le coude et passez le bras gauche derrière le dos pour joindre les mains. Si les mains ne se rejoignent pas, utilisez une sangle entre elles. Assoyez-vous droit et ouvrez la poitrine."
        ),
        durationSeconds: 50,
        difficulty: .intermediate,
        category: .hips,
        position: .seated,
        imageName: "pose.hatha.cow.face",
        voiceCueText: LocalizedString(
            en: "Stack the knees and reach to bind the hands. Open the chest and breathe into any tightness.",
            fr: "Empilez les genoux et cherchez à joindre les mains. Ouvrez la poitrine et respirez dans les zones tendues."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a strap or towel between the hands if they don't meet",
                 "Sit on a block or blanket if the hips are tight"],
            fr: ["Utilisez une sangle ou une serviette entre les mains si elles ne se rejoignent pas",
                 "Assoyez-vous sur un bloc ou une couverture si les hanches sont raides"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have serious shoulder or rotator cuff injuries",
                 "Use caution with knee injuries — do not force the stacking"],
            fr: ["Évitez en cas de blessure grave à l'épaule ou à la coiffe des rotateurs",
                 "Soyez prudent en cas de blessure au genou — ne forcez pas l'empilement"]
        ),
        breathingPattern: LocalizedString(
            en: "Breathe into the shoulders and hips — exhale to release tension",
            fr: "Respirez dans les épaules et les hanches — expirez pour relâcher la tension"
        ),
        isFree: false
    )

    public static let hathaHalfLordFishes = Pose(
        id: "hatha-half-lord-fishes",
        name: LocalizedString(
            en: "Half Lord of the Fishes (Ardha Matsyendrasana)",
            fr: "Demi-seigneur des poissons (Ardha Matsyendrasana)"
        ),
        description: LocalizedString(
            en: "Sit with legs extended, then bend your right knee and cross the right foot over the left thigh to the outside of the left knee. Place your right hand behind you for support. Hook your left elbow outside the right knee and twist to the right. Lengthen the spine on each inhale and deepen the twist on each exhale.",
            fr: "Assoyez-vous les jambes étendues, puis pliez le genou droit et croisez le pied droit par-dessus la cuisse gauche à l'extérieur du genou gauche. Placez la main droite derrière vous pour du soutien. Accrochez le coude gauche à l'extérieur du genou droit et tournez vers la droite. Allongez la colonne à chaque inspiration et approfondissez la torsion à chaque expiration."
        ),
        durationSeconds: 50,
        difficulty: .intermediate,
        category: .spine,
        position: .seated,
        imageName: "pose.hatha.half.lord.fishes",
        voiceCueText: LocalizedString(
            en: "Twist from the base of your spine upward. Use each breath to lengthen before you rotate.",
            fr: "Tournez à partir de la base de la colonne vers le haut. Utilisez chaque respiration pour allonger avant de tourner."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the bottom leg straight if bending both knees is uncomfortable",
                 "Hug the knee with the opposite arm instead of hooking the elbow"],
            fr: ["Gardez la jambe du bas droite si plier les deux genoux est inconfortable",
                 "Serrez le genou avec le bras opposé au lieu d'accrocher le coude"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with spinal disc injuries or recent back surgery",
                 "Be cautious during pregnancy — use a gentle open twist only"],
            fr: ["Évitez en cas de blessures aux disques vertébraux ou de chirurgie récente au dos",
                 "Soyez prudente pendant la grossesse — utilisez seulement une torsion douce et ouverte"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to grow tall, exhale to twist a little deeper",
            fr: "Inspirez pour grandir, expirez pour tourner un peu plus"
        ),
        isFree: false
    )

    public static let hathaBoat = Pose(
        id: "hatha-boat",
        name: LocalizedString(
            en: "Boat Pose (Navasana)",
            fr: "Posture du bateau (Navasana)"
        ),
        description: LocalizedString(
            en: "Sit with knees bent and feet on the floor. Lean back slightly, keeping the spine long. Lift your feet off the floor and bring the shins parallel to the ground. Extend your arms forward alongside the knees with palms facing inward. For a greater challenge, straighten the legs to form a V shape with the torso.",
            fr: "Assoyez-vous les genoux pliés et les pieds au sol. Penchez-vous légèrement vers l'arrière en gardant la colonne longue. Soulevez les pieds du sol et amenez les tibias parallèles au sol. Étendez les bras vers l'avant le long des genoux, paumes vers l'intérieur. Pour plus de défi, tendez les jambes pour former un V avec le torse."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .core,
        position: .seated,
        imageName: "pose.hatha.boat",
        voiceCueText: LocalizedString(
            en: "Lift into Boat Pose. Keep the chest lifted and the core engaged. Breathe steadily.",
            fr: "Montez en posture du bateau. Gardez la poitrine soulevée et les abdominaux engagés. Respirez régulièrement."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the knees bent with shins parallel to the floor for half boat",
                 "Hold behind your thighs for support while building core strength"],
            fr: ["Gardez les genoux pliés avec les tibias parallèles au sol pour le demi-bateau",
                 "Tenez l'arrière des cuisses pour du soutien pendant que vous développez la force abdominale"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid during pregnancy or with diastasis recti",
                 "Be cautious with low back pain — keep knees bent"],
            fr: ["Évitez pendant la grossesse ou en cas de diastase des grands droits",
                 "Soyez prudent en cas de douleur lombaire — gardez les genoux pliés"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady breaths — do not hold the breath, exhale to engage the core deeper",
            fr: "Respirations régulières — ne retenez pas le souffle, expirez pour engager les abdominaux plus profondément"
        ),
        isFree: false
    )

    public static let hathaBridge = Pose(
        id: "hatha-bridge",
        name: LocalizedString(
            en: "Bridge Pose (Setu Bandhasana)",
            fr: "Posture du pont (Setu Bandhasana)"
        ),
        description: LocalizedString(
            en: "Lie on your back with knees bent, feet hip-width apart and flat on the floor close to the sit bones. On an inhale, press into your feet and lift the hips toward the ceiling. Roll the shoulders under and optionally interlace the hands beneath the back. Keep the thighs parallel and the chin slightly tucked.",
            fr: "Allongez-vous sur le dos, genoux pliés, pieds à la largeur des hanches et à plat au sol près des ischions. À l'inspiration, poussez dans les pieds et soulevez les hanches vers le plafond. Roulez les épaules sous le corps et entrelacez éventuellement les mains sous le dos. Gardez les cuisses parallèles et le menton légèrement rentré."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .chest,
        position: .supine,
        imageName: "pose.hatha.bridge",
        voiceCueText: LocalizedString(
            en: "Press into your feet and lift the hips in Bridge. Open the chest and breathe into the front body.",
            fr: "Poussez dans les pieds et soulevez les hanches dans le pont. Ouvrez la poitrine et respirez dans l'avant du corps."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a block under the sacrum for a supported bridge",
                 "Keep the arms alongside the body with palms pressing down"],
            fr: ["Placez un bloc sous le sacrum pour un pont supporté",
                 "Gardez les bras le long du corps avec les paumes pressées vers le bas"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with neck injuries — do not turn the head in this pose",
                 "Be cautious with knee issues — do not push through pain"],
            fr: ["Évitez en cas de blessure au cou — ne tournez pas la tête dans cette posture",
                 "Soyez prudent en cas de problèmes de genou — ne forcez pas à travers la douleur"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift higher, exhale to maintain the height with stability",
            fr: "Inspirez pour monter plus haut, expirez pour maintenir la hauteur avec stabilité"
        ),
        isFree: false
    )

    public static let hathaWheel = Pose(
        id: "hatha-wheel",
        name: LocalizedString(
            en: "Wheel Pose (Urdhva Dhanurasana)",
            fr: "Posture de la roue (Urdhva Dhanurasana)"
        ),
        description: LocalizedString(
            en: "Lie on your back, bend your knees with feet flat on the floor. Place your hands beside your ears with fingers pointing toward the shoulders. Press into your hands and feet, lifting the hips and chest fully off the floor into a deep backbend. Straighten the arms as much as possible and let the head hang naturally.",
            fr: "Allongez-vous sur le dos, pliez les genoux avec les pieds à plat au sol. Placez les mains à côté des oreilles, doigts pointant vers les épaules. Poussez dans les mains et les pieds, soulevant les hanches et la poitrine complètement du sol dans une cambrure profonde. Tendez les bras autant que possible et laissez la tête pendre naturellement."
        ),
        durationSeconds: 30,
        difficulty: .advanced,
        category: .chest,
        position: .supine,
        imageName: "pose.hatha.wheel",
        voiceCueText: LocalizedString(
            en: "Press up into Wheel. Push the chest open and breathe into the deep backbend.",
            fr: "Poussez-vous dans la roue. Ouvrez la poitrine et respirez dans la cambrure profonde."
        ),
        modifications: LocalizedStringArray(
            en: ["Stay in Bridge Pose if full Wheel is not yet accessible",
                 "Press up to the crown of the head first before straightening the arms"],
            fr: ["Restez dans la posture du pont si la roue complète n'est pas encore accessible",
                 "Montez d'abord jusqu'au sommet de la tête avant de tendre les bras"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with wrist, shoulder, or spinal injuries",
                 "Not recommended if you have high blood pressure or heart conditions"],
            fr: ["Évitez en cas de blessures au poignet, à l'épaule ou à la colonne vertébrale",
                 "Non recommandé en cas d'hypertension artérielle ou de conditions cardiaques"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady breaths — inhale to expand the chest, exhale to hold with control",
            fr: "Respirations régulières — inspirez pour ouvrir la poitrine, expirez pour maintenir avec contrôle"
        ),
        isFree: false
    )

    public static let hathaShoulderstand = Pose(
        id: "hatha-shoulderstand",
        name: LocalizedString(
            en: "Shoulderstand (Sarvangasana)",
            fr: "Chandelle (Sarvangasana)"
        ),
        description: LocalizedString(
            en: "Lie on your back with a folded blanket under the shoulders. Swing the legs overhead, then place the hands on the lower back for support. Extend the legs straight up toward the ceiling, keeping the body in one vertical line. Press the upper arms into the floor and lift through the balls of the feet.",
            fr: "Allongez-vous sur le dos avec une couverture pliée sous les épaules. Balancez les jambes au-dessus de la tête, puis placez les mains sur le bas du dos pour du soutien. Étendez les jambes droit vers le plafond, gardant le corps en une ligne verticale. Pressez les bras supérieurs dans le sol et élevez-vous à travers la plante des pieds."
        ),
        durationSeconds: 45,
        difficulty: .advanced,
        category: .inversion,
        position: .inversion,
        imageName: "pose.hatha.shoulderstand",
        voiceCueText: LocalizedString(
            en: "Lift into Shoulderstand. Support your back with your hands and reach the legs skyward.",
            fr: "Montez dans la chandelle. Soutenez le dos avec les mains et étendez les jambes vers le ciel."
        ),
        modifications: LocalizedStringArray(
            en: ["Practice Legs Up the Wall as a gentler alternative",
                 "Use a folded blanket under the shoulders to protect the neck"],
            fr: ["Pratiquez les jambes au mur comme alternative plus douce",
                 "Utilisez une couverture pliée sous les épaules pour protéger le cou"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with neck injuries, high blood pressure, or glaucoma",
                 "Do not practice during menstruation according to traditional guidelines",
                 "Avoid if you have detached retina or ear infections"],
            fr: ["Évitez en cas de blessures au cou, d'hypertension ou de glaucome",
                 "Ne pratiquez pas pendant les menstruations selon les lignes directrices traditionnelles",
                 "Évitez en cas de décollement de la rétine ou d'infections de l'oreille"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, deep breaths — let the diaphragm adjust to the inverted position",
            fr: "Respirations lentes et profondes — laissez le diaphragme s'adapter à la position inversée"
        ),
        isFree: false
    )

    public static let hathaPlow = Pose(
        id: "hatha-plow",
        name: LocalizedString(
            en: "Plow Pose (Halasana)",
            fr: "Posture de la charrue (Halasana)"
        ),
        description: LocalizedString(
            en: "From Shoulderstand, slowly lower the legs overhead until the toes touch the floor behind your head. Keep the legs straight and the hips stacked over the shoulders. You may interlace the hands on the floor behind the back and press the arms down to lift the spine higher.",
            fr: "À partir de la chandelle, descendez lentement les jambes au-dessus de la tête jusqu'à ce que les orteils touchent le sol derrière vous. Gardez les jambes droites et les hanches empilées au-dessus des épaules. Vous pouvez entrelacer les mains au sol derrière le dos et presser les bras vers le bas pour soulever la colonne plus haut."
        ),
        durationSeconds: 45,
        difficulty: .advanced,
        category: .spine,
        position: .inversion,
        imageName: "pose.hatha.plow",
        voiceCueText: LocalizedString(
            en: "Lower the legs overhead in Plow. Keep the spine long and breathe steadily into the back body.",
            fr: "Descendez les jambes au-dessus de la tête dans la charrue. Gardez la colonne longue et respirez régulièrement dans l'arrière du corps."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a chair behind you and rest the feet on the chair seat if toes don't reach the floor",
                 "Keep the hands on the lower back for support"],
            fr: ["Placez une chaise derrière vous et reposez les pieds sur le siège si les orteils n'atteignent pas le sol",
                 "Gardez les mains sur le bas du dos pour du soutien"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with neck or cervical spine injuries",
                 "Not recommended with high blood pressure or during menstruation"],
            fr: ["Évitez en cas de blessures au cou ou à la colonne cervicale",
                 "Non recommandé en cas d'hypertension ou pendant les menstruations"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, controlled breaths — the compressed position requires gentle breathing",
            fr: "Respirations lentes et contrôlées — la position comprimée nécessite une respiration douce"
        ),
        isFree: false
    )

    public static let hathaFish = Pose(
        id: "hatha-fish",
        name: LocalizedString(
            en: "Fish Pose (Matsyasana)",
            fr: "Posture du poisson (Matsyasana)"
        ),
        description: LocalizedString(
            en: "Lie on your back with legs extended. Slide your hands under your hips, palms down. Press into the forearms and elbows to lift the chest, arching the upper back. Tilt the head back and rest the crown lightly on the floor. The weight should be mostly on the forearms, not on the head.",
            fr: "Allongez-vous sur le dos, jambes étendues. Glissez les mains sous les hanches, paumes vers le bas. Appuyez sur les avant-bras et les coudes pour soulever la poitrine en cambrant le haut du dos. Penchez la tête vers l'arrière et posez légèrement le sommet du crâne au sol. Le poids devrait reposer principalement sur les avant-bras, pas sur la tête."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .chest,
        position: .supine,
        imageName: "pose.hatha.fish",
        voiceCueText: LocalizedString(
            en: "Lift the chest in Fish Pose. Open the throat and breathe deeply into the expansion.",
            fr: "Soulevez la poitrine dans la posture du poisson. Ouvrez la gorge et respirez profondément dans l'expansion."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a block under the upper back for a supported version",
                 "Keep the knees bent with feet flat on the floor to reduce intensity"],
            fr: ["Placez un bloc sous le haut du dos pour une version supportée",
                 "Gardez les genoux pliés avec les pieds à plat au sol pour réduire l'intensité"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with serious neck injuries or cervical spine issues",
                 "Be cautious with high or low blood pressure"],
            fr: ["Évitez en cas de blessures graves au cou ou de problèmes de colonne cervicale",
                 "Soyez prudent en cas d'hypertension ou d'hypotension artérielle"]
        ),
        breathingPattern: LocalizedString(
            en: "Deep breaths into the expanded chest — feel the ribcage open with each inhale",
            fr: "Respirations profondes dans la poitrine ouverte — sentez la cage thoracique s'ouvrir à chaque inspiration"
        ),
        isFree: false
    )

    public static let hathaCobra = Pose(
        id: "hatha-cobra",
        name: LocalizedString(
            en: "Cobra Pose (Bhujangasana)",
            fr: "Posture du cobra (Bhujangasana)"
        ),
        description: LocalizedString(
            en: "Lie face down with your hands under the shoulders, elbows close to the body. On an inhale, press gently into the hands and peel the chest off the floor, keeping the lower ribs on the ground. Draw the shoulders back, open the chest, and keep the elbows slightly bent. The lift should come from the back muscles, not just the arms.",
            fr: "Allongez-vous face au sol avec les mains sous les épaules, coudes près du corps. À l'inspiration, pressez doucement dans les mains et décollez la poitrine du sol en gardant les côtes basses au sol. Tirez les épaules vers l'arrière, ouvrez la poitrine et gardez les coudes légèrement pliés. L'élévation devrait venir des muscles du dos, pas seulement des bras."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .chest,
        position: .prone,
        imageName: "pose.hatha.cobra",
        voiceCueText: LocalizedString(
            en: "Rise into Cobra. Lift with the back muscles and open the heart forward.",
            fr: "Montez dans le cobra. Soulevez avec les muscles du dos et ouvrez le cœur vers l'avant."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the lift low — Baby Cobra — with hands lightly pressing",
                 "Place the forearms on the floor for Sphinx Pose as an easier alternative"],
            fr: ["Gardez l'élévation basse — Bébé cobra — avec les mains appuyant légèrement",
                 "Placez les avant-bras au sol pour la posture du sphinx comme alternative plus facile"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with pregnancy or recent abdominal surgery",
                 "Be cautious with lower back injuries — keep the lift gentle"],
            fr: ["Évitez pendant la grossesse ou après une chirurgie abdominale récente",
                 "Soyez prudent en cas de blessures lombaires — gardez l'élévation douce"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift and lengthen, exhale to maintain the pose with ease",
            fr: "Inspirez pour vous soulever et allonger, expirez pour maintenir la posture avec aisance"
        ),
        isFree: false
    )

    public static let hathaLocust = Pose(
        id: "hatha-locust",
        name: LocalizedString(
            en: "Locust Pose (Salabhasana)",
            fr: "Posture de la sauterelle (Salabhasana)"
        ),
        description: LocalizedString(
            en: "Lie face down with arms alongside the body, palms facing up. On an inhale, lift the head, chest, arms, and legs simultaneously off the floor. Reach back through the fingertips and extend through the toes. Keep the gaze slightly forward and the back of the neck long.",
            fr: "Allongez-vous face au sol avec les bras le long du corps, paumes vers le haut. À l'inspiration, soulevez la tête, la poitrine, les bras et les jambes simultanément du sol. Étirez-vous vers l'arrière à travers les doigts et allongez à travers les orteils. Gardez le regard légèrement vers l'avant et l'arrière du cou long."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .back,
        position: .prone,
        imageName: "pose.hatha.locust",
        voiceCueText: LocalizedString(
            en: "Lift everything in Locust Pose. Reach long through the fingers and toes. Breathe steadily.",
            fr: "Soulevez tout dans la posture de la sauterelle. Étirez-vous longuement à travers les doigts et les orteils. Respirez régulièrement."
        ),
        modifications: LocalizedStringArray(
            en: ["Lift only the upper body first, then try adding the legs",
                 "Place your hands under the hips for support when lifting the legs"],
            fr: ["Soulevez seulement le haut du corps d'abord, puis essayez d'ajouter les jambes",
                 "Placez les mains sous les hanches pour du soutien en soulevant les jambes"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with pregnancy or recent abdominal surgery",
                 "Be cautious with serious lower back conditions"],
            fr: ["Évitez pendant la grossesse ou après une chirurgie abdominale récente",
                 "Soyez prudent en cas de conditions lombaires sérieuses"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift, exhale to hold with steadiness — avoid holding the breath",
            fr: "Inspirez pour soulever, expirez pour maintenir avec régularité — évitez de retenir le souffle"
        ),
        isFree: false
    )

    public static let hathaBow = Pose(
        id: "hatha-bow",
        name: LocalizedString(
            en: "Bow Pose (Dhanurasana)",
            fr: "Posture de l'arc (Dhanurasana)"
        ),
        description: LocalizedString(
            en: "Lie face down and bend the knees, reaching back to grasp the ankles or the tops of the feet. On an inhale, kick the feet into the hands to lift the chest and thighs off the floor simultaneously. The body forms the shape of a bow. Keep the knees hip-width apart and rock gently with the breath.",
            fr: "Allongez-vous face au sol et pliez les genoux, attrapez les chevilles ou le dessus des pieds en tendant les bras vers l'arrière. À l'inspiration, poussez les pieds dans les mains pour soulever la poitrine et les cuisses du sol simultanément. Le corps forme la figure d'un arc. Gardez les genoux à la largeur des hanches et balancez-vous doucement avec la respiration."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .chest,
        position: .prone,
        imageName: "pose.hatha.bow",
        voiceCueText: LocalizedString(
            en: "Kick into the hands and lift in Bow Pose. Open the chest and breathe deeply.",
            fr: "Poussez dans les mains et soulevez-vous dans la posture de l'arc. Ouvrez la poitrine et respirez profondément."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a strap around the ankles if you cannot reach them directly",
                 "Lift only the upper body with hands holding the ankles, keeping thighs on the floor"],
            fr: ["Utilisez une sangle autour des chevilles si vous ne pouvez pas les atteindre directement",
                 "Soulevez seulement le haut du corps en tenant les chevilles, cuisses au sol"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with pregnancy, recent abdominal surgery, or serious spinal conditions",
                 "Not recommended with high blood pressure or hernia"],
            fr: ["Évitez pendant la grossesse, après une chirurgie abdominale récente ou en cas de conditions spinales sérieuses",
                 "Non recommandé en cas d'hypertension artérielle ou de hernie"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift and expand, exhale to hold the shape — let the breath rock you gently",
            fr: "Inspirez pour soulever et ouvrir, expirez pour maintenir la forme — laissez la respiration vous bercer doucement"
        ),
        isFree: false
    )

    public static let hathaPigeon = Pose(
        id: "hatha-pigeon",
        name: LocalizedString(
            en: "Pigeon Pose (Eka Pada Rajakapotasana)",
            fr: "Posture du pigeon (Eka Pada Rajakapotasana)"
        ),
        description: LocalizedString(
            en: "From all fours, slide your right knee forward behind the right wrist and angle the right shin toward the left side. Extend the left leg straight back with the top of the foot on the floor. Square the hips as much as possible, then walk the hands forward and fold over the front leg for a deep hip stretch.",
            fr: "À partir de quatre pattes, glissez le genou droit vers l'avant derrière le poignet droit et orientez le tibia droit vers le côté gauche. Étendez la jambe gauche droit vers l'arrière, dessus du pied au sol. Alignez les hanches autant que possible, puis avancez les mains et pliez-vous au-dessus de la jambe avant pour un étirement profond des hanches."
        ),
        durationSeconds: 50,
        difficulty: .intermediate,
        category: .hips,
        position: .kneeling,
        imageName: "pose.hatha.pigeon",
        voiceCueText: LocalizedString(
            en: "Settle into Pigeon. Let the hips melt toward the floor and breathe into any sensation.",
            fr: "Installez-vous dans le pigeon. Laissez les hanches fondre vers le sol et respirez dans chaque sensation."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a block or blanket under the front hip for support",
                 "Stay upright on the hands instead of folding forward"],
            fr: ["Placez un bloc ou une couverture sous la hanche avant pour du soutien",
                 "Restez droit sur les mains au lieu de plier vers l'avant"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with knee injuries on the front leg side",
                 "Use caution with sacroiliac joint dysfunction"],
            fr: ["Évitez en cas de blessure au genou du côté de la jambe avant",
                 "Soyez prudent en cas de dysfonction de l'articulation sacro-iliaque"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, deep breaths — exhale to soften deeper into the stretch",
            fr: "Respirations lentes et profondes — expirez pour fondre plus profondément dans l'étirement"
        ),
        isFree: false
    )

    public static let hathaHero = Pose(
        id: "hatha-hero",
        name: LocalizedString(
            en: "Hero's Pose (Virasana)",
            fr: "Posture du héros (Virasana)"
        ),
        description: LocalizedString(
            en: "Kneel with the knees together and the feet slightly wider than the hips. Sit back between the feet, resting the sit bones on the floor or on a block. The tops of the feet press into the floor with the toes pointing straight back. Sit tall and rest the hands on the thighs.",
            fr: "Agenouillez-vous les genoux ensemble et les pieds légèrement plus larges que les hanches. Assoyez-vous entre les pieds, posant les ischions au sol ou sur un bloc. Le dessus des pieds presse dans le sol avec les orteils pointant droit vers l'arrière. Assoyez-vous bien droit et posez les mains sur les cuisses."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .legs,
        position: .kneeling,
        imageName: "pose.hatha.hero",
        voiceCueText: LocalizedString(
            en: "Sit between your heels in Hero's Pose. Lengthen the spine and breathe into the thigh stretch.",
            fr: "Assoyez-vous entre les talons dans la posture du héros. Allongez la colonne et respirez dans l'étirement des cuisses."
        ),
        modifications: LocalizedStringArray(
            en: ["Sit on a block or folded blanket if you cannot reach the floor comfortably",
                 "Place a rolled towel behind the knees if they feel compressed"],
            fr: ["Assoyez-vous sur un bloc ou une couverture pliée si vous ne pouvez pas atteindre le sol confortablement",
                 "Placez une serviette roulée derrière les genoux s'ils semblent comprimés"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with knee injuries or ankle sprains",
                 "Use caution if you have varicose veins in the legs"],
            fr: ["Évitez en cas de blessures au genou ou d'entorses à la cheville",
                 "Soyez prudent en cas de varices dans les jambes"]
        ),
        breathingPattern: LocalizedString(
            en: "Calm, steady breathing — feel the front of the thighs release with each exhale",
            fr: "Respiration calme et régulière — sentez l'avant des cuisses se relâcher à chaque expiration"
        ),
        isFree: false
    )

    public static let hathaChild = Pose(
        id: "hatha-child",
        name: LocalizedString(
            en: "Child's Pose (Balasana)",
            fr: "Posture de l'enfant (Balasana)"
        ),
        description: LocalizedString(
            en: "Kneel on the floor, bring the big toes together and separate the knees wide. Sit the hips back toward the heels and walk the hands forward, lowering the forehead to the floor. Let the entire body release and surrender to gravity. Rest the arms extended in front or alongside the body.",
            fr: "Agenouillez-vous au sol, joignez les gros orteils et écartez les genoux largement. Assoyez les hanches vers les talons et avancez les mains, en déposant le front au sol. Laissez tout le corps se relâcher et s'abandonner à la gravité. Reposez les bras étendus devant ou le long du corps."
        ),
        durationSeconds: 45,
        difficulty: .beginner,
        category: .relaxation,
        position: .kneeling,
        imageName: "pose.hatha.child",
        voiceCueText: LocalizedString(
            en: "Rest in Child's Pose. Let everything go and breathe into the back of the body.",
            fr: "Reposez-vous dans la posture de l'enfant. Lâchez tout et respirez dans l'arrière du corps."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a pillow under the forehead if it doesn't reach the floor",
                 "Keep the knees together if wide knees are uncomfortable for the hips"],
            fr: ["Placez un coussin sous le front s'il n'atteint pas le sol",
                 "Gardez les genoux ensemble si les genoux écartés sont inconfortables pour les hanches"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a knee injury that prevents deep flexion",
                 "Be cautious during pregnancy — keep the knees wide apart"],
            fr: ["Évitez en cas de blessure au genou empêchant une flexion profonde",
                 "Soyez prudente pendant la grossesse — gardez les genoux bien écartés"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, full breaths — feel the back ribs expand with each inhale",
            fr: "Respirations lentes et complètes — sentez les côtes arrière s'ouvrir à chaque inspiration"
        ),
        isFree: false
    )

    public static let hathaSavasana = Pose(
        id: "hatha-savasana",
        name: LocalizedString(
            en: "Corpse Pose (Savasana)",
            fr: "Posture du cadavre (Savasana)"
        ),
        description: LocalizedString(
            en: "Lie flat on your back with the legs extended and feet falling open naturally. Place the arms alongside the body with palms facing up. Close the eyes and consciously release every muscle from the toes to the crown of the head. Allow the breath to return to its natural rhythm without effort.",
            fr: "Allongez-vous à plat sur le dos, jambes étendues et pieds tombant ouverts naturellement. Placez les bras le long du corps, paumes vers le haut. Fermez les yeux et relâchez consciemment chaque muscle des orteils au sommet de la tête. Laissez la respiration revenir à son rythme naturel sans effort."
        ),
        durationSeconds: 60,
        difficulty: .beginner,
        category: .relaxation,
        position: .supine,
        imageName: "pose.hatha.savasana",
        voiceCueText: LocalizedString(
            en: "Let go completely in Savasana. Release all effort and simply be present.",
            fr: "Lâchez tout dans Savasana. Relâchez tout effort et soyez simplement présent."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a bolster under the knees to release the lower back",
                 "Cover yourself with a blanket for warmth and comfort"],
            fr: ["Placez un traversin sous les genoux pour relâcher le bas du dos",
                 "Couvrez-vous d'une couverture pour la chaleur et le confort"]
        ),
        contraindications: LocalizedStringArray(
            en: ["If lying flat is uncomfortable during pregnancy, lie on the left side instead"],
            fr: ["Si rester à plat est inconfortable pendant la grossesse, allongez-vous sur le côté gauche"]
        ),
        breathingPattern: LocalizedString(
            en: "Natural, effortless breathing — let the body breathe itself",
            fr: "Respiration naturelle et sans effort — laissez le corps respirer par lui-même"
        ),
        isFree: false
    )

    // MARK: - Hatha Yoga Pose Collection

    public static let hathaPoses: [Pose] = [
        // Beginner (Free)
        hathaMountain,
        hathaTree,
        hathaWarriorI,
        hathaWarriorII,
        hathaTriangle,
        hathaExtendedSideAngle,
        hathaStaff,
        hathaSeatedForwardFold,
        // Intermediate & Advanced (Premium)
        hathaHeadToKnee,
        hathaBoundAngle,
        hathaCowFace,
        hathaHalfLordFishes,
        hathaBoat,
        hathaBridge,
        hathaWheel,
        hathaShoulderstand,
        hathaPlow,
        hathaFish,
        hathaCobra,
        hathaLocust,
        hathaBow,
        hathaPigeon,
        hathaHero,
        hathaChild,
        hathaSavasana,
    ]

    // MARK: - Hatha Yoga Plans

    public static let hathaClassical = WorkoutPlan(
        id: "hatha-classical",
        name: LocalizedString(
            en: "Classical Hatha Sequence",
            fr: "Séquence classique de Hatha"
        ),
        description: LocalizedString(
            en: "A gentle 12-minute classical Hatha sequence covering standing poses, seated stretches, and final relaxation — ideal for daily practice.",
            fr: "Une séquence classique de Hatha de 12 minutes couvrant les postures debout, les étirements assis et la relaxation finale — idéale pour la pratique quotidienne."
        ),
        style: .hatha,
        poses: [
            hathaMountain,
            hathaTree,
            hathaWarriorI,
            hathaWarriorII,
            hathaTriangle,
            hathaStaff,
            hathaSeatedForwardFold,
            hathaChild,
            hathaSavasana,
        ],
        transitionSeconds: 5,
        isFree: true
    )

    public static let hathaDeepPractice = WorkoutPlan(
        id: "hatha-deep-practice",
        name: LocalizedString(
            en: "Deep Hatha Practice",
            fr: "Pratique approfondie de Hatha"
        ),
        description: LocalizedString(
            en: "A comprehensive 20-minute Hatha session with standing warriors, deep hip openers, backbends, and inversions for experienced practitioners.",
            fr: "Une séance approfondie de Hatha de 20 minutes avec des guerriers debout, des ouvertures profondes des hanches, des cambrures et des inversions pour les pratiquants expérimentés."
        ),
        style: .hatha,
        poses: [
            hathaMountain,
            hathaWarriorI,
            hathaWarriorII,
            hathaTriangle,
            hathaExtendedSideAngle,
            hathaPigeon,
            hathaCowFace,
            hathaHalfLordFishes,
            hathaBridge,
            hathaFish,
            hathaShoulderstand,
            hathaPlow,
            hathaSavasana,
        ],
        transitionSeconds: 5,
        isFree: false
    )

    public static let hathaStrengthFlex = WorkoutPlan(
        id: "hatha-strength-flex",
        name: LocalizedString(
            en: "Hatha Strength & Flexibility",
            fr: "Hatha force et souplesse"
        ),
        description: LocalizedString(
            en: "A full 25-minute Hatha session featuring all 25 poses for a complete practice building strength, flexibility, and deep relaxation.",
            fr: "Une séance complète de Hatha de 25 minutes comprenant les 25 postures pour une pratique complète développant la force, la souplesse et la relaxation profonde."
        ),
        style: .hatha,
        poses: hathaPoses,
        transitionSeconds: 5,
        isFree: false
    )

    public static let hathaPlans: [WorkoutPlan] = [
        hathaClassical,
        hathaDeepPractice,
        hathaStrengthFlex,
    ]
}
