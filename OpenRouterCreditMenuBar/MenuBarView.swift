//  MenuBarView.swift
//  OpenRouterCreditMenuBar

import SwiftUI
import AppKit

// NSScrollView subclass that always uses overlay scrollers: the bar is drawn
// on top of the content, auto-hides, and never reserves width.
// AppKit re-reads the system "Show scroll bars" preference on its first tile,
// which can bring back a wide legacy scroller that steals width from the
// model list until the next layout pass — so the style is re-applied on every
// layout and whenever the view enters a window.
final class OverlayScrollerScrollView: NSScrollView {
    override var scrollerStyle: NSScroller.Style {
        get { .overlay }
        set { super.scrollerStyle = .overlay }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        enforceOverlayStyle()
    }

    override func layout() {
        super.layout()
        enforceOverlayStyle()
    }

    private func enforceOverlayStyle() {
        // Guarded so setting the style (which triggers tiling) can't recurse.
        if super.scrollerStyle != .overlay {
            super.scrollerStyle = .overlay
        }
        if !autohidesScrollers { autohidesScrollers = true }
    }
}

// Overlay scroll view using NSScrollView with overlay scroller style
// Scrollbar appears on hover as semi-transparent overlay, no layout shift
struct OverlayScrollView<Content: View>: NSViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = OverlayScrollerScrollView()
        scrollView.scrollerStyle = .overlay
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear

        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.documentView = hostingView

        // Constrain document view width to scroll view width
        NSLayoutConstraint.activate([
            hostingView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor)
        ])

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let hostingView = nsView.documentView as? NSHostingView<Content> {
            hostingView.rootView = content
            hostingView.layoutSubtreeIfNeeded()
        }
    }
}

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
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            // Provider color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(model.providerColor)
                .frame(width: 3, height: 12)

            // Model Name - shows displayName normally, slug on hover
            Text(isHovering ? model.slug : model.displayName)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
                .foregroundColor(isHovering ? .primary : .primary)

            // Total Tokens
            Text(model.totalTokens > 0 ? model.formattedTokens : "N/A")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)

            // Input Price / Output Price (only for paid models)
            if !model.isFree, let pricing = model.formattedPricing {
                Text(pricing)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    // Wider than other numeric columns so two prices stay readable
                    .frame(width: 100, alignment: .trailing)
            }

            // Context Length
            Text(model.formattedContext)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 35, alignment: .trailing)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovering ? Color.white.opacity(0.08) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            // Copy slug to clipboard
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(model.slug, forType: .string)
        }
        .help("Click to copy slug: \(model.slug)")
    }
}

