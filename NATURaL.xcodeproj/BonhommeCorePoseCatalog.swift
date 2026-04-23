import Foundation

/// Central catalog of yoga poses and workout plans.
public enum PoseCatalog {
    
    // MARK: - Sample Poses
    
    public static let seatedCatCow = YogaPose(
        name: LocalizedString(
            en: "Seated Cat-Cow",
            fr: "Chat-Vache assis",
            es: "Gato-Vaca sentado",
            ja: "座位キャット・カウ",
            zh: "坐姿猫牛式",
            ko: "앉은 고양이-소 자세",
            ru: "Кошка-корова сидя",
            de: "Sitzende Katze-Kuh",
            ar: "القطة والبقرة جلوساً",
            it: "Gatto-Mucca seduto",
            pt: "Gato-Vaca sentado"
        ),
        durationSeconds: 60,
        category: .seated,
        instructions: LocalizedString(
            en: "Flow between arching and rounding your spine",
            fr: "Alternez entre arquer et arrondir votre colonne vertébrale",
            es: "Fluye entre arquear y redondear tu columna",
            ja: "背骨を反らせたり丸めたりを繰り返す",
            zh: "在拱起和弯曲脊柱之间流动",
            ko: "척추를 아치형으로 만들고 둥글게 하는 동작을 반복",
            ru: "Чередуйте прогиб и округление позвоночника",
            de: "Wechseln Sie zwischen Wölben und Runden Ihrer Wirbelsäule",
            ar: "تبادل بين تقويس وتدوير العمود الفقري",
            it: "Alterna tra l'inarcare e l'arrotondare la colonna vertebrale",
            pt: "Alterne entre arquear e arredondar sua coluna"
        ),
        difficulty: .beginner,
        breathingPattern: .alternate
    )
    
    public static let mountainPose = YogaPose(
        name: LocalizedString(
            en: "Mountain Pose",
            fr: "Posture de la montagne",
            es: "Postura de la montaña",
            ja: "山のポーズ",
            zh: "山式",
            ko: "산 자세",
            ru: "Поза горы",
            de: "Bergpose",
            ar: "وضعية الجبل",
            it: "Posizione della montagna",
            pt: "Postura da montanha"
        ),
        durationSeconds: 30,
        category: .standing,
        instructions: LocalizedString(
            en: "Stand tall with feet together, arms at sides",
            fr: "Tenez-vous droit, pieds joints, bras le long du corps",
            es: "Párate erguido con los pies juntos, brazos a los lados",
            ja: "足を揃えて直立し、腕を体の横に",
            zh: "双脚并拢站立，手臂放在身体两侧",
            ko: "발을 모으고 똑바로 서서 팔을 옆구리에",
            ru: "Встаньте прямо, ноги вместе, руки по бокам",
            de: "Stehen Sie aufrecht mit zusammenstehenden Füßen, Arme an den Seiten",
            ar: "قف منتصباً مع ضم القدمين، والذراعين على الجانبين",
            it: "Stai in piedi con i piedi uniti, braccia ai lati",
            pt: "Fique em pé com os pés juntos, braços ao lado do corpo"
        ),
        difficulty: .beginner,
        breathingPattern: .continuous
    )
    
