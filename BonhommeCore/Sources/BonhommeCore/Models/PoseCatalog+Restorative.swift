import Foundation

// MARK: - Restorative Yoga Poses & Plans

extension PoseCatalog {

    // MARK: - Restorative Poses (Free)

    public static let supportedChildsPose = Pose(
        id: "restorative-childs-pose",
        name: LocalizedString(
            en: "Supported Child's Pose",
            fr: "Posture de l'enfant supportée"
        ),
        description: LocalizedString(
            en: "Kneel on a soft blanket and place a bolster lengthwise between your thighs. Drape your torso over the bolster, turning your head to one side. Let your arms rest alongside the bolster. The prop fully supports your weight, allowing your back, hips, and shoulders to release completely into gravity.",
            fr: "Agenouillez-vous sur une couverture douce et placez un traversin dans le sens de la longueur entre vos cuisses. Déposez votre torse sur le traversin en tournant la tête d'un côté. Laissez vos bras reposer le long du traversin. L'accessoire supporte entièrement votre poids, permettant à votre dos, vos hanches et vos épaules de se relâcher complètement dans la gravité."
        ),
        durationSeconds: 180,
        difficulty: .beginner,
        category: .relaxation,
        position: .kneeling,
        imageName: "pose.restorative.childspose",
        voiceCueText: LocalizedString(
            en: "Melt into your bolster in Supported Child's Pose. Let every exhale soften you deeper. There is nothing to hold, nothing to fix — just rest.",
            fr: "Fondez-vous dans votre traversin en Posture de l'enfant supportée. Laissez chaque expiration vous adoucir davantage. Il n'y a rien à retenir, rien à corriger — reposez-vous simplement."
        ),
        modifications: LocalizedStringArray(
            en: ["Place an extra blanket between your calves and thighs if your knees are sensitive",
                 "Stack two bolsters for more height if folding forward is uncomfortable"],
            fr: ["Placez une couverture supplémentaire entre vos mollets et vos cuisses si vos genoux sont sensibles",
                 "Empilez deux traversins pour plus de hauteur si la flexion avant est inconfortable"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a recent knee injury or surgery",
                 "Not recommended during late pregnancy without modification"],
            fr: ["Évitez en cas de blessure ou chirurgie récente au genou",
                 "Non recommandée en fin de grossesse sans modification"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow diaphragmatic breathing — inhale 4 counts, exhale 6 counts, feeling the belly press gently into the bolster",
            fr: "Respiration diaphragmatique lente — inspirez 4 temps, expirez 6 temps, en sentant le ventre presser doucement contre le traversin"
        ),
        isFree: true
    )

    public static let supportedBridge = Pose(
        id: "restorative-supported-bridge",
        name: LocalizedString(
            en: "Supported Bridge",
            fr: "Pont supporté"
        ),
        description: LocalizedString(
            en: "Lie on your back with knees bent and feet hip-width apart. Lift your hips and slide a yoga block or bolster under your sacrum. Let your full weight rest on the prop. Arms can rest by your sides with palms up, inviting openness through the chest and front body.",
            fr: "Allongez-vous sur le dos, genoux pliés et pieds à la largeur des hanches. Soulevez vos hanches et glissez un bloc de yoga ou un traversin sous votre sacrum. Laissez tout votre poids reposer sur l'accessoire. Les bras peuvent reposer le long du corps, paumes vers le haut, invitant l'ouverture à travers la poitrine et l'avant du corps."
        ),
        durationSeconds: 150,
        difficulty: .beginner,
        category: .back,
        position: .supine,
        imageName: "pose.restorative.supportedbridge",
        voiceCueText: LocalizedString(
            en: "Rest in Supported Bridge. Let the block hold you — release all effort from your legs, hips, and back. Feel a gentle opening through your heart center.",
            fr: "Reposez-vous en Pont supporté. Laissez le bloc vous soutenir — relâchez tout effort de vos jambes, hanches et dos. Sentez une douce ouverture à travers le centre du cœur."
        ),
        modifications: LocalizedStringArray(
            en: ["Use the lowest block height if you feel any strain in the lower back",
                 "Place a folded blanket on top of the block for extra cushioning under the sacrum"],
            fr: ["Utilisez la hauteur la plus basse du bloc si vous ressentez une tension dans le bas du dos",
                 "Placez une couverture pliée sur le bloc pour un coussin supplémentaire sous le sacrum"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have acute lower back pain or sacroiliac joint dysfunction",
                 "Not recommended during the second or third trimester of pregnancy"],
            fr: ["Évitez en cas de douleur aiguë au bas du dos ou de dysfonction de l'articulation sacro-iliaque",
                 "Non recommandée durant le deuxième ou troisième trimestre de grossesse"]
        ),
        breathingPattern: LocalizedString(
            en: "Relaxed belly breathing — inhale 4 counts, exhale 5 counts, letting the chest expand freely",
            fr: "Respiration abdominale détendue — inspirez 4 temps, expirez 5 temps, en laissant la poitrine s'ouvrir librement"
        ),
        isFree: true
    )

    public static let legsUpTheWall = Pose(
        id: "restorative-legs-up-wall",
        name: LocalizedString(
            en: "Legs Up the Wall",
            fr: "Jambes au mur"
        ),
        description: LocalizedString(
            en: "Sit sideways next to a wall, then swing your legs up as you lower your back to the floor. Your sitting bones can be right at the wall or a few inches away. Place a folded blanket or bolster under your hips for extra support. Rest your arms out to the sides in a comfortable position, palms up.",
            fr: "Assoyez-vous de côté près d'un mur, puis balancez vos jambes vers le haut en abaissant votre dos au sol. Vos ischions peuvent être directement au mur ou à quelques pouces de distance. Placez une couverture pliée ou un traversin sous vos hanches pour un soutien supplémentaire. Laissez vos bras reposer sur les côtés dans une position confortable, paumes vers le haut."
        ),
        durationSeconds: 180,
        difficulty: .beginner,
        category: .legs,
        position: .inversion,
        imageName: "pose.restorative.legsupwall",
        voiceCueText: LocalizedString(
            en: "Let your legs rest against the wall. Feel the gentle reversal of blood flow calming your entire nervous system. Soften your face, jaw, and shoulders.",
            fr: "Laissez vos jambes reposer contre le mur. Sentez le doux retour du flux sanguin calmer tout votre système nerveux. Détendez votre visage, votre mâchoire et vos épaules."
        ),
        modifications: LocalizedStringArray(
            en: ["Bend your knees slightly or place the soles of your feet together in a butterfly shape if your hamstrings are tight",
                 "Move your hips a few inches from the wall if you feel tingling in your legs"],
            fr: ["Pliez légèrement les genoux ou placez la plante des pieds ensemble en forme de papillon si vos ischio-jambiers sont tendus",
                 "Éloignez vos hanches de quelques pouces du mur si vous ressentez des picotements dans les jambes"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have uncontrolled high blood pressure or glaucoma",
                 "Not recommended if you have a hiatal hernia"],
            fr: ["Évitez en cas d'hypertension non contrôlée ou de glaucome",
                 "Non recommandée en cas de hernie hiatale"]
        ),
        breathingPattern: LocalizedString(
            en: "Natural effortless breathing — allow the breath to find its own rhythm, softening with each exhale",
            fr: "Respiration naturelle sans effort — laissez le souffle trouver son propre rythme, en vous adoucissant à chaque expiration"
        ),
        isFree: true
    )

    public static let supportedFish = Pose(
        id: "restorative-supported-fish",
        name: LocalizedString(
            en: "Supported Fish",
            fr: "Poisson supporté"
        ),
        description: LocalizedString(
            en: "Place a bolster lengthwise behind you and lie back so it supports your entire spine from mid-back to head. Let your arms fall open to the sides, palms facing up. Allow your chest to open wide and your shoulders to drape toward the floor. A blanket under your head provides gentle neck support.",
            fr: "Placez un traversin dans le sens de la longueur derrière vous et allongez-vous de sorte qu'il supporte toute votre colonne du milieu du dos jusqu'à la tête. Laissez vos bras tomber ouverts sur les côtés, paumes vers le haut. Permettez à votre poitrine de s'ouvrir largement et à vos épaules de descendre vers le sol. Une couverture sous la tête offre un soutien doux pour le cou."
        ),
        durationSeconds: 150,
        difficulty: .beginner,
        category: .chest,
        position: .supine,
        imageName: "pose.restorative.supportedfish",
        voiceCueText: LocalizedString(
            en: "Open your heart in Supported Fish. Let the bolster cradle your spine as your chest expands effortlessly. Breathe into the spaciousness across your collarbones.",
            fr: "Ouvrez votre cœur en Poisson supporté. Laissez le traversin bercer votre colonne pendant que votre poitrine s'ouvre sans effort. Respirez dans l'espace qui s'ouvre à travers vos clavicules."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a rolled blanket instead of a bolster for a gentler opening",
                 "Place blocks under your forearms if your shoulders feel strained"],
            fr: ["Utilisez une couverture roulée plutôt qu'un traversin pour une ouverture plus douce",
                 "Placez des blocs sous vos avant-bras si vos épaules semblent tendues"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a neck injury or cervical disc issues",
                 "Not recommended if you have a recent shoulder dislocation"],
            fr: ["Évitez en cas de blessure au cou ou de problèmes de disques cervicaux",
                 "Non recommandée en cas de luxation récente de l'épaule"]
        ),
        breathingPattern: LocalizedString(
            en: "Expansive chest breathing — inhale 5 counts filling the ribcage wide, exhale 6 counts softening completely",
            fr: "Respiration thoracique expansive — inspirez 5 temps en remplissant la cage thoracique, expirez 6 temps en vous relâchant complètement"
        ),
        isFree: true
    )

