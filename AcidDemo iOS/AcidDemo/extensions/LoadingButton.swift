//
//  LoadingButton.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import SwiftUI

struct MainSceneRow: View {

  //MARK: - Public State Propeties

  @Binding var shouldAnimate: Bool
  var isEnabled: Bool

  //MARK: - Private Propeties
  private var loadingColor: UIColor
  private var background: Color
  private var imageScale: Image.Scale = .medium
  private var action: () -> Void
  private var title: String

  init(
    title: String,
    process: Binding<Bool>,
    loadingColor: UIColor = .white,
    isEnabled: Bool = true,
    background: Color = Color.clear,
    action: @escaping () -> Void
  ) {
    self.title = title
    self._shouldAnimate = process
    self.loadingColor = loadingColor
    self.isEnabled = isEnabled
    self.background = background
    self.action = action
  }

  //MARK: - Body

  var body: some View {
    HStack {
      Text(currentHolderText)
        .multilineTextAlignment(.leading)
        LoadingIndicator(shouldAnimate: self.$shouldAnimate, color: .gray)
        .opacity(self.shouldAnimate ? 1.0 : 0.0)
      Spacer()
    }
    .contentShape(Rectangle())
    .onTapGesture {
      if !self.shouldAnimate {
        self.action()
      }
    }
    .disabled(!self.isEnabled)
    .opacity(self.isEnabled ? 1.0 : 0.5)
  }

  private var currentHolderText: String {
    if shouldAnimate {
      return "In process..."
    }
    return title
  }
}