    public static let childsPose = YogaPose(
        name: LocalizedString(
            en: "Child's Pose",
            fr: "Posture de l'enfant",
            es: "Postura del niño",
            ja: "チャイルドポーズ",
            zh: "儿童式",
            ko: "아이 자세",
            ru: "Поза ребенка",
            de: "Kindhaltung",
            ar: "وضعية الطفل",
            it: "Posizione del bambino",
            pt: "Postura da criança"
        ),
        durationSeconds: 90,
        category: .prone,
        instructions: LocalizedString(
            en: "Kneel and fold forward, arms extended or at sides",
            fr: "Agenouillez-vous et penchez-vous, bras étendus ou sur les côtés",
            es: "Arrodíllate y dobla hacia adelante, brazos extendidos o a los lados",
            ja: "ひざまずいて前に折り曲がり、腕を伸ばすか横に",
            zh: "跪下并向前折叠，手臂伸展或放在两侧",
            ko: "무릎을 꿇고 앞으로 구부리며, 팔을 뻗거나 옆에",
            ru: "Встаньте на колени и наклонитесь вперед, руки вытянуты или по бокам",
            de: "Knien Sie und beugen Sie sich nach vorne, Arme ausgestreckt oder an den Seiten",
            ar: "اركع وانحني للأمام، الذراعين ممدودتين أو على الجانبين",
            it: "Inginocchiati e piegati in avanti, braccia distese o ai lati",
            pt: "Ajoelhe-se e dobre para frente, braços estendidos ou ao lado"
        ),
        difficulty: .beginner,
        breathingPattern: .continuous
    )
    
    public static let downwardDog = YogaPose(
        name: LocalizedString(
            en: "Downward Dog",
            fr: "Chien tête en bas",
            es: "Perro boca abajo",
            ja: "下向きの犬のポーズ",
            zh: "下犬式",
            ko: "아래를 향한 개 자세",
            ru: "Собака мордой вниз",
            de: "Herabschauender Hund",
            ar: "الكلب المتجه للأسفل",
            it: "Cane a testa in giù",
            pt: "Cachorro olhando para baixo"
        ),
        durationSeconds: 45,
        category: .inverted,
        instructions: LocalizedString(
            en: "Form an inverted V-shape with your body",
            fr: "Formez un V inversé avec votre corps",
            es: "Forma una V invertida con tu cuerpo",
            ja: "体で逆V字の形を作る",
            zh: "用身体形成一个倒V形",
            ko: "몸으로 역V자 모양을 만드세요",
            ru: "Сформируйте перевернутую V-образную форму телом",
            de: "Bilden Sie mit Ihrem Körper ein umgekehrtes V",
            ar: "شكل حرف V مقلوب بجسمك",
            it: "Forma una V rovesciata con il tuo corpo",
            pt: "Forme um V invertido com seu corpo"
        ),
        difficulty: .beginner,
        breathingPattern: .continuous
    )
    
    public static let warriorI = YogaPose(
        name: LocalizedString(
            en: "Warrior I",
            fr: "Guerrier I",
            es: "Guerrero I",
            ja: "戦士のポーズI",
            zh: "战士一式",
            ko: "전사 자세 I",
            ru: "Воин I",
            de: "Krieger I",
            ar: "المحارب الأول",
            it: "Guerriero I",
            pt: "Guerreiro I"
        ),
        durationSeconds: 30,
        category: .standing,
        instructions: LocalizedString(
            en: "Lunge forward with arms raised overhead",
            fr: "Fente avant avec les bras levés au-dessus de la tête",
            es: "Estocada hacia adelante con brazos levantados sobre la cabeza",
            ja: "前に踏み込み、腕を頭上に上げる",
            zh: "向前弓步，手臂举过头顶",
            ko: "앞으로 돌진하며 팔을 머리 위로 올리세요",
            ru: "Выпад вперед с поднятыми над головой руками",
            de: "Ausfallschritt nach vorne mit über dem Kopf erhobenen Armen",
            ar: "اندفع للأمام مع رفع الذراعين فوق الرأس",
            it: "Affondo in avanti con le braccia alzate sopra la testa",
            pt: "Avanço para frente com braços levantados acima da cabeça"
        ),
        difficulty: .intermediate,
        breathingPattern: .continuous
    )
    