    public static let supportedReclinedButterfly = Pose(
        id: "restorative-reclined-butterfly",
        name: LocalizedString(
            en: "Supported Reclined Butterfly",
            fr: "Papillon couché supporté"
        ),
        description: LocalizedString(
            en: "Lie back on a bolster placed lengthwise behind you. Bring the soles of your feet together and let your knees fall open, supported by blocks or rolled blankets underneath each thigh. Rest your arms comfortably at your sides. This deeply opening pose releases the inner thighs, groin, and hip flexors while calming the nervous system.",
            fr: "Allongez-vous sur un traversin placé dans le sens de la longueur derrière vous. Joignez la plante de vos pieds et laissez vos genoux s'ouvrir, soutenus par des blocs ou des couvertures roulées sous chaque cuisse. Laissez vos bras reposer confortablement le long du corps. Cette posture profondément ouvrante relâche l'intérieur des cuisses, l'aine et les fléchisseurs des hanches tout en calmant le système nerveux."
        ),
        durationSeconds: 180,
        difficulty: .beginner,
        category: .hips,
        position: .supine,
        imageName: "pose.restorative.reclinedbutterfly",
        voiceCueText: LocalizedString(
            en: "Let your knees fall open like butterfly wings in Supported Reclined Butterfly. Feel the props holding you — there is no effort needed. Surrender to stillness.",
            fr: "Laissez vos genoux s'ouvrir comme des ailes de papillon en Papillon couché supporté. Sentez les accessoires vous soutenir — aucun effort n'est nécessaire. Abandonnez-vous à l'immobilité."
        ),
        modifications: LocalizedStringArray(
            en: ["Use higher blocks or more blankets under the thighs if you feel pulling in the groin",
                 "Place a strap around your feet and hips to hold the legs in position without effort"],
            fr: ["Utilisez des blocs plus hauts ou plus de couvertures sous les cuisses si vous sentez un tiraillement à l'aine",
                 "Placez une sangle autour de vos pieds et hanches pour maintenir les jambes en position sans effort"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a groin or inner thigh strain",
                 "Use extra support if you have SI joint instability"],
            fr: ["Évitez en cas d'élongation de l'aine ou de l'intérieur des cuisses",
                 "Utilisez un soutien supplémentaire en cas d'instabilité de l'articulation sacro-iliaque"]
        ),
        breathingPattern: LocalizedString(
            en: "Deep belly breathing — inhale 4 counts, exhale 6 counts, visualizing tension melting from the hips",
            fr: "Respiration abdominale profonde — inspirez 4 temps, expirez 6 temps, en visualisant la tension fondre des hanches"
        ),
        isFree: true
    )

