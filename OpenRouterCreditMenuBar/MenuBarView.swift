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
                    .frame(width: 80, alignment: .trailing)
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
    let title: String
    let models: [TopModel]
    let sortMode: PaidModelSortMode
    let onTokensClick: () -> Void
    let onPriceClick: () -> Void

    // Determine if this is the "Paid" or "Free" column for styling
    private var isPaidColumn: Bool {
        title.lowercased() == "paid"
    }

    private var categoryColor: Color {
        isPaidColumn ? Color.orange : Color.green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Category label - styled as a badge/pill to clearly distinguish from column headers
            HStack(spacing: 6) {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 6, height: 6)
                Text(title.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(categoryColor)
                    .textCase(.uppercase)
                // Subtle separator line extending to the right
                Rectangle()
                    .fill(categoryColor.opacity(0.3))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)

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
                        categoryColor: isPaidColumn ? Color.orange : Color.green,
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
    let categoryColor: Color
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
                Text("Model")
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
                    .frame(width: 80, alignment: .trailing)
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
                                title: "Paid",
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
                                title: "Free",
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
                .padding(.bottom, 15)

            // MARK: - Line 2: Credit | Requests | Tokens - FIXED HEIGHT (300px for 15 items)
            HStack(alignment: .top, spacing: 12) {
                MetricBlock(
                    title: "CREDIT",
                    isLoading: creditManager.isLoading,
                    errorMessage: creditManager.creditErrorMessage,
                    content: AnyView(creditContent)
                )

                Divider()
                    .frame(height: 56)
                    .frame(maxHeight: .infinity, alignment: .top)

                MetricBlock(
                    title: "REQUESTS",
                    isLoading: creditManager.isLoading,
                    errorMessage: creditManager.requestsErrorMessage,
                    content: AnyView(requestsContent)
                )

                Divider()
                    .frame(height: 56)
                    .frame(maxHeight: .infinity, alignment: .top)

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
                .padding(.bottom, 15)

            // MARK: - Line 3: Top Models (Full Width) - FIXED HEIGHT (300px with scroll)
            TopModelsBlock(
                isLoading: creditManager.isLoading,
                errorMessage: creditManager.topModelsErrorMessage,
                paidModels: creditManager.topModelsPaid,
                freeModels: creditManager.topModelsFree,
                creditManager: creditManager
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
