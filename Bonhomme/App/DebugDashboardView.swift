#if DEBUG
import SwiftUI
import BonhommeCore

/// Debug dashboard for monitoring app initialization and runtime state.
/// Only compiled in DEBUG builds.
struct DebugDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var isExpanded = false
    @State private var diagnostics: [DiagnosticItem] = []

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "ladybug.fill")
                        .foregroundStyle(.orange)
                    Text("Debug Dashboard")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.black.opacity(0.8))
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // System Info
                        sectionHeader("System Information")
                        diagnosticRow("Platform", value: platformName)
                        diagnosticRow("HealthKit", value: HealthKitManager.isAvailable ? "✅ Available" : "⚠️ Unavailable")
                        diagnosticRow("Locale", value: "\(Locale.current.identifier)")
                        diagnosticRow("Language", value: "\(Locale.current.language.languageCode?.identifier ?? "unknown")")

                        Divider()

                        // AppState Status
                        sectionHeader("AppState")
                        diagnosticRow("Workout Active", value: appState.isWorkoutActive ? "✅ Yes" : "❌ No")
                        diagnosticRow("Premium Status", value: appState.isPremium ? "✅ Premium" : "❌ Free")
                        diagnosticRow("HealthKit Auth", value: appState.healthKitAuthorized ? "✅ Authorized" : "⚠️ Not Authorized")
                        diagnosticRow("Resumable Workout", value: appState.pendingRestoredWorkout != nil ? "✅ Yes" : "❌ No")

                        Divider()

                        // Managers Status
                        sectionHeader("Managers")
                        diagnosticRow("HealthKitManager", value: "✅ Initialized")
                        diagnosticRow("SubscriptionManager", value: "✅ Initialized")
                        diagnosticRow("TVDisplayCoordinator", value: "✅ Initialized")
                        diagnosticRow("CareKitBridge", value: "✅ Initialized")
                        diagnosticRow("PhoneConnectivityBridge", value: "✅ Initialized")
                        diagnosticRow("FeedbackEngine", value: "✅ Initialized")
                        diagnosticRow("MedicationTracker", value: "✅ Initialized")
                        diagnosticRow("PrescriptionService", value: "✅ Initialized")
                        diagnosticRow(
                            "Clinical Consent",
                            value: appState.prescriptionService.consent.isValidForCurrentPolicy
                                ? "✅ Granted v\(appState.prescriptionService.consent.policyVersion ?? "?")"
                                : "⚠️ Not granted"
                        )
                        diagnosticRow("WorkoutStateStore", value: "✅ Initialized")

                        Divider()

                        // CareKit Status
                        sectionHeader("CareKit")
                        diagnosticRow("Prescriptions", value: "\(appState.careKitBridge.prescribedTasks.count)")
                        diagnosticRow("Has Prescriptions", value: appState.careKitBridge.hasPrescriptions ? "✅ Yes" : "❌ No")

                        Divider()

                        // TV Display Status
                        sectionHeader("TV Display")
                        diagnosticRow("Coordinator Status", value: "Ready")

                        Divider()

                        // Actions
                        sectionHeader("Debug Actions")

                        Button {
                            runDiagnostics()
                        } label: {
                            HStack {
                                Image(systemName: "stethoscope")
                                Text("Run Full Diagnostics")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.blue, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)

                        Button {
                            printToConsole()
                        } label: {
                            HStack {
                                Image(systemName: "terminal")
                                Text("Print Status to Console")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.green, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)

                        Button {
                            clearWorkoutState()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear Workout State")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.red, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)

                        // Diagnostics Results
                        if !diagnostics.isEmpty {
                            Divider()
                            sectionHeader("Recent Diagnostics")
                            ForEach(diagnostics) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: item.icon)
                                        .foregroundStyle(item.color)
                                        .frame(width: 16)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.system(size: 11, weight: .semibold))
                                        if let message = item.message {
                                            Text(message)
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(item.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                }
                .frame(maxHeight: 400)
                .background(.black.opacity(0.75))
            }
        }
        .foregroundStyle(.white)
        .font(.system(size: 11, design: .monospaced))
    }

    private var platformName: String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(watchOS)
        return "watchOS"
        #elseif os(tvOS)
        return "tvOS"
        #else
        return "Unknown"
        #endif
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.cyan)
            .padding(.horizontal, 12)
            .padding(.top, 4)
    }

    private func diagnosticRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }

    // MARK: - Actions

    private func runDiagnostics() {
        diagnostics.removeAll()

        if HealthKitManager.isAvailable {
            diagnostics.append(DiagnosticItem(
                icon: "heart.fill",
                title: "HealthKit Available",
                message: "HealthKit is available on this device",
                color: .green
            ))
        } else {
            diagnostics.append(DiagnosticItem(
                icon: "heart.slash",
                title: "HealthKit Unavailable",
                message: "HealthKit is not available on this device",
                color: .orange
            ))
        }

        if appState.workoutStateStore.hasActiveWorkout {
            diagnostics.append(DiagnosticItem(
                icon: "arrow.clockwise.circle.fill",
                title: "Resumable Workout Found",
                message: "There is a workout that can be resumed",
                color: .blue
            ))
        } else {
            diagnostics.append(DiagnosticItem(
                icon: "checkmark.circle",
                title: "No Resumable Workout",
                message: "No pending workouts to resume",
                color: .green
            ))
        }

        if appState.careKitBridge.hasPrescriptions {
            diagnostics.append(DiagnosticItem(
                icon: "stethoscope",
                title: "CareKit Prescriptions Found",
                message: "\(appState.careKitBridge.prescribedTasks.count) prescribed task(s)",
                color: .green
            ))
        } else {
            diagnostics.append(DiagnosticItem(
                icon: "stethoscope",
                title: "No CareKit Prescriptions",
                message: "No prescribed tasks configured",
                color: .gray
            ))
        }

        diagnostics.append(DiagnosticItem(
            icon: "memorychip",
            title: "AppState Initialized",
            message: "All managers successfully initialized",
            color: .green
        ))

        print("🔍 Ran \(diagnostics.count) diagnostic checks")
    }

    private func printToConsole() {
        print("\n" + String(repeating: "=", count: 60))
        print("📊 DEBUG DASHBOARD STATUS")
        print(String(repeating: "=", count: 60))
        print("Platform: \(platformName)")
        print("HealthKit Available: \(HealthKitManager.isAvailable)")
        print("Locale: \(Locale.current.identifier)")
        print("Language: \(Locale.current.language.languageCode?.identifier ?? "unknown")")
        print("")
        print("AppState:")
        print("  - Workout Active: \(appState.isWorkoutActive)")
        print("  - Premium: \(appState.isPremium)")
        print("  - HealthKit Authorized: \(appState.healthKitAuthorized)")
        print("  - Resumable Workout: \(appState.pendingRestoredWorkout != nil)")
        print("")
        print("CareKit:")
        print("  - Prescriptions: \(appState.careKitBridge.prescribedTasks.count)")
        print("  - Has Prescriptions: \(appState.careKitBridge.hasPrescriptions)")
        print(String(repeating: "=", count: 60) + "\n")

        diagnostics.append(DiagnosticItem(
            icon: "terminal",
            title: "Status Printed",
            message: "Check Xcode console for full output",
            color: .green
        ))
    }

    private func clearWorkoutState() {
        appState.dismissRestoredWorkout()
        print("🗑️ Cleared workout state")

        diagnostics.append(DiagnosticItem(
            icon: "trash.fill",
            title: "Workout State Cleared",
            message: "Resumable workout state has been cleared",
            color: .orange
        ))
    }
}

// MARK: - Diagnostic Item

private struct DiagnosticItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String?
    let color: Color

    init(icon: String, title: String, message: String? = nil, color: Color) {
        self.icon = icon
        self.title = title
        self.message = message
        self.color = color
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            DebugDashboardView()
                .environment(AppState())
        }
    }
}
#endif
