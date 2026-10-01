//
//  OpenRouterCreditMenuBarApp.swift
//  OpenRouterCreditMenuBar
//
//  Created by Kittithat Patepakorn on 24/5/2568 BE.
//

import SwiftUI

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

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    @Published var creditManager = OpenRouterCreditManager()

    // Popover width must match MenuBarView's frame width so the
    // centered anchor rect aligns properly.
    private let popoverWidth: CGFloat = 240

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
            statusButton.title = "Loading..."
            statusButton.action = #selector(showMenu)
            statusButton.target = self
        }

        // สร้าง popover
        popover = NSPopover()
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(creditManager)
        )
        popover?.behavior = .transient

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

    func updateMenuBarTitle() {
        if let credit = creditManager.currentCredit {
            statusItem?.button?.title = "$\(String(format: "%.2f", credit))"
        } else {
            statusItem?.button?.title = "Error"
        }
    }
}
