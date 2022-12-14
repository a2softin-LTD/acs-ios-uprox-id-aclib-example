//
//  ActionButton.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import SwiftUI

struct ActionButton: View {
    
    private var title: String
    private var backColor: Color
    private var action: () -> Void
    
    //MARK: - Public Init
    
    public init(title: String = "Save", backColor: Color = Color(.systemBlue), action: @escaping () -> Void) {
        self.title = title
        self.action = action
        self.backColor = backColor
    }
    
    var body: some View {
        Button(action: {
            self.action()
        }) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.white)
                    .padding([.leading, .trailing])
            }
            .animation(Animation.easeIn(duration: 0.3))
            .frame(height: 50)
            .cornerRadius(15)
        }
        .frame(height: 50)
        .background(backColor)
        .cornerRadius(15)
    }
}
