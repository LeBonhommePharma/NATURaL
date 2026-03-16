import Foundation

// MARK: - Power Yoga Poses & Plans

extension PoseCatalog {

    // MARK: - Free Poses (1–8)

    public static let powerMountain = Pose(
        id: "power-mountain",
        name: LocalizedString(
            en: "Power Mountain",
            fr: "Montagne puissante"
        ),
        description: LocalizedString(
            en: "Stand tall with feet hip-width apart, engaging every muscle from your arches to your fingertips. Sweep your arms overhead dynamically on each inhale, pulling them down with controlled force on the exhale. This active variation of Mountain Pose ignites full-body awareness and builds heat from the very first breath.",
            fr: "Tenez-vous debout, pieds à la largeur des hanches, en engageant chaque muscle des voutes plantaires jusqu'au bout des doigts. Balayez les bras au-dessus de la tête de manière dynamique à chaque inspiration, puis ramenez-les avec une force contrôlée à l'expiration. Cette variation active de la posture de la Montagne éveille la conscience corporelle et bâtit la chaleur dès le premier souffle."
        ),
        durationSeconds: 30,
        difficulty: .beginner,
        category: .fullBody,
        position: .standing,
        imageName: "pose.power.mountain",
        voiceCueText: LocalizedString(
            en: "Stand strong in Power Mountain. Sweep your arms up with power, pull them down with control. Feel every muscle activate.",
            fr: "Tenez-vous fort en Montagne puissante. Balayez les bras vers le haut avec puissance, ramenez-les avec contrôle. Sentez chaque muscle s'activer."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep arms at shoulder height if full overhead reach causes discomfort",
                 "Soften the knees slightly to reduce lower back tension"],
            fr: ["Gardez les bras à la hauteur des épaules si l'extension complète cause de l'inconfort",
                 "Fléchissez légèrement les genoux pour réduire la tension au bas du dos"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Uncontrolled high blood pressure", "Shoulder impingement"],
            fr: ["Hypertension artérielle non contrôlée", "Accrochage de l'épaule"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale arms up, exhale arms down — strong rhythmic breath",
            fr: "Inspirez bras en haut, expirez bras en bas — respiration rythmique puissante"
        ),
        isFree: true
    )

    public static let chairPose = Pose(
        id: "power-chair",
        name: LocalizedString(
            en: "Chair Pose",
            fr: "Posture de la chaise"
        ),
        description: LocalizedString(
            en: "Sink your hips back and down as if sitting into an invisible chair, keeping your weight in your heels and your knees behind your toes. Reach your arms overhead, biceps by your ears, while firing up your quads and glutes. Hold deep in this demanding squat to build tremendous lower-body strength and endurance.",
            fr: "Descendez les hanches vers l'arrière et le bas comme si vous vous assoyiez sur une chaise invisible, en gardant le poids dans les talons et les genoux derrière les orteils. Tendez les bras au-dessus de la tête, biceps près des oreilles, en activant les quadriceps et les fessiers. Maintenez cette position de squat exigeante pour bâtir une force et une endurance considérables dans le bas du corps."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .legs,
        position: .standing,
        imageName: "pose.power.chair",
        voiceCueText: LocalizedString(
            en: "Sink deep into Chair Pose. Press your weight back into your heels, fire up your quads, reach tall through your fingertips.",
            fr: "Descendez profondément en posture de la chaise. Poussez le poids dans les talons, activez les quadriceps, allongez-vous jusqu'au bout des doigts."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep hands at heart center to reduce shoulder strain",
                 "Don't sink as deep — keep a shallower bend in the knees"],
            fr: ["Gardez les mains au centre du coeur pour réduire la tension aux épaules",
                 "Ne descendez pas aussi bas — gardez une flexion moins profonde aux genoux"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Knee injury or chronic knee pain", "Low blood pressure"],
            fr: ["Blessure au genou ou douleur chronique au genou", "Hypotension artérielle"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady ujjayi breath — inhale to lengthen, exhale to sink deeper",
            fr: "Respiration ujjayi régulière — inspirez pour allonger, expirez pour descendre plus profond"
        ),
        isFree: true
    )

    public static let powerPlank = Pose(
        id: "power-plank",
        name: LocalizedString(
            en: "Power Plank",
            fr: "Planche puissante"
        ),
        description: LocalizedString(
            en: "Hold a high plank position with wrists stacked under shoulders, core braced like a shield, and legs fully engaged. Push the floor away with your hands, drawing your navel toward your spine to protect the lower back. This foundational power hold develops deep core stability and full-body muscular endurance.",
            fr: "Maintenez une planche haute avec les poignets empilés sous les épaules, le tronc gainé comme un bouclier et les jambes entièrement engagées. Poussez le sol avec les mains en ramenant le nombril vers la colonne pour protéger le bas du dos. Ce maintien de force fondamental développe la stabilité profonde du tronc et l'endurance musculaire globale."
        ),
        durationSeconds: 60,
        difficulty: .intermediate,
        category: .core,
        position: .prone,
        imageName: "pose.power.plank",
        voiceCueText: LocalizedString(
            en: "Hold strong in Power Plank. Push the floor away, brace your core, keep your body in one straight line from head to heels.",
            fr: "Tenez fermement en planche puissante. Poussez le sol, gainez le tronc, gardez le corps en une ligne droite de la tête aux talons."
        ),
        modifications: LocalizedStringArray(
            en: ["Drop to your knees for a modified plank while maintaining core engagement",
                 "Place forearms on a bench or elevated surface to reduce wrist pressure"],
            fr: ["Descendez sur les genoux pour une planche modifiée tout en maintenant le gainage",
                 "Placez les avant-bras sur un banc ou une surface surélevée pour réduire la pression aux poignets"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Wrist injury or carpal tunnel syndrome", "Shoulder instability"],
            fr: ["Blessure au poignet ou syndrome du canal carpien", "Instabilité de l'épaule"]
        ),
        breathingPattern: LocalizedString(
            en: "Continuous steady breath — do not hold your breath; exhale to deepen the brace",
            fr: "Respiration continue et régulière — ne retenez pas le souffle; expirez pour renforcer le gainage"
        ),
        isFree: true
    )

    public static let sidePlank = Pose(
        id: "power-side-plank",
        name: LocalizedString(
            en: "Side Plank",
            fr: "Planche latérale"
        ),
        description: LocalizedString(
            en: "Stack your feet and lift your hips high in Vasisthasana, pressing firmly through the bottom hand while reaching the top arm skyward. Engage your obliques powerfully to keep your body in a perfectly straight line from head to feet. This pose develops exceptional lateral core strength and shoulder stability under load.",
            fr: "Empilez les pieds et soulevez les hanches en Vasisthasana, en poussant fermement à travers la main du bas tout en tendant le bras du haut vers le ciel. Engagez puissamment les obliques pour garder le corps en une ligne parfaitement droite de la tête aux pieds. Cette posture développe une force latérale exceptionnelle du tronc et la stabilité des épaules sous charge."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .core,
        position: .prone,
        imageName: "pose.power.sideplank",
        voiceCueText: LocalizedString(
            en: "Lift into Side Plank. Stack your hips, press the floor away, reach your top arm high. Keep your obliques firing.",
            fr: "Montez en planche latérale. Empilez les hanches, poussez le sol, tendez le bras du haut. Gardez les obliques engagés."
        ),
        modifications: LocalizedStringArray(
            en: ["Lower the bottom knee to the ground for support",
                 "Place the top hand on your hip instead of reaching overhead"],
            fr: ["Déposez le genou du bas au sol pour du soutien",
                 "Placez la main du haut sur la hanche plutôt que de la tendre vers le haut"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Wrist or shoulder injury", "Rotator cuff tear"],
            fr: ["Blessure au poignet ou à l'épaule", "Déchirure de la coiffe des rotateurs"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift and lengthen, exhale to stabilize and engage deeper",
            fr: "Inspirez pour soulever et allonger, expirez pour stabiliser et engager plus profondément"
        ),
        isFree: true
    )

    public static let forearmPlank = Pose(
        id: "power-forearm-plank",
        name: LocalizedString(
            en: "Forearm Plank",
            fr: "Planche sur les avant-bras"
        ),
        description: LocalizedString(
            en: "Lower onto your forearms with elbows directly beneath your shoulders, clasping your hands or keeping forearms parallel. Drive your elbows into the mat, engage your entire core, and press your heels back. This intense hold targets the deep stabilizers of the trunk while building serious muscular endurance throughout the body.",
            fr: "Descendez sur les avant-bras avec les coudes directement sous les épaules, mains jointes ou avant-bras parallèles. Enfoncez les coudes dans le tapis, engagez tout le tronc et poussez les talons vers l'arrière. Ce maintien intense cible les stabilisateurs profonds du tronc tout en bâtissant une endurance musculaire sérieuse dans tout le corps."
        ),
        durationSeconds: 60,
        difficulty: .intermediate,
        category: .core,
        position: .prone,
        imageName: "pose.power.forearmplank",
        voiceCueText: LocalizedString(
            en: "Hold Forearm Plank. Drive your elbows down, brace your core tight, keep your hips level. Breathe through the intensity.",
            fr: "Maintenez la planche sur les avant-bras. Enfoncez les coudes, gainez le tronc fort, gardez les hanches au niveau. Respirez à travers l'intensité."
        ),
        modifications: LocalizedStringArray(
            en: ["Drop to your knees while keeping your core fully braced",
                 "Use a yoga block between your hands to help align your shoulders"],
            fr: ["Descendez sur les genoux en gardant le tronc entièrement gainé",
                 "Utilisez un bloc de yoga entre les mains pour aider à aligner les épaules"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Elbow or shoulder injury", "Severe lower back pain"],
            fr: ["Blessure au coude ou à l'épaule", "Douleur sévère au bas du dos"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, steady breath — inhale for 4 counts, exhale for 4 counts",
            fr: "Respiration lente et régulière — inspirez sur 4 temps, expirez sur 4 temps"
        ),
        isFree: true
    )

    public static let boatPose = Pose(
        id: "power-boat",
        name: LocalizedString(
            en: "Boat Pose",
            fr: "Posture du bateau"
        ),
        description: LocalizedString(
            en: "Balance on your sit bones with legs lifted to a 45-degree angle, arms reaching forward parallel to the floor. Keep your chest lifted and spine long as your deep core muscles work intensely to maintain this V-shape. Navasana builds powerful abdominal strength and challenges your balance and concentration simultaneously.",
            fr: "Équilibrez-vous sur les ischions avec les jambes levées à un angle de 45 degrés, bras tendus vers l'avant parallèles au sol. Gardez la poitrine soulevée et la colonne allongée alors que les muscles profonds du tronc travaillent intensément pour maintenir cette forme en V. Navasana bâtit une puissante force abdominale et met au défi l'équilibre et la concentration simultanément."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .core,
        position: .seated,
        imageName: "pose.power.boat",
        voiceCueText: LocalizedString(
            en: "Lift into Boat Pose. Balance on your sit bones, reach your arms forward, keep your chest proud and your core on fire.",
            fr: "Montez en posture du bateau. Équilibrez-vous sur les ischions, tendez les bras vers l'avant, gardez la poitrine fière et le tronc en feu."
        ),
        modifications: LocalizedStringArray(
            en: ["Bend your knees to a 90-degree angle for Half Boat",
                 "Hold behind your thighs with your hands for extra support"],
            fr: ["Pliez les genoux à un angle de 90 degrés pour le demi-bateau",
                 "Tenez l'arrière des cuisses avec les mains pour un soutien supplémentaire"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Pregnancy", "Recent abdominal surgery", "Severe lower back issues"],
            fr: ["Grossesse", "Chirurgie abdominale récente", "Problèmes sévères au bas du dos"]
        ),
        breathingPattern: LocalizedString(
            en: "Strong ujjayi breath — exhale to engage deeper, inhale to hold steady",
            fr: "Respiration ujjayi forte — expirez pour engager plus profond, inspirez pour maintenir stable"
        ),
        isFree: true
    )

    public static let warriorIIIPowerHold = Pose(
        id: "power-warrior-iii",
        name: LocalizedString(
            en: "Warrior III Power Hold",
            fr: "Guerrier III maintien puissant"
        ),
        description: LocalizedString(
            en: "Hinge forward on one leg, extending the back leg and arms to form a powerful T-shape parallel to the floor. Engage your standing glute fiercely, fire your core, and reach through your fingertips and back heel simultaneously. This demanding balance hold builds single-leg strength, hip stability, and unshakable focus.",
            fr: "Basculez vers l'avant sur une jambe, en étendant la jambe arrière et les bras pour former un T puissant parallèle au sol. Engagez le fessier de la jambe d'appui avec intensité, activez le tronc et allongez-vous à travers les doigts et le talon arrière simultanément. Ce maintien d'équilibre exigeant bâtit la force sur une jambe, la stabilité de la hanche et une concentration inébranlable."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .balance,
        position: .standing,
        imageName: "pose.power.warrior3",
        voiceCueText: LocalizedString(
            en: "Hold Warrior III. Reach long from fingertips to back heel. Fire your standing glute. Stay strong, stay steady.",
            fr: "Maintenez le Guerrier III. Allongez-vous des doigts au talon arrière. Activez le fessier de la jambe d'appui. Restez fort, restez stable."
        ),
        modifications: LocalizedStringArray(
            en: ["Place fingertips on blocks to reduce balance demand",
                 "Keep the back leg lower — even a slight lift builds strength"],
            fr: ["Placez le bout des doigts sur des blocs pour réduire la difficulté d'équilibre",
                 "Gardez la jambe arrière plus basse — même un léger lever bâtit de la force"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Ankle instability", "Severe balance disorders"],
            fr: ["Instabilité de la cheville", "Troubles sévères de l'équilibre"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, controlled breath — inhale to extend, exhale to stabilize",
            fr: "Respiration lente et contrôlée — inspirez pour allonger, expirez pour stabiliser"
        ),
        isFree: true
    )

    public static let goddessSquat = Pose(
        id: "power-goddess-squat",
        name: LocalizedString(
            en: "Goddess Squat",
            fr: "Posture de la déesse"
        ),
        description: LocalizedString(
            en: "Step wide with toes turned out 45 degrees and sink into a deep squat, thighs approaching parallel to the floor. Hold cactus arms with elbows bent at 90 degrees, squeezing your shoulder blades together. Utkata Konasana fires up the inner thighs, quads, and glutes while opening the hips and building tremendous lower-body power.",
            fr: "Écartez les pieds largement avec les orteils tournés à 45 degrés et descendez dans un squat profond, cuisses approchant le parallèle au sol. Maintenez les bras en cactus avec les coudes pliés à 90 degrés, en serrant les omoplates ensemble. Utkata Konasana active les adducteurs, les quadriceps et les fessiers tout en ouvrant les hanches et en bâtissant une puissance considérable dans le bas du corps."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .legs,
        position: .standing,
        imageName: "pose.power.goddess",
        voiceCueText: LocalizedString(
            en: "Sink into Goddess Squat. Thighs parallel, knees tracking over toes. Squeeze your shoulder blades, hold your power.",
            fr: "Descendez en posture de la déesse. Cuisses parallèles, genoux alignés avec les orteils. Serrez les omoplates, maintenez votre puissance."
        ),
        modifications: LocalizedStringArray(
            en: ["Don't sink as low — keep a shallower squat",
                 "Place hands on thighs for support instead of cactus arms"],
            fr: ["Ne descendez pas aussi bas — gardez un squat moins profond",
                 "Placez les mains sur les cuisses pour du soutien au lieu des bras en cactus"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Knee or hip injury", "Groin strain"],
            fr: ["Blessure au genou ou à la hanche", "Élongation de l'aine"]
        ),
        breathingPattern: LocalizedString(
            en: "Deep belly breath — inhale to hold, exhale to sink a fraction deeper",
            fr: "Respiration abdominale profonde — inspirez pour maintenir, expirez pour descendre une fraction plus profond"
        ),
        isFree: true
    )

    // MARK: - Premium Poses (9–25)

    public static let dolphinPose = Pose(
        id: "power-dolphin",
        name: LocalizedString(
            en: "Dolphin Pose",
            fr: "Posture du dauphin"
        ),
        description: LocalizedString(
            en: "From forearm plank, pike your hips up and back into an inverted V on your forearms, pressing them firmly into the mat. Walk your feet in to deepen the stretch through your shoulders and hamstrings while building serious upper-body strength. Dolphin Pose is a powerful inversion prep that strengthens the shoulders, core, and upper back simultaneously.",
            fr: "Depuis la planche sur les avant-bras, poussez les hanches vers le haut et l'arrière en V inversé sur les avant-bras, en les pressant fermement dans le tapis. Avancez les pieds pour approfondir l'étirement des épaules et des ischio-jambiers tout en bâtissant une force sérieuse du haut du corps. La posture du dauphin est une préparation d'inversion puissante qui renforce les épaules, le tronc et le haut du dos simultanément."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .shoulders,
        position: .inversion,
        imageName: "pose.power.dolphin",
        voiceCueText: LocalizedString(
            en: "Press into Dolphin Pose. Drive your forearms down, pike your hips high, press your chest toward your thighs.",
            fr: "Pressez en posture du dauphin. Enfoncez les avant-bras, poussez les hanches haut, pressez la poitrine vers les cuisses."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep knees generously bent to focus on shoulder engagement",
                 "Use a strap around the upper arms to keep elbows shoulder-width"],
            fr: ["Gardez les genoux généreusement pliés pour cibler l'engagement des épaules",
                 "Utilisez une sangle autour des bras pour garder les coudes à la largeur des épaules"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Shoulder injury", "Uncontrolled high blood pressure", "Glaucoma"],
            fr: ["Blessure à l'épaule", "Hypertension artérielle non contrôlée", "Glaucome"]
        ),
        breathingPattern: LocalizedString(
            en: "Steady ujjayi breath — exhale to press deeper, inhale to hold",
            fr: "Respiration ujjayi régulière — expirez pour presser plus profond, inspirez pour maintenir"
        ),
        isFree: false
    )

    public static let revolvedChair = Pose(
        id: "power-revolved-chair",
        name: LocalizedString(
            en: "Revolved Chair",
            fr: "Chaise en torsion"
        ),
        description: LocalizedString(
            en: "From Chair Pose, bring your palms together at your heart and twist, hooking the opposite elbow outside the knee. Press your palms firmly together to deepen the rotation through the thoracic spine while maintaining the deep squat. This pose combines the leg burn of Utkatasana with a powerful spinal twist that detoxifies and strengthens.",
            fr: "Depuis la posture de la chaise, joignez les paumes au coeur et tournez, accrochant le coude opposé à l'extérieur du genou. Pressez fermement les paumes ensemble pour approfondir la rotation de la colonne thoracique tout en maintenant le squat profond. Cette posture combine la brûlure aux jambes d'Utkatasana avec une torsion spinale puissante qui détoxifie et renforce."
        ),
        durationSeconds: 40,
        difficulty: .intermediate,
        category: .spine,
        position: .standing,
        imageName: "pose.power.revolvedchair",
        voiceCueText: LocalizedString(
            en: "Twist into Revolved Chair. Hook your elbow, press your palms, keep sinking low. Breathe into the twist.",
            fr: "Tournez en chaise en torsion. Accrochez le coude, pressez les paumes, continuez à descendre. Respirez dans la torsion."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep hands at heart center without hooking the elbow for a gentler twist",
                 "Place the bottom hand on a block for support"],
            fr: ["Gardez les mains au centre du coeur sans accrocher le coude pour une torsion plus douce",
                 "Placez la main du bas sur un bloc pour du soutien"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Spinal disc issues", "Knee injury"],
            fr: ["Problèmes de disques vertébraux", "Blessure au genou"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the spine, exhale to rotate deeper",
            fr: "Inspirez pour allonger la colonne, expirez pour tourner plus profond"
        ),
        isFree: false
    )

    public static let crowPose = Pose(
        id: "power-crow",
        name: LocalizedString(
            en: "Crow Pose",
            fr: "Posture du corbeau"
        ),
        description: LocalizedString(
            en: "Plant your hands shoulder-width apart, spread your fingers wide, and set your knees high on the backs of your upper arms. Shift your weight forward until your feet lift off the ground, engaging your core powerfully to stay balanced. Bakasana is a foundational arm balance that demands wrist strength, core control, and fearless forward momentum.",
            fr: "Plantez les mains à la largeur des épaules, écartez les doigts et placez les genoux haut sur l'arrière des bras. Transférez le poids vers l'avant jusqu'à ce que les pieds décollent du sol, en engageant puissamment le tronc pour rester en équilibre. Bakasana est un équilibre sur les bras fondamental qui exige la force des poignets, le contrôle du tronc et un élan vers l'avant sans peur."
        ),
        durationSeconds: 30,
        difficulty: .advanced,
        category: .arms,
        position: .inversion,
        imageName: "pose.power.crow",
        voiceCueText: LocalizedString(
            en: "Shift forward into Crow Pose. Squeeze your knees into your arms, round your upper back, gaze forward. Trust your strength.",
            fr: "Transférez vers l'avant en posture du corbeau. Serrez les genoux dans les bras, arrondissez le haut du dos, regardez vers l'avant. Faites confiance à votre force."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a block under your feet to reduce the distance to lift off",
                 "Set a cushion in front of you for confidence — fear of falling forward is normal"],
            fr: ["Placez un bloc sous les pieds pour réduire la distance de décollage",
                 "Mettez un coussin devant vous pour la confiance — la peur de tomber vers l'avant est normale"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Wrist injury or carpal tunnel", "Shoulder injury", "Pregnancy"],
            fr: ["Blessure au poignet ou canal carpien", "Blessure à l'épaule", "Grossesse"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to lift off, then steady breath — do not hold your breath",
            fr: "Expirez pour décoller, puis respiration régulière — ne retenez pas le souffle"
        ),
        isFree: false
    )

    public static let sideCrow = Pose(
        id: "power-side-crow",
        name: LocalizedString(
            en: "Side Crow",
            fr: "Corbeau latéral"
        ),
        description: LocalizedString(
            en: "From a deep squat with knees together, twist and plant both hands to one side, stacking your outer thigh on one upper arm. Lean forward and lift your feet off the ground, using your obliques and arms to hold this asymmetric arm balance. Parsva Bakasana builds tremendous arm strength and rotational core power.",
            fr: "Depuis un squat profond genoux ensemble, tournez et plantez les deux mains d'un côté, posant la cuisse extérieure sur le bras supérieur. Penchez-vous vers l'avant et soulevez les pieds du sol, en utilisant les obliques et les bras pour maintenir cet équilibre asymétrique. Parsva Bakasana bâtit une force des bras considérable et une puissance de rotation du tronc."
        ),
        durationSeconds: 30,
        difficulty: .advanced,
        category: .arms,
        position: .inversion,
        imageName: "pose.power.sidecrow",
        voiceCueText: LocalizedString(
            en: "Twist and lean into Side Crow. Stack your thigh on your arm, shift forward, and float your feet. Engage your obliques.",
            fr: "Tournez et penchez-vous en corbeau latéral. Posez la cuisse sur le bras, transférez vers l'avant et soulevez les pieds. Engagez les obliques."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep your toes on the ground and just practice the weight shift",
                 "Use a block under your forehead for extra support while learning"],
            fr: ["Gardez les orteils au sol et pratiquez seulement le transfert de poids",
                 "Utilisez un bloc sous le front pour du soutien supplémentaire pendant l'apprentissage"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Wrist or shoulder injury", "Spinal disc herniation"],
            fr: ["Blessure au poignet ou à l'épaule", "Hernie discale"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to twist and lift, maintain steady breath while holding",
            fr: "Expirez pour tourner et soulever, maintenez une respiration régulière en maintien"
        ),
        isFree: false
    )

    public static let flyingPigeon = Pose(
        id: "power-flying-pigeon",
        name: LocalizedString(
            en: "Flying Pigeon",
            fr: "Pigeon volant"
        ),
        description: LocalizedString(
            en: "From standing, cross one ankle over the opposite thigh in a figure-four, plant your hands, and hook your crossed foot around one upper arm. Lean forward, lift your standing foot, and extend the back leg straight behind you. Eka Pada Galavasana is an advanced arm balance requiring hip openness, arm strength, and fearless commitment.",
            fr: "Depuis la position debout, croisez une cheville sur la cuisse opposée en quatre, plantez les mains et accrochez le pied croisé autour du bras. Penchez-vous vers l'avant, soulevez le pied d'appui et étendez la jambe arrière droite derrière vous. Eka Pada Galavasana est un équilibre avancé sur les bras exigeant l'ouverture des hanches, la force des bras et un engagement sans peur."
        ),
        durationSeconds: 30,
        difficulty: .advanced,
        category: .arms,
        position: .inversion,
        imageName: "pose.power.flyingpigeon",
        voiceCueText: LocalizedString(
            en: "Hook your foot, lean forward into Flying Pigeon. Extend your back leg, squeeze your arms, find your balance. This is power.",
            fr: "Accrochez le pied, penchez-vous en pigeon volant. Étendez la jambe arrière, serrez les bras, trouvez votre équilibre. C'est ça, la puissance."
        ),
        modifications: LocalizedStringArray(
            en: ["Stay in the figure-four squat without lifting off — this alone builds great strength",
                 "Use blocks under your hands to gain extra height for liftoff"],
            fr: ["Restez dans le squat en quatre sans décoller — cela seul bâtit une grande force",
                 "Utilisez des blocs sous les mains pour gagner de la hauteur au décollage"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Wrist, shoulder, or hip injury", "Knee ligament issues"],
            fr: ["Blessure au poignet, à l'épaule ou à la hanche", "Problèmes de ligaments du genou"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to shift forward and lift, breathe steadily while holding",
            fr: "Expirez pour transférer vers l'avant et soulever, respirez régulièrement en maintien"
        ),
        isFree: false
    )

    public static let eightAnglePose = Pose(
        id: "power-eight-angle",
        name: LocalizedString(
            en: "Eight-Angle Pose",
            fr: "Posture des huit angles"
        ),
        description: LocalizedString(
            en: "Hook one leg over the same-side arm and cross your ankles, then lean to the side and extend both legs out while balancing on your hands. This dramatic arm balance engages the inner thighs, arms, and core simultaneously. Astavakrasana looks intimidating but rewards practitioners with exceptional arm and oblique strength.",
            fr: "Accrochez une jambe par-dessus le bras du même côté et croisez les chevilles, puis penchez-vous sur le côté et étendez les deux jambes en vous équilibrant sur les mains. Cet équilibre spectaculaire sur les bras engage les adducteurs, les bras et le tronc simultanément. Astavakrasana semble intimidante mais récompense les pratiquants avec une force exceptionnelle des bras et des obliques."
        ),
        durationSeconds: 30,
        difficulty: .advanced,
        category: .arms,
        position: .inversion,
        imageName: "pose.power.eightangle",
        voiceCueText: LocalizedString(
            en: "Cross your ankles, lean to the side, and extend into Eight-Angle Pose. Squeeze your thighs, press into your hands. Hold with fierce focus.",
            fr: "Croisez les chevilles, penchez-vous, étendez en posture des huit angles. Serrez les cuisses, poussez dans les mains. Maintenez avec une concentration féroce."
        ),
        modifications: LocalizedStringArray(
            en: ["Practice the leg hook and ankle cross while seated before adding the arm balance",
                 "Keep your feet closer to your body instead of fully extending the legs"],
            fr: ["Pratiquez l'accrochage de la jambe et le croisement des chevilles assis avant d'ajouter l'équilibre",
                 "Gardez les pieds plus près du corps au lieu d'étendre complètement les jambes"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Wrist, elbow, or shoulder injury", "Hamstring tear"],
            fr: ["Blessure au poignet, au coude ou à l'épaule", "Déchirure des ischio-jambiers"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to extend, inhale to hold — keep breathing through the challenge",
            fr: "Expirez pour étendre, inspirez pour maintenir — continuez à respirer à travers le défi"
        ),
        isFree: false
    )

    public static let headstandPrep = Pose(
        id: "power-headstand-prep",
        name: LocalizedString(
            en: "Headstand Prep",
            fr: "Préparation au poirier"
        ),
        description: LocalizedString(
            en: "Interlace your fingers, place your forearms on the mat, and set the crown of your head lightly on the floor between your hands. Walk your feet in and lift your hips high, building the shoulder and core strength needed for a full Sirsasana. This prep teaches the alignment, core engagement, and confidence essential for safe headstands.",
            fr: "Entrelacez les doigts, placez les avant-bras sur le tapis et posez légèrement le sommet de la tête au sol entre les mains. Avancez les pieds et soulevez les hanches haut, en bâtissant la force des épaules et du tronc nécessaire pour un Sirsasana complet. Cette préparation enseigne l'alignement, l'engagement du tronc et la confiance essentiels pour des poiriers sécuritaires."
        ),
        durationSeconds: 45,
        difficulty: .advanced,
        category: .inversion,
        position: .inversion,
        imageName: "pose.power.headstandprep",
        voiceCueText: LocalizedString(
            en: "Set up for Headstand Prep. Walk your feet in, stack your hips over your shoulders. Press your forearms down, lift through your core.",
            fr: "Préparez le poirier. Avancez les pieds, empilez les hanches au-dessus des épaules. Pressez les avant-bras, soulevez à travers le tronc."
        ),
        modifications: LocalizedStringArray(
            en: ["Practice against a wall for safety and confidence",
                 "Keep both feet on the floor and focus on pressing into your forearms"],
            fr: ["Pratiquez contre un mur pour la sécurité et la confiance",
                 "Gardez les deux pieds au sol et concentrez-vous sur la pression dans les avant-bras"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Neck injury or cervical disc issues", "Uncontrolled high blood pressure", "Glaucoma or detached retina"],
            fr: ["Blessure au cou ou problèmes de disques cervicaux", "Hypertension artérielle non contrôlée", "Glaucome ou décollement de la rétine"]
        ),
        breathingPattern: LocalizedString(
            en: "Calm, steady breath — avoid holding your breath; exhale to engage core deeper",
            fr: "Respiration calme et régulière — évitez de retenir le souffle; expirez pour engager le tronc plus profond"
        ),
        isFree: false
    )

    public static let forearmStandPrep = Pose(
        id: "power-forearm-stand-prep",
        name: LocalizedString(
            en: "Forearm Stand Prep",
            fr: "Préparation à l'équilibre sur les avant-bras"
        ),
        description: LocalizedString(
            en: "From Dolphin Pose, walk your feet as close to your elbows as possible, stacking your hips over your shoulders. Practice small hops or single-leg lifts to build the shoulder stability and core power needed for Pincha Mayurasana. This prep develops the fearless strength and overhead pressing power that full forearm stand demands.",
            fr: "Depuis la posture du dauphin, avancez les pieds le plus près possible des coudes, en empilant les hanches au-dessus des épaules. Pratiquez de petits sauts ou des levers d'une jambe pour bâtir la stabilité des épaules et la puissance du tronc nécessaires pour Pincha Mayurasana. Cette préparation développe la force intrépide et la puissance de poussée au-dessus de la tête qu'exige l'équilibre complet sur les avant-bras."
        ),
        durationSeconds: 45,
        difficulty: .advanced,
        category: .inversion,
        position: .inversion,
        imageName: "pose.power.forearmstandprep",
        voiceCueText: LocalizedString(
            en: "Walk in close for Forearm Stand Prep. Stack your hips, press your forearms firmly. Kick lightly or hold with one leg high.",
            fr: "Avancez près pour la préparation à l'équilibre. Empilez les hanches, pressez les avant-bras fermement. Donnez de petits kicks ou tenez avec une jambe haute."
        ),
        modifications: LocalizedStringArray(
            en: ["Practice at a wall for support",
                 "Stay in Dolphin Pose and just walk your feet in — the shoulder work alone is powerful"],
            fr: ["Pratiquez contre un mur pour du soutien",
                 "Restez en posture du dauphin et avancez seulement les pieds — le travail des épaules seul est puissant"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Shoulder injury or instability", "Neck injury", "Uncontrolled high blood pressure"],
            fr: ["Blessure ou instabilité à l'épaule", "Blessure au cou", "Hypertension artérielle non contrôlée"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to kick or lift, inhale to stabilize — keep breathing throughout",
            fr: "Expirez pour donner un kick ou soulever, inspirez pour stabiliser — continuez à respirer tout au long"
        ),
        isFree: false
    )

    public static let horseStance = Pose(
        id: "power-horse-stance",
        name: LocalizedString(
            en: "Horse Stance",
            fr: "Posture du cheval"
        ),
        description: LocalizedString(
            en: "Stand with feet wide apart, toes pointing forward, and sink into a deep squat with thighs parallel to the ground. Hold your fists at your waist or extend your arms forward, engaging your quads, glutes, and core intensely. This martial arts-inspired isometric hold builds raw lower-body strength and unbreakable mental endurance.",
            fr: "Tenez-vous debout pieds largement écartés, orteils pointant vers l'avant, et descendez dans un squat profond avec les cuisses parallèles au sol. Maintenez les poings à la taille ou étendez les bras vers l'avant, en engageant intensément les quadriceps, les fessiers et le tronc. Ce maintien isométrique inspiré des arts martiaux bâtit une force brute du bas du corps et une endurance mentale inébranlable."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .legs,
        position: .standing,
        imageName: "pose.power.horsestance",
        voiceCueText: LocalizedString(
            en: "Drop into Horse Stance. Thighs parallel, spine tall, core braced. This is where you build your warrior foundation.",
            fr: "Descendez en posture du cheval. Cuisses parallèles, colonne droite, tronc gainé. C'est ici que vous bâtissez votre fondation de guerrier."
        ),
        modifications: LocalizedStringArray(
            en: ["Don't sink as deep — a higher stance still builds strength",
                 "Place hands on thighs for additional support"],
            fr: ["Ne descendez pas aussi bas — une posture plus haute bâtit quand même de la force",
                 "Placez les mains sur les cuisses pour du soutien supplémentaire"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Knee injury", "Hip joint issues"],
            fr: ["Blessure au genou", "Problèmes de l'articulation de la hanche"]
        ),
        breathingPattern: LocalizedString(
            en: "Deep belly breathing — inhale to hold strong, exhale to ground deeper",
            fr: "Respiration abdominale profonde — inspirez pour tenir fort, expirez pour ancrer plus profond"
        ),
        isFree: false
    )

    public static let powerLunge = Pose(
        id: "power-lunge",
        name: LocalizedString(
            en: "Power Lunge",
            fr: "Fente puissante"
        ),
        description: LocalizedString(
            en: "Step into a deep lunge with your front knee bent at 90 degrees and your back leg strong and straight. Reach your arms overhead with power, biceps framing your ears, and press your back heel away. This dynamic lunge builds explosive leg strength, hip flexor flexibility, and full-body activation from fingertips to toes.",
            fr: "Avancez dans une fente profonde avec le genou avant plié à 90 degrés et la jambe arrière forte et droite. Tendez les bras au-dessus de la tête avec puissance, biceps encadrant les oreilles, et poussez le talon arrière. Cette fente dynamique bâtit une force explosive des jambes, la flexibilité des fléchisseurs de la hanche et une activation globale des orteils au bout des doigts."
        ),
        durationSeconds: 40,
        difficulty: .intermediate,
        category: .legs,
        position: .standing,
        imageName: "pose.power.lunge",
        voiceCueText: LocalizedString(
            en: "Step deep into Power Lunge. Front knee over ankle, back leg straight and strong. Reach tall, feel the fire in your legs.",
            fr: "Avancez profondément en fente puissante. Genou avant au-dessus de la cheville, jambe arrière droite et forte. Étirez-vous haut, sentez le feu dans les jambes."
        ),
        modifications: LocalizedStringArray(
            en: ["Lower your back knee to the ground for a supported lunge",
                 "Keep hands on hips to reduce shoulder demand"],
            fr: ["Déposez le genou arrière au sol pour une fente soutenue",
                 "Gardez les mains sur les hanches pour réduire la sollicitation des épaules"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Knee injury", "Acute hip flexor strain"],
            fr: ["Blessure au genou", "Élongation aiguë des fléchisseurs de la hanche"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale arms up, exhale to sink deeper into the lunge",
            fr: "Inspirez bras en haut, expirez pour descendre plus profond dans la fente"
        ),
        isFree: false
    )

    public static let twistedPowerLunge = Pose(
        id: "power-twisted-lunge",
        name: LocalizedString(
            en: "Twisted Power Lunge",
            fr: "Fente puissante en torsion"
        ),
        description: LocalizedString(
            en: "From Power Lunge, bring your palms together and twist, hooking the opposite elbow outside the front knee while maintaining the deep lunge. Press your palms together firmly to leverage the twist through your thoracic spine. This combination builds massive leg strength while wringing out the spine and stoking your internal fire.",
            fr: "Depuis la fente puissante, joignez les paumes et tournez, accrochant le coude opposé à l'extérieur du genou avant tout en maintenant la fente profonde. Pressez les paumes fermement ensemble pour amplifier la torsion de la colonne thoracique. Cette combinaison bâtit une force massive des jambes tout en essorant la colonne et en attisant votre feu intérieur."
        ),
        durationSeconds: 40,
        difficulty: .intermediate,
        category: .spine,
        position: .standing,
        imageName: "pose.power.twistedlunge",
        voiceCueText: LocalizedString(
            en: "Twist deep in your lunge. Hook your elbow, press your palms, keep your back leg fired up. Breathe into the rotation.",
            fr: "Tournez profondément dans votre fente. Accrochez le coude, pressez les paumes, gardez la jambe arrière activée. Respirez dans la rotation."
        ),
        modifications: LocalizedStringArray(
            en: ["Drop the back knee for a supported twisted lunge",
                 "Keep hands at heart center without hooking the elbow"],
            fr: ["Déposez le genou arrière pour une fente en torsion soutenue",
                 "Gardez les mains au centre du coeur sans accrocher le coude"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Spinal disc issues", "Knee injury", "Sacroiliac joint dysfunction"],
            fr: ["Problèmes de disques vertébraux", "Blessure au genou", "Dysfonction de l'articulation sacro-iliaque"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lengthen the spine, exhale to deepen the twist",
            fr: "Inspirez pour allonger la colonne, expirez pour approfondir la torsion"
        ),
        isFree: false
    )

    public static let yogiPushUps = Pose(
        id: "power-yogi-pushups",
        name: LocalizedString(
            en: "Yogi Push-Ups",
            fr: "Pompes de yogi"
        ),
        description: LocalizedString(
            en: "Flow through slow, controlled Chaturanga push-ups — lowering with elbows hugging your ribs to just above the mat, then pressing back up to plank. Keep your body in one straight line throughout, engaging your triceps, chest, and core with each repetition. These controlled reps build pushing strength essential for all arm balances and transitions.",
            fr: "Enchaînez des pompes Chaturanga lentes et contrôlées — en descendant avec les coudes collés aux côtes juste au-dessus du tapis, puis en remontant en planche. Gardez le corps en une ligne droite tout au long, en engageant les triceps, la poitrine et le tronc à chaque répétition. Ces répétitions contrôlées bâtissent la force de poussée essentielle pour tous les équilibres sur les bras et les transitions."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .arms,
        position: .prone,
        imageName: "pose.power.yogipushups",
        voiceCueText: LocalizedString(
            en: "Flow through Yogi Push-Ups. Lower slowly with elbows in, press up with power. Keep your core rock-solid throughout.",
            fr: "Enchaînez les pompes de yogi. Descendez lentement coudes rentrés, remontez avec puissance. Gardez le tronc solide comme le roc."
        ),
        modifications: LocalizedStringArray(
            en: ["Drop to your knees to build strength before full Chaturanga push-ups",
                 "Lower only halfway to reduce intensity while maintaining form"],
            fr: ["Descendez sur les genoux pour bâtir de la force avant les pompes Chaturanga complètes",
                 "Descendez seulement à mi-chemin pour réduire l'intensité en maintenant la forme"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Wrist or shoulder injury", "Rotator cuff issues"],
            fr: ["Blessure au poignet ou à l'épaule", "Problèmes de la coiffe des rotateurs"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale at the top, exhale as you lower, inhale to press back up",
            fr: "Inspirez en haut, expirez en descendant, inspirez en remontant"
        ),
        isFree: false
    )

    public static let coreScissors = Pose(
        id: "power-core-scissors",
        name: LocalizedString(
            en: "Core Scissors",
            fr: "Ciseaux abdominaux"
        ),
        description: LocalizedString(
            en: "Lie on your back, lift your shoulders off the mat, and alternate lowering each leg just above the floor while the other points to the ceiling. Keep your lower back pressed firmly into the mat and your core deeply engaged throughout this dynamic movement. Scissors build powerful lower abdominal strength and hip flexor endurance.",
            fr: "Couchez-vous sur le dos, soulevez les épaules du tapis et alternez la descente de chaque jambe juste au-dessus du sol tandis que l'autre pointe vers le plafond. Gardez le bas du dos pressé fermement dans le tapis et le tronc profondément engagé tout au long de ce mouvement dynamique. Les ciseaux bâtissent une puissante force abdominale basse et l'endurance des fléchisseurs de la hanche."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .core,
        position: .supine,
        imageName: "pose.power.corescissors",
        voiceCueText: LocalizedString(
            en: "Start Core Scissors. Alternate your legs with control, keep your lower back glued to the mat. Feel your lower abs burn.",
            fr: "Commencez les ciseaux abdominaux. Alternez les jambes avec contrôle, gardez le bas du dos collé au tapis. Sentez la brûlure des abdominaux bas."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep your head down on the mat to reduce neck strain",
                 "Bend the knees slightly to reduce intensity on the hip flexors"],
            fr: ["Gardez la tête au sol pour réduire la tension au cou",
                 "Pliez légèrement les genoux pour réduire l'intensité sur les fléchisseurs"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Lower back pain or disc issues", "Pregnancy", "Recent abdominal surgery"],
            fr: ["Douleur au bas du dos ou problèmes discaux", "Grossesse", "Chirurgie abdominale récente"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale as each leg lowers, inhale as it returns — continuous rhythmic breath",
            fr: "Expirez quand chaque jambe descend, inspirez quand elle remonte — respiration rythmique continue"
        ),
        isFree: false
    )

    public static let bicycleCrunches = Pose(
        id: "power-bicycle-crunches",
        name: LocalizedString(
            en: "Bicycle Crunches",
            fr: "Crunchs bicyclette"
        ),
        description: LocalizedString(
            en: "Lie on your back with hands behind your head and alternate bringing each elbow toward the opposite knee in a controlled cycling motion. Extend the non-working leg fully, hovering it just above the mat to maximize oblique and rectus abdominis engagement. This dynamic exercise builds rotational core power and defines the entire midsection.",
            fr: "Couchez-vous sur le dos avec les mains derrière la tête et alternez en amenant chaque coude vers le genou opposé dans un mouvement de pédalage contrôlé. Étendez complètement la jambe libre en la maintenant juste au-dessus du tapis pour maximiser l'engagement des obliques et du grand droit. Cet exercice dynamique bâtit la puissance rotationnelle du tronc et définit toute la ceinture abdominale."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .core,
        position: .supine,
        imageName: "pose.power.bicyclecrunches",
        voiceCueText: LocalizedString(
            en: "Pedal through Bicycle Crunches. Elbow to opposite knee, extend the other leg long. Move with control, not speed.",
            fr: "Pédalez dans les crunchs bicyclette. Coude au genou opposé, étendez l'autre jambe. Bougez avec contrôle, pas avec vitesse."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep both feet on the floor and just rotate your upper body",
                 "Keep the extended leg higher to reduce lower back strain"],
            fr: ["Gardez les deux pieds au sol et tournez seulement le haut du corps",
                 "Gardez la jambe étendue plus haute pour réduire la tension au bas du dos"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Neck injury", "Lower back pain", "Pregnancy"],
            fr: ["Blessure au cou", "Douleur au bas du dos", "Grossesse"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale as you twist to each side, inhale as you transition through center",
            fr: "Expirez en tournant de chaque côté, inspirez en transitionnant par le centre"
        ),
        isFree: false
    )

    public static let supermanPose = Pose(
        id: "power-superman",
        name: LocalizedString(
            en: "Superman Pose",
            fr: "Posture du superman"
        ),
        description: LocalizedString(
            en: "Lie face down and simultaneously lift your arms, chest, and legs off the mat, squeezing your glutes and engaging your entire posterior chain. Reach your fingertips forward and your toes back to create maximum length. Viparita Shalabhasana powerfully strengthens the erector spinae, glutes, and shoulders — the muscles that support a strong, upright posture.",
            fr: "Couchez-vous face au sol et soulevez simultanément les bras, la poitrine et les jambes du tapis, en serrant les fessiers et en engageant toute la chaîne postérieure. Allongez les doigts vers l'avant et les orteils vers l'arrière pour créer un maximum de longueur. Viparita Shalabhasana renforce puissamment les érecteurs du rachis, les fessiers et les épaules — les muscles qui soutiennent une posture forte et droite."
        ),
        durationSeconds: 40,
        difficulty: .intermediate,
        category: .back,
        position: .prone,
        imageName: "pose.power.superman",
        voiceCueText: LocalizedString(
            en: "Lift into Superman. Arms, chest, and legs off the mat. Squeeze your glutes, reach long, feel your back muscles fire.",
            fr: "Montez en superman. Bras, poitrine et jambes décollés du tapis. Serrez les fessiers, allongez-vous, sentez les muscles du dos s'activer."
        ),
        modifications: LocalizedStringArray(
            en: ["Lift only the upper body, keeping legs on the mat",
                 "Alternate lifting opposite arm and leg for a gentler variation"],
            fr: ["Soulevez seulement le haut du corps, en gardant les jambes au sol",
                 "Alternez le lever du bras et de la jambe opposés pour une variation plus douce"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Severe lower back pain", "Spinal stenosis", "Pregnancy"],
            fr: ["Douleur sévère au bas du dos", "Sténose spinale", "Grossesse"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale to lift, hold and breathe steadily, exhale to lower",
            fr: "Inspirez pour soulever, maintenez et respirez régulièrement, expirez pour redescendre"
        ),
        isFree: false
    )

    public static let powerBridge = Pose(
        id: "power-bridge",
        name: LocalizedString(
            en: "Power Bridge",
            fr: "Pont puissant"
        ),
        description: LocalizedString(
            en: "Lie on your back with feet hip-width apart, then press through your heels to drive your hips up dynamically toward the ceiling. Squeeze your glutes at the top, interlace your hands beneath you, and press your shoulders into the mat. This dynamic bridge variation builds glute, hamstring, and chest-opening power with each controlled repetition.",
            fr: "Couchez-vous sur le dos pieds à la largeur des hanches, puis poussez à travers les talons pour monter les hanches dynamiquement vers le plafond. Serrez les fessiers en haut, entrelacez les mains sous vous et pressez les épaules dans le tapis. Cette variation dynamique du pont bâtit la puissance des fessiers, des ischio-jambiers et l'ouverture de la poitrine à chaque répétition contrôlée."
        ),
        durationSeconds: 45,
        difficulty: .intermediate,
        category: .chest,
        position: .supine,
        imageName: "pose.power.bridge",
        voiceCueText: LocalizedString(
            en: "Press up into Power Bridge. Drive through your heels, squeeze your glutes at the top. Lower with control, then rise again.",
            fr: "Montez en pont puissant. Poussez à travers les talons, serrez les fessiers en haut. Redescendez avec contrôle, puis remontez."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a block between your thighs to engage inner thighs and align the knees",
                 "Hold at the top instead of pulsing for a static version"],
            fr: ["Placez un bloc entre les cuisses pour engager les adducteurs et aligner les genoux",
                 "Maintenez en haut au lieu de pulser pour une version statique"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Neck injury", "Severe lower back pain"],
            fr: ["Blessure au cou", "Douleur sévère au bas du dos"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to lift hips, inhale to lower — powerful rhythmic breath",
            fr: "Expirez pour soulever les hanches, inspirez pour descendre — respiration rythmique puissante"
        ),
        isFree: false
    )

    public static let handstandKicks = Pose(
        id: "power-handstand-kicks",
        name: LocalizedString(
            en: "Handstand Kicks",
            fr: "Kicks en appui renversé"
        ),
        description: LocalizedString(
            en: "Place your hands shoulder-width apart a few inches from a wall, kick one leg up at a time to find the wall with your heels, and hold a supported handstand. Engage your core fiercely to maintain a straight line and press the floor away through your palms. This wall-supported practice builds the overhead pressing power, shoulder stability, and confidence needed for a freestanding handstand.",
            fr: "Placez les mains à la largeur des épaules à quelques pouces d'un mur, montez une jambe à la fois pour trouver le mur avec les talons et maintenez un appui renversé soutenu. Engagez le tronc avec intensité pour maintenir une ligne droite et poussez le sol avec les paumes. Cette pratique soutenue par le mur bâtit la puissance de poussée au-dessus de la tête, la stabilité des épaules et la confiance nécessaires pour un appui renversé libre."
        ),
        durationSeconds: 30,
        difficulty: .advanced,
        category: .inversion,
        position: .inversion,
        imageName: "pose.power.handstandkicks",
        voiceCueText: LocalizedString(
            en: "Kick up to the wall for Handstand. Press the floor away, engage your core, stack your hips over your shoulders. Breathe and hold.",
            fr: "Montez au mur pour l'appui renversé. Poussez le sol, engagez le tronc, empilez les hanches au-dessus des épaules. Respirez et maintenez."
        ),
        modifications: LocalizedStringArray(
            en: ["Practice just kicking halfway up without touching the wall to build strength and control",
                 "Try an L-shaped handstand with feet on the wall and body at 90 degrees"],
            fr: ["Pratiquez seulement en montant à mi-chemin sans toucher le mur pour bâtir force et contrôle",
                 "Essayez un appui renversé en L avec les pieds sur le mur et le corps à 90 degrés"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Wrist or shoulder injury", "Uncontrolled high blood pressure", "Neck injury", "Glaucoma"],
            fr: ["Blessure au poignet ou à l'épaule", "Hypertension artérielle non contrôlée", "Blessure au cou", "Glaucome"]
        ),
        breathingPattern: LocalizedString(
            en: "Exhale to kick up, then breathe steadily — never hold your breath while inverted",
            fr: "Expirez pour monter, puis respirez régulièrement — ne retenez jamais le souffle en inversion"
        ),
        isFree: false
    )

    // MARK: - Pose Collection

    public static let powerPoses: [Pose] = [
        powerMountain,
        chairPose,
        powerPlank,
        sidePlank,
        forearmPlank,
        boatPose,
        warriorIIIPowerHold,
        goddessSquat,
        dolphinPose,
        revolvedChair,
        crowPose,
        sideCrow,
        flyingPigeon,
        eightAnglePose,
        headstandPrep,
        forearmStandPrep,
        horseStance,
        powerLunge,
        twistedPowerLunge,
        yogiPushUps,
        coreScissors,
        bicycleCrunches,
        supermanPose,
        powerBridge,
        handstandKicks,
    ]

    // MARK: - Power Yoga Plans

    public static let powerIgnite = WorkoutPlan(
        id: "power-ignite",
        name: LocalizedString(
            en: "Power Ignite",
            fr: "Ignition puissante"
        ),
        description: LocalizedString(
            en: "A fiery 7-minute power sequence using all free poses to build heat, strength, and endurance. Perfect for an energizing warm-up or a quick standalone burn.",
            fr: "Une séquence puissante et enflammée de 7 minutes utilisant toutes les postures gratuites pour bâtir la chaleur, la force et l'endurance. Parfaite comme échauffement énergisant ou comme brûlure rapide en solo."
        ),
        style: .power,
        poses: [
            powerMountain,
            chairPose,
            powerPlank,
            sidePlank,
            forearmPlank,
            boatPose,
            warriorIIIPowerHold,
            goddessSquat,
        ],
        transitionSeconds: 5,
        isFree: true
    )

    public static let fullPowerFlow = WorkoutPlan(
        id: "power-full-flow",
        name: LocalizedString(
            en: "Full Power Flow",
            fr: "Enchaînement pleine puissance"
        ),
        description: LocalizedString(
            en: "An intense 15-minute full-body power flow that builds from standing strength through arm balances to deep core work. This comprehensive session will challenge your endurance, build serious muscle, and leave you drenched in sweat.",
            fr: "Un enchaînement intense de 15 minutes de pleine puissance pour tout le corps, progressant de la force debout aux équilibres sur les bras jusqu'au travail profond du tronc. Cette séance complète mettra votre endurance au défi, bâtira du muscle sérieusement et vous laissera en sueur."
        ),
        style: .power,
        poses: [
            powerMountain,
            chairPose,
            powerPlank,
            yogiPushUps,
            sidePlank,
            dolphinPose,
            warriorIIIPowerHold,
            revolvedChair,
            crowPose,
            powerLunge,
            twistedPowerLunge,
            coreScissors,
            bicycleCrunches,
            supermanPose,
            powerBridge,
            goddessSquat,
        ],
        transitionSeconds: 5,
        isFree: false
    )

    public static let coreCrusher = WorkoutPlan(
        id: "power-core-crusher",
        name: LocalizedString(
            en: "Core Crusher",
            fr: "Broyeur d'abdos"
        ),
        description: LocalizedString(
            en: "A relentless 10-minute core-focused session that hits every angle of your midsection — front, sides, and back. Planks, arm balances, and dynamic floor work combine to forge an unbreakable core.",
            fr: "Une séance impitoyable de 10 minutes axée sur le tronc qui cible chaque angle de la ceinture abdominale — avant, côtés et dos. Planches, équilibres sur les bras et travail dynamique au sol se combinent pour forger un tronc incassable."
        ),
        style: .power,
        poses: [
            powerPlank,
            forearmPlank,
            sidePlank,
            boatPose,
            coreScissors,
            bicycleCrunches,
            supermanPose,
            crowPose,
            sideCrow,
            yogiPushUps,
        ],
        transitionSeconds: 5,
        isFree: false
    )

    public static let powerPlans: [WorkoutPlan] = [
        powerIgnite,
        fullPowerFlow,
        coreCrusher,
    ]
}
