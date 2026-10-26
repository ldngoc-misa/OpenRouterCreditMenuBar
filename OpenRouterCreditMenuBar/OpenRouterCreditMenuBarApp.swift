//
//  OpenRouterCreditMenuBarApp.swift
//  OpenRouterCreditMenuBar
//
//  Created by Kittithat Patepakorn on 24/5/2568 BE.
//

import SwiftUI
import Combine

@main
struct OpenRouterCreditMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.creditManager)
                .environmentObject(appDelegate.chatGPTManager)
                .environmentObject(appDelegate.openAIAPIManager)
                .environmentObject(appDelegate.openAIPlatformLoginManager)
                .environmentObject(appDelegate.antigravityManager)
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    @Published var creditManager = OpenRouterCreditManager()
    @Published var chatGPTManager = ChatGPTManager()
    @Published var openAIAPIManager = OpenAIAPIManager()
    @Published var openAIPlatformLoginManager = OpenAIPlatformLoginManager()
    @Published var antigravityManager = AntigravityManager()

    // Bộ theo dõi sự kiện chuột để tự đóng popover khi click ra ngoài
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

    private var menuBarCancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // ซ่อน dock icon แต่ยังคงให้ app สามารถแสดง window ได่
        NSApp.setActivationPolicy(.accessory)

        // ปิดเฉพาะ main window ไม่ใช่ทุก window
        if let mainWindow = NSApp.windows.first(where: { $0.title.isEmpty }) {
            mainWindow.close()
        }

        // สร้าง menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let statusButton = statusItem?.button {
            statusButton.image = fallbackMenuBarImage()
            statusButton.imagePosition = .imageOnly
            statusButton.attributedTitle = NSAttributedString(string: "")
            statusButton.font = NSFont.menuBarFont(ofSize: 0)
            statusButton.action = #selector(showMenu)
            statusButton.target = self
        }

        observeMenuBarData()
        updateMenuBarTitle()

        // สร้าง popover
        popover = NSPopover()
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(creditManager)
                .environmentObject(chatGPTManager)
                .environmentObject(openAIAPIManager)
                .environmentObject(openAIPlatformLoginManager)
                .environmentObject(antigravityManager)
        )
        popover?.behavior = .transient
        popover?.delegate = self

        // .transient không đóng đáng tin cậy với app accessory,
        // nên thêm event monitor để tự đóng khi click ra ngoài
        setupOutsideClickDismissal()

        // เริ่ม fetch credit
        Task {
            await creditManager.fetchCredit()
            await openAIAPIManager.refresh()
        }
        antigravityManager.startMonitoring()

    }

    @objc func showMenu() {
        if let statusButton = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(
                    relativeTo: statusButton.bounds,
                    of: statusButton,
                    preferredEdge: .minY
                )
                DispatchQueue.main.async { [weak self] in
                    self?.keepPopoverOnScreen()
                }
            }
        }
    }

    private func keepPopoverOnScreen() {
        guard let popoverWindow = popover?.contentViewController?.view.window,
              let statusButton = statusItem?.button,
              let buttonWindow = statusButton.window,
              let screen = buttonWindow.screen ?? popoverWindow.screen else { return }

        let visibleFrame = screen.visibleFrame
        var frame = popoverWindow.frame
        let buttonScreenFrame = buttonWindow.convertToScreen(
            statusButton.convert(statusButton.bounds, to: nil)
        )
        let centeredLeft = buttonScreenFrame.midX - frame.width / 2
        let maximumLeft = max(visibleFrame.minX, visibleFrame.maxX - frame.width)
        frame.origin.x = min(max(centeredLeft, visibleFrame.minX), maximumLeft)
        popoverWindow.setFrame(frame, display: true)
    }

    // MARK: - Tự đóng popover khi click ra ngoài

    private func setupOutsideClickDismissal() {
        // Click trong các window của chính app (vd: cửa sổ Settings)
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.dismissPopoverIfClickOutside(event)
            return event
        }
        // Click ở các app khác
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.dismissPopoverIfClickOutside(event)
        }
    }

    private func dismissPopoverIfClickOutside(_ event: NSEvent) {
        guard let popover, popover.isShown else { return }

        // Bỏ qua click vào chính nút status item (showMenu() sẽ tự toggle)
        if let button = statusItem?.button,
           let buttonWindow = button.window,
           let cgEvent = event.cgEvent {
            let buttonScreenFrame = buttonWindow.convertToScreen(button.frame)
            if buttonScreenFrame.contains(cgEvent.location) {
                return
            }
        }

        // Bỏ qua click bên trong popover (event.window chỉ có từ local monitor)
        if let popoverWindow = popover.contentViewController?.view.window,
           event.window === popoverWindow {
            return
        }

        popover.performClose(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let localEventMonitor { NSEvent.removeMonitor(localEventMonitor) }
        if let globalEventMonitor { NSEvent.removeMonitor(globalEventMonitor) }
    }

    func updateMenuBarTitle() {
        let groups = MenuBarStatusFormatter.makeGroups(
            openRouterCredit: creditManager.isEnabled
                && !creditManager.apiKey.isEmpty
                && creditManager.creditErrorMessage == nil
                ? creditManager.currentCredit
                : nil,
            chatGPTRemainingPercent: chatGPTManager.isConnected
                ? chatGPTManager.usedPercent.map(MenuBarStatusFormatter.remainingPercent(fromUsedPercent:))
                : nil,
            openAIPlatformCredit: openAIPlatformLoginManager.isConnected
                ? openAIPlatformLoginManager.availableCredit
                : nil,
            antigravityRemainingPercent: antigravityManager.snapshot?.lowestQuotaRemainingPercent
        )

        if let statusButton = statusItem?.button {
            if groups.isEmpty {
                statusButton.image = fallbackMenuBarImage()
                statusButton.imagePosition = .imageOnly
                statusButton.attributedTitle = NSAttributedString(string: "")
            } else {
                statusButton.image = nil
                statusButton.attributedTitle = MenuBarStatusFormatter.attributedTitle(for: groups)
            }
        }
        let accessibilityLabel = groups
            .map { "\($0.provider.accessibilityName) \($0.values.joined(separator: " "))" }
            .joined(separator: ", ")
        statusItem?.button?.setAccessibilityLabel(
            accessibilityLabel.isEmpty ? "No connected provider balances" : accessibilityLabel
        )
    }

    private func fallbackMenuBarImage() -> NSImage? {
        let image = NSImage(
            systemSymbolName: AppSymbolName.popupTitle,
            accessibilityDescription: "AI Credit Monitor"
        )?.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 14, weight: .medium))
        image?.isTemplate = true
        return image
    }

    private func observeMenuBarData() {
        let changes: [AnyPublisher<Void, Never>] = [
            creditManager.$currentCredit.map { _ in () }.eraseToAnyPublisher(),
            creditManager.$creditErrorMessage.map { _ in () }.eraseToAnyPublisher(),
            chatGPTManager.$isConnected.map { _ in () }.eraseToAnyPublisher(),
            chatGPTManager.$usedPercent.map { _ in () }.eraseToAnyPublisher(),
            openAIPlatformLoginManager.$isConnected.map { _ in () }.eraseToAnyPublisher(),
            openAIPlatformLoginManager.$availableCredit.map { _ in () }.eraseToAnyPublisher(),
            antigravityManager.$snapshot.map { _ in () }.eraseToAnyPublisher(),
            NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
                .map { _ in () }
                .eraseToAnyPublisher()
        ]

        Publishers.MergeMany(changes)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateMenuBarTitle() }
            .store(in: &menuBarCancellables)
    }

    // MARK: - NSPopoverDelegate

    func popoverDidShow(_ notification: Notification) {
        creditManager.pauseMonitoring()
        print("[OpenRouter] Popover shown - auto refresh paused")
    }

    func popoverDidClose(_ notification: Notification) {
        creditManager.resumeMonitoring()
        print("[OpenRouter] Popover closed - auto refresh resumed")
    }
}

