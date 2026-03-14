import Foundation

/// Built-in chair yoga pose library bundled with the app.
public enum PoseCatalog {
    public static let allPoses: [Pose] = [
        Pose(
            id: "seated-mountain",
            name: "Seated Mountain",
            description: "Sit tall with feet flat on the floor, hands on thighs. Lengthen your spine and relax your shoulders.",
            durationSeconds: 30,
            difficulty: .beginner,
            imageName: "pose.seated.mountain",
            voiceCueText: "Sit tall in Seated Mountain pose. Feel your spine lengthen with each breath.",
            modifications: ["Place a cushion behind your lower back for support"],
            isFree: true
        ),
        Pose(
            id: "seated-cat-cow",
            name: "Seated Cat-Cow",
            description: "Hands on knees, alternate between arching and rounding your spine with each breath.",
            durationSeconds: 45,
            difficulty: .beginner,
            imageName: "pose.seated.cat.cow",
            voiceCueText: "Inhale, arch your back for cow. Exhale, round your spine for cat.",
            modifications: ["Reduce range of motion if you feel discomfort"],
            isFree: true
        ),
        Pose(
            id: "seated-twist",
            name: "Seated Spinal Twist",
            description: "Place your right hand on your left knee and gently twist to the left. Hold, then switch sides.",
            durationSeconds: 30,
            difficulty: .beginner,
            imageName: "pose.seated.twist",
            voiceCueText: "Gently twist to the left. Keep your spine tall as you rotate.",
            modifications: ["Use the chair back for support", "Twist only as far as comfortable"],
            isFree: true
        ),
        Pose(
            id: "seated-forward-fold",
            name: "Seated Forward Fold",
            description: "Hinge at the hips and fold forward over your legs, letting your arms hang toward the floor.",
            durationSeconds: 30,
            difficulty: .beginner,
            imageName: "pose.seated.forward.fold",
            voiceCueText: "Fold forward gently. Let gravity do the work. Breathe deeply.",
            modifications: ["Place a pillow on your lap to fold onto", "Bend knees more if needed"],
            isFree: true
        ),
        Pose(
            id: "seated-eagle-arms",
            name: "Seated Eagle Arms",
            description: "Cross your right arm under your left, bend elbows and press palms together. Lift elbows to shoulder height.",
            durationSeconds: 30,
            difficulty: .beginner,
            imageName: "pose.seated.eagle.arms",
            voiceCueText: "Cross your arms into Eagle. Lift your elbows and breathe into the space between your shoulders.",
            modifications: ["Simply hug yourself if wrapping arms is difficult"],
            isFree: true
        ),
        Pose(
            id: "seated-pigeon",
            name: "Seated Pigeon",
            description: "Cross your right ankle over your left knee. Gently press the right knee down. Switch sides.",
            durationSeconds: 45,
            difficulty: .intermediate,
            imageName: "pose.seated.pigeon",
            voiceCueText: "Place your ankle on the opposite knee for Seated Pigeon. Feel the stretch in your hip.",
            modifications: ["Keep the top foot flexed to protect your knee"],
            isFree: false
        ),
        Pose(
            id: "seated-warrior",
            name: "Seated Warrior II",
            description: "Sit sideways on the chair, extend one leg back. Open arms wide to the sides.",
            durationSeconds: 45,
            difficulty: .intermediate,
            imageName: "pose.seated.warrior",
            voiceCueText: "Open into Warrior Two. Gaze over your front hand. Feel strong and grounded.",
            modifications: ["Keep both feet on the floor for balance"],
            isFree: false
        ),
        Pose(
            id: "seated-side-bend",
            name: "Seated Side Bend",
            description: "Raise one arm overhead and lean to the opposite side, stretching the side body.",
            durationSeconds: 30,
            difficulty: .intermediate,
            imageName: "pose.seated.side.bend",
            voiceCueText: "Reach up and over for a side bend. Breathe into the stretch along your ribcage.",
            modifications: ["Rest the lower hand on the chair seat for support"],
            isFree: false
        ),
        Pose(
            id: "seated-backbend",
            name: "Seated Heart Opener",
            description: "Place hands on the chair back, gently press your chest forward and up, opening the front body.",
            durationSeconds: 30,
            difficulty: .intermediate,
            imageName: "pose.seated.backbend",
            voiceCueText: "Open your heart forward. Draw your shoulders back and breathe expansively.",
            modifications: ["Keep the movement gentle — stop if you feel lower back compression"],
            isFree: false
        ),
        Pose(
            id: "seated-meditation",
            name: "Seated Meditation",
            description: "Close your eyes, rest hands on your lap, and focus on slow, deep breathing.",
            durationSeconds: 60,
            difficulty: .beginner,
            imageName: "pose.seated.meditation",
            voiceCueText: "Close your eyes. Breathe naturally. Let each exhale release tension.",
            modifications: ["Keep eyes slightly open if closing them feels uncomfortable"],
            isFree: true
        ),
    ]

    /// The free-tier beginner session.
    public static let beginnerFlow = WorkoutPlan(
        id: "beginner-chair-flow",
        name: "Gentle Chair Flow",
        description: "A calming 5-minute sequence perfect for beginners or a quick break.",
        poses: allPoses.filter { $0.isFree },
        transitionSeconds: 5,
        isFree: true
    )

    /// A full-length intermediate session (premium).
    public static let intermediateFlow = WorkoutPlan(
        id: "intermediate-chair-flow",
        name: "Energizing Chair Yoga",
        description: "A 10-minute flow combining breath, movement, and gentle strength building.",
        poses: allPoses,
        transitionSeconds: 5,
        isFree: false
    )
}
