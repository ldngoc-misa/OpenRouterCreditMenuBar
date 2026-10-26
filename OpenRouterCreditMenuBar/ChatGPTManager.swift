//
//  ChatGPTManager.swift
//  OpenRouterCreditMenuBar
//

import Combine
import CoreFoundation
import Foundation
import SwiftUI
import WebKit

struct ChatGPTMetric: Identifiable {
    let id = UUID()
    let name: String
    let value: String
}

@MainActor
final class ChatGPTManager: NSObject, ObservableObject {
    private static let monitoringDefaultsKey = "chatgpt_monitoring_enabled"

    @Published private(set) var isConnected = false {
        didSet {
            guard oldValue != isConnected else { return }
            setMonitoringEnabled(isConnected)
        }
    }
    @Published private(set) var isMonitoringEnabled = UserDefaults.standard.bool(forKey: "chatgpt_monitoring_enabled")
    @Published private(set) var isLoading = false
    @Published private(set) var accountEmail: String?
    @Published private(set) var planType: String?
    @Published private(set) var usedPercent: Int?
    @Published private(set) var resetAt: Date?
    @Published private(set) var usageOverview: [ChatGPTMetric] = []
    @Published private(set) var usageOverviewDays = 7
    @Published private(set) var modelUsage: [ChatGPTMetric] = []
    @Published private(set) var analyticsDays = 7
    @Published private(set) var analyticsErrorMessage: String?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var errorMessage: String?

