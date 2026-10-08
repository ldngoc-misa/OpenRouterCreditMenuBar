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
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    @Published var creditManager = OpenRouterCreditManager()

    // Bộ theo dõi sự kiện chuột để tự đóng popover khi click ra ngoài
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

    // Popover width must match MenuBarView's frame width so the
    // centered anchor rect aligns properly.
    private let popoverWidth: CGFloat = 240
    
    // Loading animation timer
    private var loadingTimer: Timer?
    private var loadingFrame = 0
    // Smooth spinner frames - similar to ProgressView spinner
    private let loadingFrames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    
    // Track if we're currently showing loading state
    private var isShowingLoading = false
    
    // Combine cancellable for observing isLoading changes
    private var loadingCancellable: AnyCancellable?

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
            // Set the menu bar icon (template image adapts to light/dark mode)
            if let menuIcon = NSImage(named: "MenuBarIcon") {
                menuIcon.isTemplate = true
                statusButton.image = menuIcon
                statusButton.imagePosition = .imageLeft
            }
            statusButton.title = "Loading..."
            statusButton.action = #selector(showMenu)
            statusButton.target = self
            // Set minimum width to prevent UI jumping when switching between loading and credit display
            // +16px to accommodate the menu bar icon
            statusItem?.length = 56
        }

        // สร้าง popover
        popover = NSPopover()
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(creditManager)
        )
        popover?.behavior = .transient
        popover?.delegate = self

        // .transient không đóng đáng tin cậy với app accessory,
        // nên thêm event monitor để tự đóng khi click ra ngoài
        setupOutsideClickDismissal()

        // Observe isLoading changes to show/hide loading animation on menubar
        loadingCancellable = creditManager.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateMenuBarTitleForLoading(isLoading)
            }

        // เริ่ม fetch credit
        Task {
            await creditManager.fetchCredit()
            await MainActor.run {
                updateMenuBarTitle()
            }
        }

        // ตั้ง timer สำหรับ refresh
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                await self.creditManager.fetchCredit()
                await MainActor.run {
                    self.updateMenuBarTitle()
                }
            }
        }
    }

    @objc func showMenu() {
        if let statusButton = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                // Build a wide anchor rect that matches the popover width and
                // is centered on the status button.  NSPopover positions the
                // popover relative to this rect, so a matched-width centered
                // rect keeps the popover centered under the menu bar item
                // without needing to move the window after showing.
                let buttonBounds = statusButton.bounds
                let anchorRect = NSRect(
                    x: buttonBounds.midX - popoverWidth / 2,
                    y: 0,
                    width: popoverWidth,
                    height: buttonBounds.height
                )
                popover?.show(
                    relativeTo: anchorRect,
                    of: statusButton,
                    preferredEdge: .minY
                )
            }
        }
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
        loadingTimer?.invalidate()
        loadingTimer = nil
    }

    func updateMenuBarTitle() {
        // Called after fetch completes - shows final credit value
        stopLoadingAnimation()
        if let credit = creditManager.currentCredit {
            statusItem?.button?.title = "$\(String(format: "%.2f", credit))"
        } else {
            statusItem?.button?.title = "Error"
        }
    }
    
    private func updateMenuBarTitleForLoading(_ isLoading: Bool) {
        // Called when isLoading changes - handles loading animation
        if isLoading {
            startLoadingAnimation()
        } else {
            // Loading finished - stop animation and show credit
            stopLoadingAnimation()
            if let credit = creditManager.currentCredit {
                statusItem?.button?.title = "$\(String(format: "%.2f", credit))"
            } else {
                statusItem?.button?.title = "Error"
            }
        }
    }
    
    private func startLoadingAnimation() {
        guard !isShowingLoading else { return }
        isShowingLoading = true
        loadingFrame = 0
        
        // Initial frame - use smooth spinner frames
        statusItem?.button?.title = loadingFrames[0]
        
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.loadingFrame = (self.loadingFrame + 1) % self.loadingFrames.count
            self.statusItem?.button?.title = self.loadingFrames[self.loadingFrame]
        }
    }
    
    private func stopLoadingAnimation() {
        loadingTimer?.invalidate()
        loadingTimer = nil
        isShowingLoading = false
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
