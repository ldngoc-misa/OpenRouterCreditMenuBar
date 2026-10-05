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

// Popover view for spend today by model
struct SpendTodayPopover: View {
    let modelSpending: [ModelSpending]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spend Today by Model")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            if modelSpending.isEmpty {
                Text("No spend data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(modelSpending.prefix(10)) { spending in
                    HStack(spacing: 8) {
                        // Vertical pill/capsule shape - longer and narrower
                        RoundedRectangle(cornerRadius: 2)
                            .fill(spending.providerColor)
                            .frame(width: 4, height: 16)
                        Text(spending.modelName)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Text("$\(String(format: "%.4f", spending.amount))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                if modelSpending.count > 10 {
                    Text("... and \(modelSpending.count - 10) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
        }
        .padding(12)
        .frame(width: 300)
    }
}

// Spend today amount view with hover popover
struct SpendTodayAmountView: View {
    let label: String
    let amount: Double?
    let modelSpending: [ModelSpending]
    @State private var showPopover = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Group {
                if let amount = amount {
                    Text("$\(String(format: "%.4f", amount))")
                        .font(.title3)
                        .fontWeight(.semibold)
                } else {
                    Text("--")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            .onHover { hovering in
                showPopover = hovering
            }
            .popover(isPresented: $showPopover) {
                SpendTodayPopover(modelSpending: modelSpending)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    /// Label showing which day the "Spend" value refers to.
    /// Days are compared in UTC to stay consistent with the API's UTC-based data.
    private var spentTodayLabel: String {
        guard let date = creditManager.spentTodayDate else { return "Spend Today" }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        if calendar.isDate(date, inSameDayAs: Date()) {
            return "Spend Today"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Spend Yesterday"
        }
        return "Spend \(date.formatted(date: .abbreviated, time: .omitted))"
    }

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
                        // Spend Today column (left) - with hover popover
                        SpendTodayAmountView(
                            label: spentTodayLabel,
                            amount: creditManager.spentToday,
                            modelSpending: creditManager.spentTodayByModel
                        )

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