    public static let warriorII = YogaPose(
        name: LocalizedString(
            en: "Warrior II",
            fr: "Guerrier II",
            es: "Guerrero II",
            ja: "戦士のポーズII",
            zh: "战士二式",
            ko: "전사 자세 II",
            ru: "Воин II",
            de: "Krieger II",
            ar: "المحارب الثاني",
            it: "Guerriero II",
            pt: "Guerreiro II"
        ),
        durationSeconds: 30,
        category: .standing,
        instructions: LocalizedString(
            en: "Wide stance with arms extended, gaze over front hand",
            fr: "Position large avec bras étendus, regard vers la main avant",
            es: "Postura amplia con brazos extendidos, mirada sobre la mano delantera",
            ja: "広いスタンスで腕を伸ばし、前の手を見る",
            zh: "宽站姿，手臂伸展，目光看向前手",
            ko: "넓은 자세로 팔을 펴고 앞손을 바라보세요",
            ru: "Широкая стойка с вытянутыми руками, взгляд через переднюю руку",
            de: "Breite Haltung mit ausgestreckten Armen, Blick über die vordere Hand",
            ar: "وقفة واسعة مع تمديد الذراعين، انظر فوق اليد الأمامية",
            it: "Posizione ampia con braccia distese, sguardo sopra la mano anteriore",
            pt: "Postura ampla com braços estendidos, olhar sobre a mão da frente"
        ),
        difficulty: .intermediate,
        breathingPattern: .continuous
    )
    
    public static let treePose = YogaPose(
        name: LocalizedString(
            en: "Tree Pose",
            fr: "Posture de l'arbre",
            es: "Postura del árbol",
            ja: "木のポーズ",
            zh: "树式",
            ko: "나무 자세",
            ru: "Поза дерева",
            de: "Baumpose",
            ar: "وضعية الشجرة",
            it: "Posizione dell'albero",
            pt: "Postura da árvore"
        ),
        durationSeconds: 40,
        category: .balancing,
        instructions: LocalizedString(
            en: "Balance on one leg with foot on inner thigh",
            fr: "Équilibrez-vous sur une jambe avec le pied sur la cuisse intérieure",
            es: "Equilibra en una pierna con el pie en el muslo interno",
            ja: "片足で立ち、もう一方の足を内腿に置く",
            zh: "单腿站立，脚放在内侧大腿上",
            ko: "한 다리로 균형을 잡고 발을 안쪽 허벅지에",
            ru: "Балансируйте на одной ноге, ступня на внутренней стороне бедра",
            de: "Balancieren Sie auf einem Bein mit dem Fuß am inneren Oberschenkel",
            ar: "توازن على ساق واحدة مع وضع القدم على الفخذ الداخلي",
            it: "Bilancia su una gamba con il piede sulla coscia interna",
            pt: "Equilibre-se em uma perna com o pé na coxa interna"
        ),
        difficulty: .intermediate,
        breathingPattern: .continuous
    )
    
    public static let seatedForwardBend = YogaPose(
        name: LocalizedString(
            en: "Seated Forward Bend",
            fr: "Flexion avant assise",
            es: "Flexión hacia adelante sentado",
            ja: "座位前屈",
            zh: "坐姿前屈",
            ko: "앉아서 앞으로 구부리기",
            ru: "Наклон вперед сидя",
            de: "Sitzende Vorwärtsbeuge",
            ar: "الانحناء للأمام جلوساً",
            it: "Piegamento in avanti seduto",
            pt: "Flexão para frente sentado"
        ),
        durationSeconds: 60,
        category: .seated,
        instructions: LocalizedString(
            en: "Fold forward over extended legs",
            fr: "Penchez-vous vers l'avant sur les jambes étendues",
            es: "Dobla hacia adelante sobre las piernas extendidas",
            ja: "伸ばした脚の上に前屈する",
            zh: "向前折叠到伸展的腿上",
            ko: "뻗은 다리 위로 앞으로 구부리세요",
            ru: "Наклонитесь вперед над вытянутыми ногами",
            de: "Beugen Sie sich über die ausgestreckten Beine nach vorne",
            ar: "انحن للأمام فوق الساقين الممدودتين",
            it: "Piegati in avanti sulle gambe distese",
            pt: "Dobre para frente sobre as pernas estendidas"
        ),
        difficulty: .beginner,
        breathingPattern: .continuous
    )
    