// Scrollable model column with header
struct ModelColumn: View {
    let models: [TopModel]
    let sortMode: PaidModelSortMode
    let onTokensClick: () -> Void
    let onPriceClick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if models.isEmpty {
                Text("No data")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 0) {
                    // Column headers
                    ModelColumnHeader(
                        isFree: models.first?.isFree ?? false,
                        sortMode: sortMode,
                        onTokensClick: onTokensClick,
                        onPriceClick: onPriceClick
                    )

                    OverlayScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(models) { model in
                                ModelListRow(model: model)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Column header row
struct ModelColumnHeader: View {
    let isFree: Bool
    let sortMode: PaidModelSortMode
    let onTokensClick: () -> Void
    let onPriceClick: () -> Void

    // Darker version of category color for headers
    private var headerColor: Color {
        // Use a slightly darker, more saturated version for better visibility
        isFree ? Color.green.opacity(0.85) : Color.orange.opacity(0.85)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Color indicator space (3px) + Model header that overflows into model name column
            ZStack(alignment: .leading) {
                // Invisible color indicator spacer
                Color.clear
                    .frame(width: 3, height: 12)

                // Model header - starts at left edge (aligned with color indicator), overflows into model name column
                Text(isFree ? "Free Model" : "Paid Model")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(headerColor)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Spacer to push other headers to the right
            Spacer(minLength: 0)

            // Tokens header - clickable for paid models, non-clickable for free models
            Button(action: onTokensClick) {
                HStack(spacing: 2) {
                    Text("Tokens")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(headerColor)
                    // Sort indicator for tokens
                    if sortMode == .tokensDesc {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(headerColor.opacity(0.6))
                    }
                }
                .frame(width: 50, alignment: .trailing)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // For free models, make button non-interactive but keep same styling (no disabled gray)

            // Price header - clickable for paid models (cycles through price desc/asc)
            if !isFree {
                Button(action: onPriceClick) {
                    HStack(spacing: 2) {
                        Text("Price")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(headerColor)
                        // Sort indicator for price
                        if sortMode == .priceDesc {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(headerColor.opacity(0.6))
                        } else if sortMode == .priceAsc {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(headerColor.opacity(0.6))
                        }
                    }
                    .frame(width: 100, alignment: .trailing)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // Context
            Text("Ctx")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(headerColor)
                .frame(width: 35, alignment: .trailing)
        }
        .padding(.vertical, 2)
        .padding(.bottom, 2)
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
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
    }
}

// Fixed-height Top Models block for Line 3 with scrollable columns
struct TopModelsBlock: View {
    let isLoading: Bool
    let errorMessage: String?
    let paidModels: [TopModel]
    let freeModels: [TopModel]
    @ObservedObject var creditManager: OpenRouterCreditManager

    // Height for 15 items per column: header(24) + 15 items * 18px = ~300px
    let blockHeight: CGFloat = 300

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("TOP MODELS")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()

                // Search text field
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Filter model name...", text: $creditManager.topModelsSearchText)
                        .textFieldStyle(.plain)
                        .font(.caption2)
                        .frame(width: 140)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.08))
                        )
                }

                // Price filter picker (only for paid)
                Picker("", selection: $creditManager.topModelsPriceFilter) {
                    ForEach(PriceFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
                .font(.caption2)
                .labelsHidden()
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
                    GeometryReader { geometry in
                        let totalWidth = geometry.size.width
                        let paidWidth = totalWidth * 0.55 - 8  // 55% minus half spacing
                        let freeWidth = totalWidth * 0.45 - 8  // 45% minus half spacing
                        
                        HStack(alignment: .top, spacing: 16) {
                            ModelColumn(
                                models: paidModels,
                                sortMode: creditManager.paidModelsSortMode,
                                onTokensClick: { creditManager.paidModelsSortMode = .tokensDesc },
                                onPriceClick: {
                                    // Cycle: tokensDesc -> priceAsc -> priceDesc -> tokensDesc
                                    switch creditManager.paidModelsSortMode {
                                    case .tokensDesc: creditManager.paidModelsSortMode = .priceAsc
                                    case .priceAsc: creditManager.paidModelsSortMode = .priceDesc
                                    case .priceDesc: creditManager.paidModelsSortMode = .tokensDesc
                                    }
                                }
                            )
                            .frame(width: paidWidth)
                            
                            ModelColumn(
                                models: freeModels,
                                sortMode: .tokensDesc, // Free models always sorted by tokens
                                onTokensClick: {}, // No-op for free
                                onPriceClick: {} // No-op for free
                            )
                            .frame(width: freeWidth)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: blockHeight, alignment: .top)
        .padding(14)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct MenuBarView: View {
    @EnvironmentObject var creditManager: OpenRouterCreditManager
    @EnvironmentObject var chatGPTManager: ChatGPTManager
    @EnvironmentObject var openAIAPIManager: OpenAIAPIManager
    @EnvironmentObject var openAIPlatformLoginManager: OpenAIPlatformLoginManager
    @EnvironmentObject var antigravityManager: AntigravityManager
    @State private var selectedProvider: ProviderTab = .openRouter

    private enum ProviderTab: String, CaseIterable, Identifiable {
        case openRouter = "OpenRouter"
        case openAI = "OpenAI"
        case googleAI = "Antigravity"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .openRouter: ProviderIconName.openRouter
            case .openAI: ProviderIconName.openAI
            case .googleAI: ProviderIconName.googleAI
            }
        }
    }

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
    
    private var openRouterDashboard: some View {
        VStack(spacing: 14) {
            // Credit | Requests | Tokens
            HStack(alignment: .top, spacing: 12) {
                MetricBlock(
                    title: "CREDIT",
                    isLoading: creditManager.isLoading,
                    errorMessage: creditManager.creditErrorMessage,
                    content: AnyView(creditContent)
                )

                MetricBlock(
                    title: "REQUESTS",
                    isLoading: creditManager.isLoading,
                    errorMessage: creditManager.requestsErrorMessage,
                    content: AnyView(requestsContent)
                )

                MetricBlock(
                    title: "TOKENS",
                    isLoading: creditManager.isLoading,
                    errorMessage: creditManager.tokensErrorMessage,
                    content: AnyView(tokensContent)
                )
            }
            .frame(maxWidth: .infinity, alignment: .top)

            TopModelsBlock(
                isLoading: creditManager.isLoading,
                errorMessage: creditManager.topModelsErrorMessage,
                paidModels: creditManager.topModelsPaid,
                freeModels: creditManager.topModelsFree,
                creditManager: creditManager
            )
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private var selectedProviderContent: some View {
        switch selectedProvider {
        case .openRouter:
            openRouterDashboard
        case .openAI:
            OpenAIProviderView(
                manager: chatGPTManager,
                apiManager: openAIAPIManager,
                platformManager: openAIPlatformLoginManager
            )
        case .googleAI:
            GoogleAIProviderView(manager: antigravityManager)
        }
    }

    private var providerTabs: some View {
        HStack(spacing: 6) {
            ForEach(ProviderTab.allCases) { tab in
                Button {
                    selectedProvider = tab
                } label: {
                    Label(tab.rawValue, systemImage: tab.icon)
                        .font(.system(size: 12, weight: selectedProvider == tab ? .semibold : .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(selectedProvider == tab ? Color.accentColor.opacity(0.2) : .clear)
                        }
                        .foregroundStyle(selectedProvider == tab ? Color.accentColor : Color.secondary)
                        .contentShape(RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedProvider == tab ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 9))
    }

    var body: some View {
        VStack(spacing: 8) {
            // Shared title bar
            HStack(spacing: 6) {
                Image(systemName: AppSymbolName.popupTitle)
                    .foregroundStyle(Color.accentColor)
                    .font(.system(size: 14))
                Text("AI Provider Monitor")
                    .font(.system(size: 13, weight: .medium))
                Spacer()

                ToolbarButton(
                    systemName: "arrow.clockwise",
                    tooltip: "Refresh \(selectedProvider.rawValue)",
                    action: refreshSelectedProvider,
                    isLoading: selectedProvider == .openRouter
                        ? creditManager.isLoading
                        : selectedProvider == .openAI
                            ? chatGPTManager.isLoading || openAIAPIManager.isLoading
                            : antigravityManager.isLoading
                )

                if selectedProvider == .openRouter {
                    ToolbarButton(
                        systemName: "globe",
                        tooltip: "View OpenRouter Activity"
                    ) {
                        if let url = URL(string: "https://openrouter.ai/activity") {
                            NSWorkspace.shared.open(url)
                        }
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
            .padding(.vertical, 2)

            providerTabs

            Divider()

            selectedProviderContent
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 720, height: 544, alignment: .top)
    }

    private func refreshSelectedProvider() {
        switch selectedProvider {
        case .openRouter:
            Task {
                await creditManager.refresh()
                if let appDelegate = NSApp.delegate as? AppDelegate {
                    appDelegate.updateMenuBarTitle()
                }
            }
        case .openAI:
            chatGPTManager.refresh()
            Task { await openAIAPIManager.refresh() }
            openAIPlatformLoginManager.refreshAccount()
        case .googleAI:
            Task { await antigravityManager.refresh() }
        }
    }
}

private struct OpenAIProviderView: View {
    @ObservedObject var manager: ChatGPTManager
    @ObservedObject var apiManager: OpenAIAPIManager
    @ObservedObject var platformManager: OpenAIPlatformLoginManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("OpenAI")
                            .font(.title2.weight(.semibold))
                        if let lastUpdated = manager.lastUpdated {
                            Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Text("ChatGPT account and usage")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label(manager.isConnected ? "Connected" : "Not connected", systemImage: manager.isConnected ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.caption)
                    .foregroundStyle(manager.isConnected ? .green : .secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("CHATGPT", systemImage: "sparkle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Label("Account", systemImage: "person.crop.circle")
                            .font(.caption.weight(.semibold))
                        ProviderValueRow(title: "Email", value: manager.accountEmail ?? "Unavailable")
                        ProviderValueRow(title: "Plan", value: manager.planType?.capitalized ?? "Unavailable")
                        if let usedPercent = manager.usedPercent {
                            HStack(spacing: 5) {
                                Text("Usage").foregroundStyle(.secondary)
                                Spacer(minLength: 0)
                                ProgressView(value: min(Double(usedPercent), 100), total: 100)
                                    .tint(usedPercent >= 100 ? .red : .accentColor)
                                    .frame(width: 62)
                                Text("\(usedPercent)%")
                                    .font(.caption.monospacedDigit())
                                    .frame(minWidth: 30, alignment: .trailing)
                            }
                            .font(.caption)
                        } else {
                            ProviderValueRow(title: "Usage", value: "Unavailable")
                        }
                        ProviderValueRow(
                            title: "Limit reset",
                            value: manager.resetAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unavailable"
                        )
                        if !manager.isConnected {
                            Text(manager.isLoading ? "Checking session…" : "Connect in Settings")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(9)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9))

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 4) {
                            Label("Usage Overview", systemImage: "chart.bar")
                                .font(.caption.weight(.semibold))
                            Spacer(minLength: 2)
                            ForEach([7, 30], id: \.self) { days in
                                Button("\(days)d") { manager.setUsageOverviewDays(days) }
                                    .font(.caption.weight(manager.usageOverviewDays == days ? .semibold : .regular))
                                    .buttonStyle(.plain)
                                    .foregroundStyle(manager.usageOverviewDays == days ? Color.accentColor : Color.secondary)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(
                                        manager.usageOverviewDays == days ? Color.accentColor.opacity(0.14) : .clear,
                                        in: Capsule()
                                    )
                                    .disabled(manager.isLoading)
                            }
                        }
                        if !manager.usageOverview.isEmpty {
                            ForEach(manager.usageOverview) { metric in
                                ProviderValueRow(title: metric.name, value: metric.value)
                            }
                        } else {
                            Text(manager.isLoading ? "Loading…" : "Unavailable")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(9)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9))

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 4) {
                            Label("Analytics", systemImage: "chart.xyaxis.line")
                                .font(.caption.weight(.semibold))
                            Spacer(minLength: 2)
                            ForEach([7, 30], id: \.self) { days in
                                Button("\(days)d") { manager.setAnalyticsDays(days) }
                                    .font(.caption.weight(manager.analyticsDays == days ? .semibold : .regular))
                                    .buttonStyle(.plain)
                                    .foregroundStyle(manager.analyticsDays == days ? Color.accentColor : Color.secondary)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(
                                        manager.analyticsDays == days ? Color.accentColor.opacity(0.14) : .clear,
                                        in: Capsule()
                                    )
                                    .disabled(manager.isLoading)
                            }
                        }
                        Text("Credits by model")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        if let error = manager.analyticsErrorMessage {
                            Text(error).font(.caption).foregroundStyle(.secondary)
                        } else if manager.modelUsage.isEmpty {
                            Text(manager.isLoading ? "Loading…" : "No model usage")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 5) {
                                    ForEach(manager.modelUsage) { metric in
                                        ProviderValueRow(title: metric.name, value: metric.value)
                                    }
                                }
                            }
                        }
                    }
                    .padding(9)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 170, alignment: .topLeading)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("API", systemImage: "terminal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let lastUpdated = apiManager.lastUpdated {
                        Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Label(
                        apiManager.isConnected ? "Connected" : "Not connected",
                        systemImage: apiManager.isConnected ? "checkmark.circle.fill" : "circle.dashed"
                    )
                    .font(.caption2)
                    .foregroundStyle(apiManager.isConnected ? .green : .secondary)
                }

                HStack(alignment: .top, spacing: 8) {
                    OpenAIMetricBlock(title: "COST", metrics: [
                        OpenAIMetricValue(
                            label: "Spend Today",
                            value: apiManager.todayCost.map(Self.formatCurrency) ?? "--",
                            details: apiManager.costsByLineItem
                                .sorted { $0.todayAmount > $1.todayAmount }
                                .prefix(8)
                                .map { item in
                                    (
                                        [item.lineItem, item.projectID].compactMap { $0 }.joined(separator: " · "),
                                        Self.formatCurrency(item.todayAmount)
                                    )
                                }
                        ),
                        OpenAIMetricValue(
                            label: "Available",
                            value: platformManager.availableCredit.map(Self.formatCurrency) ?? "--",
                            details: [(
                                platformManager.availableCredit == nil
                                    ? (platformManager.creditGrantsErrorMessage ?? "Sign in to OpenAI Platform")
                                    : "Available credit",
                                platformManager.availableCredit.map(Self.formatCurrency) ?? "Unavailable"
                            )]
                        )
                    ])
                    OpenAIMetricBlock(title: "TOKENS", metrics: [
                        OpenAIMetricValue(
                            label: "Today",
                            value: apiManager.todayTokens.map { formatAbbreviated($0) } ?? "--",
                            details: apiManager.usageByModel
                                .sorted { $0.todayTokens > $1.todayTokens }
                                .prefix(8)
                                .map { item in
                                    (
                                        [item.model, item.projectID].compactMap { $0 }.joined(separator: " · "),
                                        formatAbbreviated(item.todayTokens)
                                    )
                                }
                        ),
                        OpenAIMetricValue(
                            label: "This Week",
                            value: apiManager.weekTokens.map { formatAbbreviated($0) } ?? "--",
                            details: apiManager.usageByModel
                                .sorted { $0.tokens > $1.tokens }
                                .prefix(8)
                                .map { item in
                                    (
                                        [item.model, item.projectID].compactMap { $0 }.joined(separator: " · "),
                                        formatAbbreviated(item.tokens)
                                    )
                                }
                        )
                    ])
                    OpenAIMetricBlock(title: "REQUEST", metrics: [
                        OpenAIMetricValue(
                            label: "Today",
                            value: apiManager.todayRequests.map { formatAbbreviated($0) } ?? "--",
                            details: apiManager.usageByModel
                                .sorted { $0.todayRequests > $1.todayRequests }
                                .prefix(8)
                                .map { item in
                                    (
                                        [item.model, item.projectID].compactMap { $0 }.joined(separator: " · "),
                                        formatAbbreviated(item.todayRequests)
                                    )
                                }
                        ),
                        OpenAIMetricValue(
                            label: "This Week",
                            value: apiManager.weekRequests.map { formatAbbreviated($0) } ?? "--",
                            details: apiManager.usageByModel
                                .sorted { $0.requests > $1.requests }
                                .prefix(8)
                                .map { item in
                                    (
                                        [item.model, item.projectID].compactMap { $0 }.joined(separator: " · "),
                                        formatAbbreviated(item.requests)
                                    )
                                }
                        )
                    ])
                }

                if !apiManager.isConnected {
                    Text(apiManager.isLoading
                        ? "Loading API usage…"
                        : (apiManager.usageErrorMessage != nil || apiManager.costsErrorMessage != nil
                            ? "Check the Admin API key and organization permissions in Settings."
                            : "Add an Organization Admin API key in Settings to connect."))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 142, alignment: .topLeading)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))

            if let error = manager.errorMessage, manager.isConnected {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 8)
    }

    private static func formatCurrency(_ value: Double) -> String {
        "$\(String(format: "%.4f", value))"
    }
}

private struct OpenAIMetricValue: Identifiable {
    var id: String { label }
    let label: String
    let value: String
    let details: [(String, String)]
}

private struct OpenAIMetricBlock: View {
    let title: String
    let metrics: [OpenAIMetricValue]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 8) {
                ForEach(metrics) { metric in
                    OpenAIMetricAmount(metric: metric)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9))
    }
}

private struct OpenAIMetricAmount: View {
    let metric: OpenAIMetricValue
    @State private var showPopover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(metric.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(metric.value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .onHover { showPopover = $0 }
                .popover(isPresented: $showPopover) {
                    OpenAIMetricPopover(metric: metric)
                }
        }
        .contentShape(Rectangle())
    }
}

private struct OpenAIMetricPopover: View {
    let metric: OpenAIMetricValue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metric.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            if metric.details.isEmpty {
                Text("No breakdown available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(metric.details.enumerated()), id: \.offset) { _, detail in
                    HStack(spacing: 8) {
                        Text(detail.0)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer(minLength: 4)
                        Text(detail.1)
                            .font(.caption.weight(.medium))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 280)
    }
}

private struct GoogleAIProviderView: View {
    @ObservedObject var manager: AntigravityManager

    private var models: [AntigravityModelQuota] {
        manager.snapshot?.models ?? []
    }

    private var groups: [AntigravityQuotaGroup] {
        manager.snapshot?.groups ?? []
    }

    private var nextReset: Date? {
        (groups.compactMap(\.resetTime) + models.compactMap(\.resetTime)).min()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Antigravity")
                        .font(.title2.weight(.semibold))
                    Text("Shared weekly quota and prompt credits")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label(
                    manager.snapshot == nil ? "Not detected" : "Connected",
                    systemImage: manager.snapshot == nil ? "circle.dashed" : "checkmark.circle.fill"
                )
                    .font(.caption)
                    .foregroundStyle(manager.snapshot == nil ? Color.secondary : Color.green)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("PROMPT CREDITS")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(creditText(manager.snapshot?.availablePromptCredits))
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                    Text("available of \(creditText(manager.snapshot?.monthlyPromptCredits)) monthly")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let snapshot = manager.snapshot,
                       let available = snapshot.availablePromptCredits,
                       let monthly = snapshot.monthlyPromptCredits,
                       monthly > 0 {
                        ProgressView(value: min(max(available / monthly, 0), 1))
                            .tint(.blue)
                    } else {
                        ProgressView(value: 0)
                            .tint(.blue)
                    }
                    if let usedCredits = usedPromptCredits {
                        Text("\(creditText(usedCredits)) used")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Prompt credits")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
                .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 10) {
                    Label("NEXT RESET", systemImage: "clock.arrow.circlepath")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if let nextReset {
                        Text(nextReset.formatted(date: .abbreviated, time: .shortened))
                            .font(.title3.weight(.medium))
                    } else {
                        Text("Unavailable")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    if let lastUpdated = manager.lastUpdated {
                        Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(16)
                .frame(minWidth: 230, maxWidth: 230, minHeight: 130, alignment: .topLeading)
                .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
            }

            HStack {
                Text("SHARED WEEKLY QUOTAS")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if manager.isLoading { ProgressView().controlSize(.small) }
                Text("\(groups.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if groups.isEmpty, models.isEmpty {
                ContentUnavailableView {
                    Label("No model quota data", systemImage: "sparkles")
                } description: {
                    Text(manager.isLoading ? "Reading local quota…" : "Start Antigravity to read its local quota.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if !groups.isEmpty {
                            ForEach(groups) { group in
                                weeklyQuotaCard(group)
                            }
                            Text("Quota is shared within each group and weighted by token cost.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if !models.isEmpty {
                            HStack {
                                Text("MODEL DETAILS")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(models.count)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 2)
                        }

                        ForEach(models) { model in
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(model.displayName)
                                        .font(.callout.weight(.medium))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    if model.displayName != model.id {
                                        Text(model.id)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                    Text(model.resetTime.map {
                                        "Resets \($0.formatted(date: .abbreviated, time: .shortened))"
                                    } ?? "Reset time unavailable")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 8)
                                ProgressView(value: model.remainingFraction)
                                    .tint(.blue)
                                    .frame(width: 90)
                                Text("\(model.remainingPercent)%")
                                    .font(.callout.monospacedDigit().weight(.semibold))
                                    .frame(width: 48, alignment: .trailing)
                            }
                            .padding(10)
                            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 9))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if let warning = manager.snapshot?.warningMessage {
                Label(warning, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let error = manager.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func weeklyQuotaCard(_ group: AntigravityQuotaGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.callout.weight(.semibold))
                    Text("WEEKLY LIMIT")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(group.remainingPercent)% remaining")
                    .font(.callout.monospacedDigit().weight(.semibold))
            }
            ProgressView(value: group.remainingFraction)
                .tint(group.remainingPercent <= 15 ? .orange : .blue)
            HStack(alignment: .top) {
                Text("\(group.usedPercent)% used")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text(group.modelNames.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
            if let resetTime = group.resetTime {
                Text("Resets \(resetTime.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(11)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
    }

    private var usedPromptCredits: Double? {
        guard let available = manager.snapshot?.availablePromptCredits,
              let monthly = manager.snapshot?.monthlyPromptCredits else { return nil }
        return max(monthly - available, 0)
    }

    private func creditText(_ value: Double?) -> String {
        guard let value else { return "—" }
        if value.rounded() == value { return String(format: "%.0f", value) }
        return String(format: "%.2f", value)
    }
}

private struct ProviderValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
        }
        .font(.caption)
    }
}

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
            .environmentObject(OpenRouterCreditManager())
            .environmentObject(ChatGPTManager())
    }
}
