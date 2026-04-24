//
//  ImmersiveView.swift
//  biometricTracker
//
//  Created by Prisha Marpu on 4/9/26.
//


import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        RealityView { content in
            if let entity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(entity)
            }
        }
    }
}