    public static let supportedSavasana = Pose(
        id: "restorative-supported-savasana",
        name: LocalizedString(
            en: "Supported Savasana",
            fr: "Savasana supporté"
        ),
        description: LocalizedString(
            en: "Lie on your back with a bolster under your knees to release the lower back. Place a folded blanket under your head and a light blanket over your body for warmth. Let your feet fall open naturally and rest your arms a few inches from your sides, palms up. Allow your entire body to be fully supported and completely still.",
            fr: "Allongez-vous sur le dos avec un traversin sous les genoux pour relâcher le bas du dos. Placez une couverture pliée sous votre tête et une couverture légère sur votre corps pour la chaleur. Laissez vos pieds s'ouvrir naturellement et reposez vos bras à quelques pouces du corps, paumes vers le haut. Permettez à tout votre corps d'être pleinement supporté et complètement immobile."
        ),
        durationSeconds: 300,
        difficulty: .beginner,
        category: .relaxation,
        position: .supine,
        imageName: "pose.restorative.supportedsavasana",
        voiceCueText: LocalizedString(
            en: "Settle into Supported Savasana. Feel the earth holding you. Release every muscle, every thought. You are safe, you are held, you are at peace.",
            fr: "Installez-vous en Savasana supporté. Sentez la terre vous porter. Relâchez chaque muscle, chaque pensée. Vous êtes en sécurité, vous êtes soutenu, vous êtes en paix."
        ),
        modifications: LocalizedStringArray(
            en: ["Place an eye pillow over your eyes to deepen relaxation and block light",
                 "Add a rolled blanket under your ankles for extra comfort"],
            fr: ["Placez un coussin pour les yeux sur vos yeux pour approfondir la relaxation et bloquer la lumière",
                 "Ajoutez une couverture roulée sous vos chevilles pour plus de confort"]
        ),
        contraindications: LocalizedStringArray(
            en: ["If lying flat causes discomfort, elevate the head and chest with extra blankets",
                 "Avoid lying flat if you are in the third trimester of pregnancy — use side-lying position instead"],
            fr: ["Si la position allongée cause de l'inconfort, surélevez la tête et la poitrine avec des couvertures supplémentaires",
                 "Évitez de vous allonger à plat au troisième trimestre de grossesse — utilisez la position sur le côté"]
        ),
        breathingPattern: LocalizedString(
            en: "Completely natural breathing — release all control, let the body breathe itself",
            fr: "Respiration complètement naturelle — relâchez tout contrôle, laissez le corps respirer de lui-même"
        ),
        isFree: true
    )

    public static let supportedSideLyingTwist = Pose(
        id: "restorative-side-lying-twist",
        name: LocalizedString(
            en: "Supported Side-Lying Twist",
            fr: "Torsion couchée sur le côté supportée"
        ),
        description: LocalizedString(
            en: "Sit with your right hip against the short end of a bolster. Gently twist your torso toward the bolster and lower yourself down, resting your chest and cheek on it. Your knees remain stacked and bent. The bolster provides full support so there is no muscular effort in the twist. This gentle rotation soothes the spine and calms the nervous system.",
            fr: "Assoyez-vous avec votre hanche droite contre le bout court d'un traversin. Tournez doucement votre torse vers le traversin et abaissez-vous, en reposant votre poitrine et votre joue dessus. Vos genoux restent empilés et pliés. Le traversin offre un soutien complet pour qu'il n'y ait aucun effort musculaire dans la torsion. Cette rotation douce apaise la colonne et calme le système nerveux."
        ),
        durationSeconds: 150,
        difficulty: .beginner,
        category: .spine,
        position: .supine,
        imageName: "pose.restorative.sidelyingtwist",
        voiceCueText: LocalizedString(
            en: "Rest into your Supported Side-Lying Twist. Let the bolster carry the weight of your torso. With each exhale, soften a little deeper into the rotation. Remember to do both sides.",
            fr: "Reposez-vous dans votre Torsion couchée supportée. Laissez le traversin porter le poids de votre torse. À chaque expiration, adoucissez-vous un peu plus dans la rotation. N'oubliez pas de faire les deux côtés."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a blanket between your knees for comfort",
                 "Add an extra blanket on top of the bolster to increase the height if the twist feels too deep"],
            fr: ["Placez une couverture entre vos genoux pour le confort",
                 "Ajoutez une couverture supplémentaire sur le traversin pour augmenter la hauteur si la torsion semble trop profonde"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a herniated disc or acute spinal injury",
                 "Use caution if you have sacroiliac joint dysfunction"],
            fr: ["Évitez en cas de hernie discale ou de blessure aiguë à la colonne vertébrale",
                 "Soyez prudent en cas de dysfonction de l'articulation sacro-iliaque"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow rhythmic breathing — inhale 4 counts, exhale 6 counts, feeling the ribcage gently expand and contract",
            fr: "Respiration rythmique lente — inspirez 4 temps, expirez 6 temps, en sentant la cage thoracique s'ouvrir et se refermer doucement"
        ),
        isFree: true
    )

    // MARK: - Restorative Poses (Premium)

    public static let supportedForwardFold = Pose(
        id: "restorative-supported-forward-fold",
        name: LocalizedString(
            en: "Supported Forward Fold",
            fr: "Flexion avant supportée"
        ),
        description: LocalizedString(
            en: "Sit with your legs extended and a bolster or stack of blankets on top of your thighs. Fold forward from the hips and rest your torso, arms, and head on the props. The height of the support allows you to release without strain, gently stretching the back body while calming the mind.",
            fr: "Assoyez-vous avec les jambes allongées et un traversin ou une pile de couvertures sur vos cuisses. Penchez-vous vers l'avant à partir des hanches et reposez votre torse, vos bras et votre tête sur les accessoires. La hauteur du support vous permet de vous relâcher sans tension, étirant doucement l'arrière du corps tout en calmant l'esprit."
        ),
        durationSeconds: 150,
        difficulty: .beginner,
        category: .back,
        position: .seated,
        imageName: "pose.restorative.supportedforwardfold",
        voiceCueText: LocalizedString(
            en: "Drape yourself over the bolster in Supported Forward Fold. Let gravity do the work. With each breath, feel the back body lengthen and soften.",
            fr: "Drapez-vous sur le traversin en Flexion avant supportée. Laissez la gravité faire le travail. À chaque respiration, sentez l'arrière du corps s'allonger et s'adoucir."
        ),
        modifications: LocalizedStringArray(
            en: ["Bend your knees generously and place a rolled blanket beneath them",
                 "Stack more blankets higher on your lap so you don't have to fold as deeply"],
            fr: ["Pliez généreusement vos genoux et placez une couverture roulée dessous",
                 "Empilez plus de couvertures plus haut sur vos cuisses pour ne pas avoir à plier aussi profondément"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a hamstring tear or acute lower back injury",
                 "Use caution with sciatica — keep knees bent"],
            fr: ["Évitez en cas de déchirure des ischio-jambiers ou de blessure aiguë au bas du dos",
                 "Soyez prudent avec la sciatique — gardez les genoux pliés"]
        ),
        breathingPattern: LocalizedString(
            en: "Posterior breathing — inhale 4 counts directing breath into the back ribs, exhale 6 counts softening the belly",
            fr: "Respiration postérieure — inspirez 4 temps en dirigeant le souffle vers les côtes arrière, expirez 6 temps en adoucissant le ventre"
        ),
        isFree: false
    )

