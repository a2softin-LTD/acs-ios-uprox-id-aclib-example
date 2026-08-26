//
//  InitialScene.swift
//  AcidDemo
//
//  Created by Yevhen Khyzhniak on 07.02.2024.
//  Copyright © 2024 Yevhen Khyzhniak. All rights reserved.
//

import SwiftUI

struct InitialScene: View {

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        MainView()
            .onChange(of: self.scenePhase) { newPhase in
                switch newPhase {
                case .active, .background:
                    // Keep the background worker in sync with the preferences
                    // whenever the app changes state.
                    BackgroundOpenDoorService.onRefresh()
                default:
                    break
                }
            }
    }
}