    public static let corpse = YogaPose(
        name: LocalizedString(
            en: "Corpse Pose (Savasana)",
            fr: "Posture du cadavre (Savasana)",
            es: "Postura del cadáver (Savasana)",
            ja: "シャヴァーサナ（屍のポーズ）",
            zh: "摊尸式",
            ko: "시체 자세 (샤바아사나)",
            ru: "Поза трупа (Шавасана)",
            de: "Totenstellung (Savasana)",
            ar: "وضعية الجثة (شافاسانا)",
            it: "Posizione del cadavere (Savasana)",
            pt: "Postura do cadáver (Savasana)"
        ),
        durationSeconds: 120,
        category: .supine,
        instructions: LocalizedString(
            en: "Lie flat on your back, arms at sides, palms up",
            fr: "Allongez-vous à plat sur le dos, bras sur les côtés, paumes vers le haut",
            es: "Acuéstate boca arriba, brazos a los lados, palmas hacia arriba",
            ja: "仰向けに寝て、腕を脇に、手のひらを上に",
            zh: "平躺在背部，手臂放在两侧，掌心朝上",
            ko: "등을 대고 누워 팔을 옆에 두고 손바닥을 위로",
            ru: "Лягте на спину, руки по бокам, ладони вверх",
            de: "Liegen Sie flach auf dem Rücken, Arme an den Seiten, Handflächen nach oben",
            ar: "استلق على ظهرك، الذراعان على الجانبين، الراحتان للأعلى",
            it: "Sdraiati sulla schiena, braccia ai lati, palmi verso l'alto",
            pt: "Deite-se de costas, braços ao lado, palmas para cima"
        ),
        difficulty: .beginner,
        breathingPattern: .continuous
    )
    
    public static let deepBreathing = YogaPose(
        name: LocalizedString(
            en: "Deep Breathing",
            fr: "Respiration profonde",
            es: "Respiración profunda",
            ja: "深呼吸",
            zh: "深呼吸",
            ko: "깊은 호흡",
            ru: "Глубокое дыхание",
            de: "Tiefe Atmung",
            ar: "التنفس العميق",
            it: "Respirazione profonda",
            pt: "Respiração profunda"
        ),
        durationSeconds: 60,
        category: .breathing,
        instructions: LocalizedString(
            en: "Breathe deeply and slowly through your nose",
            fr: "Respirez profondément et lentement par le nez",
            es: "Respira profunda y lentamente por la nariz",
            ja: "鼻からゆっくりと深く呼吸する",
            zh: "通过鼻子深呼吸并缓慢呼吸",
            ko: "코로 깊고 천천히 숨을 쉬세요",
            ru: "Дышите глубоко и медленно через нос",
            de: "Atmen Sie tief und langsam durch die Nase",
            ar: "تنفس بعمق وبطء من خلال أنفك",
            it: "Respira profondamente e lentamente attraverso il naso",
            pt: "Respire profundamente e devagar pelo nariz"
        ),
        difficulty: .beginner,
        breathingPattern: .continuous
    )
    
    public static let cobrapose = YogaPose(
        name: LocalizedString(
            en: "Cobra Pose",
            fr: "Posture du cobra",
            es: "Postura de la cobra",
            ja: "コブラのポーズ",
            zh: "眼镜蛇式",
            ko: "코브라 자세",
            ru: "Поза кобры",
            de: "Kobra-Haltung",
            ar: "وضعية الكوبرا",
            it: "Posizione del cobra",
            pt: "Postura da cobra"
        ),
        durationSeconds: 30,
        category: .prone,
        instructions: LocalizedString(
            en: "Lift chest off the ground with hands under shoulders",
            fr: "Soulevez la poitrine du sol avec les mains sous les épaules",
            es: "Levanta el pecho del suelo con las manos debajo de los hombros",
            ja: "手を肩の下に置き、胸を地面から持ち上げる",
            zh: "双手放在肩膀下方，将胸部抬离地面",
            ko: "손을 어깨 아래에 두고 가슴을 땅에서 들어 올리세요",
            ru: "Поднимите грудь от пола, руки под плечами",
            de: "Heben Sie die Brust vom Boden ab, Hände unter den Schultern",
            ar: "ارفع الصدر عن الأرض مع وضع اليدين تحت الكتفين",
            it: "Solleva il petto da terra con le mani sotto le spalle",
            pt: "Levante o peito do chão com as mãos sob os ombros"
        ),
        difficulty: .beginner,
        breathingPattern: .inhale
    )
    