    public static let supportedPigeon = Pose(
        id: "restorative-supported-pigeon",
        name: LocalizedString(
            en: "Supported Pigeon",
            fr: "Pigeon supporté"
        ),
        description: LocalizedString(
            en: "From a tabletop position, bring your right knee forward and place it behind your right wrist. Slide a bolster under your right hip and thigh, then lower your torso onto the bolster. The prop eliminates the need to hold yourself up, allowing the hip to release deeply over time. Rest your forehead on your stacked hands or the bolster.",
            fr: "À partir de la position à quatre pattes, amenez votre genou droit vers l'avant et placez-le derrière votre poignet droit. Glissez un traversin sous votre hanche et cuisse droites, puis abaissez votre torse sur le traversin. L'accessoire élimine le besoin de vous soutenir, permettant à la hanche de se relâcher profondément avec le temps. Reposez votre front sur vos mains empilées ou le traversin."
        ),
        durationSeconds: 150,
        difficulty: .beginner,
        category: .hips,
        position: .kneeling,
        imageName: "pose.restorative.supportedpigeon",
        voiceCueText: LocalizedString(
            en: "Sink into Supported Pigeon. Let the bolster hold your hip as it gradually opens. Be patient — the body releases in its own time. Breathe slowly and stay present.",
            fr: "Enfoncez-vous dans le Pigeon supporté. Laissez le traversin soutenir votre hanche pendant qu'elle s'ouvre graduellement. Soyez patient — le corps se relâche à son propre rythme. Respirez lentement et restez présent."
        ),
        modifications: LocalizedStringArray(
            en: ["Add a blanket under the bolster for extra height if the hip feels strained",
                 "Place a blanket under the back knee for cushioning"],
            fr: ["Ajoutez une couverture sous le traversin pour plus de hauteur si la hanche semble tendue",
                 "Placez une couverture sous le genou arrière pour l'amortissement"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a knee injury on the front leg side",
                 "Not recommended if you have severe sciatica on the affected side"],
            fr: ["Évitez en cas de blessure au genou du côté de la jambe avant",
                 "Non recommandée en cas de sciatique sévère du côté affecté"]
        ),
        breathingPattern: LocalizedString(
            en: "Deep slow breathing — inhale 4 counts, exhale 7 counts, directing breath to the outer hip",
            fr: "Respiration lente et profonde — inspirez 4 temps, expirez 7 temps, en dirigeant le souffle vers l'extérieur de la hanche"
        ),
        isFree: false
    )

    public static let supportedHeartOpener = Pose(
        id: "restorative-heart-opener",
        name: LocalizedString(
            en: "Supported Heart Opener",
            fr: "Ouverture du cœur supportée"
        ),
        description: LocalizedString(
            en: "Place a block on its medium height horizontally between your shoulder blades and a second block under your head. Lie back over the blocks with your arms draped open to the sides. Your legs can be extended or with knees bent and feet flat. This gentle backbend opens the chest, stretches the intercostal muscles, and encourages deep breathing.",
            fr: "Placez un bloc sur sa hauteur moyenne horizontalement entre vos omoplates et un deuxième bloc sous votre tête. Allongez-vous par-dessus les blocs avec vos bras ouverts sur les côtés. Vos jambes peuvent être allongées ou avec les genoux pliés et les pieds à plat. Cette cambrure douce ouvre la poitrine, étire les muscles intercostaux et encourage la respiration profonde."
        ),
        durationSeconds: 150,
        difficulty: .beginner,
        category: .chest,
        position: .supine,
        imageName: "pose.restorative.heartopener",
        voiceCueText: LocalizedString(
            en: "Open your heart center over the blocks. Feel the gentle expansion across your chest with each inhale. Let your shoulders melt toward the floor.",
            fr: "Ouvrez votre centre du cœur par-dessus les blocs. Sentez la douce expansion à travers votre poitrine à chaque inspiration. Laissez vos épaules fondre vers le sol."
        ),
        modifications: LocalizedStringArray(
            en: ["Use the lowest block height or a rolled blanket if the stretch feels too intense",
                 "Place a bolster lengthwise instead of blocks for a more gradual opening"],
            fr: ["Utilisez la hauteur la plus basse du bloc ou une couverture roulée si l'étirement semble trop intense",
                 "Placez un traversin dans le sens de la longueur plutôt que des blocs pour une ouverture plus graduelle"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a recent rib fracture or thoracic spine injury",
                 "Not recommended if you have severe kyphosis without professional guidance"],
            fr: ["Évitez en cas de fracture récente des côtes ou de blessure à la colonne thoracique",
                 "Non recommandée en cas de cyphose sévère sans supervision professionnelle"]
        ),
        breathingPattern: LocalizedString(
            en: "Three-part breath — inhale into belly, ribs, then upper chest over 6 counts; exhale slowly for 6 counts",
            fr: "Respiration en trois parties — inspirez dans le ventre, les côtes, puis le haut de la poitrine en 6 temps; expirez lentement en 6 temps"
        ),
        isFree: false
    )

    public static let supportedShoulderstand = Pose(
        id: "restorative-supported-shoulderstand",
        name: LocalizedString(
            en: "Supported Shoulderstand",
            fr: "Chandelle supportée"
        ),
        description: LocalizedString(
            en: "Stack two to three folded blankets and lie with your shoulders on the blankets and your head on the floor. Walk your feet toward your hips, press into the floor, and lift your hips, placing your hands on your lower back for support. Extend your legs upward. The blanket elevation protects the neck and allows a comfortable hold. This gentle inversion calms the mind and improves circulation.",
            fr: "Empilez deux à trois couvertures pliées et allongez-vous avec vos épaules sur les couvertures et votre tête au sol. Rapprochez vos pieds de vos hanches, poussez dans le sol et soulevez vos hanches en plaçant vos mains sur le bas du dos pour le soutien. Étendez vos jambes vers le haut. L'élévation des couvertures protège le cou et permet un maintien confortable. Cette inversion douce calme l'esprit et améliore la circulation."
        ),
        durationSeconds: 120,
        difficulty: .intermediate,
        category: .inversion,
        position: .inversion,
        imageName: "pose.restorative.supportedshoulderstand",
        voiceCueText: LocalizedString(
            en: "Rise into Supported Shoulderstand. Let the blankets support your shoulders and neck. Breathe steadily and find calm in the stillness of the inversion.",
            fr: "Élevez-vous en Chandelle supportée. Laissez les couvertures soutenir vos épaules et votre cou. Respirez régulièrement et trouvez le calme dans l'immobilité de l'inversion."
        ),
        modifications: LocalizedStringArray(
            en: ["Keep your legs at a 45-degree angle instead of fully vertical if balance is challenging",
                 "Use a wall behind you to rest your feet against for added stability"],
            fr: ["Gardez vos jambes à un angle de 45 degrés plutôt que complètement verticales si l'équilibre est difficile",
                 "Utilisez un mur derrière vous pour appuyer vos pieds pour plus de stabilité"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have neck injuries, cervical disc problems, or uncontrolled high blood pressure",
                 "Not recommended during menstruation or if you have glaucoma or detached retina"],
            fr: ["Évitez en cas de blessures au cou, de problèmes de disques cervicaux ou d'hypertension non contrôlée",
                 "Non recommandée durant les menstruations ou en cas de glaucome ou de décollement de rétine"]
        ),
        breathingPattern: LocalizedString(
            en: "Calm steady breathing — inhale 4 counts, exhale 4 counts, keeping the breath smooth and even",
            fr: "Respiration calme et régulière — inspirez 4 temps, expirez 4 temps, en gardant le souffle doux et uniforme"
        ),
        isFree: false
    )

