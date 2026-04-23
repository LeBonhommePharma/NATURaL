import SwiftUI
import BonhommeCore

/// Detail view showing all workout plans for a specific yoga style.
struct StyleDetailView: View {
    let style: YogaStyle
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Style header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        Image(systemName: style.symbolName)
                            .font(.system(size: 48))
                            .foregroundStyle(Color(hue: style.accentHue, saturation: 0.6, brightness: 0.8))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(style.localizedName.localized)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            
                            Text(styleDescription)
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Workout plans for this style
                let plans = PoseCatalog.plans(for: style)
                
                if plans.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.yoga")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text(LocalizedString(
                            en: "No plans available yet",
                            fr: "Aucun programme disponible pour le moment",
                            es: "No hay planes disponibles aún",
                            ja: "まだプランはありません",
                            zh: "暂无可用计划",
                            ko: "아직 사용 가능한 플랜이 없습니다",
                            ru: "Пока нет доступных планов",
                            de: "Noch keine Pläne verfügbar",
                            ar: "لا توجد خطط متاحة بعد",
                            it: "Nessun piano disponibile al momento",
                            pt: "Nenhum plano disponível ainda"
                        ).localized)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(LocalizedString(
                            en: "Check back soon for new workouts",
                            fr: "Revenez bientôt pour de nouveaux entraînements",
                            es: "Vuelve pronto para nuevos entrenamientos",
                            ja: "新しいワークアウトをお楽しみに",
                            zh: "请稍后查看新的锻炼",
                            ko: "새로운 운동을 곧 확인하세요",
                            ru: "Скоро появятся новые тренировки",
                            de: "Schauen Sie bald nach neuen Workouts",
                            ar: "تحقق قريباً من التمارين الجديدة",
                            it: "Torna presto per nuovi allenamenti",
                            pt: "Volte em breve para novos treinos"
                        ).localized)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    VStack(spacing: 16) {
                        ForEach(plans) { plan in
                            planCard(plan: plan)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(style.localizedName.localized)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func planCard(plan: WorkoutPlan) -> some View {
        NavigationLink {
            if !plan.isFree && !appState.isPremium {
                PaywallView()
            } else {
                WorkoutFlowView(plan: plan)
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plan.name.localized)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text(plan.description.localized)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    
                    Spacer()
                    
                    if !plan.isFree {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 16))
                    }
                }
                
                HStack(spacing: 16) {
                    Label("\(plan.poseCount) poses", systemImage: "list.number")
                    Label(formattedDuration(plan.totalDuration), systemImage: "clock")
                }
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                
                // Start button
                HStack {
                    Text(LocalizedString(
                        en: "Start Workout",
                        fr: "Commencer",
                        es: "Comenzar entrenamiento",
                        ja: "ワークアウト開始",
                        zh: "开始锻炼",
                        ko: "운동 시작",
                        ru: "Начать тренировку",
                        de: "Training starten",
                        ar: "ابدأ التمرين",
                        it: "Inizia allenamento",
                        pt: "Iniciar treino"
                    ).localized)
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Color(hue: style.accentHue, saturation: 0.6, brightness: 0.8),
                    in: RoundedRectangle(cornerRadius: 12)
                )
            }
            .padding()
            .background(
                Color(hue: style.accentHue, saturation: 0.1, brightness: 0.97),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        Color(hue: style.accentHue, saturation: 0.3, brightness: 0.8).opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var styleDescription: String {
        switch style {
        case .pranayama:
            return LocalizedString(
                en: "Breathing exercises to calm the mind and energize the body",
                fr: "Exercices de respiration pour calmer l'esprit et énergiser le corps",
                es: "Ejercicios de respiración para calmar la mente y energizar el cuerpo",
                ja: "心を落ち着かせ体を活性化する呼吸法",
                zh: "呼吸练习以平静心灵和激活身体",
                ko: "마음을 진정시키고 몸을 활성화하는 호흡 운동",
                ru: "Дыхательные упражнения для успокоения ума и энергизации тела",
                de: "Atemübungen zur Beruhigung des Geistes und Energetisierung des Körpers",
                ar: "تمارين التنفس لتهدئة العقل وتنشيط الجسم",
                it: "Esercizi di respirazione per calmare la mente e energizzare il corpo",
                pt: "Exercícios de respiração para acalmar a mente e energizar o corpo"
            ).localized
        case .chairYoga:
            return LocalizedString(
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
            ).localized
        case .vinyasa:
            return LocalizedString(
                en: "Dynamic flow linking breath with movement",
                fr: "Flux dynamique reliant la respiration au mouvement",
                es: "Flujo dinámico que vincula la respiración con el movimiento",
                ja: "呼吸と動きを結びつけるダイナミックなフロー",
                zh: "将呼吸与动作联系起来的动态流动",
                ko: "호흡과 동작을 연결하는 역동적인 플로우",
                ru: "Динамичный поток, связывающий дыхание с движением",
                de: "Dynamischer Flow, der Atem mit Bewegung verbindet",
                ar: "تدفق ديناميكي يربط التنفس بالحركة",
                it: "Flusso dinamico che collega il respiro al movimento",
                pt: "Fluxo dinâmico que conecta respiração e movimento"
            ).localized
        case .hatha:
            return LocalizedString(
                en: "Traditional yoga focusing on physical postures and breathing",
                fr: "Yoga traditionnel axé sur les postures physiques et la respiration",
                es: "Yoga tradicional centrado en posturas físicas y respiración",
                ja: "身体的な姿勢と呼吸に焦点を当てた伝統的なヨガ",
                zh: "专注于身体姿势和呼吸的传统瑜伽",
                ko: "신체 자세와 호흡에 집중하는 전통 요가",
                ru: "Традиционная йога с акцентом на физические позы и дыхание",
                de: "Traditionelles Yoga mit Fokus auf körperliche Haltungen und Atmung",
                ar: "اليوغا التقليدية التي تركز على الوضعيات الجسدية والتنفس",
                it: "Yoga tradizionale incentrato su posture fisiche e respirazione",
                pt: "Yoga tradicional focado em posturas físicas e respiração"
            ).localized
        case .yin:
            return LocalizedString(
                en: "Slow-paced practice with longer holds for deep stretching",
                fr: "Pratique lente avec des maintiens plus longs pour un étirement profond",
                es: "Práctica de ritmo lento con mantenimientos más largos para estiramientos profundos",
                ja: "深いストレッチのための長い保持を伴うゆっくりしたペースの練習",
                zh: "缓慢节奏的练习，更长时间的保持以进行深度伸展",
                ko: "깊은 스트레칭을 위한 더 긴 유지 시간의 느린 속도 연습",
                ru: "Медленная практика с более длительными удержаниями для глубокой растяжки",
                de: "Langsame Praxis mit längeren Haltungen für tiefes Dehnen",
                ar: "ممارسة بطيئة مع استمرارات أطول للتمدد العميق",
                it: "Pratica lenta con mantenimenti più lunghi per allungamenti profondi",
                pt: "Prática de ritmo lento com retenções mais longas para alongamento profundo"
            ).localized
        case .restorative:
            return LocalizedString(
                en: "Gentle poses to relax and restore the body",
                fr: "Postures douces pour relaxer et restaurer le corps",
                es: "Posturas suaves para relajar y restaurar el cuerpo",
                ja: "体をリラックスさせ回復させるための優しいポーズ",
                zh: "温和的姿势以放松和恢复身体",
                ko: "몸을 편안하게 하고 회복시키는 부드러운 자세",
                ru: "Мягкие позы для расслабления и восстановления тела",
                de: "Sanfte Posen zum Entspannen und Wiederherstellen des Körpers",
                ar: "وضعيات لطيفة للاسترخاء واستعادة الجسم",
                it: "Pose delicate per rilassare e ripristinare il corpo",
                pt: "Posturas suaves para relaxar e restaurar o corpo"
            ).localized
        case .power:
            return LocalizedString(
                en: "Vigorous workout building strength and stamina",
                fr: "Entraînement vigoureux développant force et endurance",
                es: "Entrenamiento vigoroso que desarrolla fuerza y resistencia",
                ja: "力と持久力を養う活発なワークアウト",
                zh: "强力的锻炼以增强力量和耐力",
                ko: "힘과 체력을 키우는 강력한 운동",
                ru: "Энергичная тренировка для развития силы и выносливости",
                de: "Intensives Training zum Aufbau von Kraft und Ausdauer",
                ar: "تمرين قوي لبناء القوة والقدرة على التحمل",
                it: "Allenamento vigoroso che sviluppa forza e resistenza",
                pt: "Treino vigoroso que desenvolve força e resistência"
            ).localized
        case .standingBalance:
            return LocalizedString(
                en: "Focus on balance and stability with standing poses",
                fr: "Concentration sur l'équilibre et la stabilité avec des postures debout",
                es: "Enfócate en el equilibrio y la estabilidad con posturas de pie",
                ja: "立位ポーズでバランスと安定性に焦点を当てる",
                zh: "通过站立姿势专注于平衡和稳定性",
                ko: "서 있는 자세로 균형과 안정성에 집중",
                ru: "Сосредоточьтесь на балансе и стабильности со стоячими позами",
                de: "Fokus auf Balance und Stabilität mit stehenden Posen",
                ar: "التركيز على التوازن والاستقرار مع الوضعيات الواقفة",
                it: "Concentrati sull'equilibrio e sulla stabilità con pose in piedi",
                pt: "Foque no equilíbrio e estabilidade com posturas em pé"
            ).localized
        case .prenatal:
            return LocalizedString(
                en: "Safe and gentle practice designed for pregnancy",
                fr: "Pratique sûre et douce conçue pour la grossesse",
                es: "Práctica segura y suave diseñada para el embarazo",
                ja: "妊娠のために設計された安全で優しい練習",
                zh: "为怀孕设计的安全温和的练习",
                ko: "임신을 위해 설계된 안전하고 부드러운 연습",
                ru: "Безопасная и мягкая практика, разработанная для беременности",
                de: "Sichere und sanfte Praxis für die Schwangerschaft",
                ar: "ممارسة آمنة ولطيفة مصممة للحمل",
                it: "Pratica sicura e delicata progettata per la gravidanza",
                pt: "Prática segura e suave projetada para gravidez"
            ).localized
        }
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}
