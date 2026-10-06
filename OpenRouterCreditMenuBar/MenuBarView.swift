//  MenuBarView.swift
//  OpenRouterCreditMenuBar

import SwiftUI

// Custom toolbar button with hover effect
struct ToolbarButton: View {
    let systemName: String
    let tooltip: String
    let action: () -> Void
    var isLoading: Bool = false
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: systemName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Color.white.opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .disabled(isLoading)
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

// Scrollable model list row
struct ModelListRow: View {
    let model: TopModel
    
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(model.providerColor)
                .frame(width: 3, height: 12)
            Text(model.displayName)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Text(model.totalTokens > 0 ? model.formattedTokens : "N/A")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// Scrollable model column with header
struct ModelColumn: View {
    let title: String
    let models: [TopModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            if models.isEmpty {
                Text("No data")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(models) { model in
                            ModelListRow(model: model)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Fixed-height metric block for Line 2 (Credit/Requests/Tokens)
struct MetricBlock: View {
    let title: String
    let isLoading: Bool
    let errorMessage: String?
    let content: AnyView
    
    // Height: header(20) + 2 rows * 22px + spacing = ~76px
    private let blockHeight: CGFloat = 76
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Group {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading...")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if let error = errorMessage {
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
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    content
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: blockHeight, alignment: .top)
    }
}

// Fixed-height Top Models block for Line 3 with scrollable columns
struct TopModelsBlock: View {
    let isLoading: Bool
    let errorMessage: String?
    let paidModels: [TopModel]
    let freeModels: [TopModel]
    
    // Height for 15 items per column: header(24) + 15 items * 18px = ~300px
    private let blockHeight: CGFloat = 300
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("TOP MODELS")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            
            Group {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading...")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else if let error = errorMessage {
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
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    HStack(alignment: .top, spacing: 16) {
                        ModelColumn(title: "Paid", models: paidModels)
                        ModelColumn(title: "Free", models: freeModels)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: blockHeight, alignment: .top)
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
    
    // Credit content view
    private var creditContent: some View {
        Group {
            if let credit = creditManager.currentCredit {
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
            }
        }
    }
    
    // Requests content view
    private var requestsContent: some View {
        Group {
            if creditManager.requestsToday != nil {
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
            }
        }
    }
    
    // Tokens content view
    private var tokensContent: some View {
        Group {
            if creditManager.tokensToday != nil {
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
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {  // Reduced from 8 to 2
            // MARK: - Line 1: Title Bar with buttons (reduced height)
            HStack(spacing: 6) {
                Image(systemName: "creditcard")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                Text("OpenRouter Credit")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                
                ToolbarButton(
                    systemName: "arrow.clockwise",
                    tooltip: "Refresh",
                    action: {
                        Task {
                            await creditManager.fetchCredit()
                        }
                    },
                    isLoading: creditManager.isLoading
                )
                
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
            .padding(.vertical, 2)  // Reduced from 4 to 2
            
            // Separator after title bar
            Divider()
            
            // MARK: - Line 2: Credit | Requests | Tokens - FIXED HEIGHT (300px for 15 items)
            HStack(spacing: 12) {
                MetricBlock(
                    title: "CREDIT",
                    isLoading: creditManager.isLoading,
                    errorMessage: creditManager.creditErrorMessage,
                    content: AnyView(creditContent)
                )
                
                Divider()
                
                MetricBlock(
                    title: "REQUESTS",
                    isLoading: creditManager.isLoading,
                    errorMessage: creditManager.requestsErrorMessage,
                    content: AnyView(requestsContent)
                )
                
                Divider()
                
                MetricBlock(
                    title: "TOKENS",
                    isLoading: creditManager.isLoading,
                    errorMessage: creditManager.tokensErrorMessage,
                    content: AnyView(tokensContent)
                )
            }
            .frame(maxWidth: .infinity, alignment: .top)
            
            // Separator before Top Models
            Divider()
            
            // MARK: - Line 3: Top Models (Full Width) - FIXED HEIGHT (300px with scroll)
            TopModelsBlock(
                isLoading: creditManager.isLoading,
                errorMessage: creditManager.topModelsErrorMessage,
                paidModels: creditManager.topModelsPaid,
                freeModels: creditManager.topModelsFree
            )
            .frame(maxWidth: .infinity, alignment: .topLeading)
            
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)  // Reduced from 6 to 4
        .frame(width: 720)
    }
}

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
            .environmentObject(OpenRouterCreditManager())
    }
}