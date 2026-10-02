//
//  MenuBarView.swift
//  OpenRouterCreditMenuBar
//

import SwiftUI

// Custom toolbar button with hover effect
struct ToolbarButton: View {
    let systemName: String
    let tooltip: String
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovering ? Color.white.opacity(0.2) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// Toolbar button content for use inside SettingsLink (unused - keeping for reference)
// struct ToolbarButtonContent: View {
//     let systemName: String
//     @State private var isHovering = false
//     
//     var body: some View {
//         Image(systemName: systemName)
//             .font(.system(size: 14, weight: .medium))
//             .foregroundColor(.white)
//             .frame(width: 28, height: 28)
//             .background(
//                 RoundedRectangle(cornerRadius: 6)
//                     .fill(isHovering ? Color.white.opacity(0.2) : Color.clear)
//             )
//             .onHover { hovering in
//                 isHovering = hovering
//             }
//     }
// }

// Toolbar button with hover effect for use inside SettingsLink
struct SettingsToolbarButton: View {
    let systemName: String
    @State private var isHovering = false
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Color.white.opacity(0.2) : Color.clear)
            )
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

struct MenuBarView: View {
    @EnvironmentObject var creditManager: OpenRouterCreditManager

    var body: some View {
        VStack(spacing: 8) {
            // MARK: - Area 1: Title (compact)
            HStack(spacing: 6) {
                Image(systemName: "creditcard")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                Text("OpenRouter Credit")
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.vertical, 4)

            Divider()

            // MARK: - Area 2: Credit Information
            VStack(alignment: .leading, spacing: 6) {
                Text("CREDIT")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                if creditManager.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading...")
                            .font(.caption)
                    }
                } else if let credit = creditManager.currentCredit {
                    HStack(alignment: .top, spacing: 12) {
                        // Spent Today column (left)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Spent Today")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$0.00")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Available column (right)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(String(format: "%.4f", credit))")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else if let error = creditManager.errorMessage {
                    VStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(error)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                    }
                }
            }

            Divider()

            // MARK: - Area 3: Top Models (Paid / Free columns - implement later)
            VStack(alignment: .leading, spacing: 6) {
                Text("Top Models")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                HStack(alignment: .top, spacing: 12) {
                    // Paid models column
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Paid")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text("Coming soon")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Free models column
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Free")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text("Coming soon")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 2)

            Divider()

            // MARK: - Area 4: Toolbar (icon-only with tooltips + hover)
            HStack(spacing: 8) {
                ToolbarButton(
                    systemName: "arrow.clockwise",
                    tooltip: "Refresh"
                ) {
                    Task {
                        await creditManager.fetchCredit()
                    }
                }

                ToolbarButton(
                    systemName: "globe",
                    tooltip: "View Activity"
                ) {
                    if let url = URL(string: "https://openrouter.ai/activity") {
                        NSWorkspace.shared.open(url)
                    }
                }

                SettingsLink {
                    SettingsToolbarButton(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help("Settings")

                ToolbarButton(
                    systemName: "power",
                    tooltip: "Quit"
                ) {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.vertical, 6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(width: 240)
    }
}

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
            .environmentObject(OpenRouterCreditManager())
    }
}
