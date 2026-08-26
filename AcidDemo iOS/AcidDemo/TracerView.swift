//
//  TracerView.swift
//  AcidDemo
//
//  Created by Yevhen Khyzhniak on 12.04.2021.
//  Copyright © 2021 Yevhen Khyzhniak. All rights reserved.
//

import SwiftUI
import u_prox_id_lib

/// Shows the library trace log (REST, WebSocket, BLE and UI events).
struct TracerView: View {

    @State private var traces: [TraceService.Trace] = []
    @State private var isTracingEnabled: Bool = TraceService.getTracingState()
    @State private var exportURL: URL?

    var body: some View {
        Group {
            if self.traces.isEmpty {
                self.emptyState
            } else {
                self.list
            }
        }
        .navigationTitle("Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Toggle("Tracing", isOn: self.$isTracingEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let exportURL = self.exportURL {
                    ShareLink(item: exportURL)
                }
                Button(role: .destructive) {
                    TraceService.removeAll()
                    self.traces = []
                    self.exportURL = nil
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(self.traces.isEmpty)
            }
        }
        .task { await self.reload() }
        .refreshable { await self.reload() }
        .onChange(of: self.isTracingEnabled) { isEnabled in
            TraceService.setTracingState(isEnabled)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.alignleft")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No log entries")
                .font(.headline)
            Text(
                self.isTracingEnabled
                    ? "Entries appear here as soon as the library talks to a reader or the server."
                    : "Tracing is switched off. Turn it on to start collecting entries."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        ScrollViewReader { proxy in
            List(self.traces, id: \.id) { item in
                TraceRow(trace: item).id(item.id)
            }
            .listStyle(.plain)
            .onChange(of: self.traces) { newValue in
                guard let last = newValue.last else { return }
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    // MARK: - Data

    private func reload() async {
        let result = await TraceService.get().sorted()
        self.traces = result
        // Written once per reload, not on every SwiftUI body evaluation.
        self.exportURL = Self.makeExportFile(from: result)
    }

    /// Dumps the log to a single file in the temporary directory. The same file
    /// name is reused so the demo does not pile up exports on disk.
    private static func makeExportFile(from traces: [TraceService.Trace]) -> URL? {
        guard !traces.isEmpty else { return nil }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("acid-demo-trace.txt")
        let text = traces.map(\.makeTraceForShareList).joined(separator: "\n\n")

        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to write the trace export: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Row

extension TracerView {

    struct TraceRow: View {

        let trace: TraceService.Trace
        @State private var isExpanded: Bool = false

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    self.typeBadge
                    if self.trace.type == .rest || self.trace.type == .webSocket {
                        self.methodBadge
                        self.statusCode
                    }
                    Spacer(minLength: 4)
                    if self.trace.type == .rest || self.trace.type == .webSocket {
                        Text("\(self.trace.diffMiliseconds) ms")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Text(self.dateText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if self.trace.type == .rest || self.trace.type == .webSocket {
                    Text(self.trace.makeFullAddress)
                        .font(.footnote)
                        .lineLimit(self.isExpanded ? nil : 2)
                }

                self.message

                if self.isExpanded, !self.trace.data.isEmpty {
                    Text(self.trace.data)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { self.isExpanded.toggle() }
            .contextMenu {
                Button {
                    UIPasteboard.general.string = self.trace.makeTraceForShareList
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
        }

        private var dateText: String {
            self.trace.type == .ble ? self.trace.correctedDateShort : self.trace.correctedDate
        }

        @ViewBuilder
        private var typeBadge: some View {
            switch self.trace.type {
            case .rest: self.badge("REST", color: .green)
            case .webSocket: self.badge("SOCKET", color: .red)
            case .app: self.badge("UI", color: .blue)
            case .ble: self.badge("BLE", color: .teal)
            @unknown default: EmptyView()
            }
        }

        private var methodBadge: some View {
            self.badge(self.trace.method, color: .gray)
        }

        @ViewBuilder
        private var statusCode: some View {
            let code = self.trace.code
            Text("\(code)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle((200..<300).contains(code) ? Color.green : Color.red)
        }

        @ViewBuilder
        private var message: some View {
            switch self.trace.type {
            case .rest:
                if !self.trace.queryItems.isEmpty {
                    self.detail("query: [\(self.trace.queryItems)]")
                }
            case .webSocket:
                if !self.trace.message.isEmpty {
                    self.detail("command: [\(self.trace.message)]")
                }
            case .app:
                if !self.trace.message.isEmpty {
                    self.detail("action: [\(self.trace.message)]")
                }
            case .ble:
                if !self.trace.message.isEmpty {
                    self.detail(self.trace.message)
                }
            @unknown default:
                EmptyView()
            }
        }

        private func detail(_ text: String) -> some View {
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        private func badge(_ text: String, color: Color) -> some View {
            Text(text)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.2)))
                .foregroundStyle(color)
        }
    }
}
