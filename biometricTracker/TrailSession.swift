//
//  TrailSession.swift
//  biometricTracker
//
//  Created by Prisha Marpu on 4/23/26.
//

import Foundation
import Combine
import simd
import QuartzCore

struct TrialEvent: Codable {
    let trialIndex:        Int
    let spawnTimestamp:    TimeInterval
    let responseTimestamp: TimeInterval
    let reactionTimeMs:    Double
    let reactionTimeMsCorrected: Double
    let dotPosition:       SIMD3<Float>
    let responded:         Bool

    enum CodingKeys: String, CodingKey {
        case trialIndex, spawnTimestamp, responseTimestamp
        case reactionTimeMs, reactionTimeMsCorrected
        case dotPosX, dotPosY, dotPosZ, responded
    }

    static let pinchLatencyMs: Double = 100.0

    init(trialIndex: Int, spawnTimestamp: TimeInterval,
         responseTimestamp: TimeInterval, dotPosition: SIMD3<Float>,
         responded: Bool) {
        self.trialIndex        = trialIndex
        self.spawnTimestamp    = spawnTimestamp
        self.responseTimestamp = responseTimestamp
        self.reactionTimeMs    = (responseTimestamp - spawnTimestamp) * 1000.0
        self.reactionTimeMsCorrected = responded
            ? max(0, self.reactionTimeMs - Self.pinchLatencyMs)
            : self.reactionTimeMs
        self.dotPosition = dotPosition
        self.responded   = responded
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(trialIndex,               forKey: .trialIndex)
        try c.encode(spawnTimestamp,           forKey: .spawnTimestamp)
        try c.encode(responseTimestamp,        forKey: .responseTimestamp)
        try c.encode(reactionTimeMs,           forKey: .reactionTimeMs)
        try c.encode(reactionTimeMsCorrected,  forKey: .reactionTimeMsCorrected)
        try c.encode(dotPosition.x,            forKey: .dotPosX)
        try c.encode(dotPosition.y,            forKey: .dotPosY)
        try c.encode(dotPosition.z,            forKey: .dotPosZ)
        try c.encode(responded,                forKey: .responded)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        trialIndex               = try c.decode(Int.self,          forKey: .trialIndex)
        spawnTimestamp           = try c.decode(TimeInterval.self, forKey: .spawnTimestamp)
        responseTimestamp        = try c.decode(TimeInterval.self, forKey: .responseTimestamp)
        reactionTimeMs           = try c.decode(Double.self,       forKey: .reactionTimeMs)
        reactionTimeMsCorrected  = try c.decode(Double.self,       forKey: .reactionTimeMsCorrected)
        let x                    = try c.decode(Float.self,        forKey: .dotPosX)
        let y                    = try c.decode(Float.self,        forKey: .dotPosY)
        let z                    = try c.decode(Float.self,        forKey: .dotPosZ)
        dotPosition              = SIMD3<Float>(x, y, z)
        responded                = try c.decode(Bool.self,         forKey: .responded)
    }

    var csvRow: String {
        [
            String(trialIndex),
            String(format: "%.6f", spawnTimestamp),
            String(format: "%.6f", responseTimestamp),
            String(format: "%.3f", reactionTimeMs),
            String(format: "%.3f", reactionTimeMsCorrected),
            String(format: "%.4f", dotPosition.x),
            String(format: "%.4f", dotPosition.y),
            String(format: "%.4f", dotPosition.z),
            responded ? "true" : "false"
        ].joined(separator: ",")
    }

    static let csvHeader = [
        "trial_index", "spawn_timestamp", "response_timestamp",
        "reaction_time_ms", "reaction_time_ms_corrected",
        "dot_pos_x", "dot_pos_y", "dot_pos_z", "responded"
    ].joined(separator: ",")
}

@MainActor
final class TrialSession: ObservableObject {
    @Published var events:         [TrialEvent] = []
    @Published var lastReactionMs: Double?      = nil
    @Published var lastExportPath: String?      = nil
}
