//
//  LogsListView.swift
//  AcidDemo
//
//  Created by Yevhen Khyzhniak on 12.04.2021.
//  Copyright © 2021 Yevhen Khyzhniak. All rights reserved.
//

import u_prox_id_lib
import SwiftUI

struct TracerView: View {
    
    @State var trace: [TraceService.Trace] = []
    @State private var isEnabledTrace: Bool = TraceService.getTracingState()
    
    
    var body: some View {
        VStack(spacing: 2) {
            ScrollViewReader { proxy in
                List(self.trace.sorted(), id: \.id) { item in
                        TraceRow(trace: item)
                        .id(item.id)
                }
                .onChange(of: self.trace) { newValue in
                    guard !newValue.isEmpty else { return }
                    proxy.scrollTo(trace.last?.id, anchor: .bottom)
                }
            }
            HStack {
                Button {
                    self.toggleTrace()
                } label: {
                    Text(self.isEnabledTrace ? "ON" : "OFF")
                        .foregroundColor(self.isEnabledTrace ? Color.green : Color.red)
                }
                Spacer()
                Divider()
                Spacer()
                Button("Remove logs") {
                    TraceService.removeAll()
                    self.trace = []
                }
                Spacer()
                Divider()
                Spacer()
                if #available(iOS 16.0, *) {
                    if !self.trace.isEmpty {
                        if let url = self.createCSV(from: self.trace, filename: "\(Date()).txt") {
                            ShareLink.init(item: url)
                        }
                            
                    }
                }
            }
            .frame(height: 30)
            .padding(.horizontal)
        }
        .onAppear {
            Task {
                let result = await TraceService.get()
                await MainActor.run {
                    self.trace = result
                }
            }
        }
    }
    
    private func toggleTrace() {
        self.isEnabledTrace.toggle()
        TraceService.setTracingState(self.isEnabledTrace)
    }
    
    struct TraceRow: View {
        
        let trace: TraceService.Trace
        @State var showData: Bool = false
        
        @ViewBuilder
        var body: some View {
            switch self.trace.type {
            case .rest, .webSocket:
                networkBody
            case .app:
                appBody
            case .ble:
                bleBody
            default:
                EmptyView()
            }
        }
        
        private var networkBody: some View {
            VStack(spacing: 10) {
                HStack {
                    self.makeType
                    self.method
                    self.code
                    Spacer()
                    Text("\(trace.diffMiliseconds) ms.").fontWeight(.medium)
                }
                Text("Date: \(trace.correctedDate)").font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(trace.makeFullAddress)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.footnote)
                
                
                if self.showData {
                    self.message
                    HStack {
                        Text(trace.data)
                            .multilineTextAlignment(.leading)
                            .font(.footnote)
                        Spacer()
                    }

                }
                
            }
//            .contextMenu {
//                Button(action: {
//                    UIPasteboard.general.string = trace.clipboardCopy
//                }) {
//                    AppTxt(R.string.localizable.entity_default_copy_clipboard())
//                    Image(systemName: "doc.on.doc")
//                }
//
//            }
            .onTapGesture {
                self.showData.toggle()
            }
        }
        
        private var appBody: some View {
            VStack {
                HStack {
                    makeType
                    Spacer()
                }
                Text("Date: \(trace.correctedDate)").font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                message
            }
        }
        
        
        @ViewBuilder
        private var makeType: some View {
            switch trace.type {
            case .rest:
                Text("REST")
                    .font(.footnote)
                    .padding(3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.green))
            case .webSocket:
                Text("SOCKET")
                    .font(.footnote)
                    .padding(3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.red))
            case .app:
                Text("UI Actions")
                    .font(.footnote)
                    .padding(3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color(UIColor.systemBlue)))
            case .ble:
                Text("BLE Actions")
                    .font(.footnote)
                    .padding(3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color(UIColor.systemGreen)))
            default:
                EmptyView()
            }
        }
        
        private var bleBody: some View {
            VStack(spacing: 8) {
                HStack {
                    makeType
                    Spacer(minLength: 1)
                }
                Text("Date: \(trace.correctedDateShort)").font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.gray)
                message
            }
        }
        
        private var method: some View {
            Text(trace.method)
                .font(.footnote)
                .padding(3)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray))
        }
        
        @ViewBuilder
        private var code: some View {
            let code = trace.code
            if (200..<300).contains(code) {
                Text("\(code)").foregroundColor(.green)
            } else {
                Text("\(code)").foregroundColor(.red)
            }
        }
        
        @ViewBuilder
        private var message: some View {
            switch trace.type {
            case .rest:
                if !trace.queryItems.isEmpty {
                    Text(String(format: "query: [%@]", trace.queryItems))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            case .webSocket:
                if !trace.message.isEmpty {
                    Text(String(format: "command: [%@]", trace.message))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            case .app:
                if !trace.message.isEmpty {
                    Text(String(format: "action: [%@]", trace.message))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            case .ble:
                if !trace.message.isEmpty {
                    Text(String(format: "%@", trace.message))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.footnote)
                }
            default:
                EmptyView()
            }
        }
    }
    
    @available(iOS 16.0, *)
    @MainActor func render(viewsPerPage: Int) -> URL {
        print(self.trace.count)
        // Save it to our documents directory
                let url = URL.documentsDirectory.appending(path: "output.pdf")

                // Calculate number of pages based on passed amount of viewsPerPage
                // you would like to have
                let numberOfPages = trace.count / viewsPerPage
        
                // Tell SwiftUI our PDF should be of certain size
                var box = CGRect(x: 0, y: 0, width: 600, height: 610)

                // Create the CGContext for our PDF pages
                guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                    return url
                }


                var index = 0
                for _ in 0..<numberOfPages {

                    // Start a new PDF page
                    pdf.beginPDFPage(nil)

                    // Render necessary views
                    for num in 0..<viewsPerPage {
                        let renderer = ImageRenderer(
                            content:
                                TraceRow(
                                trace: trace[index]
                            ).frame(width: 600, height: 60)
                        )
                        renderer.render { size, context in

                            // Will place the view in the middle of pdf on x-axis
                            let xTranslation = box.size.width / 2 - size.width / 2

                            // Spacing between the views on y-axis
                            let spacing: CGFloat = 1

                            // TODO: - View starts printing from bottom, need to inverse Y position
                            pdf.translateBy(
                                x: xTranslation - min(max(CGFloat(num) * xTranslation, 0), xTranslation),
                                y: (size.height + spacing)
                            )


                            // Render the SwiftUI view data onto the page
                            context(pdf)
                            // End the page and close the file
                        }
                        index += 1

                    }
                    pdf.endPDFPage()
                }
                pdf.closePDF()
                return url
    }
    
    private func createCSV(from traces: [TraceService.Trace], filename: String) -> URL? {

        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let fileURL = documentDirectory.appendingPathComponent(filename)

        var csvText = ""
        for row in traces {
            csvText.append(row.makeTraceForShareList)
            csvText.append("\n\n")
        }

        do {
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error while creating CSV file: \(error.localizedDescription)")
            return nil
        }
    }
    
}
