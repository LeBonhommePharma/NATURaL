// Bonhomme/Features/Workout/YouTubeProgramPickerView.swift
#if canImport(UIKit)
import SwiftUI
import BonhommeCore

struct YouTubeProgramPickerView: View {

    @State private var selectedProgram: YouTubeWorkoutProgram?
    @State private var isPresenting = false

    var body: some View {
        List(YouTubeProgramCatalog.programs) { program in
            Button {
                selectedProgram = program
                isPresenting = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.title).font(.headline)
                    Text(program.programDescription).font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Label(program.expectedDuration.formattedMinutes, systemImage: "clock").font(.caption2)
                        Label("\(program.phases.count) phases", systemImage: "waveform").font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("YouTube Programs")
        .fullScreenCover(isPresented: $isPresenting) {
            if let p = selectedProgram { YouTubeWorkoutScreen(program: p) }
        }
    }
}

private extension TimeInterval {
    var formattedMinutes: String { "\(Int(self / 60)) min" }
}
#endif
