//
//  MainView.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import SwiftUI

struct MainView: View {
    
    enum ShowingType: Int, Identifiable {
        case openScanning = 1
        case logs = 2
        
        var id: Int {
            return self.rawValue
        }
    }
    
    @ObservedObject var viewModel: MainViewModel = .init()
    @State var onShow: ShowingType? = nil
    
    var body: some View {
        ScrollView {
            Group {
                Section(header: Text("Settings:")) {
                    Toggle(
                        "Turn on display - \(self.viewModel.turnOnDisplay ? "YES" : "NO")",
                        isOn: self.$viewModel.turnOnDisplay)
                    
                    Toggle(
                        "Hands Free Mode - \(self.viewModel.handsFreeMode ? "YES" : "NO")",
                        isOn: self.$viewModel.handsFreeMode)
                    
                    Text("Power correction - \(self.viewModel.powerCorrection).")
                    Slider(
                        value: self.$viewModel.powerCorrection, in: .init(uncheckedBounds: (lower: 0.2, upper: 1.6)))
                }
                
                Section(header: Text("Keys:")) {
                    self.accessKeysList()
                        .padding(.vertical, 20)
                }
                
                Section(header: Text("Actions:")) {
                    Button(action: {
                        self.viewModel.getKeyRequest()
                    }, label: {
                        HStack {
                            Text("Get access key from reader").foregroundColor(.white)
                            ProgressView().opacity(self.viewModel.inProcessGetKey ? 1.0 : 0.0)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(.blue))
                    })
                    
                    Button(action: {
                        self.viewModel.openDoor()
                    }, label: {
                        HStack {
                            Text("Open Door").foregroundColor(.white)
                            ProgressView().opacity(self.viewModel.inProcessOpen ? 1.0 : 0.0)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(.green))
                    })
                }
                
                Section {
                    Button(action: {
                        self.onShow = .openScanning
                    }, label: {
                        HStack {
                            Text("Open Qr scanner").foregroundColor(.white)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(.red))
                    })
                }
            }
            .padding()
        }
        .overlay(
            self.logsButtonView().padding(),
            alignment: .bottomTrailing
        )
        
        .sheet(item: self.$onShow) { item in
            switch item {
            case .openScanning:
                QrScannerView()
                    .onDisappear {
                        self.viewModel.getAccessKeys()
                    }
            case .logs:
                TracerView()
            }
        }
        
        .alert(isPresented: self.$viewModel.showMessage) { () -> Alert in
            Alert(
                title: Text("Result"),
                message: Text(self.viewModel.message),
                dismissButton: .cancel())
        }
        
        .onAppear {
            self.viewModel.getAccessKeys()
        }
    }
    
    private func logsButtonView() -> some View {
        Circle()
            .frame(width: 50, height: 50)
            .foregroundColor(.orange)
            .overlay(Text("Logs"))
            .onTapGesture {
                self.onShow = .logs
            }
    }
    
    @ViewBuilder
    private func accessKeysList() -> some View {
        if self.viewModel.keys.isEmpty {
            Text("Empty list of access keys")
        } else {
            ScrollView(.horizontal) {
                HStack(spacing: 20) { 
                    ForEach(Array(self.viewModel.keys.enumerated()), id: \.element) { index, key in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.orange)
                            .frame(width: 200, height: 120)
                            .overlay(Text(key.displayedName.isEmpty ? "\(key.keyType.self)" : key.displayedName))
                            .overlay(
                                Text("Selected")
                                    .padding(5)
                                    .foregroundColor(.green)
                                    .opacity(self.viewModel.initialKeyIndex == index ? 1.0 : 0.0)
                                , alignment: .topTrailing
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.viewModel.initialKeyIndex = index
                            }
                    }
                }
            }
        }
    }
}
