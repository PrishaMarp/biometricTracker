//
//  ContentView.swift
//  biometricTracker
//
//  Created by Prisha Marpu on 4/9/26.
//

import SwiftUI

struct ContentView: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 20) {

            // ── Score bar ──────────────────────────────────────────
            HStack(spacing: 0) {
                ScoreTile(label: "Score",   value: "\(appModel.mathManager.score)",        color: .blue)
                Divider().frame(height: 40)
                ScoreTile(label: "Correct", value: "\(appModel.mathManager.correctCount)",  color: .green)
                Divider().frame(height: 40)
                ScoreTile(label: "Wrong",   value: "\(appModel.mathManager.wrongCount)",    color: .red)
                Divider().frame(height: 40)
                ScoreTile(label: "Total",   value: "\(appModel.mathManager.totalAnswered)", color: .primary)
            }
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

            // ── Level badge ────────────────────────────────────────
            Text(appModel.mathManager.currentLevel.title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 16).padding(.vertical, 6)
                .background(levelColor.opacity(0.15), in: Capsule())
                .foregroundStyle(levelColor)

            // ── Question ───────────────────────────────────────────
            Text(appModel.mathManager.current.question)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.vertical, 28)
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))

            // ── Feedback ───────────────────────────────────────────
            Group {
                if let result = appModel.mathManager.lastCorrect {
                    Text(result ? "✓ Correct!" : "✗ Wrong")
                        .font(.title2.bold())
                        .foregroundStyle(result ? .green : .red)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text(" ").font(.title2)
                }
            }
            .animation(.spring(duration: 0.3), value: appModel.mathManager.lastCorrect)

            // ── Answer grid ────────────────────────────────────────
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 14
            ) {
                ForEach(
                    Array(appModel.mathManager.current.answers.enumerated()),
                    id: \.offset
                ) { i, answer in
                    AnswerTile(
                        label:  answer,
                        state:  tileState(for: i),
                        action: { appModel.mathManager.submit(answerIndex: i) }
                    )
                }
            }

            // ── Log panel ──────────────────────────────────────────
            LogPanel(
                entries: appModel.mathManager.log,
                trials:  appModel.mathManager.trial.events
            )

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }

    private var levelColor: Color {
        switch appModel.mathManager.currentLevel {
        case .easy:   return .green
        case .medium: return .orange
        case .hard:   return .red
        }
    }

    private func tileState(for index: Int) -> AnswerTile.State {
        guard let result = appModel.mathManager.lastCorrect else { return .idle }
        if index == appModel.mathManager.current.correctIndex       { return .correct }
        if index == appModel.mathManager.lastAnsweredIndex && !result { return .wrong  }
        return .idle
    }
}

// MARK: - Score tile
struct ScoreTile: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
    }
}

// MARK: - Answer tile
struct AnswerTile: View {
    enum State { case idle, correct, wrong }

    let label:  String
    let state:  State
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(bgColor, in: RoundedRectangle(cornerRadius: 18))
                .foregroundStyle(fgColor)
        }
        .buttonStyle(.plain)
        .disabled(state != .idle)
    }

    private var bgColor: Color {
        switch state {
        case .idle:    return Color.blue.opacity(0.12)
        case .correct: return Color.green.opacity(0.85)
        case .wrong:   return Color.red.opacity(0.85)
        }
    }

    private var fgColor: Color {
        switch state {
        case .idle:             return .primary
        case .correct, .wrong:  return .white
        }
    }
}

// MARK: - Log panel
struct LogPanel: View {
    let entries: [LogEntry]
    let trials:  [TrialEvent]
    @State private var exportMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text("Event Log (\(entries.count) entries)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Export CSV") {
                    if let url = LogExporter.saveCombined(entries: entries, trials: trials) {
                        exportMessage = "✅ \(url.lastPathComponent)"
                    } else {
                        exportMessage = "❌ Export failed"
                    }
                }
                .font(.caption)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.green.opacity(0.15), in: Capsule())
            }

            if !exportMessage.isEmpty {
                Text(exportMessage)
                    .font(.caption2)
                    .foregroundStyle(.green)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(entries.suffix(12).reversed()) { entry in
                        HStack(alignment: .top, spacing: 6) {
                            Circle()
                                .fill(dotColor(for: entry.eventType))
                                .frame(width: 6, height: 6)
                                .padding(.top, 3)
                            Text(entry.formatted)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(logColor(for: entry.message))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .frame(maxHeight: 160)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func dotColor(for eventType: String) -> Color {
        switch eventType {
        case "answer_selected":  return .blue
        case "new_question":     return .orange
        case "gaze_on_answer":   return .cyan
        case "gaze_coordinates": return .purple
        case "gaze_idle":        return .gray
        case "level_change":     return .pink
        case "session_start":    return .gray
        default:                 return .secondary
        }
    }

    private func logColor(for message: String) -> Color {
        if message.contains("✓")          { return .green              }
        if message.contains("✗")          { return .red                }
        if message.contains("GAZE ON")    { return .cyan               }
        if message.contains("GAZE COORD") { return .blue.opacity(0.7)  }
        if message.contains("GAZE IDLE")  { return .gray               }
        if message.contains("NEW QUEST")  { return .orange             }
        if message.contains("LEVEL")      { return .pink               }
        return .secondary
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