    public static let bridgePose = YogaPose(
        name: LocalizedString(
            en: "Bridge Pose",
            fr: "Posture du pont",
            es: "Postura del puente",
            ja: "橋のポーズ",
            zh: "桥式",
            ko: "다리 자세",
            ru: "Поза моста",
            de: "Brücke",
            ar: "وضعية الجسر",
            it: "Posizione del ponte",
            pt: "Postura da ponte"
        ),
        durationSeconds: 45,
        category: .supine,
        instructions: LocalizedString(
            en: "Lift hips while lying on your back, feet flat",
            fr: "Soulevez les hanches en étant allongé sur le dos, pieds à plat",
            es: "Levanta las caderas mientras estás acostado boca arriba, pies planos",
            ja: "仰向けに寝て、足を平らにして腰を持ち上げる",
            zh: "仰卧时抬起臀部，双脚平放",
            ko: "등을 대고 누워 엉덩이를 들어 올리고 발을 평평하게",
            ru: "Поднимите бедра, лежа на спине, ступни плоско",
            de: "Heben Sie die Hüften, während Sie auf dem Rücken liegen, Füße flach",
            ar: "ارفع الوركين بينما تستلقي على ظهرك، القدمان مسطحتان",
            it: "Solleva i fianchi mentre sei sdraiato sulla schiena, piedi piatti",
            pt: "Levante os quadris enquanto está deitado de costas, pés planos"
        ),
        difficulty: .beginner,
        breathingPattern: .continuous
    )
    
    // MARK: - Workout Plans
    
    public static let beginnerFlow = WorkoutPlan(
        name: LocalizedString(
            en: "Gentle Beginner Flow",
            fr: "Flux doux pour débutants",
            es: "Flujo suave para principiantes",
            ja: "優しい初心者フロー",
            zh: "温和初学者流",
            ko: "부드러운 초보자 플로우",
            ru: "Мягкий поток для начинающих",
            de: "Sanfter Anfängerflow",
            ar: "تدفق لطيف للمبتدئين",
            it: "Flusso dolce per principianti",
            pt: "Fluxo suave para iniciantes"
        ),
        description: LocalizedString(
            en: "A gentle introduction to yoga with basic poses and breathing",
            fr: "Une introduction douce au yoga avec des postures de base et la respiration",
            es: "Una introducción suave al yoga con posturas básicas y respiración",
            ja: "基本的なポーズと呼吸を含む優しいヨガ入門",
            zh: "温和的瑜伽入门，包括基本姿势和呼吸",
            ko: "기본 자세와 호흡을 포함한 부드러운 요가 입문",
            ru: "Мягкое введение в йогу с базовыми позами и дыханием",
            de: "Eine sanfte Einführung in Yoga mit grundlegenden Posen und Atmung",
            ar: "مقدمة لطيفة لليوغا مع الوضعيات الأساسية والتنفس",
            it: "Un'introduzione dolce allo yoga con pose di base e respirazione",
            pt: "Uma introdução suave ao yoga com posturas básicas e respiração"
        ),
        style: .hatha,
        poses: [
            deepBreathing,
            mountainPose,
            seatedCatCow,
            childsPose,
            corpse
        ],
        isFree: true
    )
    
