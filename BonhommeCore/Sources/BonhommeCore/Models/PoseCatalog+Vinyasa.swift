import Foundation

// MARK: - Vinyasa Flow Poses & Plans

extension PoseCatalog {

    // MARK: - Vinyasa Poses (Free — Foundational Standing)

    public static let vinyasaMountain = Pose(
        id: "vinyasa-mountain",
        name: LocalizedString(
            en: "Mountain Pose",
            fr: "Posture de la montagne"
        ),
        description: LocalizedString(
            en: "Stand tall with your feet together or hip-width apart, arms at your sides with palms facing forward. Ground evenly through all four corners of your feet. Engage your thighs, lengthen your tailbone toward the floor, and reach the crown of your head toward the ceiling.",
            fr: "Tenez-vous debout, pieds joints ou à la largeur des hanches, bras le long du corps, paumes vers l'avant. Ancrez-vous uniformément à travers les quatre coins de vos pieds. Engagez les cuisses, allongez le coccyx vers le sol et étirez le sommet de la tête vers le plafond."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .fullBody,
        position: .standing,
        imageName: "pose.standing.mountain",
        voiceCueText: LocalizedString(
            en: "Stand tall in Mountain Pose. Root down through your feet and lengthen up through the crown of your head.",
            fr: "Tenez-vous bien droit en Posture de la montagne. Enracinez-vous à travers vos pieds et allongez-vous vers le sommet de la tête."
        ),
        modifications: LocalizedStringArray(
            en: ["Separate your feet hip-width apart for better balance",
                 "Place your hands on your hips if keeping arms at your sides feels uncomfortable"],
            fr: ["Écartez les pieds à la largeur des hanches pour un meilleur équilibre",
                 "Placez les mains sur les hanches si garder les bras le long du corps est inconfortable"]
        ),
        contraindications: LocalizedStringArray(en: [], fr: []),
        breathingPattern: LocalizedString(
            en: "Breathe deeply and evenly through the nose, expanding the ribcage in all directions",
            fr: "Respirez profondément et régulièrement par le nez, en élargissant la cage thoracique dans toutes les directions"
        ),
        isFree: true
    )

    public static let vinyasaForwardFold = Pose(
        id: "vinyasa-forward-fold",
        name: LocalizedString(
            en: "Standing Forward Fold",
            fr: "Flexion avant debout"
        ),
        description: LocalizedString(
            en: "From standing, exhale and hinge at your hips to fold your torso over your legs. Let your head hang heavy and relax your neck. Bend your knees as much as needed to release tension in the hamstrings. Allow your fingertips or palms to rest on the floor, shins, or opposite elbows.",
            fr: "Depuis la position debout, expirez et pliez à partir des hanches pour rabattre le torse sur les jambes. Laissez la tête pendre lourdement et relâchez le cou. Pliez les genoux autant que nécessaire pour relâcher la tension dans les ischio-jambiers. Laissez le bout des doigts ou les paumes reposer au sol, sur les tibias ou sur les coudes opposés."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .back,
        position: .standing,
        imageName: "pose.standing.forward.fold",
        voiceCueText: LocalizedString(
            en: "Fold forward from the hips. Let your head hang heavy. Soften your knees if your hamstrings feel tight.",
            fr: "Pliez vers l'avant à partir des hanches. Laissez la tête pendre lourdement. Adoucissez les genoux si les ischio-jambiers sont tendus."
        ),
        modifications: LocalizedStringArray(
            en: ["Bend your knees generously to protect the lower back",
                 "Rest your hands on blocks if you cannot reach the floor"],
            fr: ["Pliez généreusement les genoux pour protéger le bas du dos",
                 "Posez les mains sur des blocs si vous ne pouvez pas atteindre le sol"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute lower back injury or herniated disc",
                 "Use caution if you have low blood pressure — rise slowly"],
            fr: ["Évitez en cas de blessure aiguë au bas du dos ou de hernie discale",
                 "Prudence en cas de tension artérielle basse — relevez-vous lentement"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to fold deeper, inhale to create length in the spine",
            fr: "Expirez pour plier plus profondément, inspirez pour créer de la longueur dans la colonne"
        ),
        isFree: true
    )

    public static let vinyasaHalfwayLift = Pose(
        id: "vinyasa-halfway-lift",
        name: LocalizedString(
            en: "Halfway Lift",
            fr: "Demi-redressement"
        ),
        description: LocalizedString(
            en: "From a forward fold, inhale and lift your torso halfway up, bringing your back parallel to the floor. Place your fingertips on your shins or the floor. Draw your shoulder blades together and extend the crown of your head forward, creating a long flat back.",
            fr: "Depuis la flexion avant, inspirez et soulevez le torse à mi-chemin, amenant le dos parallèle au sol. Placez le bout des doigts sur les tibias ou au sol. Rapprochez les omoplates et étendez le sommet de la tête vers l'avant, créant un dos long et plat."
        ),
        durationSeconds: 15,
        difficulty: .beginner,
        category: .back,
        position: .standing,
        imageName: "pose.standing.halfway.lift",
        voiceCueText: LocalizedString(
            en: "Inhale, lift halfway. Lengthen your spine forward. Flat back, gaze slightly ahead.",
            fr: "Inspirez, soulevez à mi-chemin. Allongez la colonne vers l'avant. Dos plat, regard légèrement devant."
        ),
        modifications: LocalizedStringArray(
            en: ["Place hands on thighs instead of shins for more support",
                 "Bend knees slightly to keep the back flat"],
            fr: ["Placez les mains sur les cuisses au lieu des tibias pour plus de soutien",
                 "Pliez légèrement les genoux pour garder le dos plat"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute lower back pain"],
            fr: ["Évitez en cas de douleur aiguë au bas du dos"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift and lengthen, exhale to fold back down",
            fr: "Inspirez pour lever et allonger, expirez pour replier vers le bas"
        ),
        isFree: true
    )

    public static let vinyasaHighPlank = Pose(
        id: "vinyasa-high-plank",
        name: LocalizedString(
            en: "High Plank",
            fr: "Planche haute"
        ),
        description: LocalizedString(
            en: "Place your hands shoulder-width apart on the floor with fingers spread wide. Step your feet back so your body forms a straight line from head to heels. Engage your core, press the floor away, and keep your hips level — not sagging or piking. Gaze slightly ahead of your fingertips.",
            fr: "Placez les mains à la largeur des épaules au sol, doigts écartés. Reculez les pieds pour que le corps forme une ligne droite de la tête aux talons. Engagez le tronc, repoussez le sol et gardez les hanches au niveau — sans affaissement ni cambrure. Regardez légèrement devant le bout des doigts."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .core,
        position: .prone,
        imageName: "pose.prone.high.plank",
        voiceCueText: LocalizedString(
            en: "Hold your plank strong. Press the floor away, engage your core, one long line from head to heels.",
            fr: "Maintenez votre planche solidement. Repoussez le sol, engagez le tronc, une longue ligne de la tête aux talons."
        ),
        modifications: LocalizedStringArray(
            en: ["Drop your knees to the floor for a modified plank",
                 "Place forearms on the floor instead of hands for less wrist pressure"],
            fr: ["Déposez les genoux au sol pour une planche modifiée",
                 "Placez les avant-bras au sol au lieu des mains pour moins de pression sur les poignets"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with wrist injuries — use forearm variation instead",
                 "Not recommended with acute shoulder impingement"],
            fr: ["Évitez en cas de blessures aux poignets — utilisez la variation sur les avant-bras",
                 "Non recommandé en cas de conflit aigu à l'épaule"]
        ),
        breathingPattern: LocalizedString(
            en: "Breathe steadily — inhale to lengthen, exhale to engage the core deeper",
            fr: "Respirez régulièrement — inspirez pour allonger, expirez pour engager le tronc plus profondément"
        ),
        isFree: true
    )

    public static let vinyasaChaturanga = Pose(
        id: "vinyasa-chaturanga",
        name: LocalizedString(
            en: "Low Plank (Chaturanga)",
            fr: "Planche basse (Chaturanga)"
        ),
        description: LocalizedString(
            en: "From High Plank, shift your weight forward and lower your body halfway down, keeping elbows hugging close to your ribs at a 90-degree angle. Your shoulders should stay level with or above your elbows. Maintain a straight line from head to heels throughout the descent.",
            fr: "Depuis la planche haute, transférez le poids vers l'avant et abaissez le corps à mi-chemin, en gardant les coudes serrés près des côtes à un angle de 90 degrés. Les épaules doivent rester au niveau des coudes ou au-dessus. Maintenez une ligne droite de la tête aux talons durant toute la descente."
        ),
        durationSeconds: 15,
        difficulty: .intermediate,
        category: .arms,
        position: .prone,
        imageName: "pose.prone.chaturanga",
        voiceCueText: LocalizedString(
            en: "Lower halfway down with control. Elbows hug your ribs. Keep your body in one strong line.",
            fr: "Abaissez-vous à mi-chemin avec contrôle. Les coudes serrent les côtes. Gardez le corps en une ligne solide."
        ),
        modifications: LocalizedStringArray(
            en: ["Lower your knees to the floor before bending the elbows",
                 "Lower all the way to the floor and rebuild from there"],
            fr: ["Déposez les genoux au sol avant de plier les coudes",
                 "Descendez complètement au sol et reconstruisez à partir de là"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with shoulder injuries or rotator cuff issues",
                 "Not recommended with wrist pain or carpal tunnel syndrome"],
            fr: ["Évitez en cas de blessures à l'épaule ou de problèmes de coiffe des rotateurs",
                 "Non recommandé en cas de douleur aux poignets ou de syndrome du canal carpien"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale as you lower, inhale to transition to the next pose",
            fr: "Expirez en descendant, inspirez pour la transition vers la posture suivante"
        ),
        isFree: true
    )

    public static let vinyasaUpwardDog = Pose(
        id: "vinyasa-upward-dog",
        name: LocalizedString(
            en: "Upward-Facing Dog",
            fr: "Chien tête en haut"
        ),
        description: LocalizedString(
            en: "From Low Plank, inhale and press through your hands to straighten your arms, lifting your chest and thighs off the floor. Roll your shoulders back and down, open the chest wide, and press the tops of your feet into the mat. Only your hands and the tops of your feet touch the floor.",
            fr: "Depuis la planche basse, inspirez et poussez à travers les mains pour tendre les bras, soulevant la poitrine et les cuisses du sol. Roulez les épaules vers l'arrière et vers le bas, ouvrez la poitrine largement et pressez le dessus des pieds dans le tapis. Seuls les mains et le dessus des pieds touchent le sol."
        ),
        durationSeconds: 20,
        difficulty: .intermediate,
        category: .chest,
        position: .prone,
        imageName: "pose.prone.upward.dog",
        voiceCueText: LocalizedString(
            en: "Press up into Upward Dog. Lift your chest, roll shoulders back, thighs off the mat.",
            fr: "Poussez vers le haut en Chien tête en haut. Soulevez la poitrine, roulez les épaules en arrière, cuisses décollées du tapis."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep thighs on the floor and practice Cobra Pose instead",
                 "Bend your elbows slightly if full arm extension is too intense"],
            fr: ["Gardez les cuisses au sol et pratiquez la posture du Cobra à la place",
                 "Pliez légèrement les coudes si l'extension complète des bras est trop intense"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with lower back injuries or spinal disc issues",
                 "Use caution if you have wrist pain"],
            fr: ["Évitez en cas de blessures au bas du dos ou de problèmes discaux",
                 "Prudence en cas de douleur aux poignets"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift and open the chest, exhale to transition back",
            fr: "Inspirez pour lever et ouvrir la poitrine, expirez pour la transition"
        ),
        isFree: true
    )

    public static let vinyasaDownwardDog = Pose(
        id: "vinyasa-downward-dog",
        name: LocalizedString(
            en: "Downward-Facing Dog",
            fr: "Chien tête en bas"
        ),
        description: LocalizedString(
            en: "From all fours or Upward Dog, tuck your toes and lift your hips high toward the ceiling, forming an inverted V-shape. Press your hands firmly into the mat, spread your fingers wide, and rotate your upper arms outward. Pedal your heels toward the floor and let your head hang between your arms.",
            fr: "Depuis les quatre pattes ou le Chien tête en haut, repliez les orteils et soulevez les hanches haut vers le plafond, formant un V inversé. Pressez fermement les mains dans le tapis, écartez les doigts et tournez les bras supérieurs vers l'extérieur. Pédalez les talons vers le sol et laissez la tête pendre entre les bras."
        ),
        durationSeconds: 45,
        difficulty: .beginner,
        category: .fullBody,
        position: .inversion,
        imageName: "pose.inversion.downward.dog",
        voiceCueText: LocalizedString(
            en: "Lift your hips high in Downward Dog. Press the floor away, lengthen your spine, pedal your heels.",
            fr: "Soulevez les hanches en Chien tête en bas. Repoussez le sol, allongez la colonne, pédalez les talons."
        ),
        modifications: LocalizedStringArray(
            en: ["Bend your knees generously to focus on lengthening the spine",
                 "Place hands on blocks to reduce wrist strain"],
            fr: ["Pliez généreusement les genoux pour allonger la colonne",
                 "Placez les mains sur des blocs pour réduire la tension aux poignets"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with uncontrolled high blood pressure",
                 "Use caution with wrist injuries — try Dolphin Pose instead"],
            fr: ["Évitez en cas d'hypertension artérielle non contrôlée",
                 "Prudence en cas de blessures aux poignets — essayez la posture du Dauphin à la place"]
        ),
        breathingPattern: LocalizedString(
            en: "Breathe deeply and steadily, lengthening the spine on each inhale",
            fr: "Respirez profondément et régulièrement, allongeant la colonne à chaque inspiration"
        ),
        isFree: true
    )

    public static let vinyasaWarriorI = Pose(
        id: "vinyasa-warrior-i",
        name: LocalizedString(
            en: "Warrior I",
            fr: "Guerrier I"
        ),
        description: LocalizedString(
            en: "Step one foot forward into a lunge with the back foot angled at about 45 degrees. Bend the front knee to 90 degrees, stacking it over the ankle. Square your hips forward and reach both arms overhead with palms facing each other. Lift through the chest and gaze up toward your thumbs.",
            fr: "Avancez un pied en fente avec le pied arrière tourné à environ 45 degrés. Pliez le genou avant à 90 degrés, aligné au-dessus de la cheville. Alignez les hanches vers l'avant et levez les deux bras au-dessus de la tête, paumes face à face. Soulevez la poitrine et regardez vers les pouces."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .legs,
        position: .standing,
        imageName: "pose.standing.warrior.one",
        voiceCueText: LocalizedString(
            en: "Rise into Warrior I. Front knee over ankle, arms reaching high. Square your hips and lift your chest.",
            fr: "Montez en Guerrier I. Genou avant au-dessus de la cheville, bras tendus vers le haut. Alignez les hanches et soulevez la poitrine."
        ),
        modifications: LocalizedStringArray(
            en: ["Shorten your stance if the lunge feels too deep",
                 "Keep hands on hips instead of overhead if shoulders are tight"],
            fr: ["Raccourcissez votre position si la fente est trop profonde",
                 "Gardez les mains sur les hanches au lieu de les lever si les épaules sont tendues"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with knee injuries — do not let the front knee extend past the ankle",
                 "Use caution with hip flexor strains"],
            fr: ["Évitez en cas de blessures au genou — ne laissez pas le genou avant dépasser la cheville",
                 "Prudence en cas de tensions au fléchisseur de la hanche"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to reach higher, exhale to sink deeper into the lunge",
            fr: "Inspirez pour vous étirer plus haut, expirez pour descendre plus profondément dans la fente"
        ),
        isFree: true
    )

    // MARK: - Vinyasa Poses (Premium)

    public static let vinyasaWarriorII = Pose(
        id: "vinyasa-warrior-ii",
        name: LocalizedString(
            en: "Warrior II",
            fr: "Guerrier II"
        ),
        description: LocalizedString(
            en: "From a wide stance, bend your front knee to 90 degrees over the ankle while keeping the back leg straight and strong. Extend your arms out to the sides at shoulder height, palms facing down. Stack your torso directly over your pelvis, gaze past your front fingertips, and sink your hips low.",
            fr: "Depuis une position large, pliez le genou avant à 90 degrés au-dessus de la cheville tout en gardant la jambe arrière droite et forte. Étendez les bras sur les côtés à la hauteur des épaules, paumes vers le bas. Empilez le torse directement au-dessus du bassin, regardez au-delà du bout des doigts avant et descendez les hanches."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .legs,
        position: .standing,
        imageName: "pose.standing.warrior.two",
        voiceCueText: LocalizedString(
            en: "Open into Warrior II. Arms wide, front knee bent, gaze past your front hand. Strong and steady.",
            fr: "Ouvrez-vous en Guerrier II. Bras écartés, genou avant plié, regard au-delà de la main avant. Fort et stable."
        ),
        modifications: LocalizedStringArray(
            en: ["Shorten your stance to reduce intensity on the front thigh",
                 "Rest your hands on your hips if your shoulders fatigue quickly"],
            fr: ["Raccourcissez votre position pour réduire l'intensité sur la cuisse avant",
                 "Posez les mains sur les hanches si les épaules fatiguent rapidement"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a knee injury on the front leg",
                 "Use caution with hip replacements"],
            fr: ["Évitez en cas de blessure au genou de la jambe avant",
                 "Prudence en cas de prothèse de hanche"]
        ),
        breathingPattern: LocalizedString(
            en: "Breathe evenly — inhale to lengthen, exhale to deepen the bend",
            fr: "Respirez régulièrement — inspirez pour allonger, expirez pour approfondir la flexion"
        ),
        isFree: false
    )

    public static let vinyasaWarriorIII = Pose(
        id: "vinyasa-warrior-iii",
        name: LocalizedString(
            en: "Warrior III",
            fr: "Guerrier III"
        ),
        description: LocalizedString(
            en: "From standing, shift your weight onto one leg and hinge forward at the hips while lifting the back leg parallel to the floor. Extend your arms forward alongside your ears or keep them along your torso. Your body forms a T-shape from fingertips to lifted heel. Engage your standing leg and core for balance.",
            fr: "Depuis la position debout, transférez le poids sur une jambe et penchez-vous vers l'avant à partir des hanches en soulevant la jambe arrière parallèle au sol. Étendez les bras vers l'avant le long des oreilles ou gardez-les le long du torse. Le corps forme un T du bout des doigts au talon levé. Engagez la jambe d'appui et le tronc pour l'équilibre."
        ),
        durationSeconds: 25,
        difficulty: .advanced,
        category: .balance,
        position: .standing,
        imageName: "pose.standing.warrior.three",
        voiceCueText: LocalizedString(
            en: "Fly into Warrior III. One strong standing leg, body in a T-shape. Find a focal point and breathe.",
            fr: "Envolez-vous en Guerrier III. Une jambe d'appui solide, corps en forme de T. Trouvez un point focal et respirez."
        ),
        modifications: LocalizedStringArray(
            en: ["Place your hands on blocks beneath your shoulders for support",
                 "Keep the lifted leg lower — it doesn't need to be parallel to the floor"],
            fr: ["Placez les mains sur des blocs sous les épaules pour du soutien",
                 "Gardez la jambe levée plus basse — elle n'a pas besoin d'être parallèle au sol"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with ankle instability or recent ankle sprains",
                 "Not recommended if you have severe balance disorders"],
            fr: ["Évitez en cas d'instabilité de la cheville ou d'entorse récente",
                 "Non recommandé en cas de troubles graves de l'équilibre"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady, calm breaths — exhale to stabilize, inhale to lengthen",
            fr: "Respirations calmes et régulières — expirez pour stabiliser, inspirez pour allonger"
        ),
        isFree: false
    )

    public static let vinyasaReverseWarrior = Pose(
        id: "vinyasa-reverse-warrior",
        name: LocalizedString(
            en: "Reverse Warrior",
            fr: "Guerrier inversé"
        ),
        description: LocalizedString(
            en: "From Warrior II, flip your front palm to face the ceiling and reach your front arm up and back overhead while your back hand slides down the back leg. Keep the front knee bent deeply and lift through the side body, creating a graceful arch. Open your chest toward the sky.",
            fr: "Depuis le Guerrier II, retournez la paume avant vers le plafond et étirez le bras avant vers le haut et l'arrière au-dessus de la tête tandis que la main arrière glisse le long de la jambe arrière. Gardez le genou avant profondément plié et soulevez le côté du corps, créant un arc gracieux. Ouvrez la poitrine vers le ciel."
        ),
        durationSeconds: 25,
        difficulty: .intermediate,
        category: .spine,
        position: .standing,
        imageName: "pose.standing.reverse.warrior",
        voiceCueText: LocalizedString(
            en: "Reach up and back in Reverse Warrior. Keep the front knee bent. Open the side body long.",
            fr: "Étirez-vous vers le haut et l'arrière en Guerrier inversé. Gardez le genou avant plié. Ouvrez le côté du corps en longueur."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the reaching arm bent at the elbow if the shoulder is tight",
                 "Straighten the front leg slightly to reduce thigh fatigue"],
            fr: ["Gardez le bras tendu plié au coude si l'épaule est tendue",
                 "Redressez légèrement la jambe avant pour réduire la fatigue de la cuisse"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid deep lateral bending with spinal disc issues",
                 "Use caution if you have neck problems — keep the gaze forward instead of up"],
            fr: ["Évitez les flexions latérales profondes en cas de problèmes discaux",
                 "Prudence en cas de problèmes cervicaux — gardez le regard vers l'avant au lieu de vers le haut"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to reach and open, exhale to deepen the side stretch",
            fr: "Inspirez pour atteindre et ouvrir, expirez pour approfondir l'étirement latéral"
        ),
        isFree: false
    )

    public static let vinyasaExtendedSideAngle = Pose(
        id: "vinyasa-extended-side-angle",
        name: LocalizedString(
            en: "Extended Side Angle",
            fr: "Angle latéral étendu"
        ),
        description: LocalizedString(
            en: "From Warrior II, place your front forearm on your front thigh or bring your front hand to the floor outside your front foot. Extend your top arm overhead alongside your ear, creating one long line from back heel to fingertips. Rotate your chest open toward the ceiling and engage your core.",
            fr: "Depuis le Guerrier II, placez l'avant-bras avant sur la cuisse avant ou amenez la main avant au sol à l'extérieur du pied avant. Étendez le bras supérieur au-dessus de la tête le long de l'oreille, créant une longue ligne du talon arrière au bout des doigts. Tournez la poitrine ouverte vers le plafond et engagez le tronc."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .fullBody,
        position: .standing,
        imageName: "pose.standing.extended.side.angle",
        voiceCueText: LocalizedString(
            en: "Reach long in Extended Side Angle. One line from heel to fingertips. Open your chest to the sky.",
            fr: "Étirez-vous en longueur en Angle latéral étendu. Une ligne du talon au bout des doigts. Ouvrez la poitrine vers le ciel."
        ),
        modifications: LocalizedStringArray(
            en: ["Rest your forearm on your thigh instead of reaching to the floor",
                 "Use a block under your bottom hand for more height"],
            fr: ["Posez l'avant-bras sur la cuisse au lieu de descendre au sol",
                 "Utilisez un bloc sous la main du bas pour plus de hauteur"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with knee pain — do not let the front knee collapse inward",
                 "Use caution with neck injuries — look down instead of up"],
            fr: ["Évitez en cas de douleur au genou — ne laissez pas le genou avant s'effondrer vers l'intérieur",
                 "Prudence en cas de blessures cervicales — regardez vers le bas au lieu de vers le haut"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to extend and lengthen, exhale to rotate the chest open",
            fr: "Inspirez pour étendre et allonger, expirez pour tourner la poitrine ouverte"
        ),
        isFree: false
    )

    public static let vinyasaTriangle = Pose(
        id: "vinyasa-triangle",
        name: LocalizedString(
            en: "Triangle Pose",
            fr: "Posture du triangle"
        ),
        description: LocalizedString(
            en: "From a wide stance with arms extended, straighten your front leg and hinge at the hip to reach your front hand toward your shin, ankle, or the floor. Stack your top shoulder over the bottom one and extend the top arm straight up. Create length through both sides of the torso equally.",
            fr: "Depuis une position large avec les bras étendus, redressez la jambe avant et pliez à la hanche pour amener la main avant vers le tibia, la cheville ou le sol. Empilez l'épaule supérieure au-dessus de l'inférieure et étendez le bras supérieur droit vers le haut. Créez de la longueur des deux côtés du torse également."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .legs,
        position: .standing,
        imageName: "pose.standing.triangle",
        voiceCueText: LocalizedString(
            en: "Extend into Triangle. Long front leg, reach down and up. Both sides of the torso equally long.",
            fr: "Étendez-vous en Triangle. Jambe avant longue, étirez vers le bas et vers le haut. Les deux côtés du torse également longs."
        ),
        modifications: LocalizedStringArray(
            en: ["Place your bottom hand on a block instead of the floor",
                 "Micro-bend the front knee to avoid hyperextension"],
            fr: ["Placez la main du bas sur un bloc au lieu du sol",
                 "Micro-pliez le genou avant pour éviter l'hyperextension"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with severe hamstring injuries",
                 "Use caution if you have low blood pressure or dizziness"],
            fr: ["Évitez en cas de blessures graves aux ischio-jambiers",
                 "Prudence en cas de tension artérielle basse ou d'étourdissements"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the spine, exhale to rotate the chest open",
            fr: "Inspirez pour allonger la colonne, expirez pour tourner la poitrine ouverte"
        ),
        isFree: false
    )

    public static let vinyasaHalfMoon = Pose(
        id: "vinyasa-half-moon",
        name: LocalizedString(
            en: "Half Moon",
            fr: "Demi-lune"
        ),
        description: LocalizedString(
            en: "From Triangle, bend your front knee and shift your weight forward, placing your front hand on the floor or a block about a foot ahead. Lift your back leg parallel to the floor and open your hips and chest toward the ceiling. Extend your top arm skyward and find a steady gaze point.",
            fr: "Depuis le Triangle, pliez le genou avant et transférez le poids vers l'avant, plaçant la main avant au sol ou sur un bloc environ un pied devant. Soulevez la jambe arrière parallèle au sol et ouvrez les hanches et la poitrine vers le plafond. Étendez le bras supérieur vers le ciel et trouvez un point de regard stable."
        ),
        durationSeconds: 25,
        difficulty: .advanced,
        category: .balance,
        position: .standing,
        imageName: "pose.standing.half.moon",
        voiceCueText: LocalizedString(
            en: "Rise into Half Moon. Stack your hips, lift the back leg, reach up. Find your balance and shine.",
            fr: "Montez en Demi-lune. Empilez les hanches, soulevez la jambe arrière, étirez vers le haut. Trouvez votre équilibre et rayonnez."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a block under your bottom hand for better balance",
                 "Keep the top hand on your hip instead of reaching up"],
            fr: ["Utilisez un bloc sous la main du bas pour un meilleur équilibre",
                 "Gardez la main du haut sur la hanche au lieu de la tendre vers le haut"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with ankle or knee instability on the standing leg",
                 "Not recommended for those with severe vertigo"],
            fr: ["Évitez en cas d'instabilité de la cheville ou du genou de la jambe d'appui",
                 "Non recommandé en cas de vertiges sévères"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, steady breaths — exhale to stabilize, inhale to expand",
            fr: "Respirations lentes et régulières — expirez pour stabiliser, inspirez pour ouvrir"
        ),
        isFree: false
    )

    public static let vinyasaChairPose = Pose(
        id: "vinyasa-chair-pose",
        name: LocalizedString(
            en: "Chair Pose",
            fr: "Posture de la chaise"
        ),
        description: LocalizedString(
            en: "Stand with feet together or hip-width apart. Bend your knees deeply as if sitting back into an imaginary chair, keeping your weight in your heels. Sweep your arms overhead alongside your ears. Keep your chest lifted, core engaged, and thighs working toward parallel with the floor.",
            fr: "Tenez-vous debout, pieds joints ou à la largeur des hanches. Pliez profondément les genoux comme si vous vous assoyiez sur une chaise imaginaire, en gardant le poids dans les talons. Balayez les bras au-dessus de la tête le long des oreilles. Gardez la poitrine soulevée, le tronc engagé et les cuisses travaillant vers la parallèle au sol."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .legs,
        position: .standing,
        imageName: "pose.standing.chair",
        voiceCueText: LocalizedString(
            en: "Sit back into Chair Pose. Weight in the heels, arms high, chest lifted. Feel the burn in your thighs.",
            fr: "Assoyez-vous en Posture de la chaise. Le poids dans les talons, bras hauts, poitrine soulevée. Sentez les cuisses travailler."
        ),
        modifications: LocalizedStringArray(
            en: ["Don't bend as deeply — a slight bend is enough to start",
                 "Keep arms at heart center instead of overhead"],
            fr: ["Ne pliez pas aussi profondément — une légère flexion suffit pour commencer",
                 "Gardez les bras au centre du cœur au lieu de les lever"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with knee injuries or acute knee pain",
                 "Use caution with low blood pressure when rising"],
            fr: ["Évitez en cas de blessures au genou ou de douleur aiguë au genou",
                 "Prudence en cas de tension artérielle basse en vous relevant"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the spine, exhale to sit deeper",
            fr: "Inspirez pour allonger la colonne, expirez pour descendre plus profondément"
        ),
        isFree: false
    )

    public static let vinyasaCrescentLunge = Pose(
        id: "vinyasa-crescent-lunge",
        name: LocalizedString(
            en: "Crescent Lunge",
            fr: "Fente en croissant"
        ),
        description: LocalizedString(
            en: "From Downward Dog, step one foot forward between your hands. Rise up on an inhale, stacking your front knee over the ankle at 90 degrees. Keep the back leg straight and strong with the heel lifted high. Reach both arms overhead and gently arch your upper back.",
            fr: "Depuis le Chien tête en bas, avancez un pied entre les mains. Levez-vous en inspirant, en alignant le genou avant au-dessus de la cheville à 90 degrés. Gardez la jambe arrière droite et forte avec le talon levé haut. Levez les deux bras au-dessus de la tête et cambrez doucement le haut du dos."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .legs,
        position: .standing,
        imageName: "pose.standing.crescent.lunge",
        voiceCueText: LocalizedString(
            en: "Rise into Crescent Lunge. Strong back leg, front knee at 90 degrees. Reach high and lift the chest.",
            fr: "Montez en Fente en croissant. Jambe arrière forte, genou avant à 90 degrés. Étirez-vous haut et soulevez la poitrine."
        ),
        modifications: LocalizedStringArray(
            en: ["Lower the back knee to the floor for a Low Lunge variation",
                 "Keep hands on hips if raising arms overhead is too intense"],
            fr: ["Abaissez le genou arrière au sol pour une variation en fente basse",
                 "Gardez les mains sur les hanches si lever les bras est trop intense"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute knee injuries",
                 "Use caution with hip flexor strains on the back leg"],
            fr: ["Évitez en cas de blessures aiguës au genou",
                 "Prudence en cas de tensions au fléchisseur de la hanche de la jambe arrière"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift and lengthen, exhale to ground and deepen the lunge",
            fr: "Inspirez pour lever et allonger, expirez pour ancrer et approfondir la fente"
        ),
        isFree: false
    )

    public static let vinyasaHighLungeTwist = Pose(
        id: "vinyasa-high-lunge-twist",
        name: LocalizedString(
            en: "High Lunge Twist",
            fr: "Fente haute avec torsion"
        ),
        description: LocalizedString(
            en: "From Crescent Lunge, bring your palms together at heart center. On an exhale, twist your torso toward your front leg, hooking your opposite elbow outside the front knee. Press your palms together to deepen the rotation. Keep your hips square and your spine long.",
            fr: "Depuis la Fente en croissant, joignez les paumes au centre du cœur. En expirant, tournez le torse vers la jambe avant, accrochant le coude opposé à l'extérieur du genou avant. Pressez les paumes ensemble pour approfondir la rotation. Gardez les hanches alignées et la colonne longue."
        ),
        durationSeconds: 25,
        difficulty: .intermediate,
        category: .spine,
        position: .standing,
        imageName: "pose.standing.high.lunge.twist",
        voiceCueText: LocalizedString(
            en: "Twist from your Lunge. Elbow outside the knee, palms together. Lengthen on the inhale, rotate on the exhale.",
            fr: "Tournez depuis votre Fente. Coude à l'extérieur du genou, paumes jointes. Allongez en inspirant, tournez en expirant."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep hands on the front knee and twist gently without the bind",
                 "Lower the back knee to the floor for more stability"],
            fr: ["Gardez les mains sur le genou avant et tournez doucement sans la liaison",
                 "Abaissez le genou arrière au sol pour plus de stabilité"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid deep twists with spinal disc herniation",
                 "Use caution during pregnancy — keep the twist mild"],
            fr: ["Évitez les torsions profondes en cas de hernie discale",
                 "Prudence durant la grossesse — gardez la torsion légère"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the spine, exhale to deepen the twist",
            fr: "Inspirez pour allonger la colonne, expirez pour approfondir la torsion"
        ),
        isFree: false
    )

    public static let vinyasaWideLegForwardFold = Pose(
        id: "vinyasa-wide-leg-forward-fold",
        name: LocalizedString(
            en: "Wide-Legged Forward Fold",
            fr: "Flexion avant jambes écartées"
        ),
        description: LocalizedString(
            en: "Stand with feet wide apart, toes pointing slightly inward. Hinge at the hips and fold your torso forward, bringing your hands to the floor between your feet. Walk your hands back in line with your feet and let the crown of your head release toward the floor. Keep your legs strong and your weight shifted slightly forward.",
            fr: "Tenez-vous debout avec les pieds largement écartés, orteils pointant légèrement vers l'intérieur. Pliez à partir des hanches et rabattez le torse vers l'avant, amenant les mains au sol entre les pieds. Reculez les mains en ligne avec les pieds et laissez le sommet de la tête descendre vers le sol. Gardez les jambes fortes et le poids légèrement vers l'avant."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .back,
        position: .standing,
        imageName: "pose.standing.wide.leg.fold",
        voiceCueText: LocalizedString(
            en: "Fold forward with wide legs. Release the crown of the head down. Strong legs, soft spine.",
            fr: "Pliez vers l'avant avec les jambes écartées. Relâchez le sommet de la tête vers le bas. Jambes fortes, colonne souple."
        ),
        modifications: LocalizedStringArray(
            en: ["Place hands on blocks if they don't reach the floor",
                 "Bend the knees slightly to ease hamstring tension"],
            fr: ["Placez les mains sur des blocs si elles n'atteignent pas le sol",
                 "Pliez légèrement les genoux pour atténuer la tension des ischio-jambiers"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with lower back injuries — bend knees generously",
                 "Rise slowly if you have low blood pressure"],
            fr: ["Évitez en cas de blessures au bas du dos — pliez généreusement les genoux",
                 "Relevez-vous lentement en cas de tension artérielle basse"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to fold deeper, inhale to create space in the spine",
            fr: "Expirez pour plier plus profondément, inspirez pour créer de l'espace dans la colonne"
        ),
        isFree: false
    )

    public static let vinyasaPyramid = Pose(
        id: "vinyasa-pyramid",
        name: LocalizedString(
            en: "Pyramid Pose",
            fr: "Posture de la pyramide"
        ),
        description: LocalizedString(
            en: "From standing, step one foot back about three feet with both feet pointing forward. Square your hips and fold over the front leg with a long spine. Place your hands on blocks, your shin, or the floor on either side of the front foot. Keep both legs straight and press evenly through both feet.",
            fr: "Depuis la position debout, reculez un pied d'environ un mètre, les deux pieds pointant vers l'avant. Alignez les hanches et pliez au-dessus de la jambe avant avec une colonne longue. Placez les mains sur des blocs, le tibia ou le sol de chaque côté du pied avant. Gardez les deux jambes droites et appuyez uniformément sur les deux pieds."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .legs,
        position: .standing,
        imageName: "pose.standing.pyramid",
        voiceCueText: LocalizedString(
            en: "Fold over the front leg in Pyramid. Square the hips, lengthen the spine, straight legs.",
            fr: "Pliez au-dessus de la jambe avant en Pyramide. Hanches alignées, colonne longue, jambes droites."
        ),
        modifications: LocalizedStringArray(
            en: ["Use blocks under both hands for more height",
                 "Bend the front knee slightly if hamstrings are very tight"],
            fr: ["Utilisez des blocs sous les deux mains pour plus de hauteur",
                 "Pliez légèrement le genou avant si les ischio-jambiers sont très tendus"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with hamstring tears or acute pulls",
                 "Use caution with lower back sensitivity"],
            fr: ["Évitez en cas de déchirures ou de claquages aux ischio-jambiers",
                 "Prudence en cas de sensibilité au bas du dos"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the front of the body, exhale to fold deeper",
            fr: "Inspirez pour allonger l'avant du corps, expirez pour plier plus profondément"
        ),
        isFree: false
    )

    public static let vinyasaRevolvedTriangle = Pose(
        id: "vinyasa-revolved-triangle",
        name: LocalizedString(
            en: "Revolved Triangle",
            fr: "Triangle en torsion"
        ),
        description: LocalizedString(
            en: "From Pyramid Pose, place your opposite hand on the floor or a block outside your front foot and twist your torso open toward the front leg side. Extend your top arm straight up, stacking the shoulders. Keep both legs straight and your hips as level as possible while rotating through the mid-spine.",
            fr: "Depuis la posture de la Pyramide, placez la main opposée au sol ou sur un bloc à l'extérieur du pied avant et tournez le torse ouvert vers le côté de la jambe avant. Étendez le bras supérieur droit vers le haut, en empilant les épaules. Gardez les deux jambes droites et les hanches aussi nivelées que possible en tournant à travers le milieu de la colonne."
        ),
        durationSeconds: 30,
        difficulty: .advanced,
        category: .spine,
        position: .standing,
        imageName: "pose.standing.revolved.triangle",
        voiceCueText: LocalizedString(
            en: "Twist into Revolved Triangle. Bottom hand down, top arm up. Rotate from the mid-back, not the lower back.",
            fr: "Tournez en Triangle en torsion. Main du bas en appui, bras du haut vers le ciel. Tournez à partir du milieu du dos, pas du bas du dos."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a block under the bottom hand for more space to twist",
                 "Bend the front knee slightly for more balance"],
            fr: ["Utilisez un bloc sous la main du bas pour plus d'espace de torsion",
                 "Pliez légèrement le genou avant pour plus d'équilibre"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with spinal disc issues or acute back pain",
                 "Not recommended during pregnancy"],
            fr: ["Évitez en cas de problèmes discaux ou de douleur aiguë au dos",
                 "Non recommandé durant la grossesse"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the spine, exhale to revolve deeper",
            fr: "Inspirez pour allonger la colonne, expirez pour tourner plus profondément"
        ),
        isFree: false
    )

    public static let vinyasaCrow = Pose(
        id: "vinyasa-crow",
        name: LocalizedString(
            en: "Crow Pose",
            fr: "Posture du corbeau"
        ),
        description: LocalizedString(
            en: "From a low squat, place your hands shoulder-width apart on the floor. Bend your elbows slightly and place your knees high on the backs of your upper arms. Shift your weight forward into your hands, lift your feet off the floor one at a time, and draw your heels toward your seat. Round your upper back and gaze slightly forward.",
            fr: "Depuis un squat bas, placez les mains à la largeur des épaules au sol. Pliez légèrement les coudes et placez les genoux haut sur l'arrière des bras supérieurs. Transférez le poids vers l'avant dans les mains, soulevez les pieds du sol un à la fois et ramenez les talons vers les fesses. Arrondissez le haut du dos et regardez légèrement vers l'avant."
        ),
        durationSeconds: 20,
        difficulty: .advanced,
        category: .arms,
        position: .inversion,
        imageName: "pose.inversion.crow",
        voiceCueText: LocalizedString(
            en: "Lean forward into Crow. Knees on the arms, shift the weight, lift the feet. Trust your hands.",
            fr: "Penchez-vous vers l'avant en Corbeau. Genoux sur les bras, transférez le poids, soulevez les pieds. Faites confiance à vos mains."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a block under your feet to start from a higher position",
                 "Keep your toes on the floor and practice the weight shift without lifting fully"],
            fr: ["Placez un bloc sous les pieds pour partir d'une position plus haute",
                 "Gardez les orteils au sol et pratiquez le transfert de poids sans lever complètement"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with wrist injuries or carpal tunnel syndrome",
                 "Not recommended with shoulder instability or recent shoulder surgery"],
            fr: ["Évitez en cas de blessures aux poignets ou de syndrome du canal carpien",
                 "Non recommandé en cas d'instabilité de l'épaule ou de chirurgie récente de l'épaule"]
        ),
        breathingPattern: LocalizedString(
            en: "Breathe steadily — exhale to engage the core and lift, inhale to hold",
            fr: "Respirez régulièrement — expirez pour engager le tronc et lever, inspirez pour maintenir"
        ),
        isFree: false
    )

    public static let vinyasaSidePlank = Pose(
        id: "vinyasa-side-plank",
        name: LocalizedString(
            en: "Side Plank",
            fr: "Planche latérale"
        ),
        description: LocalizedString(
            en: "From High Plank, shift your weight onto one hand and the outer edge of the same-side foot. Stack your feet or stagger them for balance. Lift your hips high and extend the top arm toward the ceiling. Your body forms a diagonal line from head to feet. Engage your obliques to keep the hips lifted.",
            fr: "Depuis la planche haute, transférez le poids sur une main et le bord extérieur du pied du même côté. Empilez les pieds ou décalez-les pour l'équilibre. Soulevez les hanches haut et étendez le bras supérieur vers le plafond. Le corps forme une ligne diagonale de la tête aux pieds. Engagez les obliques pour garder les hanches levées."
        ),
        durationSeconds: 25,
        difficulty: .intermediate,
        category: .core,
        position: .prone,
        imageName: "pose.prone.side.plank",
        voiceCueText: LocalizedString(
            en: "Lift into Side Plank. Hips high, top arm reaching up. Stay strong through the core.",
            fr: "Montez en Planche latérale. Hanches hautes, bras du haut vers le ciel. Restez fort à travers le tronc."
        ),
        modifications: LocalizedStringArray(
            en: ["Lower your bottom knee to the floor for support",
                 "Place the top hand on your hip instead of reaching up"],
            fr: ["Abaissez le genou du bas au sol pour du soutien",
                 "Placez la main du haut sur la hanche au lieu de la tendre vers le haut"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with wrist or shoulder injuries on the supporting side",
                 "Not recommended with severe rotator cuff issues"],
            fr: ["Évitez en cas de blessures au poignet ou à l'épaule du côté d'appui",
                 "Non recommandé en cas de problèmes graves de la coiffe des rotateurs"]
        ),
        breathingPattern: LocalizedString(
            en: "Breathe deeply to maintain stability — exhale to engage, inhale to lengthen",
            fr: "Respirez profondément pour maintenir la stabilité — expirez pour engager, inspirez pour allonger"
        ),
        isFree: false
    )

    public static let vinyasaWildThing = Pose(
        id: "vinyasa-wild-thing",
        name: LocalizedString(
            en: "Wild Thing",
            fr: "Chose sauvage"
        ),
        description: LocalizedString(
            en: "From Downward Dog or Side Plank, lift your top leg and step it behind you, landing on the ball of the foot. Let your hips rise high as your supporting hand stays planted. Sweep your free arm overhead, opening the chest wide toward the ceiling. Arch your back and let your head drop back gently.",
            fr: "Depuis le Chien tête en bas ou la Planche latérale, soulevez la jambe du haut et posez-la derrière vous sur la plante du pied. Laissez les hanches monter haut tandis que la main d'appui reste plantée. Balayez le bras libre au-dessus de la tête, ouvrant la poitrine largement vers le plafond. Cambrez le dos et laissez la tête retomber doucement."
        ),
        durationSeconds: 20,
        difficulty: .advanced,
        category: .chest,
        position: .prone,
        imageName: "pose.prone.wild.thing",
        voiceCueText: LocalizedString(
            en: "Flip into Wild Thing. Open your heart to the sky, let your hips lift high. Feel the freedom in the chest.",
            fr: "Retournez-vous en Chose sauvage. Ouvrez le cœur vers le ciel, laissez les hanches monter haut. Sentez la liberté dans la poitrine."
        ),
        modifications: LocalizedStringArray(
            en: ["Stay in Side Plank with the top arm extended as a gentler option",
                 "Keep the back foot closer to the front foot for more stability"],
            fr: ["Restez en Planche latérale avec le bras du haut tendu pour une option plus douce",
                 "Gardez le pied arrière plus près du pied avant pour plus de stabilité"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with wrist, shoulder, or rotator cuff injuries",
                 "Not recommended with severe lower back issues"],
            fr: ["Évitez en cas de blessures aux poignets, épaules ou coiffe des rotateurs",
                 "Non recommandé en cas de problèmes graves au bas du dos"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to open the chest and lift, exhale to return with control",
            fr: "Inspirez pour ouvrir la poitrine et lever, expirez pour revenir avec contrôle"
        ),
        isFree: false
    )

    public static let vinyasaCamel = Pose(
        id: "vinyasa-camel",
        name: LocalizedString(
            en: "Camel Pose",
            fr: "Posture du chameau"
        ),
        description: LocalizedString(
            en: "Kneel with your knees hip-width apart, thighs perpendicular to the floor. Place your hands on your lower back with fingers pointing down. On an inhale, lift your chest and begin to arch backward, pressing your hips forward. If comfortable, reach your hands back to your heels. Keep your neck long and avoid crunching the lower back.",
            fr: "Agenouillez-vous avec les genoux à la largeur des hanches, cuisses perpendiculaires au sol. Placez les mains sur le bas du dos, doigts pointant vers le bas. En inspirant, soulevez la poitrine et commencez à cambrer vers l'arrière, poussant les hanches vers l'avant. Si c'est confortable, tendez les mains vers les talons. Gardez le cou long et évitez de comprimer le bas du dos."
        ),
        durationSeconds: 25,
        difficulty: .intermediate,
        category: .chest,
        position: .kneeling,
        imageName: "pose.kneeling.camel",
        voiceCueText: LocalizedString(
            en: "Open into Camel. Press your hips forward, lift the chest high, reach for the heels. Breathe into the heart.",
            fr: "Ouvrez-vous en Chameau. Poussez les hanches vers l'avant, soulevez la poitrine, tendez vers les talons. Respirez dans le cœur."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep your hands on your lower back instead of reaching for the heels",
                 "Tuck your toes under to bring the heels higher and closer"],
            fr: ["Gardez les mains sur le bas du dos au lieu de tendre vers les talons",
                 "Repliez les orteils pour rapprocher et surélever les talons"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute lower back pain or spinal stenosis",
                 "Not recommended with neck injuries — keep the head neutral"],
            fr: ["Évitez en cas de douleur aiguë au bas du dos ou de sténose spinale",
                 "Non recommandé en cas de blessures cervicales — gardez la tête neutre"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift and open the chest, exhale to settle deeper into the backbend",
            fr: "Inspirez pour lever et ouvrir la poitrine, expirez pour vous installer plus profondément dans la cambrure"
        ),
        isFree: false
    )

    public static let vinyasaDancer = Pose(
        id: "vinyasa-dancer",
        name: LocalizedString(
            en: "Dancer's Pose",
            fr: "Posture du danseur"
        ),
        description: LocalizedString(
            en: "Stand tall and shift your weight onto one leg. Bend your opposite knee and reach back with the same-side hand to grab the inner ankle. On an inhale, extend your free arm forward and up. Begin to kick the lifted foot into your hand, pressing the leg back and up while hinging your torso forward. Find a steady gaze point.",
            fr: "Tenez-vous debout et transférez le poids sur une jambe. Pliez le genou opposé et tendez la main du même côté vers l'arrière pour saisir l'intérieur de la cheville. En inspirant, étendez le bras libre vers l'avant et le haut. Commencez à pousser le pied levé dans la main, pressant la jambe vers l'arrière et le haut tout en penchant le torse vers l'avant. Trouvez un point de regard stable."
        ),
        durationSeconds: 25,
        difficulty: .advanced,
        category: .balance,
        position: .standing,
        imageName: "pose.standing.dancer",
        voiceCueText: LocalizedString(
            en: "Rise into Dancer. Kick back into your hand, reach forward. Balance, grace, and strength.",
            fr: "Montez en Danseur. Poussez le pied dans la main, étirez-vous vers l'avant. Équilibre, grâce et force."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a strap around the ankle if you cannot reach your foot",
                 "Stand near a wall and place your free hand on it for balance"],
            fr: ["Utilisez une sangle autour de la cheville si vous ne pouvez pas atteindre le pied",
                 "Tenez-vous près d'un mur et placez la main libre dessus pour l'équilibre"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with ankle, knee, or hip injuries on the standing leg",
                 "Not recommended with severe balance disorders or vertigo"],
            fr: ["Évitez en cas de blessures à la cheville, au genou ou à la hanche de la jambe d'appui",
                 "Non recommandé en cas de troubles graves de l'équilibre ou de vertiges"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, focused breaths — inhale to lift and extend, exhale to stabilize",
            fr: "Respirations lentes et concentrées — inspirez pour lever et étendre, expirez pour stabiliser"
        ),
        isFree: false
    )

    // MARK: - Vinyasa Pose Collection

    public static let vinyasaPoses: [Pose] = [
        // Beginner / Free
        vinyasaMountain,
        vinyasaForwardFold,
        vinyasaHalfwayLift,
        vinyasaHighPlank,
        vinyasaChaturanga,
        vinyasaUpwardDog,
        vinyasaDownwardDog,
        vinyasaWarriorI,
        // Intermediate & Advanced / Premium
        vinyasaWarriorII,
        vinyasaWarriorIII,
        vinyasaReverseWarrior,
        vinyasaExtendedSideAngle,
        vinyasaTriangle,
        vinyasaHalfMoon,
        vinyasaChairPose,
        vinyasaCrescentLunge,
        vinyasaHighLungeTwist,
        vinyasaWideLegForwardFold,
        vinyasaPyramid,
        vinyasaRevolvedTriangle,
        vinyasaCrow,
        vinyasaSidePlank,
        vinyasaWildThing,
        vinyasaCamel,
        vinyasaDancer,
    ]

    // MARK: - Vinyasa Plans

    public static let vinyasaSunSalutationA = WorkoutPlan(
        id: "vinyasa-sun-salutation-a",
        name: LocalizedString(
            en: "Sun Salutation A",
            fr: "Salutation au soleil A"
        ),
        description: LocalizedString(
            en: "A classic 7-minute sun salutation linking breath to movement through foundational standing and floor poses.",
            fr: "Une salutation au soleil classique de 7 minutes reliant le souffle au mouvement à travers des postures fondamentales debout et au sol."
        ),
        style: .vinyasa,
        poses: [
            vinyasaMountain,
            vinyasaForwardFold,
            vinyasaHalfwayLift,
            vinyasaHighPlank,
            vinyasaChaturanga,
            vinyasaUpwardDog,
            vinyasaDownwardDog,
            vinyasaForwardFold,
            vinyasaMountain,
        ],
        transitionSeconds: 5,
        isFree: true
    )

    public static let vinyasaPowerFlow = WorkoutPlan(
        id: "vinyasa-power-flow",
        name: LocalizedString(
            en: "Power Vinyasa Flow",
            fr: "Vinyasa dynamique"
        ),
        description: LocalizedString(
            en: "An energizing 15-minute power flow combining sun salutation transitions with standing warrior and lunge sequences.",
            fr: "Un enchaînement dynamique de 15 minutes combinant des transitions de salutation au soleil avec des séquences de guerriers debout et de fentes."
        ),
        style: .vinyasa,
        poses: [
            vinyasaMountain,
            vinyasaForwardFold,
            vinyasaHalfwayLift,
            vinyasaHighPlank,
            vinyasaChaturanga,
            vinyasaUpwardDog,
            vinyasaDownwardDog,
            vinyasaWarriorI,
            vinyasaWarriorII,
            vinyasaReverseWarrior,
            vinyasaExtendedSideAngle,
            vinyasaTriangle,
            vinyasaChairPose,
            vinyasaCrescentLunge,
            vinyasaHighLungeTwist,
            vinyasaForwardFold,
            vinyasaMountain,
        ],
        transitionSeconds: 5,
        isFree: false
    )

    public static let vinyasaFullExperience = WorkoutPlan(
        id: "vinyasa-full-experience",
        name: LocalizedString(
            en: "Full Vinyasa Experience",
            fr: "Expérience Vinyasa complète"
        ),
        description: LocalizedString(
            en: "A comprehensive 20-minute session flowing through all 25 vinyasa poses — from foundational sun salutations to advanced arm balances and backbends.",
            fr: "Une séance complète de 20 minutes parcourant les 25 postures vinyasa — des salutations au soleil fondamentales aux équilibres sur les bras et cambrures avancées."
        ),
        style: .vinyasa,
        poses: vinyasaPoses,
        transitionSeconds: 5,
        isFree: false
    )

    public static let vinyasaPlans: [WorkoutPlan] = [
        vinyasaSunSalutationA,
        vinyasaPowerFlow,
        vinyasaFullExperience,
    ]
}