    public static let crocodilePose = Pose(
        id: "restorative-crocodile",
        name: LocalizedString(
            en: "Crocodile Pose",
            fr: "Posture du crocodile"
        ),
        description: LocalizedString(
            en: "Lie face down and stack your forearms, resting your forehead on your hands. Let your legs turn out naturally with toes pointing outward. A bolster or blanket under your chest and belly provides gentle support. This prone position encourages diaphragmatic breathing as the belly presses into the floor, making it an excellent pose for calming anxiety and restoring the breath.",
            fr: "Allongez-vous face contre terre et empilez vos avant-bras, en reposant votre front sur vos mains. Laissez vos jambes tourner naturellement vers l'extérieur avec les orteils pointant vers l'extérieur. Un traversin ou une couverture sous votre poitrine et votre ventre offre un soutien doux. Cette position sur le ventre encourage la respiration diaphragmatique car le ventre presse contre le sol, en faisant une excellente posture pour calmer l'anxiété et restaurer le souffle."
        ),
        durationSeconds: 150,
        difficulty: .beginner,
        category: .relaxation,
        position: .prone,
        imageName: "pose.restorative.crocodile",
        voiceCueText: LocalizedString(
            en: "Rest in Crocodile Pose. Feel your belly pressing into the floor with each inhale — this is pure diaphragmatic breathing. Let the ground hold you completely.",
            fr: "Reposez-vous en Posture du crocodile. Sentez votre ventre presser contre le sol à chaque inspiration — c'est une respiration diaphragmatique pure. Laissez le sol vous porter complètement."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a thin blanket under your forehead if the floor feels hard",
                 "Slide a blanket under your ankles to reduce pressure on the tops of your feet"],
            fr: ["Placez une couverture mince sous votre front si le sol semble dur",
                 "Glissez une couverture sous vos chevilles pour réduire la pression sur le dessus de vos pieds"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if lying prone causes lower back pain",
                 "Not recommended during pregnancy"],
            fr: ["Évitez si la position sur le ventre cause des douleurs au bas du dos",
                 "Non recommandée durant la grossesse"]
        ),
        breathingPattern: LocalizedString(
            en: "Diaphragmatic belly breathing — inhale 4 counts feeling belly expand against the floor, exhale 6 counts letting everything soften",
            fr: "Respiration diaphragmatique abdominale — inspirez 4 temps en sentant le ventre s'élargir contre le sol, expirez 6 temps en laissant tout s'adoucir"
        ),
        isFree: false
    )

    public static let supportedWideLeggedForwardFold = Pose(
        id: "restorative-wide-legged-forward-fold",
        name: LocalizedString(
            en: "Supported Wide-Legged Forward Fold",
            fr: "Flexion avant jambes écartées supportée"
        ),
        description: LocalizedString(
            en: "Sit with your legs spread wide and a bolster or stack of blankets placed lengthwise in front of you. Hinge from the hips and fold forward, draping your torso over the props. Rest your arms alongside the bolster and turn your head to one side. The support allows you to release deeply into the inner thighs and groin without strain.",
            fr: "Assoyez-vous avec les jambes écartées et un traversin ou une pile de couvertures placé dans le sens de la longueur devant vous. Penchez-vous à partir des hanches et pliez-vous vers l'avant, drapant votre torse sur les accessoires. Reposez vos bras le long du traversin et tournez la tête d'un côté. Le support vous permet de vous relâcher profondément dans l'intérieur des cuisses et l'aine sans tension."
        ),
        durationSeconds: 150,
        difficulty: .beginner,
        category: .hips,
        position: .seated,
        imageName: "pose.restorative.wideleggedforwardfold",
        voiceCueText: LocalizedString(
            en: "Fold forward between your wide legs and rest on the bolster. Let the inner thighs soften with each exhale. Turn your head halfway through to balance both sides of the neck.",
            fr: "Penchez-vous vers l'avant entre vos jambes écartées et reposez-vous sur le traversin. Laissez l'intérieur des cuisses s'adoucir à chaque expiration. Tournez la tête à mi-parcours pour équilibrer les deux côtés du cou."
        ),
        modifications: LocalizedStringArray(
            en: ["Stack extra blankets higher if you cannot comfortably reach the bolster",
                 "Bend your knees slightly and place rolled blankets beneath them for hamstring relief"],
            fr: ["Empilez des couvertures supplémentaires plus haut si vous ne pouvez pas atteindre le traversin confortablement",
                 "Pliez légèrement les genoux et placez des couvertures roulées dessous pour soulager les ischio-jambiers"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have an inner thigh or groin strain",
                 "Use caution if you have lower back disc issues — keep the spine long"],
            fr: ["Évitez en cas d'élongation de l'intérieur des cuisses ou de l'aine",
                 "Soyez prudent en cas de problèmes de disques lombaires — gardez la colonne allongée"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow wave breathing — inhale 4 counts, exhale 7 counts, imagining tension washing out of the inner legs",
            fr: "Respiration en vagues lentes — inspirez 4 temps, expirez 7 temps, en imaginant la tension se dissiper de l'intérieur des jambes"
        ),
        isFree: false
    )

    public static let bolsterBackbend = Pose(
        id: "restorative-bolster-backbend",
        name: LocalizedString(
            en: "Bolster Backbend",
            fr: "Cambrure sur traversin"
        ),
        description: LocalizedString(
            en: "Place a bolster horizontally across your mat. Sit just in front of it and lie back so the bolster supports your mid to upper back. Let your head and neck extend beyond the bolster, supported by a folded blanket. Open your arms wide to the sides. Legs can be extended or with knees bent. This passive backbend opens the entire front body without muscular effort.",
            fr: "Placez un traversin horizontalement sur votre tapis. Assoyez-vous juste devant et allongez-vous de sorte que le traversin supporte le milieu et le haut de votre dos. Laissez votre tête et votre cou s'étendre au-delà du traversin, soutenus par une couverture pliée. Ouvrez vos bras largement sur les côtés. Les jambes peuvent être allongées ou avec les genoux pliés. Cette cambrure passive ouvre tout l'avant du corps sans effort musculaire."
        ),
        durationSeconds: 150,
        difficulty: .beginner,
        category: .chest,
        position: .supine,
        imageName: "pose.restorative.bolsterbackbend",
        voiceCueText: LocalizedString(
            en: "Drape yourself over the bolster and open your entire front body. Feel your chest and belly expand with each breath. There is nothing to do — just receive the opening.",
            fr: "Drapez-vous sur le traversin et ouvrez tout l'avant de votre corps. Sentez votre poitrine et votre ventre s'ouvrir à chaque respiration. Il n'y a rien à faire — recevez simplement l'ouverture."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a rolled blanket instead of a bolster for a gentler curve",
                 "Place blocks under your hands if your arms feel unsupported when open"],
            fr: ["Utilisez une couverture roulée plutôt qu'un traversin pour une courbe plus douce",
                 "Placez des blocs sous vos mains si vos bras semblent non soutenus lorsqu'ils sont ouverts"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have spondylolisthesis or acute spinal stenosis",
                 "Not recommended if you have a recent abdominal surgery"],
            fr: ["Évitez en cas de spondylolisthésis ou de sténose spinale aiguë",
                 "Non recommandée en cas de chirurgie abdominale récente"]
        ),
        breathingPattern: LocalizedString(
            en: "Full yogic breath — inhale 5 counts filling belly, ribs, and chest; exhale 6 counts releasing from top to bottom",
            fr: "Respiration yogique complète — inspirez 5 temps en remplissant le ventre, les côtes et la poitrine; expirez 6 temps en relâchant du haut vers le bas"
        ),
        isFree: false
    )

    public static let sideLyingSavasana = Pose(
        id: "restorative-side-lying-savasana",
        name: LocalizedString(
            en: "Side-Lying Savasana",
            fr: "Savasana sur le côté"
        ),
        description: LocalizedString(
            en: "Lie on your left side with a bolster between your knees and another supporting your top arm. Place a folded blanket under your head. Curl slightly into a fetal position, allowing your body to feel completely safe and held. This variation of Savasana is ideal for anyone who finds lying on their back uncomfortable, including pregnant practitioners.",
            fr: "Allongez-vous sur votre côté gauche avec un traversin entre vos genoux et un autre supportant votre bras du dessus. Placez une couverture pliée sous votre tête. Recourbez-vous légèrement en position fœtale, permettant à votre corps de se sentir complètement en sécurité et soutenu. Cette variante du Savasana est idéale pour quiconque trouve la position sur le dos inconfortable, incluant les pratiquantes enceintes."
        ),
        durationSeconds: 300,
        difficulty: .beginner,
        category: .relaxation,
        position: .supine,
        imageName: "pose.restorative.sidelyingsavasana",
        voiceCueText: LocalizedString(
            en: "Curl into Side-Lying Savasana. Feel the bolsters cradling you on all sides. Let go of the day, let go of effort. Simply be.",
            fr: "Recourbez-vous en Savasana sur le côté. Sentez les traversins vous bercer de tous les côtés. Laissez aller la journée, laissez aller l'effort. Soyez simplement."
        ),
        modifications: LocalizedStringArray(
            en: ["Hug a bolster to your chest for an extra sense of comfort and security",
                 "Place a blanket behind your back for additional support and warmth"],
            fr: ["Serrez un traversin contre votre poitrine pour un sentiment supplémentaire de confort et de sécurité",
                 "Placez une couverture derrière votre dos pour un soutien et une chaleur supplémentaires"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid lying on the right side if you have acid reflux — left side is preferred",
                 "Use extra padding if you have shoulder pain on the down side"],
            fr: ["Évitez de vous allonger sur le côté droit en cas de reflux acide — le côté gauche est préférable",
                 "Utilisez un rembourrage supplémentaire en cas de douleur à l'épaule du côté vers le sol"]
        ),
        breathingPattern: LocalizedString(
            en: "Soft natural breathing — no counting, no control, just witnessing the breath come and go",
            fr: "Respiration douce et naturelle — pas de comptage, pas de contrôle, observez simplement le souffle aller et venir"
        ),
        isFree: false
    )

    public static let supportedSeatedForwardFold = Pose(
        id: "restorative-seated-forward-fold",
        name: LocalizedString(
            en: "Supported Seated Forward Fold",
            fr: "Flexion avant assise supportée"
        ),
        description: LocalizedString(
            en: "Sit on the edge of a folded blanket with your legs extended. Place a bolster on top of your legs and fold forward, resting your forehead and arms on the bolster. The blanket tilts your pelvis forward, and the bolster provides complete support for your upper body. This deeply calming pose soothes the nervous system and gently stretches the entire posterior chain.",
            fr: "Assoyez-vous sur le bord d'une couverture pliée avec les jambes allongées. Placez un traversin sur vos jambes et penchez-vous vers l'avant, en reposant votre front et vos bras sur le traversin. La couverture incline votre bassin vers l'avant, et le traversin offre un support complet pour le haut du corps. Cette posture profondément calmante apaise le système nerveux et étire doucement toute la chaîne postérieure."
        ),
        durationSeconds: 150,
        difficulty: .beginner,
        category: .back,
        position: .seated,
        imageName: "pose.restorative.seatedforwardfold",
        voiceCueText: LocalizedString(
            en: "Fold forward and rest on your bolster. Let your spine round gently — there is no need to keep it straight. Feel the back body lengthen with patient, slow breaths.",
            fr: "Penchez-vous vers l'avant et reposez-vous sur votre traversin. Laissez votre colonne s'arrondir doucement — il n'est pas nécessaire de la garder droite. Sentez l'arrière du corps s'allonger avec des respirations patientes et lentes."
        ),
        modifications: LocalizedStringArray(
            en: ["Sit on a higher blanket stack to increase pelvic tilt and reduce hamstring pull",
                 "Place a strap around your feet to gently guide yourself forward without forcing"],
            fr: ["Assoyez-vous sur une pile de couvertures plus haute pour augmenter l'inclinaison du bassin et réduire la tension des ischio-jambiers",
                 "Placez une sangle autour de vos pieds pour vous guider doucement vers l'avant sans forcer"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a herniated lumbar disc in the acute phase",
                 "Use caution with osteoporosis — avoid deep spinal flexion"],
            fr: ["Évitez en cas de hernie discale lombaire en phase aiguë",
                 "Soyez prudent avec l'ostéoporose — évitez la flexion profonde de la colonne"]
        ),
        breathingPattern: LocalizedString(
            en: "Back body breathing — inhale 4 counts expanding the back ribs, exhale 6 counts releasing forward a fraction more",
            fr: "Respiration dans le dos — inspirez 4 temps en ouvrant les côtes arrière, expirez 6 temps en relâchant vers l'avant un tout petit peu plus"
        ),
        isFree: false
    )

    public static let supportedSuptaBaddhaKonasana = Pose(
        id: "restorative-supta-baddha-konasana",
        name: LocalizedString(
            en: "Supported Supta Baddha Konasana",
            fr: "Supta Baddha Konasana supporté"
        ),
        description: LocalizedString(
            en: "Place a bolster lengthwise behind you with a blanket at the far end for head support. Sit in front of the bolster, bring the soles of your feet together, and recline back onto it. Support each knee with a block or rolled blanket. A strap looped around your hips and feet keeps the legs in place without effort. This deeply restorative pose opens the hips, chest, and front body simultaneously.",
            fr: "Placez un traversin dans le sens de la longueur derrière vous avec une couverture au bout pour soutenir la tête. Assoyez-vous devant le traversin, joignez la plante de vos pieds et allongez-vous vers l'arrière dessus. Supportez chaque genou avec un bloc ou une couverture roulée. Une sangle bouclée autour de vos hanches et pieds maintient les jambes en place sans effort. Cette posture profondément restaurative ouvre les hanches, la poitrine et l'avant du corps simultanément."
        ),
        durationSeconds: 180,
        difficulty: .beginner,
        category: .hips,
        position: .supine,
        imageName: "pose.restorative.suptabaddhakonasana",
        voiceCueText: LocalizedString(
            en: "Recline into Supported Supta Baddha Konasana. Every part of you is held by props. Let the hips open naturally — never force. Breathe into the space that appears.",
            fr: "Allongez-vous en Supta Baddha Konasana supporté. Chaque partie de vous est soutenue par les accessoires. Laissez les hanches s'ouvrir naturellement — ne forcez jamais. Respirez dans l'espace qui apparaît."
        ),
        modifications: LocalizedStringArray(
            en: ["Move your feet further from your body to reduce the intensity of the hip opening",
                 "Use higher supports under the knees if you feel any strain in the groin or inner thighs"],
            fr: ["Éloignez vos pieds de votre corps pour réduire l'intensité de l'ouverture des hanches",
                 "Utilisez des supports plus hauts sous les genoux si vous ressentez une tension à l'aine ou à l'intérieur des cuisses"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a pubic symphysis dysfunction or SPD",
                 "Use extra knee support if you have knee ligament injuries"],
            fr: ["Évitez en cas de dysfonction de la symphyse pubienne ou SPD",
                 "Utilisez un soutien supplémentaire aux genoux en cas de blessures ligamentaires au genou"]
        ),
        breathingPattern: LocalizedString(
            en: "Pelvic floor breathing — inhale 4 counts gently expanding the pelvic floor, exhale 6 counts releasing completely",
            fr: "Respiration du plancher pelvien — inspirez 4 temps en ouvrant doucement le plancher pelvien, expirez 6 temps en relâchant complètement"
        ),
        isFree: false
    )

    public static let restorativeMountainBrook = Pose(
        id: "restorative-mountain-brook",
        name: LocalizedString(
            en: "Restorative Mountain Brook",
            fr: "Ruisseau de montagne restauratif"
        ),
        description: LocalizedString(
            en: "Lie on your back and place a rolled blanket under your upper back, a bolster under your knees, and a small rolled towel under your neck. This creates a gentle undulating shape through the body, like a mountain stream flowing over rocks. The multiple support points open the chest, release the lower back, and cradle the cervical spine, creating a deeply restorative experience.",
            fr: "Allongez-vous sur le dos et placez une couverture roulée sous le haut de votre dos, un traversin sous vos genoux et une petite serviette roulée sous votre cou. Cela crée une forme ondulante douce à travers le corps, comme un ruisseau de montagne coulant sur des roches. Les multiples points de support ouvrent la poitrine, relâchent le bas du dos et bercent la colonne cervicale, créant une expérience profondément restaurative."
        ),
        durationSeconds: 180,
        difficulty: .beginner,
        category: .spine,
        position: .supine,
        imageName: "pose.restorative.mountainbrook",
        voiceCueText: LocalizedString(
            en: "Flow into Mountain Brook. Feel the gentle wave shape through your body, supported at every curve. Let your breath be like a stream — steady, effortless, and continuous.",
            fr: "Coulez dans le Ruisseau de montagne. Sentez la douce forme d'onde à travers votre corps, supporté à chaque courbe. Laissez votre souffle être comme un ruisseau — régulier, sans effort et continu."
        ),
        modifications: LocalizedStringArray(
            en: ["Adjust the height of each prop until every part of your body feels completely supported",
                 "Add a blanket over your body for warmth if the room is cool"],
            fr: ["Ajustez la hauteur de chaque accessoire jusqu'à ce que chaque partie de votre corps soit complètement supportée",
                 "Ajoutez une couverture sur votre corps pour la chaleur si la pièce est fraîche"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Remove the upper back roll if you have thoracic spine issues or rib injuries",
                 "Avoid if lying on your back causes dizziness or discomfort"],
            fr: ["Retirez le rouleau du haut du dos en cas de problèmes de colonne thoracique ou de blessures aux côtes",
                 "Évitez si la position sur le dos cause des étourdissements ou de l'inconfort"]
        ),
        breathingPattern: LocalizedString(
            en: "Flowing breath — inhale 5 counts like a wave rising, exhale 5 counts like a wave receding, no pauses between",
            fr: "Souffle fluide — inspirez 5 temps comme une vague qui monte, expirez 5 temps comme une vague qui recule, sans pauses entre"
        ),
        isFree: false
    )

    public static let eyePillowSavasana = Pose(
        id: "restorative-eye-pillow-savasana",
        name: LocalizedString(
            en: "Eye Pillow Savasana",
            fr: "Savasana avec coussin pour les yeux"
        ),
        description: LocalizedString(
            en: "Lie in a traditional Savasana position with a bolster under your knees and a blanket over your body. Place a weighted eye pillow over your closed eyes. The gentle pressure on the eyelids stimulates the vagus nerve, activating the parasympathetic nervous system and deepening relaxation. Allow the weight to draw your awareness inward and quiet the mind.",
            fr: "Allongez-vous en position de Savasana traditionnelle avec un traversin sous vos genoux et une couverture sur votre corps. Placez un coussin pour les yeux lesté sur vos yeux fermés. La pression douce sur les paupières stimule le nerf vague, activant le système nerveux parasympathique et approfondissant la relaxation. Permettez au poids de diriger votre conscience vers l'intérieur et de calmer l'esprit."
        ),
        durationSeconds: 300,
        difficulty: .beginner,
        category: .relaxation,
        position: .supine,
        imageName: "pose.restorative.eyepillowsavasana",
        voiceCueText: LocalizedString(
            en: "Rest in Eye Pillow Savasana. Feel the gentle weight on your eyes drawing you inward. Let the darkness behind your eyelids become a refuge of deep peace.",
            fr: "Reposez-vous en Savasana avec coussin pour les yeux. Sentez le poids doux sur vos yeux vous attirer vers l'intérieur. Laissez l'obscurité derrière vos paupières devenir un refuge de paix profonde."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a folded washcloth instead of an eye pillow if you don't have one",
                 "Place a small rolled towel under your neck for cervical support"],
            fr: ["Utilisez une débarbouillette pliée au lieu d'un coussin pour les yeux si vous n'en avez pas",
                 "Placez une petite serviette roulée sous votre cou pour un soutien cervical"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid the eye pillow if you have an eye infection or recent eye surgery",
                 "Do not use if you feel claustrophobic with weight on your eyes"],
            fr: ["Évitez le coussin pour les yeux en cas d'infection oculaire ou de chirurgie oculaire récente",
                 "N'utilisez pas si vous vous sentez claustrophobe avec un poids sur les yeux"]
        ),
        breathingPattern: LocalizedString(
            en: "Effortless breathing — release all technique, all counting; simply witness the breath as it naturally flows",
            fr: "Respiration sans effort — relâchez toute technique, tout comptage; observez simplement le souffle tel qu'il coule naturellement"
        ),
        isFree: false
    )

    public static let constructiveRest = Pose(
        id: "restorative-constructive-rest",
        name: LocalizedString(
            en: "Constructive Rest",
            fr: "Repos constructif"
        ),
        description: LocalizedString(
            en: "Lie on your back with your knees bent and feet flat on the floor, hip-width apart. Let your knees lean against each other so no muscular effort is required to hold them. Place your hands on your belly or rest your arms by your sides. A blanket under your head keeps the neck in a neutral position. This foundational restorative pose releases the psoas muscle and is used in somatic therapy to reset the nervous system.",
            fr: "Allongez-vous sur le dos avec les genoux pliés et les pieds à plat au sol, à la largeur des hanches. Laissez vos genoux s'appuyer l'un contre l'autre pour qu'aucun effort musculaire ne soit nécessaire pour les maintenir. Placez vos mains sur votre ventre ou reposez vos bras le long du corps. Une couverture sous la tête maintient le cou en position neutre. Cette posture restaurative fondamentale relâche le muscle psoas et est utilisée en thérapie somatique pour réinitialiser le système nerveux."
        ),
        durationSeconds: 180,
        difficulty: .beginner,
        category: .relaxation,
        position: .supine,
        imageName: "pose.restorative.constructiverest",
        voiceCueText: LocalizedString(
            en: "Settle into Constructive Rest. Let your knees lean together and release all holding in the hip flexors. Feel the deep muscles of the pelvis begin to let go. This is profound rest.",
            fr: "Installez-vous en Repos constructif. Laissez vos genoux s'appuyer ensemble et relâchez toute tension dans les fléchisseurs de hanches. Sentez les muscles profonds du bassin commencer à lâcher prise. C'est un repos profond."
        ),
        modifications: LocalizedStringArray(
            en: ["Tie a yoga strap loosely around your thighs so your legs are held without any effort",
                 "Place your feet wider than hip-width and let the knees fall in if that feels more comfortable"],
            fr: ["Attachez une sangle de yoga lâchement autour de vos cuisses pour que vos jambes soient maintenues sans effort",
                 "Placez vos pieds plus larges que la largeur des hanches et laissez les genoux tomber vers l'intérieur si c'est plus confortable"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Adjust foot placement if you feel any knee discomfort",
                 "Use a higher head support if you have acid reflux when lying flat"],
            fr: ["Ajustez le placement des pieds si vous ressentez un inconfort au genou",
                 "Utilisez un support plus haut pour la tête en cas de reflux acide lorsque vous êtes allongé à plat"]
        ),
        breathingPattern: LocalizedString(
            en: "Hands-on-belly breathing — inhale 4 counts feeling your hands rise, exhale 6 counts feeling them fall, grounding into the present moment",
            fr: "Respiration mains sur le ventre — inspirez 4 temps en sentant vos mains monter, expirez 6 temps en les sentant descendre, en vous ancrant dans le moment présent"
        ),
        isFree: false
    )

    // MARK: - Pose Collection

    public static let restorativePoses: [Pose] = [
        supportedChildsPose,
        supportedBridge,
        legsUpTheWall,
        supportedFish,
        supportedReclinedButterfly,
        supportedSavasana,
        supportedSideLyingTwist,
        supportedForwardFold,
        supportedPigeon,
        supportedHeartOpener,
        supportedShoulderstand,
        crocodilePose,
        supportedWideLeggedForwardFold,
        bolsterBackbend,
        sideLyingSavasana,
        supportedSeatedForwardFold,
        supportedSuptaBaddhaKonasana,
        restorativeMountainBrook,
        eyePillowSavasana,
        constructiveRest,
    ]

    // MARK: - Restorative Plans

    public static let stressReliefRecovery = WorkoutPlan(
        id: "restorative-stress-relief",
        name: LocalizedString(
            en: "Stress Relief & Recovery",
            fr: "Soulagement du stress et récupération"
        ),
        description: LocalizedString(
            en: "A gentle 25-minute restorative sequence using the seven foundational prop-supported poses. Designed to activate the parasympathetic nervous system, release muscular tension, and guide you into deep relaxation. Perfect for stress recovery, sleep preparation, or rest days.",
            fr: "Une séquence restaurative douce de 25 minutes utilisant les sept postures fondamentales supportées par des accessoires. Conçue pour activer le système nerveux parasympathique, relâcher la tension musculaire et vous guider vers une relaxation profonde. Parfaite pour la récupération du stress, la préparation au sommeil ou les journées de repos."
        ),
        style: .restorative,
        poses: [
            supportedChildsPose,
            supportedBridge,
            legsUpTheWall,
            supportedFish,
            supportedReclinedButterfly,
            supportedSideLyingTwist,
            supportedSavasana,
        ],
        transitionSeconds: 15,
        isFree: true
    )

    public static let deepRestorativeSurrender = WorkoutPlan(
        id: "restorative-deep-surrender",
        name: LocalizedString(
            en: "Deep Restorative Surrender",
            fr: "Abandon restauratif profond"
        ),
        description: LocalizedString(
            en: "An immersive 40-minute deep restorative journey through twelve prop-supported poses. This extended practice systematically releases tension from every region of the body, calms the nervous system at the deepest level, and cultivates a profound state of stillness and inner peace. Ideal for experienced practitioners seeking complete restoration.",
            fr: "Un voyage restauratif profond et immersif de 40 minutes à travers douze postures supportées par des accessoires. Cette pratique prolongée relâche systématiquement la tension de chaque région du corps, calme le système nerveux au niveau le plus profond et cultive un état profond d'immobilité et de paix intérieure. Idéale pour les pratiquants expérimentés recherchant une restauration complète."
        ),
        style: .restorative,
        poses: [
            supportedChildsPose,
            supportedBridge,
            supportedPigeon,
            supportedHeartOpener,
            supportedWideLeggedForwardFold,
            restorativeMountainBrook,
            supportedSuptaBaddhaKonasana,
            bolsterBackbend,
            supportedSideLyingTwist,
            crocodilePose,
            constructiveRest,
            eyePillowSavasana,
        ],
        transitionSeconds: 15,
        isFree: false
    )

    public static let restorativePlans: [WorkoutPlan] = [
        stressReliefRecovery,
        deepRestorativeSurrender,
    ]
}
