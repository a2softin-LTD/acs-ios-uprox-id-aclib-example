//
//  WalletView.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import SwiftUI

struct WalletView: View {

  @ObservedObject var viewModel: WalletViewModel = .init()

  var body: some View {
    NavigationView {
      List {
        ForEach(self.viewModel.keys, id: \.self) { key in
          WalletCellView(title: key.displayedName, selected: key.isKeySelected) {
            self.viewModel.setSelectedKey(key)
          }
        }
      }
      .navigationBarTitle("Wallet", displayMode: .inline)
      .listStyle(GroupedListStyle())
      .environment(\.horizontalSizeClass, .regular)
    }
    .onAppear {
      self.viewModel.fetchAccessKeys()
    }
  }
}

fileprivate struct WalletCellView: View {

  public var title: String
  public var selected: Bool
  public var action: () -> Void

  var body: some View {
    HStack {
      Text(title)
      Spacer()
      if selected {
        Image(systemName: "checkmark")
      }
    }
    .onTapGesture {
      self.action()
    }
  }
}
