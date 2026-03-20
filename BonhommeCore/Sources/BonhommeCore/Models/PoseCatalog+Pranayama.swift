import Foundation

// MARK: - Pranayama & Meditation Poses & Plans

extension PoseCatalog {

    // MARK: - Breathing Poses (Free)

    public static let diaphragmaticBreathing = Pose(
        id: "pranayama-diaphragmatic",
        name: LocalizedString(
            en: "Diaphragmatic Breathing",
            fr: "Respiration diaphragmatique"
        ),
        description: LocalizedString(
            en: "Sit comfortably with one hand on your chest and the other on your belly. Breathe in slowly through the nose for 4 counts, feeling the belly expand outward against your hand while the chest stays relatively still. Exhale through the nose for 6 counts, feeling the belly draw gently inward. This engages the diaphragm fully, activating the parasympathetic nervous system and promoting deep relaxation.",
            fr: "Assoyez-vous confortablement avec une main sur la poitrine et l'autre sur le ventre. Inspirez lentement par le nez pendant 4 temps en sentant le ventre se gonfler contre votre main tandis que la poitrine reste relativement immobile. Expirez par le nez pendant 6 temps en sentant le ventre se rétracter doucement vers l'intérieur. Ceci engage pleinement le diaphragme, active le système nerveux parasympathique et favorise une relaxation profonde."
        ),
        durationSeconds: 90,
        difficulty: .beginner,
        category: .breathing,
        position: .seated,
        imageName: "pose.pranayama.diaphragmatic",
        voiceCueText: LocalizedString(
            en: "Place one hand on your belly. Breathe in through the nose, feel the belly rise. Exhale slowly, feel it fall. Let the breath be smooth and effortless.",
            fr: "Placez une main sur votre ventre. Inspirez par le nez, sentez le ventre se soulever. Expirez lentement, sentez-le redescendre. Laissez le souffle être doux et sans effort."
        ),
        modifications: LocalizedStringArray(
            en: ["Lie on your back with knees bent if seated position is uncomfortable",
                 "Place a light book on your belly to provide tactile feedback for the breath"],
            fr: ["Allongez-vous sur le dos avec les genoux fléchis si la position assise est inconfortable",
                 "Placez un livre léger sur le ventre pour fournir un retour tactile du souffle"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid forcing the breath if you experience dizziness; return to natural breathing"],
            fr: ["Évitez de forcer le souffle si vous ressentez des étourdissements; revenez à une respiration naturelle"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale through the nose for 4 counts, expanding the belly. Exhale through the nose for 6 counts, drawing the belly inward. No pause between breaths.",
            fr: "Inspirez par le nez pendant 4 temps en gonflant le ventre. Expirez par le nez pendant 6 temps en rentrant le ventre. Aucune pause entre les respirations."
        ),
        isFree: true
    )

    public static let ujjayiBreath = Pose(
        id: "pranayama-ujjayi",
        name: LocalizedString(
            en: "Ujjayi / Ocean Breath",
            fr: "Ujjayi / Souffle de l'océan"
        ),
        description: LocalizedString(
            en: "Sit tall with the spine long. Slightly constrict the back of your throat — as if fogging a mirror — while keeping the mouth closed. Inhale through the nose for 4 counts, producing a soft, audible hissing sound in the throat. Exhale through the nose for 4 counts with the same gentle constriction. The sound should resemble ocean waves. This technique builds internal heat and focuses the mind.",
            fr: "Assoyez-vous droit, la colonne allongée. Contractez légèrement l'arrière de la gorge — comme pour embuer un miroir — tout en gardant la bouche fermée. Inspirez par le nez pendant 4 temps en produisant un son doux et audible dans la gorge. Expirez par le nez pendant 4 temps avec la même légère constriction. Le son devrait ressembler aux vagues de l'océan. Cette technique génère une chaleur interne et concentre l'esprit."
        ),
        durationSeconds: 90,
        difficulty: .beginner,
        category: .breathing,
        position: .seated,
        imageName: "pose.pranayama.ujjayi",
        voiceCueText: LocalizedString(
            en: "Gently constrict the back of your throat. Breathe in through the nose, hear the soft ocean sound. Exhale with the same whisper. Keep the rhythm steady.",
            fr: "Contractez doucement l'arrière de la gorge. Inspirez par le nez, écoutez le doux son de l'océan. Expirez avec le même murmure. Gardez un rythme régulier."
        ),
        modifications: LocalizedStringArray(
            en: ["Practice first with the mouth open, exhaling a 'haaa' sound, then close the mouth while maintaining the constriction",
                 "Reduce the constriction if you feel strain in the throat; the sound should be gentle, not forced"],
            fr: ["Pratiquez d'abord bouche ouverte en expirant un son « haaa », puis fermez la bouche en maintenant la constriction",
                 "Réduisez la constriction si vous sentez une tension dans la gorge; le son doit être doux, pas forcé"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have a sore throat or active respiratory infection"],
            fr: ["Évitez en cas de mal de gorge ou d'infection respiratoire active"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale through the nose for 4 counts with slight throat constriction. Exhale through the nose for 4 counts maintaining the same constriction. Equal ratio breathing.",
            fr: "Inspirez par le nez pendant 4 temps avec une légère constriction de la gorge. Expirez par le nez pendant 4 temps en maintenant la même constriction. Respiration à ratio égal."
        ),
        isFree: true
    )

    public static let nadiShodhana = Pose(
        id: "pranayama-nadi-shodhana",
        name: LocalizedString(
            en: "Nadi Shodhana / Alternate Nostril",
            fr: "Nadi Shodhana / Respiration alternée"
        ),
        description: LocalizedString(
            en: "Sit comfortably and bring your right hand into Vishnu Mudra by folding the index and middle fingers to the palm. Close the right nostril with your thumb and inhale through the left nostril for 4 counts. Close the left nostril with the ring finger, open the right, and exhale for 4 counts. Inhale through the right for 4 counts, then close the right, open the left, and exhale for 4 counts. This completes one round. This practice balances the left and right hemispheres of the brain and calms the nervous system.",
            fr: "Assoyez-vous confortablement et amenez la main droite en Vishnu Mudra en repliant l'index et le majeur vers la paume. Fermez la narine droite avec le pouce et inspirez par la narine gauche pendant 4 temps. Fermez la narine gauche avec l'annulaire, ouvrez la droite et expirez pendant 4 temps. Inspirez par la droite pendant 4 temps, puis fermez la droite, ouvrez la gauche et expirez pendant 4 temps. Ceci complète un cycle. Cette pratique équilibre les hémisphères gauche et droit du cerveau et apaise le système nerveux."
        ),
        durationSeconds: 120,
        difficulty: .beginner,
        category: .breathing,
        position: .seated,
        imageName: "pose.pranayama.nadishodhana",
        voiceCueText: LocalizedString(
            en: "Close the right nostril, inhale left. Switch — exhale right. Inhale right, switch — exhale left. Keep each breath smooth and equal.",
            fr: "Fermez la narine droite, inspirez à gauche. Changez — expirez à droite. Inspirez à droite, changez — expirez à gauche. Gardez chaque souffle doux et régulier."
        ),
        modifications: LocalizedStringArray(
            en: ["Rest your right elbow on a cushion or bolster if your arm fatigues quickly",
                 "Visualize the breath alternating nostrils instead of using the hand if you have limited arm mobility"],
            fr: ["Appuyez le coude droit sur un coussin ou un traversin si votre bras se fatigue rapidement",
                 "Visualisez le souffle alternant entre les narines au lieu d'utiliser la main si vous avez une mobilité limitée du bras"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have severe nasal congestion; try gentle breathing until passages clear",
                 "Do not practice during an active nosebleed"],
            fr: ["Évitez en cas de congestion nasale sévère; essayez une respiration douce jusqu'à ce que les voies se dégagent",
                 "Ne pratiquez pas pendant un saignement de nez actif"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale left nostril 4 counts, close left and exhale right 4 counts. Inhale right 4 counts, close right and exhale left 4 counts. One full round = 16 counts.",
            fr: "Inspirez narine gauche 4 temps, fermez la gauche et expirez narine droite 4 temps. Inspirez narine droite 4 temps, fermez la droite et expirez narine gauche 4 temps. Un cycle complet = 16 temps."
        ),
        isFree: true
    )

    public static let kapalabhati = Pose(
        id: "pranayama-kapalabhati",
        name: LocalizedString(
            en: "Kapalabhati / Skull Shining",
            fr: "Kapalabhati / Crâne brillant"
        ),
        description: LocalizedString(
            en: "Sit tall with hands on the knees. Take a deep inhale to prepare. Begin short, forceful exhales through the nose by sharply contracting the lower belly, followed by passive inhales where the belly relaxes and air flows in naturally. Start with 20 pumps per round at a pace of roughly one per second, then take 2–3 natural recovery breaths before the next round. This kriya energizes the body, clears the sinuses, and strengthens the abdominal muscles.",
            fr: "Assoyez-vous droit, mains sur les genoux. Prenez une grande inspiration pour vous préparer. Commencez de courtes expirations puissantes par le nez en contractant brusquement le bas du ventre, suivies d'inspirations passives où le ventre se relâche et l'air entre naturellement. Débutez avec 20 pompages par cycle à un rythme d'environ un par seconde, puis prenez 2 à 3 respirations naturelles de récupération avant le cycle suivant. Ce kriya énergise le corps, dégage les sinus et renforce les muscles abdominaux."
        ),
        durationSeconds: 90,
        difficulty: .intermediate,
        category: .breathing,
        position: .seated,
        imageName: "pose.pranayama.kapalabhati",
        voiceCueText: LocalizedString(
            en: "Sharp exhale through the nose, belly snaps in. Let the inhale happen on its own. Keep the chest still, only the belly moves. Pump, pump, pump.",
            fr: "Expiration vive par le nez, le ventre se contracte. Laissez l'inspiration se faire toute seule. Gardez la poitrine immobile, seul le ventre bouge. Pompez, pompez, pompez."
        ),
        modifications: LocalizedStringArray(
            en: ["Reduce to 10 pumps per round and slow the pace if you feel lightheaded",
                 "Place a hand on the belly to feel the rhythmic contraction and ensure the chest stays stable"],
            fr: ["Réduisez à 10 pompages par cycle et ralentissez le rythme si vous vous sentez étourdi",
                 "Placez une main sur le ventre pour sentir la contraction rythmique et vous assurer que la poitrine reste stable"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid during pregnancy or if you have high blood pressure, heart disease, or epilepsy",
                 "Do not practice on a full stomach; wait at least 2 hours after eating"],
            fr: ["Évitez pendant la grossesse ou en cas d'hypertension, de maladie cardiaque ou d'épilepsie",
                 "Ne pratiquez pas l'estomac plein; attendez au moins 2 heures après avoir mangé"]
        ),
        breathingPattern: LocalizedString(
            en: "Forceful exhale through the nose (belly contracts sharply), passive inhale (belly relaxes). 20 pumps per round at ~1 per second, then 2–3 natural breaths to recover.",
            fr: "Expiration puissante par le nez (le ventre se contracte vivement), inspiration passive (le ventre se relâche). 20 pompages par cycle à ~1 par seconde, puis 2 à 3 respirations naturelles pour récupérer."
        ),
        isFree: true
    )

    public static let bhramariBreath = Pose(
        id: "pranayama-bhramari",
        name: LocalizedString(
            en: "Bhramari / Bee Breath",
            fr: "Bhramari / Souffle de l'abeille"
        ),
        description: LocalizedString(
            en: "Sit comfortably and close your eyes. Gently place your index fingers on the tragus cartilage of each ear (or lightly press the ear flaps closed). Inhale deeply through the nose for 4 counts. On the exhale, keep the mouth closed and produce a steady, medium-pitched humming sound like a bee for 6–8 counts. Feel the vibration resonate through the skull. The humming activates the vagus nerve, lowers blood pressure, and profoundly calms the mind.",
            fr: "Assoyez-vous confortablement et fermez les yeux. Placez doucement vos index sur le tragus de chaque oreille (ou appuyez légèrement sur les lobes pour fermer les oreilles). Inspirez profondément par le nez pendant 4 temps. À l'expiration, gardez la bouche fermée et produisez un bourdonnement continu et de tonalité moyenne comme une abeille pendant 6 à 8 temps. Sentez la vibration résonner à travers le crâne. Le bourdonnement active le nerf vague, abaisse la pression artérielle et calme profondément l'esprit."
        ),
        durationSeconds: 90,
        difficulty: .beginner,
        category: .breathing,
        position: .seated,
        imageName: "pose.pranayama.bhramari",
        voiceCueText: LocalizedString(
            en: "Close your ears gently. Inhale deeply. Now hum on the exhale — a steady, resonant bee sound. Feel the vibration fill your head. Let all thoughts dissolve into the hum.",
            fr: "Fermez doucement vos oreilles. Inspirez profondément. Maintenant, bourdonnez à l'expiration — un son d'abeille constant et résonnant. Sentez la vibration remplir votre tête. Laissez toutes les pensées se dissoudre dans le bourdonnement."
        ),
        modifications: LocalizedStringArray(
            en: ["Simply close the eyes and hum without covering the ears if the hand position is uncomfortable",
                 "Vary the pitch of the hum to find the vibration that feels most soothing to you"],
            fr: ["Fermez simplement les yeux et bourdonnez sans couvrir les oreilles si la position des mains est inconfortable",
                 "Variez la tonalité du bourdonnement pour trouver la vibration qui vous apaise le plus"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid if you have an active ear infection or severe tinnitus"],
            fr: ["Évitez en cas d'infection active de l'oreille ou d'acouphènes sévères"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale through the nose for 4 counts. Exhale with a humming sound (mouth closed) for 6–8 counts. Pause briefly, then repeat.",
            fr: "Inspirez par le nez pendant 4 temps. Expirez en bourdonnant (bouche fermée) pendant 6 à 8 temps. Pause brève, puis répétez."
        ),
        isFree: true
    )

    public static let boxBreathing = Pose(
        id: "pranayama-box-breathing",
        name: LocalizedString(
            en: "Box Breathing",
            fr: "Respiration carrée"
        ),
        description: LocalizedString(
            en: "Sit with the spine straight and hands resting on the knees. Inhale through the nose for 4 counts. Hold the breath in for 4 counts, keeping the body relaxed — no clenching. Exhale through the nose for 4 counts, emptying the lungs completely. Hold the breath out for 4 counts before beginning the next cycle. Visualize tracing the four equal sides of a square with each phase. This military-grade technique regulates the autonomic nervous system and sharpens focus under stress.",
            fr: "Assoyez-vous la colonne droite, mains sur les genoux. Inspirez par le nez pendant 4 temps. Retenez le souffle pendant 4 temps en gardant le corps détendu — sans crispation. Expirez par le nez pendant 4 temps en vidant complètement les poumons. Retenez le souffle vide pendant 4 temps avant de commencer le cycle suivant. Visualisez le tracé des quatre côtés égaux d'un carré avec chaque phase. Cette technique de calibre militaire régule le système nerveux autonome et aiguise la concentration sous stress."
        ),
        durationSeconds: 120,
        difficulty: .beginner,
        category: .breathing,
        position: .seated,
        imageName: "pose.pranayama.boxbreathing",
        voiceCueText: LocalizedString(
            en: "Inhale, two, three, four. Hold, two, three, four. Exhale, two, three, four. Hold empty, two, three, four. Smooth and steady, like drawing a square.",
            fr: "Inspirez, deux, trois, quatre. Retenez, deux, trois, quatre. Expirez, deux, trois, quatre. Retenez vide, deux, trois, quatre. Doux et régulier, comme dessiner un carré."
        ),
        modifications: LocalizedStringArray(
            en: ["Reduce to 3-count sides if 4 counts causes strain or anxiety",
                 "Skip the breath-out hold (making it a triangle breath) if retaining on empty lungs feels uncomfortable"],
            fr: ["Réduisez à 3 temps par côté si les 4 temps causent de la tension ou de l'anxiété",
                 "Omettez la rétention poumons vides (en faisant un souffle triangulaire) si retenir à vide est inconfortable"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid breath retention if you are pregnant or have uncontrolled high blood pressure",
                 "Stop immediately if you feel dizzy or nauseous; return to natural breathing"],
            fr: ["Évitez la rétention du souffle si vous êtes enceinte ou souffrez d'hypertension non contrôlée",
                 "Arrêtez immédiatement si vous vous sentez étourdi ou nauséeux; revenez à une respiration naturelle"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale 4 counts → hold in 4 counts → exhale 4 counts → hold out 4 counts. Each full cycle = 16 counts. Repeat for the duration.",
            fr: "Inspirez 4 temps → retenez plein 4 temps → expirez 4 temps → retenez vide 4 temps. Chaque cycle complet = 16 temps. Répétez pour la durée."
        ),
        isFree: true
    )

    // MARK: - Breathing & Meditation Poses (Premium)

    public static let sitaliBreath = Pose(
        id: "pranayama-sitali",
        name: LocalizedString(
            en: "Sitali / Cooling Breath",
            fr: "Sitali / Souffle rafraîchissant"
        ),
        description: LocalizedString(
            en: "Sit comfortably and curl the tongue into a tube shape, extending it slightly past the lips. Inhale slowly through the rolled tongue for 4–6 counts, feeling the cool air pass over the tongue. Retract the tongue, close the mouth, and exhale slowly through the nose for 6–8 counts. If you cannot curl your tongue genetically, use Sitkari instead: place the tongue behind the teeth and inhale through the gaps. This technique lowers body temperature and reduces mental agitation.",
            fr: "Assoyez-vous confortablement et enroulez la langue en forme de tube, en l'étendant légèrement au-delà des lèvres. Inspirez lentement à travers la langue enroulée pendant 4 à 6 temps en sentant l'air frais passer sur la langue. Rétractez la langue, fermez la bouche et expirez lentement par le nez pendant 6 à 8 temps. Si vous ne pouvez pas génétiquement enrouler la langue, utilisez Sitkari à la place : placez la langue derrière les dents et inspirez par les interstices. Cette technique abaisse la température corporelle et réduit l'agitation mentale."
        ),
        durationSeconds: 90,
        difficulty: .beginner,
        category: .breathing,
        position: .seated,
        imageName: "pose.pranayama.sitali",
        voiceCueText: LocalizedString(
            en: "Curl the tongue and extend it slightly. Sip the cool air in through the tongue tube. Close the mouth, exhale warm air through the nose. Feel the body cool down with each cycle.",
            fr: "Enroulez la langue et étendez-la légèrement. Aspirez l'air frais à travers le tube de la langue. Fermez la bouche, expirez l'air chaud par le nez. Sentez le corps se rafraîchir à chaque cycle."
        ),
        modifications: LocalizedStringArray(
            en: ["Use Sitkari variation (inhale through clenched teeth) if you cannot curl the tongue",
                 "Reduce the inhale duration to 3 counts if you feel strain while breathing through the tongue"],
            fr: ["Utilisez la variante Sitkari (inspirez à travers les dents serrées) si vous ne pouvez pas enrouler la langue",
                 "Réduisez la durée de l'inspiration à 3 temps si vous sentez une tension en respirant par la langue"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid in cold weather or if you have low blood pressure, as it further lowers body temperature",
                 "Do not practice if you have chronic respiratory issues such as asthma triggered by cool air"],
            fr: ["Évitez par temps froid ou en cas d'hypotension, car cela abaisse davantage la température corporelle",
                 "Ne pratiquez pas si vous avez des problèmes respiratoires chroniques comme l'asthme déclenché par l'air froid"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale through the curled tongue for 4–6 counts. Close mouth, exhale through the nose for 6–8 counts. No retention. Repeat smoothly.",
            fr: "Inspirez par la langue enroulée pendant 4 à 6 temps. Fermez la bouche, expirez par le nez pendant 6 à 8 temps. Aucune rétention. Répétez en douceur."
        ),
        isFree: false
    )

    public static let fourSevenEightBreathing = Pose(
        id: "pranayama-478",
        name: LocalizedString(
            en: "4-7-8 Breathing",
            fr: "Respiration 4-7-8"
        ),
        description: LocalizedString(
            en: "Sit with the back straight and the tip of the tongue resting behind the upper front teeth. Exhale completely through the mouth with a whoosh sound. Close the mouth and inhale quietly through the nose for 4 counts. Hold the breath for 7 counts, keeping the body soft. Exhale completely through the mouth with a whoosh for 8 counts. This asymmetric ratio deeply activates the parasympathetic response and is widely used as a natural sleep aid and anxiety reducer.",
            fr: "Assoyez-vous le dos droit, le bout de la langue posé derrière les dents supérieures avant. Expirez complètement par la bouche avec un son de souffle. Fermez la bouche et inspirez tranquillement par le nez pendant 4 temps. Retenez le souffle pendant 7 temps en gardant le corps souple. Expirez complètement par la bouche avec un souffle pendant 8 temps. Ce ratio asymétrique active profondément la réponse parasympathique et est largement utilisé comme aide naturelle au sommeil et réducteur d'anxiété."
        ),
        durationSeconds: 120,
        difficulty: .beginner,
        category: .breathing,
        position: .seated,
        imageName: "pose.pranayama.478",
        voiceCueText: LocalizedString(
            en: "Tongue behind upper teeth. Inhale through the nose, two, three, four. Hold, two, three, four, five, six, seven. Whoosh out through the mouth for eight full counts. Let go completely.",
            fr: "Langue derrière les dents supérieures. Inspirez par le nez, deux, trois, quatre. Retenez, deux, trois, quatre, cinq, six, sept. Soufflez par la bouche pendant huit temps complets. Relâchez complètement."
        ),
        modifications: LocalizedStringArray(
            en: ["Halve the counts (2-3.5-4) if the full ratio feels too long initially; gradually build up",
                 "Practice lying down at bedtime for maximum relaxation benefit"],
            fr: ["Divisez les temps par deux (2-3,5-4) si le ratio complet semble trop long au début; augmentez progressivement",
                 "Pratiquez allongé au coucher pour un bénéfice de relaxation maximal"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Avoid the long retention if you have respiratory conditions or panic disorder",
                 "Do not practice while driving or operating machinery due to the sedative effect"],
            fr: ["Évitez la longue rétention si vous avez des troubles respiratoires ou un trouble panique",
                 "Ne pratiquez pas en conduisant ou en utilisant de la machinerie en raison de l'effet sédatif"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale through the nose for 4 counts → hold breath for 7 counts → exhale through the mouth (whoosh) for 8 counts. Ratio 4:7:8. Repeat 4 cycles.",
            fr: "Inspirez par le nez pendant 4 temps → retenez le souffle pendant 7 temps → expirez par la bouche (souffle) pendant 8 temps. Ratio 4:7:8. Répétez 4 cycles."
        ),
        isFree: false
    )

    public static let bodyScanMeditation = Pose(
        id: "pranayama-body-scan",
        name: LocalizedString(
            en: "Body Scan Meditation",
            fr: "Méditation par balayage corporel"
        ),
        description: LocalizedString(
            en: "Sit or lie comfortably and close your eyes. Begin by bringing awareness to the top of the head. Slowly scan downward, pausing at each body region: forehead, eyes, jaw, neck, shoulders, arms, hands, chest, belly, hips, thighs, knees, calves, feet. At each region, notice any tension, warmth, tingling, or numbness without judgment. Breathe into areas of tension and consciously release them on the exhale. This practice cultivates interoception — the ability to sense the body's internal state — and systematically dissolves stored physical tension.",
            fr: "Assoyez-vous ou allongez-vous confortablement et fermez les yeux. Commencez en portant l'attention au sommet de la tête. Balayez lentement vers le bas, en faisant une pause à chaque région du corps : front, yeux, mâchoire, cou, épaules, bras, mains, poitrine, ventre, hanches, cuisses, genoux, mollets, pieds. À chaque région, remarquez toute tension, chaleur, picotement ou engourdissement sans jugement. Respirez dans les zones de tension et relâchez-les consciemment à l'expiration. Cette pratique cultive l'intéroception — la capacité de sentir l'état interne du corps — et dissout systématiquement les tensions physiques accumulées."
        ),
        durationSeconds: 300,
        difficulty: .beginner,
        category: .relaxation,
        position: .seated,
        imageName: "pose.pranayama.bodyscan",
        voiceCueText: LocalizedString(
            en: "Close your eyes. Bring your attention to the top of your head. Slowly scan down through your body. Notice each area without trying to change anything. Simply observe. Breathe into any tension you find.",
            fr: "Fermez les yeux. Portez votre attention au sommet de la tête. Balayez lentement vers le bas à travers votre corps. Remarquez chaque zone sans essayer de changer quoi que ce soit. Observez simplement. Respirez dans toute tension que vous trouvez."
        ),
        modifications: LocalizedStringArray(
            en: ["Lie in Savasana for a more restorative version of the body scan",
                 "Focus on just 5 major regions (head, torso, arms, legs, feet) if a detailed scan feels overwhelming"],
            fr: ["Allongez-vous en Savasana pour une version plus restaurative du balayage corporel",
                 "Concentrez-vous sur 5 régions principales (tête, torse, bras, jambes, pieds) si un balayage détaillé semble accablant"]
        ),
        contraindications: LocalizedStringArray(
            en: ["If you experience trauma-related body sensations, practice with a qualified instructor present",
                 "Discontinue if strong emotional distress arises and seek support from a mental health professional"],
            fr: ["Si vous ressentez des sensations corporelles liées à un traumatisme, pratiquez en présence d'un instructeur qualifié",
                 "Cessez si une détresse émotionnelle forte survient et consultez un professionnel de la santé mentale"]
        ),
        breathingPattern: LocalizedString(
            en: "Natural, relaxed breathing throughout. Inhale 4 counts, exhale 6 counts. Direct the exhale toward any area of tension to encourage release.",
            fr: "Respiration naturelle et détendue tout au long. Inspirez 4 temps, expirez 6 temps. Dirigez l'expiration vers toute zone de tension pour favoriser le relâchement."
        ),
        isFree: false
    )

    public static let lovingKindnessMeditation = Pose(
        id: "pranayama-loving-kindness",
        name: LocalizedString(
            en: "Loving-Kindness Meditation",
            fr: "Méditation de bienveillance aimante"
        ),
        description: LocalizedString(
            en: "Sit comfortably, close your eyes, and bring both hands to the heart center. Begin by silently repeating phrases of kindness toward yourself: 'May I be happy. May I be healthy. May I be safe. May I live with ease.' After several rounds, extend these wishes to a loved one, then to a neutral person, then to a difficult person, and finally to all beings everywhere. Feel warmth radiating outward from the heart with each phrase. This ancient Metta practice cultivates compassion, reduces self-criticism, and strengthens emotional resilience.",
            fr: "Assoyez-vous confortablement, fermez les yeux et amenez les deux mains au centre du cœur. Commencez en répétant silencieusement des phrases de bienveillance envers vous-même : « Que je sois heureux. Que je sois en santé. Que je sois en sécurité. Que je vive avec aisance. » Après plusieurs cycles, étendez ces souhaits à un être cher, puis à une personne neutre, puis à une personne difficile, et enfin à tous les êtres partout. Sentez la chaleur rayonner du cœur avec chaque phrase. Cette ancienne pratique Metta cultive la compassion, réduit l'autocritique et renforce la résilience émotionnelle."
        ),
        durationSeconds: 300,
        difficulty: .beginner,
        category: .relaxation,
        position: .seated,
        imageName: "pose.pranayama.lovingkindness",
        voiceCueText: LocalizedString(
            en: "Hands on your heart. Repeat gently: May I be happy. May I be healthy. May I be safe. Now send this warmth to someone you love. Feel it expand outward to all beings.",
            fr: "Mains sur le cœur. Répétez doucement : Que je sois heureux. Que je sois en santé. Que je sois en sécurité. Maintenant, envoyez cette chaleur à quelqu'un que vous aimez. Sentez-la s'étendre à tous les êtres."
        ),
        modifications: LocalizedStringArray(
            en: ["Use only the self-directed phrases if extending to others feels too challenging at first",
                 "Place a hand on the belly instead of the heart if the heart area triggers discomfort"],
            fr: ["Utilisez uniquement les phrases dirigées vers vous-même si les étendre aux autres semble trop difficile au début",
                 "Placez une main sur le ventre au lieu du cœur si la zone du cœur provoque de l'inconfort"]
        ),
        contraindications: LocalizedStringArray(
            en: ["May bring up strong emotions; allow tears or feelings to surface without suppressing them",
                 "If the difficult-person phase causes distress, skip it and return to self-compassion phrases"],
            fr: ["Peut faire remonter des émotions fortes; laissez les larmes ou les sentiments émerger sans les réprimer",
                 "Si la phase de la personne difficile cause de la détresse, sautez-la et revenez aux phrases d'auto-compassion"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, natural breathing. Inhale gently for 4 counts, silently repeat a phrase on the exhale for 6 counts. Let the breath carry the intention.",
            fr: "Respiration lente et naturelle. Inspirez doucement pendant 4 temps, répétez silencieusement une phrase à l'expiration pendant 6 temps. Laissez le souffle porter l'intention."
        ),
        isFree: false
    )

    public static let yogaNidraIntroduction = Pose(
        id: "pranayama-yoga-nidra",
        name: LocalizedString(
            en: "Yoga Nidra Introduction",
            fr: "Introduction au Yoga Nidra"
        ),
        description: LocalizedString(
            en: "Lie on your back in Savasana with arms slightly away from the body, palms up, and legs hip-width apart. Close your eyes and set a Sankalpa — a short, positive intention in present tense (e.g., 'I am at peace'). Follow the guided rotation of consciousness: bring awareness to each body part as it is named, without moving. Progress through the right hand, arm, shoulder, torso, right leg, left leg, left arm, face, and back of the head. Then observe the breath without controlling it. Yoga Nidra induces a state between waking and sleeping where deep healing and restoration occur.",
            fr: "Allongez-vous sur le dos en Savasana, bras légèrement écartés du corps, paumes vers le haut, jambes à la largeur des hanches. Fermez les yeux et établissez un Sankalpa — une courte intention positive au présent (p. ex., « Je suis en paix »). Suivez la rotation guidée de la conscience : portez l'attention à chaque partie du corps nommée, sans bouger. Progressez à travers la main droite, le bras, l'épaule, le torse, la jambe droite, la jambe gauche, le bras gauche, le visage et l'arrière de la tête. Puis observez le souffle sans le contrôler. Le Yoga Nidra induit un état entre l'éveil et le sommeil où une guérison et une restauration profondes se produisent."
        ),
        durationSeconds: 300,
        difficulty: .beginner,
        category: .relaxation,
        position: .supine,
        imageName: "pose.pranayama.yoganidra",
        voiceCueText: LocalizedString(
            en: "Lie still. Set your intention. Now bring awareness to your right thumb… index finger… middle finger… Let each part relax as you name it. You are awake but deeply at rest.",
            fr: "Restez immobile. Établissez votre intention. Maintenant, portez l'attention au pouce droit… l'index… le majeur… Laissez chaque partie se relâcher en la nommant. Vous êtes éveillé mais profondément au repos."
        ),
        modifications: LocalizedStringArray(
            en: ["Place a bolster under the knees and a blanket over the body for maximum comfort",
                 "Practice in a seated position if lying down causes you to fall asleep immediately"],
            fr: ["Placez un traversin sous les genoux et une couverture sur le corps pour un confort maximal",
                 "Pratiquez en position assise si vous vous endormez immédiatement en position allongée"]
        ),
        contraindications: LocalizedStringArray(
            en: ["If you have trauma-related dissociation, practice only with a trained facilitator",
                 "Avoid if you experience severe insomnia triggered by relaxation techniques (paradoxical insomnia)"],
            fr: ["En cas de dissociation liée à un traumatisme, pratiquez uniquement avec un facilitateur formé",
                 "Évitez si vous souffrez d'insomnie sévère déclenchée par les techniques de relaxation (insomnie paradoxale)"]
        ),
        breathingPattern: LocalizedString(
            en: "Natural, uncontrolled breathing. Simply observe the breath flowing in and out. No counting, no manipulation. Let the body breathe itself.",
            fr: "Respiration naturelle, non contrôlée. Observez simplement le souffle qui entre et sort. Pas de comptage, pas de manipulation. Laissez le corps respirer de lui-même."
        ),
        isFree: false
    )

    public static let visualizationMeditation = Pose(
        id: "pranayama-visualization",
        name: LocalizedString(
            en: "Visualization Meditation",
            fr: "Méditation de visualisation"
        ),
        description: LocalizedString(
            en: "Sit comfortably with eyes closed. Begin with 5 deep breaths to settle the mind. Then create a vivid mental image of a peaceful place — perhaps a quiet forest, a sunlit beach, or a mountain meadow. Engage all senses: see the colors, hear the sounds, feel the temperature on your skin, smell the air. Walk slowly through this landscape in your mind's eye. If the mind wanders, gently return to the scene. This practice harnesses the brain's inability to distinguish between vividly imagined and real experiences, reducing cortisol and inducing calm.",
            fr: "Assoyez-vous confortablement les yeux fermés. Commencez par 5 respirations profondes pour calmer l'esprit. Puis créez une image mentale vivante d'un endroit paisible — peut-être une forêt tranquille, une plage ensoleillée ou un pré de montagne. Engagez tous les sens : voyez les couleurs, entendez les sons, sentez la température sur votre peau, respirez l'air. Marchez lentement à travers ce paysage dans votre esprit. Si l'esprit s'égare, revenez doucement à la scène. Cette pratique exploite l'incapacité du cerveau à distinguer entre les expériences vivement imaginées et réelles, réduisant le cortisol et induisant le calme."
        ),
        durationSeconds: 240,
        difficulty: .intermediate,
        category: .relaxation,
        position: .seated,
        imageName: "pose.pranayama.visualization",
        voiceCueText: LocalizedString(
            en: "Close your eyes. Picture a place where you feel completely at peace. See the colors, hear the sounds, feel the warmth. Walk slowly through this place. You are safe here.",
            fr: "Fermez les yeux. Imaginez un endroit où vous vous sentez complètement en paix. Voyez les couleurs, entendez les sons, sentez la chaleur. Marchez lentement à travers cet endroit. Vous êtes en sécurité ici."
        ),
        modifications: LocalizedStringArray(
            en: ["Use a guided audio description if creating your own imagery feels difficult",
                 "Start with a familiar, real location (your childhood home, a favorite park) before inventing imaginary scenes"],
            fr: ["Utilisez une description audio guidée si créer vos propres images semble difficile",
                 "Commencez par un endroit familier et réel (votre maison d'enfance, un parc préféré) avant d'inventer des scènes imaginaires"]
        ),
        contraindications: LocalizedStringArray(
            en: ["If visualization triggers anxiety or intrusive thoughts, switch to breath-focused meditation instead",
                 "Avoid nature-based visualizations if they trigger phobias (e.g., ocean for those with thalassophobia)"],
            fr: ["Si la visualisation déclenche de l'anxiété ou des pensées intrusives, passez plutôt à une méditation axée sur le souffle",
                 "Évitez les visualisations basées sur la nature si elles déclenchent des phobies (p. ex., l'océan pour la thalassophobie)"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, natural breathing. Inhale for 4 counts, exhale for 6 counts. Use each exhale to deepen the visualization and relax further into the scene.",
            fr: "Respiration lente et naturelle. Inspirez pendant 4 temps, expirez pendant 6 temps. Utilisez chaque expiration pour approfondir la visualisation et vous détendre davantage dans la scène."
        ),
        isFree: false
    )

    public static let mantraMeditation = Pose(
        id: "pranayama-mantra",
        name: LocalizedString(
            en: "Mantra Meditation",
            fr: "Méditation par mantra"
        ),
        description: LocalizedString(
            en: "Sit tall with hands on the knees in Chin Mudra (thumb and index finger touching, other fingers extended). Choose a mantra — a short, meaningful word or phrase such as 'Om', 'So Hum' (I am That), or 'Sat Nam' (Truth is my identity). On each exhale, silently or softly repeat the mantra. Let the mantra become the anchor for the mind. When thoughts arise, acknowledge them without judgment and return to the mantra. Over time, the repetition quiets mental chatter and induces a state of absorbed concentration (dharana).",
            fr: "Assoyez-vous droit, mains sur les genoux en Chin Mudra (pouce et index se touchant, autres doigts tendus). Choisissez un mantra — un mot ou une phrase courte et significative comme « Om », « So Hum » (Je suis Cela), ou « Sat Nam » (La vérité est mon identité). À chaque expiration, répétez silencieusement ou doucement le mantra. Laissez le mantra devenir l'ancre de l'esprit. Quand des pensées surgissent, reconnaissez-les sans jugement et revenez au mantra. Avec le temps, la répétition apaise le bavardage mental et induit un état de concentration absorbée (dharana)."
        ),
        durationSeconds: 240,
        difficulty: .intermediate,
        category: .relaxation,
        position: .seated,
        imageName: "pose.pranayama.mantra",
        voiceCueText: LocalizedString(
            en: "Find your mantra. On each exhale, repeat it silently. Let the word fill your awareness. When the mind drifts, gently return. The mantra is your anchor.",
            fr: "Trouvez votre mantra. À chaque expiration, répétez-le silencieusement. Laissez le mot remplir votre conscience. Quand l'esprit dérive, revenez doucement. Le mantra est votre ancre."
        ),
        modifications: LocalizedStringArray(
            en: ["Use mala beads (108 beads) to track repetitions and give the hands something to do",
                 "Whisper the mantra aloud if silent repetition does not hold your attention"],
            fr: ["Utilisez un mala (108 perles) pour compter les répétitions et occuper les mains",
                 "Chuchotez le mantra à voix haute si la répétition silencieuse ne retient pas votre attention"]
        ),
        contraindications: LocalizedStringArray(
            en: ["If a particular mantra triggers negative associations, choose a neutral word like 'peace' or 'calm'",
                 "Avoid forcing concentration; if frustration builds, take a break and return later"],
            fr: ["Si un mantra particulier déclenche des associations négatives, choisissez un mot neutre comme « paix » ou « calme »",
                 "Évitez de forcer la concentration; si la frustration monte, faites une pause et revenez plus tard"]
        ),
        breathingPattern: LocalizedString(
            en: "Natural, unhurried breathing. Inhale naturally, silently repeat the mantra on the exhale. Let the mantra rhythm gradually slow the breath on its own.",
            fr: "Respiration naturelle et sans hâte. Inspirez naturellement, répétez silencieusement le mantra à l'expiration. Laissez le rythme du mantra ralentir graduellement le souffle de lui-même."
        ),
        isFree: false
    )

    public static let walkingMeditationPrep = Pose(
        id: "pranayama-walking-meditation",
        name: LocalizedString(
            en: "Walking Meditation Prep",
            fr: "Préparation à la méditation marchée"
        ),
        description: LocalizedString(
            en: "Stand with feet hip-width apart, arms relaxed at your sides. Close the eyes briefly and take 3 centering breaths. Open the eyes with a soft, unfocused gaze directed about 2 meters ahead on the ground. Begin walking very slowly: lift the right foot, move it forward, place it down — heel, ball, toes. Notice each micro-phase of the step. Synchronize the breath: inhale as you lift and move the foot, exhale as you place it down. Walk a short path of 5–10 steps, pause, turn mindfully, and walk back. This practice bridges seated meditation and daily life awareness.",
            fr: "Tenez-vous debout, pieds à la largeur des hanches, bras détendus le long du corps. Fermez brièvement les yeux et prenez 3 respirations de centrage. Ouvrez les yeux avec un regard doux et non focalisé dirigé environ 2 mètres devant vous au sol. Commencez à marcher très lentement : soulevez le pied droit, avancez-le, posez-le — talon, plante, orteils. Remarquez chaque micro-phase du pas. Synchronisez le souffle : inspirez en soulevant et avançant le pied, expirez en le posant. Parcourez un court trajet de 5 à 10 pas, faites une pause, tournez en pleine conscience et revenez. Cette pratique fait le pont entre la méditation assise et la pleine conscience au quotidien."
        ),
        durationSeconds: 180,
        difficulty: .beginner,
        category: .relaxation,
        position: .standing,
        imageName: "pose.pranayama.walkingmeditation",
        voiceCueText: LocalizedString(
            en: "Stand still. Feel your feet on the ground. Now, lift the right foot slowly. Move it forward. Place it down. Heel, ball, toes. Breathe with each step. There is no rush.",
            fr: "Restez debout. Sentez vos pieds au sol. Maintenant, soulevez lentement le pied droit. Avancez-le. Posez-le. Talon, plante, orteils. Respirez avec chaque pas. Il n'y a pas de hâte."
        ),
        modifications: LocalizedStringArray(
            en: ["Hold onto a wall or railing for balance if slow walking feels unstable",
                 "Practice barefoot on a soft surface (grass, carpet) for enhanced sensory awareness"],
            fr: ["Tenez-vous à un mur ou une rampe pour l'équilibre si la marche lente semble instable",
                 "Pratiquez pieds nus sur une surface douce (gazon, tapis) pour une conscience sensorielle accrue"]
        ),
        contraindications: LocalizedStringArray(
            en: ["Use a mobility aid if you have balance disorders; safety takes priority over form",
                 "Avoid if you have vertigo that worsens with slow, deliberate movement"],
            fr: ["Utilisez une aide à la mobilité si vous avez des troubles d'équilibre; la sécurité prime sur la forme",
                 "Évitez si vous avez des vertiges qui s'aggravent avec des mouvements lents et délibérés"]
        ),
        breathingPattern: LocalizedString(
            en: "Inhale as you lift and advance the foot (2–3 counts). Exhale as you place it down (2–3 counts). One breath per step. Slow, deliberate rhythm.",
            fr: "Inspirez en soulevant et avançant le pied (2 à 3 temps). Expirez en le posant (2 à 3 temps). Un souffle par pas. Rythme lent et délibéré."
        ),
        isFree: false
    )

    public static let gratitudeMeditation = Pose(
        id: "pranayama-gratitude",
        name: LocalizedString(
            en: "Gratitude Meditation",
            fr: "Méditation de gratitude"
        ),
        description: LocalizedString(
            en: "Sit comfortably and close your eyes. Place both hands on the heart. Take 3 deep breaths to settle. Then bring to mind three things you are grateful for today — they can be as simple as morning sunlight, a warm meal, or a kind word from someone. For each one, visualize it clearly, recall how it made you feel, and silently say 'thank you.' Notice the warmth building in the chest. After the three specific gratitudes, expand the feeling outward, radiating appreciation to your body, your breath, and the present moment. This practice rewires neural pathways toward positivity and has been shown to improve sleep quality and overall wellbeing.",
            fr: "Assoyez-vous confortablement et fermez les yeux. Placez les deux mains sur le cœur. Prenez 3 respirations profondes pour vous installer. Puis amenez à l'esprit trois choses pour lesquelles vous êtes reconnaissant aujourd'hui — elles peuvent être aussi simples que la lumière du matin, un repas chaud ou un mot gentil de quelqu'un. Pour chacune, visualisez-la clairement, rappelez-vous comment elle vous a fait sentir et dites silencieusement « merci ». Remarquez la chaleur qui s'accumule dans la poitrine. Après les trois gratitudes spécifiques, étendez le sentiment vers l'extérieur, rayonnant l'appréciation vers votre corps, votre souffle et le moment présent. Cette pratique recâble les voies neuronales vers la positivité et il a été démontré qu'elle améliore la qualité du sommeil et le bien-être global."
        ),
        durationSeconds: 240,
        difficulty: .beginner,
        category: .relaxation,
        position: .seated,
        imageName: "pose.pranayama.gratitude",
        voiceCueText: LocalizedString(
            en: "Hands on your heart. Think of one thing you are grateful for. See it. Feel it. Say thank you. Now a second. And a third. Let gratitude fill your whole chest.",
            fr: "Mains sur le cœur. Pensez à une chose pour laquelle vous êtes reconnaissant. Voyez-la. Ressentez-la. Dites merci. Maintenant une deuxième. Et une troisième. Laissez la gratitude remplir toute votre poitrine."
        ),
        modifications: LocalizedStringArray(
            en: ["Write down the three gratitudes in a journal before meditating if mental recall is challenging",
                 "Focus on sensory gratitudes (things you can see, hear, touch) if abstract gratitude feels forced"],
            fr: ["Écrivez les trois gratitudes dans un journal avant de méditer si le rappel mental est difficile",
                 "Concentrez-vous sur des gratitudes sensorielles (choses que vous pouvez voir, entendre, toucher) si la gratitude abstraite semble forcée"]
        ),
        contraindications: LocalizedStringArray(
            en: ["If you are in acute grief, allow whatever emotions arise without forcing positivity",
                 "Do not use this practice to suppress or invalidate difficult emotions; gratitude should complement, not replace, emotional processing"],
            fr: ["Si vous êtes en deuil aigu, permettez à toutes les émotions de surgir sans forcer la positivité",
                 "N'utilisez pas cette pratique pour réprimer ou invalider les émotions difficiles; la gratitude devrait compléter, pas remplacer, le traitement émotionnel"]
        ),
        breathingPattern: LocalizedString(
            en: "Slow, heart-centered breathing. Inhale for 4 counts feeling the chest expand under your hands. Exhale for 6 counts, sending gratitude outward with each breath.",
            fr: "Respiration lente centrée sur le cœur. Inspirez pendant 4 temps en sentant la poitrine se gonfler sous vos mains. Expirez pendant 6 temps en envoyant la gratitude vers l'extérieur à chaque souffle."
        ),
        isFree: false
    )

    // MARK: - Pose & Plan Collections

    public static let pranayamaPoses: [Pose] = [
        diaphragmaticBreathing,
        ujjayiBreath,
        nadiShodhana,
        kapalabhati,
        bhramariBreath,
        boxBreathing,
        sitaliBreath,
        fourSevenEightBreathing,
        bodyScanMeditation,
        lovingKindnessMeditation,
        yogaNidraIntroduction,
        visualizationMeditation,
        mantraMeditation,
        walkingMeditationPrep,
        gratitudeMeditation
    ]

    // MARK: - Workout Plans

    public static let breathworkFoundationsPlan = WorkoutPlan(
        id: "pranayama-foundations",
        name: LocalizedString(
            en: "Breathwork Foundations",
            fr: "Fondements du travail respiratoire"
        ),
        description: LocalizedString(
            en: "A beginner-friendly sequence of six essential breathing techniques. Learn to engage the diaphragm, create ocean breath, alternate nostrils, energize with Kapalabhati, soothe with Bhramari, and focus with Box Breathing. A complete introduction to pranayama.",
            fr: "Une séquence accessible aux débutants de six techniques respiratoires essentielles. Apprenez à engager le diaphragme, créer le souffle de l'océan, alterner les narines, énergiser avec Kapalabhati, apaiser avec Bhramari et vous concentrer avec la respiration carrée. Une introduction complète au pranayama."
        ),
        style: .pranayama,
        poses: [
            diaphragmaticBreathing,
            ujjayiBreath,
            nadiShodhana,
            kapalabhati,
            bhramariBreath,
            boxBreathing
        ],
        transitionSeconds: 10,
        isFree: true
    )

    public static let deepPranayamaPlan = WorkoutPlan(
        id: "pranayama-deep",
        name: LocalizedString(
            en: "Deep Pranayama & Meditation",
            fr: "Pranayama profond et méditation"
        ),
        description: LocalizedString(
            en: "An immersive journey through advanced breathwork and guided meditation. Begin with Ujjayi and Nadi Shodhana to center the mind, progress through cooling Sitali and calming 4-7-8 breathing, then transition into Body Scan, Loving-Kindness, Visualization, Mantra Meditation, Yoga Nidra, and close with Gratitude Meditation. A transformative 45-minute session.",
            fr: "Un voyage immersif à travers le travail respiratoire avancé et la méditation guidée. Commencez par Ujjayi et Nadi Shodhana pour centrer l'esprit, progressez à travers le Sitali rafraîchissant et la respiration calmante 4-7-8, puis transitionnez vers le balayage corporel, la bienveillance aimante, la visualisation, la méditation par mantra, le Yoga Nidra, et terminez avec la méditation de gratitude. Une séance transformatrice de 45 minutes."
        ),
        style: .pranayama,
        poses: [
            ujjayiBreath,
            nadiShodhana,
            sitaliBreath,
            fourSevenEightBreathing,
            bodyScanMeditation,
            lovingKindnessMeditation,
            visualizationMeditation,
            mantraMeditation,
            yogaNidraIntroduction,
            gratitudeMeditation
        ],
        transitionSeconds: 10,
        isFree: false
    )

    public static let pranayamaPlans: [WorkoutPlan] = [
        breathworkFoundationsPlan,
        deepPranayamaPlan
    ]
}
