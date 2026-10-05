//
//  MenuBarView.swift
//  OpenRouterCreditMenuBar
//

import SwiftUI

/// Formats a number in abbreviated form (e.g., 1.5K, 2.3M, 1.2B)
func formatAbbreviated(_ number: Int) -> String {
    let value = Double(number)
    switch value {
    case 1_000_000_000...:
        return String(format: "%.1fB", value / 1_000_000_000)
    case 1_000_000...:
        return String(format: "%.1fM", value / 1_000_000)
    case 1_000...:
        return String(format: "%.1fK", value / 1_000)
    default:
        return "\(number)"
    }
}

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

// Requests today amount view with hover popover
struct RequestsTodayAmountView: View {
    let label: String
    let count: Int?
    let modelRequests: [ModelRequests]
    let popoverTitle: String
    @State private var showPopover = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Group {
                if let count = count {
                    Text(formatAbbreviated(count))
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
                RequestsTodayPopover(modelRequests: modelRequests, title: popoverTitle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Popover view for requests by model
struct RequestsTodayPopover: View {
    let modelRequests: [ModelRequests]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            if modelRequests.isEmpty {
                Text("No request data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(modelRequests.prefix(10)) { request in
                    HStack(spacing: 8) {
                        // Vertical pill/capsule shape - longer and narrower
                        RoundedRectangle(cornerRadius: 2)
                            .fill(request.providerColor)
                            .frame(width: 4, height: 16)
                        Text(request.modelName)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Text(formatAbbreviated(request.count))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                if modelRequests.count > 10 {
                    Text("... and \(modelRequests.count - 10) more")
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
    
    /// Label showing which day the "Requests" value refers to.
    private var requestsTodayLabel: String {
        guard let date = creditManager.requestsTodayDate else { return "Requests Today" }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        if calendar.isDate(date, inSameDayAs: Date()) {
            return "Requests Today"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Requests Yesterday"
        }
        return "Requests \(date.formatted(date: .abbreviated, time: .omitted))"
    }

    var body: some View {
        VStack(spacing: 8) {
            // MARK: - Title (full width)
            HStack(spacing: 6) {
                Image(systemName: "creditcard")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                Text("OpenRouter Credit")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.vertical, 4)

            // MARK: - Middle Section: Left Content (3 blocks) + Right Content (TOP MODELS)
            HStack(alignment: .top, spacing: 16) {
                // Left Column: Credit, Requests, Tokens stacked
                VStack(alignment: .leading, spacing: 8) {
                    // MARK: - Credit Information
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
                                SpendTodayAmountView(
                                    label: spentTodayLabel,
                                    amount: creditManager.spentToday,
                                    modelSpending: creditManager.spentTodayByModel
                                )

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

                    // MARK: - Requests Information
                    VStack(alignment: .leading, spacing: 6) {
                        Text("REQUESTS")
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
                        } else if creditManager.requestsToday != nil {
                            HStack(alignment: .top, spacing: 12) {
                                RequestsTodayAmountView(
                                    label: "Today",
                                    count: creditManager.requestsToday,
                                    modelRequests: creditManager.requestsTodayByModel,
                                    popoverTitle: "Requests Today by Model"
                                )

                                RequestsTodayAmountView(
                                    label: "This Week",
                                    count: creditManager.requestsThisWeek,
                                    modelRequests: creditManager.requestsThisWeekByModel,
                                    popoverTitle: "Requests This Week by Model"
                                )
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

                    // MARK: - Tokens Information
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TOKENS")
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
                        } else if creditManager.tokensToday != nil {
                            HStack(alignment: .top, spacing: 12) {
                                RequestsTodayAmountView(
                                    label: "Today",
                                    count: creditManager.tokensToday,
                                    modelRequests: creditManager.tokensTodayByModel,
                                    popoverTitle: "Tokens Today by Model"
                                )

                                RequestsTodayAmountView(
                                    label: "This Week",
                                    count: creditManager.tokensThisWeek,
                                    modelRequests: creditManager.tokensThisWeekByModel,
                                    popoverTitle: "Tokens This Week by Model"
                                )
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
                }
                .frame(width: 220)

                // Right Column: TOP MODELS - height matches the 3 left blocks
                VStack(alignment: .leading, spacing: 6) {
                    Text("TOP MODELS")
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

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            Divider()

            // MARK: - Toolbar (full width)
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
        .frame(width: 720)
    }
}

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
            .environmentObject(OpenRouterCreditManager())
    }
}
