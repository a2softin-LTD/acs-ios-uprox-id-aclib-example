//
//  InitialScene.swift
//  AcidDemo
//
//  Created by Yevhen Khyzhniak on 07.02.2024.
//  Copyright © 2024 Yevhen Khyzhniak. All rights reserved.
//

import SwiftUI

struct InitialScene: View {
    var body: some View {
        ZStack {
            ScenePhaseListener()
            MainView()
        }
    }
}

struct ScenePhaseListener: View {
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        EmptyView()
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .active, .background:
                    BackgroundOpenDoorService.onRefresh()
                default:
                    break
                }
            }
    }
}