    public static let morningEnergizer = WorkoutPlan(
        name: LocalizedString(
            en: "Morning Energizer",
            fr: "Énergisant matinal",
            es: "Energizante matutino",
            ja: "朝のエナジャイザー",
            zh: "晨间活力",
            ko: "아침 에너지",
            ru: "Утренний заряд",
            de: "Morgen-Energizer",
            ar: "منشط الصباح",
            it: "Energizzante mattutino",
            pt: "Energizante matinal"
        ),
        description: LocalizedString(
            en: "Wake up your body with flowing movements and sun salutations",
            fr: "Réveillez votre corps avec des mouvements fluides et des salutations au soleil",
            es: "Despierta tu cuerpo con movimientos fluidos y saludos al sol",
            ja: "流れるような動きと太陽礼拝で体を目覚めさせる",
            zh: "用流畅的动作和拜日式唤醒你的身体",
            ko: "유동적인 동작과 태양 인사로 몸을 깨우세요",
            ru: "Пробудите тело плавными движениями и приветствиями солнцу",
            de: "Wecken Sie Ihren Körper mit fließenden Bewegungen und Sonnengrüßen",
            ar: "أيقظ جسمك بحركات انسيابية وتحيات الشمس",
            it: "Risveglia il tuo corpo con movimenti fluidi e saluti al sole",
            pt: "Desperte seu corpo com movimentos fluidos e saudações ao sol"
        ),
        style: .vinyasa,
        poses: [
            mountainPose,
            downwardDog,
            cobrapose,
            downwardDog,
            mountainPose,
            childsPose
        ],
        isFree: true
    )
    
    public static let relaxationFlow = WorkoutPlan(
        name: LocalizedString(
            en: "Evening Relaxation",
            fr: "Relaxation du soir",
            es: "Relajación nocturna",
            ja: "夜のリラクゼーション",
            zh: "晚间放松",
            ko: "저녁 휴식",
            ru: "Вечерняя релаксация",
            de: "Abendentspannung",
            ar: "استرخاء المساء",
            it: "Rilassamento serale",
            pt: "Relaxamento noturno"
        ),
        description: LocalizedString(
            en: "Gentle stretches and calming poses to wind down your day",
            fr: "Étirements doux et postures calmantes pour terminer votre journée",
            es: "Estiramientos suaves y posturas calmantes para terminar tu día",
            ja: "1日を落ち着かせるための優しいストレッチと落ち着いたポーズ",
            zh: "温和的伸展和平静的姿势来结束你的一天",
            ko: "하루를 마무리하는 부드러운 스트레칭과 진정 자세",
            ru: "Мягкие растяжки и успокаивающие позы для завершения дня",
            de: "Sanfte Dehnungen und beruhigende Posen zum Ausklingen des Tages",
            ar: "تمددات لطيفة ووضعيات مهدئة لإنهاء يومك",
            it: "Allungamenti delicati e pose calmanti per concludere la giornata",
            pt: "Alongamentos suaves e posturas calmantes para terminar seu dia"
        ),
        style: .restorative,
        poses: [
            seatedForwardBend,
            childsPose,
            bridgePose,
            corpse
        ],
        isFree: true
    )
    
    public static let balanceFocus = WorkoutPlan(
        name: LocalizedString(
            en: "Balance & Stability",
            fr: "Équilibre et stabilité",
            es: "Equilibrio y estabilidad",
            ja: "バランスと安定性",
            zh: "平衡与稳定",
            ko: "균형과 안정성",
            ru: "Баланс и стабильность",
            de: "Balance und Stabilität",
            ar: "التوازن والاستقرار",
            it: "Equilibrio e stabilità",
            pt: "Equilíbrio e estabilidade"
        ),
        description: LocalizedString(
            en: "Build strength and focus with balancing poses",
            fr: "Développez la force et la concentration avec des postures d'équilibre",
            es: "Desarrolla fuerza y concentración con posturas de equilibrio",
            ja: "バランスポーズで筋力と集中力を養う",
            zh: "通过平衡姿势增强力量和专注力",
            ko: "균형 자세로 힘과 집중력을 기르세요",
            ru: "Развивайте силу и концентрацию с помощью балансирующих поз",
            de: "Bauen Sie Kraft und Fokus mit Balanceposen auf",
            ar: "بناء القوة والتركيز مع وضعيات التوازن",
            it: "Sviluppa forza e concentrazione con pose di equilibrio",
            pt: "Desenvolva força e foco com posturas de equilíbrio"
        ),
        style: .standingBalance,
        poses: [
            mountainPose,
            treePose,
            warriorI,
            warriorII,
            treePose,
            childsPose
        ],
        isFree: false
    )
    