    let browserView: WKWebView
    private var refreshTimer: Timer?
    private var refreshInterval: TimeInterval = {
        let interval = UserDefaults.standard.double(forKey: "refresh_interval")
        return interval > 0 ? interval : 300
    }()

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        browserView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        browserView.navigationDelegate = self
        setupRefreshTimer()
        browserView.load(URLRequest(url: URL(string: "https://chatgpt.com/")!))
    }

    func setRefreshInterval(_ interval: TimeInterval) {
        refreshInterval = interval
        setupRefreshTimer()
    }

    func setMonitoringEnabled(_ enabled: Bool) {
        let shouldEnable = isConnected && enabled
        if isMonitoringEnabled != shouldEnable {
            isMonitoringEnabled = shouldEnable
            UserDefaults.standard.set(shouldEnable, forKey: Self.monitoringDefaultsKey)
        }
        setupRefreshTimer()
    }

    func setAnalyticsDays(_ days: Int) {
        guard [7, 30].contains(days), analyticsDays != days, !isLoading else { return }
        analyticsDays = days
        if isConnected { refresh() }
    }

    func setUsageOverviewDays(_ days: Int) {
        guard [7, 30].contains(days), usageOverviewDays != days, !isLoading else { return }
        usageOverviewDays = days
        if isConnected { refresh() }
    }

    func openLogin() {
        if browserView.url == nil || browserView.url?.host != "chatgpt.com" {
            browserView.load(URLRequest(url: URL(string: "https://chatgpt.com/")!))
        }
    }

    func disconnect() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        let store = WKWebsiteDataStore.default()
        store.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { [weak self] records in
            let chatGPTRecords = records.filter { $0.displayName.contains("chatgpt.com") }
            store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: chatGPTRecords) {
                Task { @MainActor in
                    self?.clearAccountData()
                    self?.browserView.load(URLRequest(url: URL(string: "https://chatgpt.com/")!))
                    self?.setupRefreshTimer()
                }
            }
        }
    }

    func refresh() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        let script = """
          const sessionResponse = await fetch('/api/auth/session', {credentials: 'include'});
          const session = sessionResponse.ok ? await sessionResponse.json() : {};
          if (!session.accessToken) return JSON.stringify({unauthenticated: true});
          const headers = { 'accept': 'application/json' };
          headers['authorization'] = `Bearer ${session.accessToken}`;
          const request = async (path, accountId) => {
            const requestHeaders = {...headers};
            if (accountId) requestHeaders['chatgpt-account-id'] = accountId;
            const response = await fetch(path, {credentials: 'include', headers: requestHeaders});
            if (!response.ok) throw new Error(`Request failed (${response.status})`);
            return await response.json();
          };
          const usage = await request('/backend-api/wham/usage');
          const accountId = usage.account_id;
          const date = value => value.toISOString().slice(0, 10);
          const range = days => {
            const end = new Date();
            const start = new Date(end);
            start.setDate(start.getDate() - (days - 1));
            return `start_date=${date(start)}&end_date=${date(end)}&group_by=day`;
          };
          const analyticsRange = range(\(analyticsDays));
          const overviewRange = range(\(usageOverviewDays));
          const paths = [
            `/backend-api/wham/usage/daily-token-usage-breakdown?${analyticsRange}`,
            `/backend-api/wham/analytics/daily-workspace-usage-counts?${overviewRange}&workspace_user=true`
          ];
          const results = await Promise.allSettled(paths.map(path => request(path, accountId)));
          return JSON.stringify({usage, analytics: results.map(result =>
            result.status === 'fulfilled' ? result.value : {error: result.reason?.message || 'Request failed'}
          )});
        """

        browserView.callAsyncJavaScript(script, arguments: [:], in: nil, in: .page) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                defer { self.isLoading = false }
                guard case .success(let value) = result else {
                    if case .failure = result {
                        if self.isConnected {
                            self.errorMessage = "Could not refresh ChatGPT data. Your session may have expired; sign in again."
                        } else {
                            self.errorMessage = nil
                        }
                    }
                    return
                }
                guard let json = value as? String,
                      let data = json.data(using: .utf8),
                      let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self.errorMessage = self.isConnected
                        ? "Could not read ChatGPT account data. Sign in again to reconnect."
                        : nil
                    return
                }
                if payload["unauthenticated"] as? Bool == true {
                    let hadSession = self.isConnected
                    self.isConnected = false
                    self.setupRefreshTimer()
                    self.errorMessage = hadSession ? "Your ChatGPT session expired. Sign in again to reconnect." : nil
                    return
                }
                guard let usage = payload["usage"] as? [String: Any] else {
                    self.errorMessage = "Could not read ChatGPT account data. Sign in again to reconnect."
                    return
                }
                self.apply(usage: usage, analytics: payload["analytics"] as? [[String: Any]] ?? [])
            }
        }
    }

    private func setupRefreshTimer() {
        refreshTimer?.invalidate()
        guard isConnected && isMonitoringEnabled else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    private func apply(usage: [String: Any], analytics: [[String: Any]]) {
        isConnected = true
        accountEmail = usage["email"] as? String
        planType = usage["plan_type"] as? String
        if let rateLimit = usage["rate_limit"] as? [String: Any],
           let window = rateLimit["primary_window"] as? [String: Any] {
            usedPercent = window["used_percent"] as? Int
            if let reset = window["reset_at"] as? TimeInterval {
                resetAt = Date(timeIntervalSince1970: reset)
            } else {
                resetAt = nil
            }
        }

        usageOverview = Self.makeOverview(from: analytics.count > 1 ? analytics[1] : [:])
        let tokenResponse = analytics.first ?? [:]
        modelUsage = Self.makeModelUsage(from: tokenResponse)
        analyticsErrorMessage = tokenResponse["error"] == nil
            ? nil
            : "Model usage could not be loaded."
        lastUpdated = Date()
        errorMessage = nil
        setupRefreshTimer()
    }

    private func clearAccountData() {
        isConnected = false
        accountEmail = nil
        planType = nil
        usedPercent = nil
        resetAt = nil
        usageOverview = []
        modelUsage = []
        analyticsErrorMessage = nil
        lastUpdated = nil
        errorMessage = nil
    }

    private static func makeOverview(from payload: [String: Any]) -> [ChatGPTMetric] {
        guard payload["error"] == nil,
              let days = payload["data"] as? [[String: Any]],
              !days.isEmpty else { return [] }

        let totals = days.compactMap { $0["totals"] as? [String: Any] }
        func sum(_ key: String) -> Double {
            totals.reduce(0) { $0 + number($1[key]) }
        }
        var metrics: [ChatGPTMetric] = []
        appendCount("Turns", sum("turns"), to: &metrics)
        appendCount("Conversations", sum("threads"), to: &metrics)
        appendCount("Tokens", sum("text_total_tokens"), to: &metrics)
        let credits = sum("credits")
        if credits > 0 {
            metrics.append(ChatGPTMetric(name: "Credits", value: credits.formatted(.number.precision(.fractionLength(0...2)))))
        }
        return metrics
    }

    private static func makeModelUsage(from response: [String: Any]) -> [ChatGPTMetric] {
        guard response["error"] == nil,
              let days = response["data"] as? [[String: Any]] else { return [] }

        var creditsByModel: [String: Double] = [:]
        for day in days {
            for model in day["models"] as? [[String: Any]] ?? [] {
                guard let name = model["model"] as? String else { continue }
                creditsByModel[name, default: 0] += number(model["credits"])
            }
        }
        return creditsByModel
            .sorted { $0.value > $1.value }
            .map {
                ChatGPTMetric(
                    name: $0.key,
                    value: $0.value.formatted(.number.precision(.fractionLength(0...2)))
                )
            }
    }

    private static func appendCount(_ title: String, _ value: Double, to metrics: inout [ChatGPTMetric]) {
        guard value > 0 else { return }
        metrics.append(ChatGPTMetric(name: title, value: Int(value.rounded()).formatted()))
    }

    private static func number(_ value: Any?) -> Double {
        if let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() {
            return number.doubleValue
        }
        if let string = value as? String { return Double(string) ?? 0 }
        return 0
    }

}

extension ChatGPTManager: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard webView.url?.host == "chatgpt.com" else { return }
        refresh()
    }
}

struct ChatGPTWebView: NSViewRepresentable {
    @ObservedObject var manager: ChatGPTManager

    func makeNSView(context: Context) -> WKWebView { manager.browserView }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