enum ProviderIconName {
    static let openRouter = "point.3.connected.trianglepath.dotted"
    static let chatGPT = "bubble.left"
    static let openAI = "terminal"
    static let googleAI = "AntigravityProviderIcon"
}

enum ProviderIconColor {
    static let openRouter: UInt32 = 0xC8FE03
    static let chatGPT: UInt32 = 0x71D6B5
    static let openAI: UInt32 = 0x358AFF
    static let googleAI: UInt32 = 0x9065B6

    static func swiftUIColor(hex: UInt32) -> Color {
        Color(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    static func nsColor(hex: UInt32) -> NSColor {
        NSColor(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

enum ProviderIcon: Equatable {
    case symbol(String)
    case asset(String)

    @ViewBuilder
    func swiftUIImage(size: CGFloat = 13) -> some View {
        switch self {
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: size, weight: .regular))
        case .asset(let name):
            Image(name)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        }
    }
}

enum AppSymbolName {
    static let popupTitle = "square.stack.3d.up"
}

struct MenuBarStatusGroup: Equatable {
    enum Provider: Equatable {
        case openRouter
        case chatGPT
        case openAI
        case googleAI

        var icon: ProviderIcon {
            switch self {
            case .openRouter: .symbol(ProviderIconName.openRouter)
            case .chatGPT: .symbol(ProviderIconName.chatGPT)
            case .openAI: .symbol(ProviderIconName.openAI)
            case .googleAI: .asset(ProviderIconName.googleAI)
            }
        }

        var accessibilityName: String {
            switch self {
            case .openRouter: "OpenRouter"
            case .chatGPT: "ChatGPT"
            case .openAI: "OpenAI"
            case .googleAI: "Google AI"
            }
        }

        var iconColorHex: UInt32 {
            switch self {
            case .openRouter: ProviderIconColor.openRouter
            case .chatGPT: ProviderIconColor.chatGPT
            case .openAI: ProviderIconColor.openAI
            case .googleAI: ProviderIconColor.googleAI
            }
        }
    }

    let provider: Provider
    let values: [String]
}

enum MenuBarStatusFormatter {
    static func remainingPercent(fromUsedPercent usedPercent: Int) -> Int {
        Int((100.0 - Double(usedPercent)).rounded(.toNearestOrAwayFromZero))
    }

    static func formatCurrency(_ amount: Double) -> String {
        let roundedAmount: Double
        let formattedAmount: String
        if abs(amount) < 10 {
            roundedAmount = (amount * 10).rounded(.toNearestOrAwayFromZero) / 10
            formattedAmount = String(format: "%.1f", roundedAmount)
        } else {
            roundedAmount = amount.rounded(.toNearestOrAwayFromZero)
            formattedAmount = String(format: "%.0f", roundedAmount)
        }
        return "$\(formattedAmount)"
    }

    static func makeGroups(
        openRouterCredit: Double?,
        chatGPTRemainingPercent: Int?,
        openAIPlatformCredit: Double?,
        antigravityRemainingPercent: Int? = nil
    ) -> [MenuBarStatusGroup] {
        var groups: [MenuBarStatusGroup] = []

        if let openRouterCredit {
            groups.append(MenuBarStatusGroup(
                provider: .openRouter,
                values: [formatCurrency(openRouterCredit)]
            ))
        }

        if let chatGPTRemainingPercent {
            groups.append(MenuBarStatusGroup(
                provider: .chatGPT,
                values: ["\(chatGPTRemainingPercent)%"]
            ))
        }
        if let openAIPlatformCredit {
            groups.append(MenuBarStatusGroup(
                provider: .openAI,
                values: [formatCurrency(openAIPlatformCredit)]
            ))
        }

        if let antigravityRemainingPercent {
            groups.append(MenuBarStatusGroup(
                provider: .googleAI,
                values: ["\(antigravityRemainingPercent)%"]
            ))
        }

        return groups
    }

    static func attributedTitle(for groups: [MenuBarStatusGroup]) -> NSAttributedString {
        let title = NSMutableAttributedString(string: "")
        let font = NSFont.menuBarFont(ofSize: 0)
        guard !groups.isEmpty else { return title }

        title.append(NSAttributedString(string: "{ ", attributes: [.font: font]))

        for (index, group) in groups.enumerated() {
            if index > 0 {
                let separator = NSMutableAttributedString(string: "  ", attributes: [.font: font])
                separator.append(NSAttributedString(
                    string: "●",
                    attributes: [
                        .font: NSFont.systemFont(ofSize: 5.5, weight: .regular),
                        .baselineOffset: 2,
                        .foregroundColor: NSColor.tertiaryLabelColor.withAlphaComponent(0.45)
                    ]
                ))
                separator.append(NSAttributedString(string: "  ", attributes: [.font: font]))
                title.append(separator)
            }

            if let image = tintedProviderImage(for: group.provider) {
                let attachment = NSTextAttachment()
                attachment.image = image
                attachment.bounds = CGRect(x: 0, y: -2, width: 13, height: 13)
                title.append(NSAttributedString(attachment: attachment))
            }

            title.append(NSAttributedString(
                string: " \(group.values.joined(separator: " "))",
                attributes: [.font: font]
            ))
        }

        title.append(NSAttributedString(string: " }", attributes: [.font: font]))
        return title
    }

    private static func tintedProviderImage(for provider: MenuBarStatusGroup.Provider) -> NSImage? {
        let sourceImage: NSImage
        switch provider.icon {
        case .symbol(let name):
            guard let symbol = NSImage(
                systemSymbolName: name,
                accessibilityDescription: provider.accessibilityName
            )?.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)) else {
                return nil
            }
            sourceImage = symbol
        case .asset(let name):
            guard let asset = NSImage(named: name) else { return nil }
            sourceImage = asset
        }

        let bounds = NSRect(origin: .zero, size: sourceImage.size)
        let image = NSImage(size: sourceImage.size)
        image.lockFocus()
        sourceImage.draw(in: bounds, from: bounds, operation: .sourceOver, fraction: 1)
        if let context = NSGraphicsContext.current?.cgContext {
            context.saveGState()
            context.setBlendMode(.sourceAtop)
            context.setFillColor(ProviderIconColor.nsColor(hex: provider.iconColorHex).cgColor)
            context.fill(bounds)
            context.restoreGState()
        }
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

}
