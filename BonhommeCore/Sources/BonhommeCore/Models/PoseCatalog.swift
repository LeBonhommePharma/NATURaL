import Foundation

/// Central pose and workout plan registry aggregating all yoga styles.
///
/// Each style contributes its poses and plans via extensions in dedicated files
/// (PoseCatalog+ChairYoga.swift, PoseCatalog+Vinyasa.swift, etc.).
public enum PoseCatalog {

    // MARK: - Aggregated Collections

    public static let allPoses: [Pose] =
        chairYogaPoses + vinyasaPoses + hathaPoses + yinPoses +
        restorativePoses + powerPoses + standingBalancePoses +
        prenatalPoses + pranayamaPoses

    public static let allPlans: [WorkoutPlan] =
        chairYogaPlans + vinyasaPlans + hathaPlans + yinPlans +
        restorativePlans + powerPlans + standingBalancePlans +
        prenatalPlans + pranayamaPlans

    public static let freePoses: [Pose] = allPoses.filter(\.isFree)
    public static let premiumPoses: [Pose] = allPoses.filter { !$0.isFree }

    // MARK: - Style Filtering

    /// All plans for a given yoga style.
    public static func plans(for style: YogaStyle) -> [WorkoutPlan] {
        allPlans.filter { $0.style == style }
    }

    /// Number of plans for a given style.
    public static func planCount(for style: YogaStyle) -> Int {
        plans(for: style).count
    }
}
