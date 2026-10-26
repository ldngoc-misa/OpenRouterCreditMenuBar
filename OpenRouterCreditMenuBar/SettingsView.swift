//
//  SettingsView.swift
//  OpenRouterCreditMenuBar
//

import ServiceManagement
import SwiftUI
import WebKit

struct SettingsView: View {
    @EnvironmentObject var creditManager: OpenRouterCreditManager
    @EnvironmentObject var chatGPTManager: ChatGPTManager
    @EnvironmentObject var openAIAPIManager: OpenAIAPIManager
    @EnvironmentObject var openAIPlatformLoginManager: OpenAIPlatformLoginManager
    @EnvironmentObject var antigravityManager: AntigravityManager
    @State private var apiKey: String = ""
    @State private var openAIAdminAPIKey: String = ""
    @State private var openAtLogin: Bool = false
    @State private var refreshInterval: Double = 300  // default 5 minutes
    @State private var isShowingChatGPTLogin = false
    @State private var isShowingOpenAIPlatformLogin = false

    private let refreshIntervalOptions: [Double] = [30, 60, 180, 300, 600, 1800, 3600]

    var body: some View {
        Form {
            Section("General") {
                Toggle("Open at Login", isOn: $openAtLogin)
                    .onChange(of: openAtLogin) { _, newValue in
                        setLoginItemEnabled(newValue)
                    }

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
                    openAIAPIManager.setRefreshInterval(newValue)
                    openAIPlatformLoginManager.setRefreshInterval(newValue)
                    antigravityManager.setRefreshInterval(newValue)
                }
            }

            Section {
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
                    } else if creditManager.currentCredit != nil && creditManager.creditErrorMessage == nil {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Connected")
                        }
                        .font(.caption)
                        .foregroundStyle(.green)
                    }
                }
            } header: {
                providerSectionHeader(
                    "OpenRouter",
                    icon: .symbol(ProviderIconName.openRouter),
                    color: ProviderIconColor.swiftUIColor(hex: ProviderIconColor.openRouter),
                    isConnected: creditManager.isConnected,
                    isMonitoringEnabled: Binding(
                        get: { creditManager.isConnected && creditManager.isMonitoringEnabled },
                        set: { creditManager.setMonitoringEnabled($0) }
                    )
                )
            }

            Section {
                SettingsGroupCard(title: "Account", systemImage: "person.crop.circle") {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledContent(
                            "Signed in as",
                            value: chatGPTManager.accountEmail
                                ?? (chatGPTManager.isConnected ? "Email unavailable" : "Not connected")
                        )
                        HStack {
                            Button(chatGPTManager.isConnected ? "Login ChatGPT" : "Connect ChatGPT") {
                                chatGPTManager.openLogin()
                                isShowingChatGPTLogin = true
                            }
                            if chatGPTManager.isConnected {
                                Button("Disconnect", role: .destructive) { chatGPTManager.disconnect() }
                            }
                            if chatGPTManager.isConnected {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Connected")
                                }
                                .font(.caption)
                                .foregroundStyle(.green)
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
                    }
                }
            } header: {
                providerSectionHeader(
                    "ChatGPT",
                    icon: .symbol(ProviderIconName.chatGPT),
                    color: ProviderIconColor.swiftUIColor(hex: ProviderIconColor.chatGPT),
                    isConnected: chatGPTManager.isConnected,
                    isMonitoringEnabled: Binding(
                        get: { chatGPTManager.isConnected && chatGPTManager.isMonitoringEnabled },
                        set: { chatGPTManager.setMonitoringEnabled($0) }
                    )
                )
            }

            Section {
                SettingsGroupCard(title: "Platform API", systemImage: "chart.bar.xaxis") {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("Admin API key", text: $openAIAdminAPIKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                            .onChange(of: openAIAdminAPIKey) { _, newValue in
                                openAIAPIManager.adminAPIKey = newValue
                            }
                        HStack {
                            Button("Test Connection") {
                                Task { await openAIAPIManager.refresh() }
                            }
                            .disabled(openAIAdminAPIKey.isEmpty || openAIAPIManager.isLoading)

                            if openAIAPIManager.isLoading {
                                ProgressView().controlSize(.small)
                            } else if openAIAPIManager.isConnected {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Connected")
                                }
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                        if let error = openAIAPIManager.usageErrorMessage ?? openAIAPIManager.costsErrorMessage {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        LabeledContent(
                            "Account",
                            value: openAIPlatformLoginManager.accountEmail
                                ?? (openAIPlatformLoginManager.isConnected ? "Email unavailable" : "Not connected")
                        )

                        if openAIPlatformLoginManager.isConnected,
                           openAIPlatformLoginManager.organizations.isEmpty {
                            LabeledContent("Organization") {
                                HStack {
                                    Text(openAIPlatformLoginManager.isLoading ? "Loading…" : "Unavailable")
                                        .foregroundStyle(.secondary)
                                    Button("Refresh") {
                                        openAIPlatformLoginManager.refreshAccount()
                                    }
                                }
                            }
                        } else if !openAIPlatformLoginManager.organizations.isEmpty {
                            Picker(
                                "Organization",
                                selection: Binding(
                                    get: { openAIPlatformLoginManager.selectedOrganizationID ?? "" },
                                    set: { openAIPlatformLoginManager.selectOrganization($0) }
                                )
                            ) {
                                ForEach(openAIPlatformLoginManager.organizations) { organization in
                                    Text(organization.displayName).tag(organization.id)
                                }
                            }
                            .disabled(openAIPlatformLoginManager.isLoading)
                        }

                        HStack {
                            Button(openAIPlatformLoginManager.isConnected ? "Login OpenAI" : "Connect OpenAI") {
                                openAIPlatformLoginManager.beginLogin()
                                isShowingOpenAIPlatformLogin = true
                            }
                            if openAIPlatformLoginManager.isConnected {
                                Button("Disconnect", role: .destructive) {
                                    openAIPlatformLoginManager.disconnect()
                                }
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Connected")
                                }
                                .font(.caption)
                                .foregroundStyle(.green)
                            }
                            if openAIPlatformLoginManager.isLoading {
                                ProgressView().controlSize(.small)
                            }
                        }
                        if let error = openAIPlatformLoginManager.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            } header: {
                providerSectionHeader(
                    "OpenAI",
                    icon: .symbol(ProviderIconName.openAI),
                    color: ProviderIconColor.swiftUIColor(hex: ProviderIconColor.openAI),
                    isConnected: openAIAPIManager.isConnected || openAIPlatformLoginManager.isConnected,
                    isMonitoringEnabled: Binding(
                        get: {
                            let isConnected = openAIAPIManager.isConnected || openAIPlatformLoginManager.isConnected
                            let isMonitoringEnabled = openAIAPIManager.isMonitoringEnabled
                                || openAIPlatformLoginManager.isMonitoringEnabled
                            return isConnected && isMonitoringEnabled
                        },
                        set: { enabled in
                            openAIAPIManager.setMonitoringEnabled(enabled)
                            openAIPlatformLoginManager.setMonitoringEnabled(enabled)
                        }
                    )
                )
            }

            Section {
                LabeledContent("Quota source", value: "agy /usage + language server")
                LabeledContent(
                    "Status",
                    value: antigravityManager.isLoading
                        ? "Checking…"
                        : antigravityManager.isConnected ? "Connected" : "Not detected"
                )
                if let lastUpdated = antigravityManager.lastUpdated {
                    LabeledContent("Last updated", value: lastUpdated.formatted(date: .abbreviated, time: .shortened))
                }
                HStack {
                    Button("Refresh") {
                        Task { await antigravityManager.refresh() }
                    }
                    .disabled(antigravityManager.isLoading)
                    if antigravityManager.isLoading {
                        ProgressView().controlSize(.small)
                    }
                }
                if let error = antigravityManager.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                providerSectionHeader(
                    "Google AI",
                    icon: .asset(ProviderIconName.googleAI),
                    color: ProviderIconColor.swiftUIColor(hex: ProviderIconColor.googleAI),
                    isConnected: antigravityManager.isConnected,
                    isMonitoringEnabled: Binding(
                        get: { antigravityManager.isConnected && antigravityManager.isMonitoringEnabled },
                        set: { antigravityManager.setMonitoringEnabled($0) }
                    )
                )
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
        .sheet(isPresented: $isShowingOpenAIPlatformLogin) {
            OpenAIPlatformLoginSheet(manager: openAIPlatformLoginManager)
                .frame(minWidth: 720, minHeight: 600)
        }
    }

    private func loadSettings() {
        apiKey = creditManager.apiKey
        openAIAdminAPIKey = openAIAPIManager.adminAPIKey
        refreshInterval = creditManager.refreshInterval
        openAtLogin = SMAppService.mainApp.status == .enabled
        openAIAPIManager.setRefreshInterval(refreshInterval)
        openAIPlatformLoginManager.setRefreshInterval(refreshInterval)
        antigravityManager.setRefreshInterval(refreshInterval)
    }

    private func providerSectionHeader(
        _ title: String,
        icon: ProviderIcon,
        color: Color,
        isConnected: Bool,
        isMonitoringEnabled: Binding<Bool>
    ) -> some View {
        HStack(spacing: 6) {
            icon.swiftUIImage(size: 16)
                .foregroundStyle(color)
            Text(title)
            Spacer(minLength: 8)
            Toggle("Enable \(title) credit monitoring", isOn: isMonitoringEnabled)
                .labelsHidden()
                .disabled(!isConnected)
        }
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

private struct SettingsGroupCard<Content: View>: View {
    private let title: String
    private let systemImage: String
    private let content: Content

    init(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
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

private struct OpenAIPlatformLoginSheet: View {
    @ObservedObject var manager: OpenAIPlatformLoginManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(manager.isConnected ? "OpenAI Platform connected" : "Sign in to OpenAI Platform")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    manager.refreshAccount()
                    dismiss()
                }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(12)
            Divider()
            OpenAIPlatformWebView(manager: manager)
        }
    }
}

private struct OpenAIPlatformWebView: NSViewRepresentable {
    @ObservedObject var manager: OpenAIPlatformLoginManager

    func makeNSView(context: Context) -> WKWebView { manager.browserView }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
