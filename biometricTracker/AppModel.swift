//
//  AppModel.swift
//  biometricTracker
//
//  Created by Prisha Marpu on 4/9/26.
//

//
//  AppModel.swift
//  biometricTracker
//

import SwiftUI
import Observation

@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"

    enum ImmersiveSpaceState {
        case closed, inTransition, open
    }

    var immersiveSpaceState = ImmersiveSpaceState.closed
    var mathManager         = MathProblemManager()
}
