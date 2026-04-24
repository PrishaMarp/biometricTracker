//
//  LogExporter.swift
//  biometricTracker
//
//  Created by Prisha Marpu on 4/23/26.
//



import Foundation

struct LogExporter {

    // MARK: - Parse event type
    static func parseEventType(from message: String) -> String {
        if message.hasPrefix("ANSWER SELECTED") { return "answer_selected"  }
        if message.hasPrefix("NEW QUESTION")    { return "new_question"     }
        if message.hasPrefix("GAZE ON ANSWER")  { return "gaze_on_answer"   }
        if message.hasPrefix("GAZE COORDINATES"){ return "gaze_coordinates" }
        if message.hasPrefix("GAZE IDLE")       { return "gaze_idle"        }
        if message.hasPrefix("LEVEL CHANGE")    { return "level_change"     }
        if message.hasPrefix("SESSION START")   { return "session_start"    }
        return "other"
    }

    // MARK: - Combined CSV (event log + trial data)
    static func toCombinedCSV(entries: [LogEntry], trials: [TrialEvent]) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var lines: [String] = []

        // Section 1 — event log
        lines.append("=== EVENT LOG ===")
        lines.append("timestamp_iso,timestamp_unix,event_type,detail")
        for entry in entries {
            let unix   = entry.timestamp.timeIntervalSince1970
            let type   = parseEventType(from: entry.message)
            let detail = entry.message
                .replacingOccurrences(of: ",", with: ";")
                .replacingOccurrences(of: "\"", with: "'")
            lines.append("\"\(iso.string(from: entry.timestamp))\",\(unix),\"\(type)\",\"\(detail)\"")
        }

        // Section 2 — trial reaction times
        lines.append("")
        lines.append("=== TRIAL DATA ===")
        lines.append(TrialEvent.csvHeader)
        for trial in trials {
            lines.append(trial.csvRow)
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Save to Documents directory
    static func saveCombined(entries: [LogEntry], trials: [TrialEvent]) -> URL? {
        let content   = toCombinedCSV(entries: entries, trials: trials)
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename  = "mathvision_\(timestamp).csv"
        let url       = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            print("✅ Saved: \(url.path)")
            return url
        } catch {
            print("❌ Export failed: \(error)")
            return nil
        }
    }
}
