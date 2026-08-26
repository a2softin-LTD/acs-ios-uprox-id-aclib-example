//
//  DemoComponents.swift
//  AcidDemo
//
//  Small shared UI kit so both demo tabs look and behave the same way.
//

import SwiftUI

// MARK: - Section card

/// Titled card used to group one step of the demo.
struct DemoSection<Content: View>: View {

    let title: String
    var subtitle: String? = nil
    var accessory: AnyView? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(self.title)
                        .font(.headline)
                    if let subtitle = self.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                self.accessory
            }
            self.content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Button

struct DemoButton: View {

    enum Style {
        case primary
        case secondary

        var foreground: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .accentColor
            }
        }

        var background: Color {
            switch self {
            case .primary: return .accentColor
            case .secondary: return Color.accentColor.opacity(0.14)
            }
        }
    }

    let title: String
    var systemImage: String? = nil
    var style: Style = .primary
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack(spacing: 8) {
                if self.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(self.style.foreground)
                } else if let systemImage = self.systemImage {
                    Image(systemName: systemImage)
                }
                Text(self.title)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(self.style.foreground)
            .frame(maxWidth: .infinity, minHeight: 22)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(self.style.background)
            )
        }
        .buttonStyle(.plain)
        .disabled(!self.isEnabled || self.isLoading)
        .opacity(self.isEnabled ? 1 : 0.4)
        .animation(.easeInOut(duration: 0.15), value: self.isLoading)
    }
}

// MARK: - Selectable row

/// Row used for both access keys and discovered readers.
struct SelectionRow: View {

    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(self.title)
                        .foregroundStyle(.primary)
                    Text(self.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                Image(systemName: self.isSelected ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .foregroundStyle(self.isSelected ? Color.accentColor : Color.secondary.opacity(0.35))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(self.isSelected ? Color.accentColor.opacity(0.10) : Color(.tertiarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(self.isSelected ? Color.accentColor : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status banner

struct StatusBanner: View {

    let status: DemoStatus

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: self.systemImage)
            Text(self.status.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .font(.footnote)
        .foregroundStyle(self.tint)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(self.tint.opacity(0.12))
        )
    }

    private var tint: Color {
        switch self.status.kind {
        case .info: return .secondary
        case .success: return .green
        case .failure: return .red
        }
    }

    private var systemImage: String {
        switch self.status.kind {
        case .info: return "info.circle"
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Empty state

struct EmptyHint: View {

    let text: String

    var body: some View {
        Text(self.text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Power correction

/// Shared control — power correction affects both demos and the background worker.
struct PowerCorrectionSlider: View {

    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Power correction")
                Spacer()
                Text(String(format: "%.1f", self.value))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            Slider(
                value: self.$value,
                in: AppPreferences.powerCorrectionRange,
                step: 0.1
            )

            Text("Lower values shorten the BLE range, so the reader has to be closer.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
