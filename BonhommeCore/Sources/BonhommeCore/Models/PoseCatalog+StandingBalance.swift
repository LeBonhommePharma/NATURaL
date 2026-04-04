import Foundation

// MARK: - Standing Balance Poses & Plans

extension PoseCatalog {

    // MARK: - Beginner Poses (Free)

    public static let treePose = Pose(
        id: "balance-tree",
        name: LocalizedString(
            en: "Tree Pose (Vrksasana)",
            fr: "Posture de l'arbre (Vrksasana)"
        ),
        description: LocalizedString(
            en: "Root through your standing foot and draw the opposite foot to your inner thigh or calf, never on the knee. Fix your dristi on a single still point ahead to anchor your balance. This foundational single-leg pose develops proprioception and steady focus over time.",
            fr: "Enracinez-vous à travers le pied d'appui et amenez le pied opposé à l'intérieur de la cuisse ou du mollet, jamais sur le genou. Fixez votre dristi sur un point fixe devant vous pour ancrer votre équilibre. Cette posture fondamentale sur une jambe développe la proprioception et la concentration stable avec le temps."
        ),
        durationSeconds: 35,
        difficulty: .beginner,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.tree",
        voiceCueText: LocalizedString(
            en: "Rise into Tree Pose. Press your standing foot firmly into the earth. Find a focal point and breathe steadily.",
            fr: "Montez en posture de l'arbre. Pressez fermement votre pied d'appui dans le sol. Trouvez un point focal et respirez de façon régulière."
        ),
        modifications: LocalizedStringArray(
            en: ["Place your foot on your ankle instead of your thigh for more stability",
                 "Keep your hands at heart center instead of overhead if balance is challenging"],
            fr: ["Placez votre pied sur la cheville plutôt que sur la cuisse pour plus de stabilité",
                 "Gardez les mains au centre du cœur plutôt qu'au-dessus de la tête si l'équilibre est difficile"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute ankle or knee injuries on the standing leg"],
            fr: ["Évitez en cas de blessure aiguë à la cheville ou au genou de la jambe d'appui"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, even breaths — inhale to lengthen the spine, exhale to root down through the foot",
            fr: "Respirations lentes et régulières — inspirez pour allonger la colonne, expirez pour vous enraciner à travers le pied"
        ),
        isFree: true
    )

    public static let eaglePose = Pose(
        id: "balance-eagle",
        name: LocalizedString(
            en: "Eagle Pose (Garudasana)",
            fr: "Posture de l'aigle (Garudasana)"
        ),
        description: LocalizedString(
            en: "Wrap one leg over the other and sink into a single-leg squat while entwining the arms. Keep your dristi fixed on a point just above eye level to stabilize the body. This compact posture challenges proprioception by narrowing your base of support while engaging the hips and shoulders.",
            fr: "Enroulez une jambe par-dessus l'autre et descendez en squat sur une jambe en entrelaçant les bras. Gardez votre dristi fixé sur un point juste au-dessus du niveau des yeux pour stabiliser le corps. Cette posture compacte sollicite la proprioception en réduisant la base d'appui tout en engageant les hanches et les épaules."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.eagle",
        voiceCueText: LocalizedString(
            en: "Cross into Eagle Pose. Wrap the arms, sink the hips, and fix your gaze on a single steady point.",
            fr: "Croisez en posture de l'aigle. Enroulez les bras, descendez les hanches et fixez votre regard sur un point stable."
        ),
        modifications: LocalizedStringArray(
            en: ["Rest the top foot's toes on the floor instead of fully wrapping the leg",
                 "Simply cross the arms at the wrists if the full wrap is too intense"],
            fr: ["Déposez les orteils du pied supérieur au sol au lieu d'enrouler complètement la jambe",
                 "Croisez simplement les bras aux poignets si l'enroulement complet est trop intense"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with recent knee or shoulder injuries"],
            fr: ["Évitez en cas de blessure récente au genou ou à l'épaule"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady nasal breathing — exhale as you sink deeper, inhale to hold and lengthen",
            fr: "Respiration nasale régulière — expirez en descendant plus bas, inspirez pour maintenir et allonger"
        ),
        isFree: true
    )

    public static let warriorIII = Pose(
        id: "balance-warrior-iii",
        name: LocalizedString(
            en: "Warrior III (Virabhadrasana III)",
            fr: "Guerrier III (Virabhadrasana III)"
        ),
        description: LocalizedString(
            en: "Hinge forward from the hips while extending the back leg straight behind you, forming a T-shape. Direct your dristi to a spot on the floor about a metre ahead to maintain alignment. This powerful balance pose demands hip-level alignment and engages the entire posterior chain for single-leg stability.",
            fr: "Penchez-vous vers l'avant à partir des hanches en étirant la jambe arrière droite derrière vous pour former un T. Dirigez votre dristi vers un point au sol à environ un mètre devant vous pour maintenir l'alignement. Cette puissante posture d'équilibre exige un alignement au niveau des hanches et engage toute la chaîne postérieure pour la stabilité sur une jambe."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.warrior.iii",
        voiceCueText: LocalizedString(
            en: "Float into Warrior III. Reach forward as the back leg lifts. Keep hips squared to the ground.",
            fr: "Glissez en Guerrier III. Tendez vers l'avant pendant que la jambe arrière se soulève. Gardez les hanches parallèles au sol."
        ),
        modifications: LocalizedStringArray(
            en: ["Place fingertips on blocks to reduce the balance demand",
                 "Keep the back leg lower — even a slight lift builds strength"],
            fr: ["Placez le bout des doigts sur des blocs pour réduire la difficulté de l'équilibre",
                 "Gardez la jambe arrière plus basse — même un léger soulèvement renforce la force"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with high blood pressure or significant lower back issues"],
            fr: ["Évitez en cas d'hypertension artérielle ou de problèmes importants au bas du dos"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to extend through the crown and back heel, exhale to stabilize the standing leg",
            fr: "Inspirez pour vous étendre à travers le sommet du crâne et le talon arrière, expirez pour stabiliser la jambe d'appui"
        ),
        isFree: true
    )

    public static let halfMoon = Pose(
        id: "balance-half-moon",
        name: LocalizedString(
            en: "Half Moon (Ardha Chandrasana)",
            fr: "Demi-lune (Ardha Chandrasana)"
        ),
        description: LocalizedString(
            en: "Open the hips and torso to the side while balancing on one leg with the bottom hand grounded or on a block. Fix your dristi upward toward the raised hand to deepen the rotational balance challenge. This pose builds single-leg stability while opening the hips and strengthening proprioceptive awareness.",
            fr: "Ouvrez les hanches et le torse sur le côté en vous tenant en équilibre sur une jambe, la main du bas au sol ou sur un bloc. Fixez votre dristi vers le haut en direction de la main levée pour approfondir le défi d'équilibre rotatif. Cette posture développe la stabilité sur une jambe tout en ouvrant les hanches et en renforçant la conscience proprioceptive."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.half.moon",
        voiceCueText: LocalizedString(
            en: "Open into Half Moon. Stack the hips, extend through both legs, and gaze up if your neck allows.",
            fr: "Ouvrez en demi-lune. Empilez les hanches, allongez les deux jambes et regardez vers le haut si votre cou le permet."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a block under the bottom hand to bring the floor closer",
                 "Keep the top hand on the hip and gaze forward instead of upward"],
            fr: ["Utilisez un bloc sous la main du bas pour rapprocher le sol",
                 "Gardez la main du haut sur la hanche et regardez devant vous plutôt que vers le haut"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with severe neck issues — keep the gaze neutral",
                 "Use caution with low blood pressure or dizziness"],
            fr: ["Évitez en cas de problèmes cervicaux importants — gardez le regard neutre",
                 "Soyez prudent en cas d'hypotension artérielle ou d'étourdissements"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to expand through the chest and top arm, exhale to firm the standing leg",
            fr: "Inspirez pour ouvrir la poitrine et le bras supérieur, expirez pour raffermir la jambe d'appui"
        ),
        isFree: true
    )

    public static let dancersPose = Pose(
        id: "balance-dancer",
        name: LocalizedString(
            en: "Dancer's Pose (Natarajasana)",
            fr: "Posture du danseur (Natarajasana)"
        ),
        description: LocalizedString(
            en: "Grasp your back ankle and press the foot into the hand while reaching the opposite arm forward, creating a graceful bow shape. Lock your dristi on a fixed point at eye level to keep the torso lifting. This elegant backbend-balance hybrid builds single-leg proprioception and opens the chest and hip flexors simultaneously.",
            fr: "Saisissez votre cheville arrière et pressez le pied dans la main tout en tendant le bras opposé vers l'avant, créant une forme d'arc gracieuse. Verrouillez votre dristi sur un point fixe au niveau des yeux pour garder le torse soulevé. Cet hybride élégant de flexion arrière et d'équilibre développe la proprioception sur une jambe et ouvre la poitrine et les fléchisseurs de la hanche simultanément."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.dancer",
        voiceCueText: LocalizedString(
            en: "Rise into Dancer's Pose. Kick the back foot into the hand, reach forward, and find your focal point.",
            fr: "Montez en posture du danseur. Poussez le pied arrière dans la main, tendez vers l'avant et trouvez votre point focal."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a yoga strap around the back foot if reaching the ankle is difficult",
                 "Keep the back kick gentle and the torso more upright for less intensity"],
            fr: ["Utilisez une sangle de yoga autour du pied arrière si la cheville est difficile à atteindre",
                 "Gardez le coup de pied arrière doux et le torse plus droit pour moins d'intensité"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with shoulder impingement or acute lower back pain"],
            fr: ["Évitez en cas de conflit à l'épaule ou de douleur aiguë au bas du dos"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift and expand, exhale to press the foot deeper into the hand",
            fr: "Inspirez pour soulever et ouvrir, expirez pour presser le pied plus profondément dans la main"
        ),
        isFree: true
    )

    public static let standingFigureFour = Pose(
        id: "balance-figure-four",
        name: LocalizedString(
            en: "Standing Figure Four",
            fr: "Quatre debout"
        ),
        description: LocalizedString(
            en: "Cross one ankle over the opposite thigh and slowly bend the standing knee as if sitting into a chair. Soften your dristi onto a still point on the floor a few feet ahead to maintain calm focus. This accessible balance pose opens the outer hip while developing single-leg stability and body awareness.",
            fr: "Croisez une cheville sur la cuisse opposée et pliez lentement le genou d'appui comme si vous vous assoyiez sur une chaise. Adoucissez votre dristi sur un point fixe au sol à quelques pieds devant vous pour maintenir une concentration calme. Cette posture d'équilibre accessible ouvre la hanche externe tout en développant la stabilité sur une jambe et la conscience corporelle."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.figure.four",
        voiceCueText: LocalizedString(
            en: "Cross into Standing Figure Four. Sit back slowly, keep the chest lifted, and soften your gaze.",
            fr: "Croisez en quatre debout. Assoyez-vous lentement vers l'arrière, gardez la poitrine soulevée et adoucissez le regard."
        ),
        modifications: LocalizedStringArray(
            en: ["Hold onto a wall or chair back for additional support",
                 "Keep the standing leg straighter if the deep squat is too challenging"],
            fr: ["Tenez-vous à un mur ou au dossier d'une chaise pour plus de soutien",
                 "Gardez la jambe d'appui plus droite si le squat profond est trop exigeant"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute knee pain on the standing leg"],
            fr: ["Évitez en cas de douleur aiguë au genou de la jambe d'appui"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to stand tall, exhale to sit a little deeper with control",
            fr: "Inspirez pour vous redresser, expirez pour descendre un peu plus bas avec contrôle"
        ),
        isFree: true
    )

    public static let extendedHandToBigToe = Pose(
        id: "balance-hand-to-toe",
        name: LocalizedString(
            en: "Extended Hand-to-Big-Toe (Utthita Hasta Padangusthasana)",
            fr: "Main au gros orteil étendue (Utthita Hasta Padangusthasana)"
        ),
        description: LocalizedString(
            en: "Stand tall, lift one knee to the chest, then extend the leg forward while holding the big toe or using a strap. Fix your dristi on a steady point directly ahead to keep the torso upright and the hips square. This demanding balance develops hamstring flexibility and deep proprioceptive control on one leg.",
            fr: "Tenez-vous droit, levez un genou vers la poitrine, puis allongez la jambe vers l'avant en tenant le gros orteil ou en utilisant une sangle. Fixez votre dristi sur un point stable directement devant vous pour garder le torse droit et les hanches alignées. Cet équilibre exigeant développe la souplesse des ischio-jambiers et un contrôle proprioceptif profond sur une jambe."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.hand.to.toe",
        voiceCueText: LocalizedString(
            en: "Extend into Hand-to-Big-Toe Pose. Straighten the lifted leg slowly. Keep your standing hip firm and your gaze steady.",
            fr: "Étendez en posture main au gros orteil. Allongez la jambe levée lentement. Gardez la hanche d'appui ferme et le regard stable."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the lifted knee bent if the hamstrings are tight",
                 "Use a yoga strap around the foot sole to extend your reach"],
            fr: ["Gardez le genou levé plié si les ischio-jambiers sont tendus",
                 "Utilisez une sangle de yoga autour de la plante du pied pour allonger votre portée"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with hamstring tears or acute groin strain"],
            fr: ["Évitez en cas de déchirure des ischio-jambiers ou de tension aiguë à l'aine"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the spine, exhale to extend the leg a little further",
            fr: "Inspirez pour allonger la colonne, expirez pour étendre la jambe un peu plus loin"
        ),
        isFree: true
    )

    // MARK: - Intermediate & Advanced Poses (Premium)

    public static let standingBow = Pose(
        id: "balance-standing-bow",
        name: LocalizedString(
            en: "Standing Bow (Dandayamana Dhanurasana)",
            fr: "Arc debout (Dandayamana Dhanurasana)"
        ),
        description: LocalizedString(
            en: "Grip the inner ankle of the back leg and kick upward while reaching the opposite arm forward, tilting the torso toward the floor. Lock your dristi on one unwavering point ahead to keep the chest open and the body steady. This intense single-leg backbend demands hip alignment and trains deep proprioceptive awareness under load.",
            fr: "Saisissez l'intérieur de la cheville de la jambe arrière et poussez vers le haut tout en tendant le bras opposé vers l'avant, inclinant le torse vers le sol. Verrouillez votre dristi sur un point immuable devant vous pour garder la poitrine ouverte et le corps stable. Cette flexion arrière intense sur une jambe exige un alignement des hanches et entraîne la conscience proprioceptive profonde sous charge."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.standing.bow",
        voiceCueText: LocalizedString(
            en: "Enter Standing Bow. Kick the back foot up and reach forward. Let your dristi anchor you as you open.",
            fr: "Entrez en arc debout. Poussez le pied arrière vers le haut et tendez vers l'avant. Laissez votre dristi vous ancrer pendant que vous ouvrez."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a strap around the back ankle for greater reach",
                 "Keep the torso more upright and the kick lower to reduce intensity"],
            fr: ["Utilisez une sangle autour de la cheville arrière pour une meilleure portée",
                 "Gardez le torse plus droit et le coup de pied plus bas pour réduire l'intensité"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with shoulder or lower back injuries"],
            fr: ["Évitez en cas de blessures à l'épaule ou au bas du dos"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift the chest, exhale to kick the foot deeper and hinge forward",
            fr: "Inspirez pour soulever la poitrine, expirez pour pousser le pied plus profondément et pivoter vers l'avant"
        ),
        isFree: false
    )

    public static let revolvedHalfMoon = Pose(
        id: "balance-revolved-half-moon",
        name: LocalizedString(
            en: "Revolved Half Moon (Parivrtta Ardha Chandrasana)",
            fr: "Demi-lune en torsion (Parivrtta Ardha Chandrasana)"
        ),
        description: LocalizedString(
            en: "From a single-leg stand, twist the torso open toward the lifted-leg side while grounding the opposite hand on the floor or a block. Direct your dristi toward the ceiling hand to deepen the spinal rotation and balance challenge. This advanced pose layers a deep twist onto single-leg stability, demanding precise hip alignment and constant proprioceptive adjustment.",
            fr: "Depuis un appui sur une jambe, tournez le torse du côté de la jambe levée en ancrant la main opposée au sol ou sur un bloc. Dirigez votre dristi vers la main au plafond pour approfondir la rotation vertébrale et le défi d'équilibre. Cette posture avancée superpose une torsion profonde à la stabilité sur une jambe, exigeant un alignement précis des hanches et un ajustement proprioceptif constant."
        ),
        durationSeconds: 30,
        difficulty: .advanced,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.revolved.half.moon",
        voiceCueText: LocalizedString(
            en: "Twist into Revolved Half Moon. Ground the bottom hand, rotate the chest, and lift your gaze slowly.",
            fr: "Tournez en demi-lune en torsion. Ancrez la main du bas, faites pivoter la poitrine et levez le regard lentement."
        ),
        modifications: LocalizedStringArray(
            en: ["Place the bottom hand on a tall block to reduce the twist depth",
                 "Keep the top hand on the hip and gaze downward for stability"],
            fr: ["Placez la main du bas sur un bloc haut pour réduire la profondeur de la torsion",
                 "Gardez la main du haut sur la hanche et regardez vers le bas pour la stabilité"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with spinal disc issues or sacroiliac joint dysfunction",
                 "Not recommended during pregnancy"],
            fr: ["Évitez en cas de problèmes discaux vertébraux ou de dysfonction de l'articulation sacro-iliaque",
                 "Non recommandé pendant la grossesse"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the spine, exhale to deepen the twist with control",
            fr: "Inspirez pour allonger la colonne, expirez pour approfondir la torsion avec contrôle"
        ),
        isFree: false
    )

    public static let standingSplit = Pose(
        id: "balance-standing-split",
        name: LocalizedString(
            en: "Standing Split (Urdhva Prasarita Eka Padasana)",
            fr: "Grand écart debout (Urdhva Prasarita Eka Padasana)"
        ),
        description: LocalizedString(
            en: "Fold forward over the standing leg while lifting the back leg as high as possible toward the ceiling. Set your dristi softly on the standing shin or the floor beneath you to calm the nervous system. This deep forward fold on one leg builds hamstring length, hip alignment, and refined proprioceptive balance.",
            fr: "Pliez vers l'avant au-dessus de la jambe d'appui tout en levant la jambe arrière aussi haut que possible vers le plafond. Posez votre dristi doucement sur le tibia d'appui ou le sol en dessous pour calmer le système nerveux. Ce pli avant profond sur une jambe développe la souplesse des ischio-jambiers, l'alignement des hanches et un équilibre proprioceptif raffiné."
        ),
        durationSeconds: 30,
        difficulty: .advanced,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.standing.split",
        voiceCueText: LocalizedString(
            en: "Fold into Standing Split. Walk the hands close to the standing foot and let the back leg float upward.",
            fr: "Pliez en grand écart debout. Rapprochez les mains du pied d'appui et laissez la jambe arrière flotter vers le haut."
        ),
        modifications: LocalizedStringArray(
            en: ["Place hands on blocks if the floor is far away",
                 "Keep the back leg lower and focus on the forward fold depth"],
            fr: ["Placez les mains sur des blocs si le sol est loin",
                 "Gardez la jambe arrière plus basse et concentrez-vous sur la profondeur du pli avant"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute hamstring injuries or sciatica"],
            fr: ["Évitez en cas de blessure aiguë aux ischio-jambiers ou de sciatique"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to fold deeper, inhale to lengthen the spine slightly before folding again",
            fr: "Expirez pour plier plus profondément, inspirez pour allonger légèrement la colonne avant de replier"
        ),
        isFree: false
    )

    public static let airplanePose = Pose(
        id: "balance-airplane",
        name: LocalizedString(
            en: "Airplane Pose",
            fr: "Posture de l'avion"
        ),
        description: LocalizedString(
            en: "From Warrior III, sweep the arms back along the sides like wings while keeping the torso and back leg parallel to the floor. Anchor your dristi on a point ahead on the floor to steady the long horizontal line of the body. This variation strengthens the posterior chain and challenges proprioception without the counterbalance of arms reaching forward.",
            fr: "Depuis Guerrier III, balayez les bras vers l'arrière le long du corps comme des ailes en gardant le torse et la jambe arrière parallèles au sol. Ancrez votre dristi sur un point au sol devant vous pour stabiliser la longue ligne horizontale du corps. Cette variante renforce la chaîne postérieure et met au défi la proprioception sans le contrepoids des bras tendus vers l'avant."
        ),
        durationSeconds: 35,
        difficulty: .intermediate,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.airplane",
        voiceCueText: LocalizedString(
            en: "Glide into Airplane Pose. Sweep the arms back, level the hips, and hold your gaze on the floor ahead.",
            fr: "Glissez en posture de l'avion. Balayez les bras vers l'arrière, nivelez les hanches et gardez le regard sur le sol devant vous."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the back leg lower to reduce difficulty",
                 "Place fingertips on the floor or blocks for extra support"],
            fr: ["Gardez la jambe arrière plus basse pour réduire la difficulté",
                 "Placez le bout des doigts au sol ou sur des blocs pour un soutien supplémentaire"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with lower back pain or hamstring injuries"],
            fr: ["Évitez en cas de douleur au bas du dos ou de blessure aux ischio-jambiers"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady breaths — inhale to extend from crown to heel, exhale to firm the standing leg",
            fr: "Respirations stables — inspirez pour vous étendre du sommet du crâne au talon, expirez pour raffermir la jambe d'appui"
        ),
        isFree: false
    )

    public static let topplingTree = Pose(
        id: "balance-toppling-tree",
        name: LocalizedString(
            en: "Toppling Tree",
            fr: "Arbre qui penche"
        ),
        description: LocalizedString(
            en: "From Tree Pose, slowly tilt the torso sideways toward the lifted-leg side while extending the top arm overhead. Keep your dristi on a point ahead at eye level to manage the lateral weight shift. This side-bending balance strengthens the obliques and standing-leg stabilizers while sharpening proprioceptive control in an unusual plane.",
            fr: "Depuis la posture de l'arbre, inclinez lentement le torse sur le côté vers la jambe levée tout en étendant le bras supérieur au-dessus de la tête. Gardez votre dristi sur un point au niveau des yeux devant vous pour gérer le déplacement latéral du poids. Cet équilibre en flexion latérale renforce les obliques et les stabilisateurs de la jambe d'appui tout en affinant le contrôle proprioceptif dans un plan inhabituel."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.toppling.tree",
        voiceCueText: LocalizedString(
            en: "Tilt into Toppling Tree. Lean sideways slowly, reach overhead, and keep your focus point steady.",
            fr: "Inclinez en arbre qui penche. Penchez lentement sur le côté, tendez au-dessus de la tête et gardez votre point focal stable."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the lifted foot lower on the calf for easier balance",
                 "Reduce the side tilt and keep the top hand on the hip"],
            fr: ["Gardez le pied levé plus bas sur le mollet pour un équilibre plus facile",
                 "Réduisez l'inclinaison latérale et gardez la main du haut sur la hanche"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if prone to vertigo or lateral spinal issues"],
            fr: ["Évitez si vous êtes sujet aux vertiges ou aux problèmes latéraux de la colonne"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen through the extended arm, exhale to control the lateral lean",
            fr: "Inspirez pour allonger à travers le bras étendu, expirez pour contrôler l'inclinaison latérale"
        ),
        isFree: false
    )

    public static let standingPigeon = Pose(
        id: "balance-standing-pigeon",
        name: LocalizedString(
            en: "Standing Pigeon (Figure Four Forward Fold)",
            fr: "Pigeon debout (Quatre en pli avant)"
        ),
        description: LocalizedString(
            en: "From Standing Figure Four, hinge forward at the hips and lower the torso toward the crossed leg while keeping the spine long. Drop your dristi to a point between the hands or on the floor to find calm within the deep fold. This forward-folding balance deeply opens the piriformis and outer hip while demanding steady single-leg proprioception.",
            fr: "Depuis le quatre debout, penchez-vous vers l'avant aux hanches et abaissez le torse vers la jambe croisée en gardant la colonne allongée. Abaissez votre dristi vers un point entre les mains ou au sol pour trouver le calme dans le pli profond. Cet équilibre en pli avant ouvre profondément le piriforme et la hanche externe tout en exigeant une proprioception stable sur une jambe."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .hips,
        position: .standing,
        imageName: "pose.balance.standing.pigeon",
        voiceCueText: LocalizedString(
            en: "Fold into Standing Pigeon. Hinge at the hips with the ankle crossed over. Breathe into the outer hip.",
            fr: "Pliez en pigeon debout. Pivotez aux hanches avec la cheville croisée. Respirez dans la hanche externe."
        ),
        modifications: LocalizedStringArray(
            en: ["Hold a wall or chair for balance support during the fold",
                 "Keep the standing knee more bent to ease the balance demand"],
            fr: ["Tenez-vous à un mur ou à une chaise pour le soutien de l'équilibre pendant le pli",
                 "Gardez le genou d'appui plus plié pour faciliter l'exigence d'équilibre"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute knee issues on the crossed leg"],
            fr: ["Évitez en cas de problèmes aigus au genou de la jambe croisée"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to fold deeper, inhale to maintain length in the spine",
            fr: "Expirez pour plier plus profondément, inspirez pour maintenir la longueur de la colonne"
        ),
        isFree: false
    )

    public static let flamingoPose = Pose(
        id: "balance-flamingo",
        name: LocalizedString(
            en: "Flamingo Pose",
            fr: "Posture du flamant rose"
        ),
        description: LocalizedString(
            en: "Stand on one leg and draw the opposite knee toward the chest, holding the shin with both hands. Set your dristi on a calm, unmoving point at eye level to root the posture. This gentle single-leg balance is an excellent introduction to proprioceptive training, building ankle stability and quiet focus.",
            fr: "Tenez-vous sur une jambe et ramenez le genou opposé vers la poitrine en tenant le tibia avec les deux mains. Posez votre dristi sur un point calme et immobile au niveau des yeux pour enraciner la posture. Cet équilibre doux sur une jambe est une excellente introduction à l'entraînement proprioceptif, développant la stabilité de la cheville et une concentration tranquille."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.flamingo",
        voiceCueText: LocalizedString(
            en: "Lift into Flamingo Pose. Hug the knee in gently and root through the standing foot.",
            fr: "Montez en posture du flamant rose. Serrez doucement le genou et enracinez-vous dans le pied d'appui."
        ),
        modifications: LocalizedStringArray(
            en: ["Lightly touch a wall with one hand for extra balance",
                 "Keep the lifted knee lower if hip flexion is limited"],
            fr: ["Touchez légèrement un mur d'une main pour un équilibre supplémentaire",
                 "Gardez le genou levé plus bas si la flexion de la hanche est limitée"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute hip flexor strain"],
            fr: ["Évitez en cas de tension aiguë au fléchisseur de la hanche"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow breaths — inhale to stand taller, exhale to draw the knee closer",
            fr: "Respirations lentes — inspirez pour vous grandir, expirez pour rapprocher le genou"
        ),
        isFree: false
    )

    public static let oneLeggedMountain = Pose(
        id: "balance-one-legged-mountain",
        name: LocalizedString(
            en: "One-Legged Mountain",
            fr: "Montagne sur une jambe"
        ),
        description: LocalizedString(
            en: "From Mountain Pose, simply lift one foot a few inches off the floor while keeping the arms at the sides and the body perfectly upright. Fix your dristi straight ahead on a single point at eye level to cultivate stillness. This deceptively simple pose is the purest test of single-leg stability and teaches proprioceptive awareness from the ground up.",
            fr: "Depuis la posture de la montagne, levez simplement un pied de quelques pouces du sol en gardant les bras le long du corps et le corps parfaitement droit. Fixez votre dristi droit devant sur un point au niveau des yeux pour cultiver l'immobilité. Cette posture d'apparence simple est le test le plus pur de la stabilité sur une jambe et enseigne la conscience proprioceptive depuis la base."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.one.legged.mountain",
        voiceCueText: LocalizedString(
            en: "Stand in One-Legged Mountain. Lift one foot just off the floor. Be still and breathe.",
            fr: "Tenez-vous en montagne sur une jambe. Levez un pied juste au-dessus du sol. Restez immobile et respirez."
        ),
        modifications: LocalizedStringArray(
            en: ["Barely lift the foot — even a millimetre off the floor counts",
                 "Close your eyes for an advanced proprioceptive challenge"],
            fr: ["Levez à peine le pied — même un millimètre du sol compte",
                 "Fermez les yeux pour un défi proprioceptif avancé"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Use caution if you have significant balance disorders — stay near a wall"],
            fr: ["Soyez prudent si vous avez des troubles importants de l'équilibre — restez près d'un mur"]
        ),
        breathingPattern: LocalizedString(
            en: "Quiet, even breathing — let the breath be invisible",
            fr: "Respiration calme et régulière — laissez le souffle être invisible"
        ),
        isFree: false
    )

    public static let toeStand = Pose(
        id: "balance-toe-stand",
        name: LocalizedString(
            en: "Toe Stand (Padangusthasana)",
            fr: "Posture sur les orteils (Padangusthasana)"
        ),
        description: LocalizedString(
            en: "From Tree Pose, fold forward and lower onto the ball of the standing foot, sitting on the heel with the opposite foot remaining on the inner thigh. Set your dristi on a point on the floor just ahead to manage this extremely compressed balance. This advanced pose requires exceptional ankle strength, proprioception, and mental focus to maintain stillness near the floor.",
            fr: "Depuis la posture de l'arbre, pliez vers l'avant et descendez sur l'avant du pied d'appui, en vous assoyant sur le talon avec le pied opposé toujours sur la cuisse intérieure. Posez votre dristi sur un point au sol juste devant vous pour gérer cet équilibre extrêmement comprimé. Cette posture avancée exige une force exceptionnelle de la cheville, de la proprioception et une concentration mentale pour maintenir l'immobilité près du sol."
        ),
        durationSeconds: 30,
        difficulty: .advanced,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.toe.stand",
        voiceCueText: LocalizedString(
            en: "Lower into Toe Stand. Descend slowly, keep the spine tall, and breathe through the challenge.",
            fr: "Descendez en posture sur les orteils. Descendez lentement, gardez la colonne droite et respirez à travers le défi."
        ),
        modifications: LocalizedStringArray(
            en: ["Place fingertips on the floor for support as you lower down",
                 "Use a block under the sitting bones to reduce the depth"],
            fr: ["Placez le bout des doigts au sol pour vous soutenir en descendant",
                 "Utilisez un bloc sous les ischions pour réduire la profondeur"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with ankle instability, knee injuries, or meniscus issues",
                 "Not suitable if you have foot or toe joint problems"],
            fr: ["Évitez en cas d'instabilité de la cheville, de blessures au genou ou de problèmes de ménisque",
                 "Non adapté si vous avez des problèmes articulaires au pied ou aux orteils"]
        ),
        breathingPattern: LocalizedString(
            en: "Short, controlled breaths — exhale to lower, inhale to maintain height",
            fr: "Respirations courtes et contrôlées — expirez pour descendre, inspirez pour maintenir la hauteur"
        ),
        isFree: false
    )

    public static let warriorIIITwist = Pose(
        id: "balance-warrior-iii-twist",
        name: LocalizedString(
            en: "Warrior III Twist",
            fr: "Guerrier III en torsion"
        ),
        description: LocalizedString(
            en: "From Warrior III, bring the hands to heart center and rotate the torso open toward the lifted-leg side. Let your dristi follow the rotation to a point on the wall beside you to reinforce the twist. This advanced variation combines single-leg balance, hip alignment, and spinal rotation, taxing proprioception on multiple planes at once.",
            fr: "Depuis Guerrier III, amenez les mains au centre du cœur et faites pivoter le torse du côté de la jambe levée. Laissez votre dristi suivre la rotation vers un point sur le mur à côté de vous pour renforcer la torsion. Cette variante avancée combine l'équilibre sur une jambe, l'alignement des hanches et la rotation vertébrale, sollicitant la proprioception sur plusieurs plans à la fois."
        ),
        durationSeconds: 30,
        difficulty: .advanced,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.warrior.iii.twist",
        voiceCueText: LocalizedString(
            en: "Add the twist in Warrior III. Hands at heart, rotate the chest open. Keep the hips level.",
            fr: "Ajoutez la torsion en Guerrier III. Mains au cœur, ouvrez la poitrine en rotation. Gardez les hanches de niveau."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep the back leg lower to focus on the twist rather than the balance",
                 "Place the bottom hand on a block and twist from there"],
            fr: ["Gardez la jambe arrière plus basse pour vous concentrer sur la torsion plutôt que l'équilibre",
                 "Placez la main du bas sur un bloc et tournez à partir de là"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with spinal disc issues or sacroiliac instability",
                 "Not recommended with acute lower back pain"],
            fr: ["Évitez en cas de problèmes discaux vertébraux ou d'instabilité sacro-iliaque",
                 "Non recommandé en cas de douleur aiguë au bas du dos"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the spine in Warrior III, exhale to rotate deeper",
            fr: "Inspirez pour allonger la colonne en Guerrier III, expirez pour tourner plus profondément"
        ),
        isFree: false
    )

    public static let starPose = Pose(
        id: "balance-star",
        name: LocalizedString(
            en: "Star Pose (Utthita Tadasana)",
            fr: "Posture de l'étoile (Utthita Tadasana)"
        ),
        description: LocalizedString(
            en: "Stand with feet wide apart and extend the arms out to the sides at shoulder height, creating a five-pointed star shape. Soften your dristi to the horizon to embody expansive stillness through the whole body. This grounding full-body pose activates the legs, core, and shoulders while building awareness of spatial balance and alignment.",
            fr: "Tenez-vous debout les pieds écartés et étendez les bras sur les côtés à la hauteur des épaules, créant une forme d'étoile à cinq branches. Adoucissez votre dristi vers l'horizon pour incarner une immobilité expansive à travers tout le corps. Cette posture ancrante de corps complet active les jambes, le tronc et les épaules tout en développant la conscience de l'équilibre spatial et de l'alignement."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .fullBody,
        position: .standing,
        imageName: "pose.balance.star",
        voiceCueText: LocalizedString(
            en: "Open into Star Pose. Spread wide through fingers and toes. Stand strong and breathe fully.",
            fr: "Ouvrez en posture de l'étoile. Écartez-vous à travers les doigts et les orteils. Tenez-vous fort et respirez pleinement."
        ),
        modifications: LocalizedStringArray(
            en: ["Narrow the stance if the wide legs feel unstable",
                 "Lower the arms to hip height if the shoulders fatigue quickly"],
            fr: ["Réduisez l'écart des pieds si les jambes écartées vous semblent instables",
                 "Abaissez les bras à la hauteur des hanches si les épaules fatiguent rapidement"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if wide stance aggravates inner knee or groin"],
            fr: ["Évitez si l'écart large aggrave l'intérieur du genou ou l'aine"]
        ),
        breathingPattern: LocalizedString(
            en: "Full, expansive breaths — inhale to radiate outward, exhale to root through the feet",
            fr: "Respirations amples et expansives — inspirez pour rayonner vers l'extérieur, expirez pour vous enraciner dans les pieds"
        ),
        isFree: false
    )

    public static let oneLeggedChair = Pose(
        id: "balance-one-legged-chair",
        name: LocalizedString(
            en: "One-Legged Chair",
            fr: "Chaise sur une jambe"
        ),
        description: LocalizedString(
            en: "From Chair Pose, shift your weight onto one foot and lift the other foot off the floor while maintaining the deep knee bend. Lock your dristi on a point ahead at eye level to counteract the asymmetric load. This variation builds tremendous single-leg quad and glute strength while challenging proprioceptive control in a loaded squat position.",
            fr: "Depuis la posture de la chaise, transférez votre poids sur un pied et levez l'autre pied du sol en maintenant la flexion profonde du genou. Verrouillez votre dristi sur un point au niveau des yeux devant vous pour contrebalancer la charge asymétrique. Cette variante développe une force considérable du quadriceps et du fessier sur une jambe tout en mettant au défi le contrôle proprioceptif en position de squat chargé."
        ),
        durationSeconds: 30,
        difficulty: .intermediate,
        category: .legs,
        position: .standing,
        imageName: "pose.balance.one.legged.chair",
        voiceCueText: LocalizedString(
            en: "Shift into One-Legged Chair. Lift one foot slowly, keep sitting deep, and hold your gaze ahead.",
            fr: "Glissez en chaise sur une jambe. Levez un pied lentement, continuez à descendre et gardez le regard devant."
        ),
        modifications: LocalizedStringArray(
            en: ["Barely lift the foot off the floor — the weight shift alone is powerful",
                 "Hold the arms forward at shoulder height or lower them for less demand"],
            fr: ["Levez à peine le pied du sol — le transfert de poids seul est puissant",
                 "Tenez les bras vers l'avant à la hauteur des épaules ou abaissez-les pour moins de difficulté"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid with acute knee pain or patella instability"],
            fr: ["Évitez en cas de douleur aiguë au genou ou d'instabilité de la rotule"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to sink deeper into the single-leg squat, inhale to maintain height and length",
            fr: "Expirez pour descendre plus bas dans le squat sur une jambe, inspirez pour maintenir la hauteur et la longueur"
        ),
        isFree: false
    )

    public static let storkPose = Pose(
        id: "balance-stork",
        name: LocalizedString(
            en: "Stork Pose",
            fr: "Posture de la cigogne"
        ),
        description: LocalizedString(
            en: "Stand on one leg and lift the opposite knee to hip height, keeping the arms relaxed at the sides. Fix your dristi on a calm point straight ahead to find quiet steadiness. This classic single-leg balance is ideal for building foundational proprioception and ankle stability in a simple, accessible shape.",
            fr: "Tenez-vous sur une jambe et levez le genou opposé à la hauteur de la hanche, en gardant les bras détendus le long du corps. Fixez votre dristi sur un point calme droit devant vous pour trouver une stabilité tranquille. Cet équilibre classique sur une jambe est idéal pour développer la proprioception de base et la stabilité de la cheville dans une forme simple et accessible."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .balance,
        position: .standing,
        imageName: "pose.balance.stork",
        voiceCueText: LocalizedString(
            en: "Stand in Stork Pose. Lift the knee to hip height and find your stillness. Breathe easy.",
            fr: "Tenez-vous en posture de la cigogne. Levez le genou à la hauteur de la hanche et trouvez votre immobilité. Respirez calmement."
        ),
        modifications: LocalizedStringArray(
            en: ["Hold a wall for support if balance is new to you",
                 "Lower the knee below hip height if the hip flexor fatigues"],
            fr: ["Tenez-vous au mur pour du soutien si l'équilibre est nouveau pour vous",
                 "Abaissez le genou en dessous de la hauteur de la hanche si le fléchisseur fatigue"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Use caution with significant balance disorders — keep a support nearby"],
            fr: ["Soyez prudent en cas de troubles importants de l'équilibre — gardez un soutien à proximité"]
        ),
        breathingPattern: LocalizedString(
            en: "Easy, natural breaths — let the breath settle the body into stillness",
            fr: "Respirations faciles et naturelles — laissez le souffle installer le corps dans l'immobilité"
        ),
        isFree: false
    )

    // MARK: - Standing Balance Pose Collection

    public static let standingBalancePoses: [Pose] = [
        // Beginner & Intermediate (Free)
        treePose,
        eaglePose,
        warriorIII,
        halfMoon,
        dancersPose,
        standingFigureFour,
        extendedHandToBigToe,
        // Intermediate & Advanced (Premium)
        standingBow,
        revolvedHalfMoon,
        standingSplit,
        airplanePose,
        topplingTree,
        standingPigeon,
        flamingoPose,
        oneLeggedMountain,
        toeStand,
        warriorIIITwist,
        starPose,
        oneLeggedChair,
        storkPose,
    ]

    // MARK: - Standing Balance Plans

    public static let balanceFoundations = WorkoutPlan(
        id: "balance-foundations",
        name: LocalizedString(
            en: "Balance Foundations",
            fr: "Bases de l'équilibre"
        ),
        description: LocalizedString(
            en: "A grounding 7-minute sequence of essential standing balance poses, building single-leg stability from the simplest shapes to more expressive postures.",
            fr: "Un enchaînement ancrant de 7 minutes de postures d'équilibre debout essentielles, développant la stabilité sur une jambe des formes les plus simples aux postures les plus expressives."
        ),
        style: .standingBalance,
        poses: [
            treePose,
            eaglePose,
            standingFigureFour,
            warriorIII,
            halfMoon,
            dancersPose,
            extendedHandToBigToe,
        ],
        transitionSeconds: 5,
        isFree: true
    )

    public static let advancedBalanceChallenge = WorkoutPlan(
        id: "balance-advanced-challenge",
        name: LocalizedString(
            en: "Advanced Balance Challenge",
            fr: "Défi d'équilibre avancé"
        ),
        description: LocalizedString(
            en: "An intensive 12-minute balance practice featuring all twenty standing poses, progressing from foundational holds through demanding single-leg twists, splits, and deep compressions.",
            fr: "Une pratique d'équilibre intensive de 12 minutes comprenant les vingt postures debout, progressant des maintiens fondamentaux jusqu'aux torsions exigeantes sur une jambe, aux grands écarts et aux compressions profondes."
        ),
        style: .standingBalance,
        poses: standingBalancePoses,
        transitionSeconds: 5,
        isFree: false
    )

    public static let standingBalancePlans: [WorkoutPlan] = [
        balanceFoundations,
        advancedBalanceChallenge,
    ]
}