    public static let strengthBuilder = WorkoutPlan(
        name: LocalizedString(
            en: "Strength Builder",
            fr: "Développement de force",
            es: "Constructor de fuerza",
            ja: "筋力ビルダー",
            zh: "力量塑造",
            ko: "근력 강화",
            ru: "Развитие силы",
            de: "Kraftaufbau",
            ar: "بناء القوة",
            it: "Costruttore di forza",
            pt: "Construtor de força"
        ),
        description: LocalizedString(
            en: "Dynamic flow to build muscle strength and endurance",
            fr: "Flux dynamique pour développer la force musculaire et l'endurance",
            es: "Flujo dinámico para desarrollar fuerza muscular y resistencia",
            ja: "筋力と持久力を養うダイナミックなフロー",
            zh: "动态流动以增强肌肉力量和耐力",
            ko: "근육 강도와 지구력을 키우는 역동적인 플로우",
            ru: "Динамичный поток для развития мышечной силы и выносливости",
            de: "Dynamischer Flow zum Aufbau von Muskelkraft und Ausdauer",
            ar: "تدفق ديناميكي لبناء قوة العضلات والتحمل",
            it: "Flusso dinamico per sviluppare forza muscolare e resistenza",
            pt: "Fluxo dinâmico para desenvolver força muscular e resistência"
        ),
        style: .power,
        poses: [
            mountainPose,
            downwardDog,
            warriorI,
            warriorII,
            downwardDog,
            cobrapose,
            childsPose,
            corpse
        ],
        isFree: false
    )
    
    public static let chairYogaSession = WorkoutPlan(
        name: LocalizedString(
            en: "Gentle Chair Yoga",
            fr: "Yoga doux sur chaise",
            es: "Yoga suave en silla",
            ja: "優しいチェアヨガ",
            zh: "温和椅子瑜伽",
            ko: "부드러운 의자 요가",
            ru: "Мягкая йога на стуле",
            de: "Sanftes Stuhl-Yoga",
            ar: "يوغا لطيفة على الكرسي",
            it: "Yoga dolce sulla sedia",
            pt: "Yoga suave na cadeira"
        ),
        description: LocalizedString(
            en: "Accessible yoga practice from the comfort of a chair",
            fr: "Pratique de yoga accessible depuis le confort d'une chaise",
            es: "Práctica de yoga accesible desde la comodidad de una silla",
            ja: "椅子の快適さから行えるアクセシブルなヨガ",
            zh: "在椅子上舒适地进行无障碍瑜伽练习",
            ko: "의자의 편안함에서 접근 가능한 요가 연습",
            ru: "Доступная практика йоги в комфорте стула",
            de: "Zugängliche Yoga-Praxis bequem auf einem Stuhl",
            ar: "ممارسة اليوغا سهلة الوصول من راحة الكرسي",
            it: "Pratica di yoga accessibile dal comfort di una sedia",
            pt: "Prática de yoga acessível no conforto de uma cadeira"
        ),
        style: .chairYoga,
        poses: [
            seatedCatCow,
            seatedForwardBend,
            seatedCatCow
        ],
        isFree: true
    )
    
