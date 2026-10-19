//
//  SettingsView.swift
//  OpenRouterCreditMenuBar
//

import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var creditManager: OpenRouterCreditManager
    @EnvironmentObject var chatGPTManager: ChatGPTManager
    @State private var apiKey: String = ""
    @State private var isEnabled: Bool = true
    @State private var openAtLogin: Bool = false
    @State private var refreshInterval: Double = 300  // default 5 minutes
    @State private var isShowingChatGPTLogin = false

    private let refreshIntervalOptions: [Double] = [30, 60, 180, 300, 600, 1800, 3600]

    var body: some View {
        Form {
            Section("General") {
                Toggle("Enable Credit Monitoring", isOn: $isEnabled)
                    .onChange(of: isEnabled) { _, newValue in
                        creditManager.isEnabled = newValue
                        if newValue {
                            Task {
                                await creditManager.fetchCredit()
                            }
                        }
                    }

                Toggle("Open at Login", isOn: $openAtLogin)
                    .onChange(of: openAtLogin) { _, newValue in
                        setLoginItemEnabled(newValue)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Picker("Refresh Interval", selection: $refreshInterval) {
                        Text("30 seconds").tag(30.0)
                        Text("1 minute").tag(60.0)
                        Text("3 minutes").tag(180.0)
                        Text("5 minutes").tag(300.0)
                        Text("10 minutes").tag(600.0)
                        Text("30 minutes").tag(1800.0)
                        Text("1 hour").tag(3600.0)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: refreshInterval) { _, newValue in
                        creditManager.refreshInterval = newValue
                        chatGPTManager.setRefreshInterval(newValue)
                    }

                    Text("Applies to all connected providers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("OpenRouter") {
                Text("Credit balance, spend, requests, tokens, and model activity")
                    .font(.caption)
                    .foregroundColor(.secondary)

                SecureField("OpenRouter API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: apiKey) { _, newValue in
                        creditManager.apiKey = newValue
                    }
                HStack {
                    Button("Test Connection") {
                        Task {
                            await creditManager.fetchCredit()
                        }
                    }
                    .disabled(apiKey.isEmpty)

                    if creditManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                }
            }

            Section("OpenAI") {
                LabeledContent("ChatGPT", value: chatGPTManager.isConnected ? "Connected" : "Not connected")
                if let email = chatGPTManager.accountEmail {
                    LabeledContent("Account", value: email)
                }
                HStack {
                    Button(chatGPTManager.isConnected ? "Open ChatGPT Login" : "Connect ChatGPT") {
                        chatGPTManager.openLogin()
                        isShowingChatGPTLogin = true
                    }
                    if chatGPTManager.isConnected {
                        Button("Disconnect", role: .destructive) { chatGPTManager.disconnect() }
                    }
                    if chatGPTManager.isLoading {
                        ProgressView().controlSize(.small)
                    }
                }
                if let error = chatGPTManager.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Text("Sign in to ChatGPT in the embedded window. The session stays on this Mac for automatic refresh.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Antigravity") {
                LabeledContent("Account", value: "Not connected")
                LabeledContent("Quota monitoring", value: "Not connected")
                Text("Antigravity account and quota connection will be configured here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let error = creditManager.errorMessage {
                Section("Status") {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: 400, maxHeight: .infinity)
        .onAppear {
            loadSettings()
        }
        .sheet(isPresented: $isShowingChatGPTLogin) {
            ChatGPTLoginSheet(manager: chatGPTManager)
                .frame(minWidth: 720, minHeight: 600)
        }
    }

    private func loadSettings() {
        apiKey = creditManager.apiKey
        isEnabled = creditManager.isEnabled
        refreshInterval = creditManager.refreshInterval
        openAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func setLoginItemEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") login item: \(error)")
        }
    }
}

private struct ChatGPTLoginSheet: View {
    @ObservedObject var manager: ChatGPTManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(manager.isConnected ? "ChatGPT connected" : "Sign in to ChatGPT")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(12)
            Divider()
            ChatGPTWebView(manager: manager)
        }
    }
}
