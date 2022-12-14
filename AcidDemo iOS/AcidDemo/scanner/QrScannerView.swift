//
//  QrScannerView.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import SwiftUI

struct QrScannerView: View {

  @ObservedObject var viewModel: ScannerViewModel = .init()

  var body: some View {
    NavigationView {
      VStack {
        CodeScannerView(codeTypes: [.qr], completion: self.viewModel.handleScan)
      }
      .navigationBarTitle("Scanning", displayMode: .inline)
    }

    .alert(isPresented: self.$viewModel.showMessage) { () -> Alert in
      Alert(
        title: Text("Warning!!!"), message: Text(self.viewModel.message), dismissButton: .cancel())
    }
  }
}

struct QrScannerView_Previews: PreviewProvider {
  static var previews: some View {
    QrScannerView()
  }
}