    public static let pranayamaSession = WorkoutPlan(
        name: LocalizedString(
            en: "Breathing Practice",
            fr: "Pratique de la respiration",
            es: "Práctica de respiración",
            ja: "呼吸の練習",
            zh: "呼吸练习",
            ko: "호흡 연습",
            ru: "Практика дыхания",
            de: "Atempraxis",
            ar: "ممارسة التنفس",
            it: "Pratica della respirazione",
            pt: "Prática de respiração"
        ),
        description: LocalizedString(
            en: "Focus on breath control and mindful breathing techniques",
            fr: "Concentrez-vous sur le contrôle de la respiration et les techniques de respiration consciente",
            es: "Enfócate en el control de la respiración y técnicas de respiración consciente",
            ja: "呼吸コントロールとマインドフルな呼吸法に焦点を当てる",
            zh: "专注于呼吸控制和正念呼吸技巧",
            ko: "호흡 조절과 마음챙김 호흡 기술에 집중하세요",
            ru: "Сосредоточьтесь на контроле дыхания и осознанных дыхательных техниках",
            de: "Konzentrieren Sie sich auf Atemkontrolle und achtsame Atemtechniken",
            ar: "ركز على التحكم في التنفس وتقنيات التنفس الواعي",
            it: "Concentrati sul controllo del respiro e sulle tecniche di respirazione consapevole",
            pt: "Concentre-se no controle da respiração e técnicas de respiração consciente"
        ),
        style: .pranayama,
        poses: [
            deepBreathing,
            seatedCatCow,
            deepBreathing
        ],
        isFree: true
    )
    
    public static let yinSession = WorkoutPlan(
        name: LocalizedString(
            en: "Yin Deep Stretch",
            fr: "Étirement profond Yin",
            es: "Estiramiento profundo Yin",
            ja: "陰ヨガ深いストレッチ",
            zh: "阴瑜伽深度伸展",
            ko: "음 요가 깊은 스트레칭",
            ru: "Глубокая растяжка Инь",
            de: "Yin-Tiefendehnung",
            ar: "تمدد يين العميق",
            it: "Allungamento profondo Yin",
            pt: "Alongamento profundo Yin"
        ),
        description: LocalizedString(
            en: "Hold poses longer for deep connective tissue work",
            fr: "Maintenez les postures plus longtemps pour un travail profond des tissus conjonctifs",
            es: "Mantén las posturas por más tiempo para un trabajo profundo del tejido conectivo",
            ja: "深い結合組織の働きのためにポーズを長く保持する",
            zh: "更长时间保持姿势以深度工作结缔组织",
            ko: "깊은 결합 조직 작업을 위해 자세를 더 오래 유지하세요",
            ru: "Держите позы дольше для глубокой работы с соединительной тканью",
            de: "Halten Sie Posen länger für tiefe Bindegewebsarbeit",
            ar: "احتفظ بالوضعيات لفترة أطول لعمل عميق على الأنسجة الضامة",
            it: "Mantieni le pose più a lungo per un lavoro profondo sul tessuto connettivo",
            pt: "Mantenha as posturas por mais tempo para trabalho profundo do tecido conjuntivo"
        ),
        style: .yin,
        poses: [
            seatedForwardBend,
            childsPose,
            bridgePose,
            corpse
        ],
        isFree: false
    )
    
    // MARK: - Catalog Helpers
    
    /// All available workout plans.
    public static let allPlans: [WorkoutPlan] = [
        beginnerFlow,
        morningEnergizer,
        relaxationFlow,
        balanceFocus,
        strengthBuilder,
        chairYogaSession,
        pranayamaSession,
        yinSession
    ]
    
    /// Get all plans for a specific style.
    public static func plans(for style: YogaStyle) -> [WorkoutPlan] {
        allPlans.filter { $0.style == style }
    }
    
    /// Get the count of plans for a specific style.
    public static func planCount(for style: YogaStyle) -> Int {
        plans(for: style).count
    }
    
    /// Get a plan by ID.
    public static func plan(withID id: UUID) -> WorkoutPlan? {
        allPlans.first { $0.id == id }
    }
}
