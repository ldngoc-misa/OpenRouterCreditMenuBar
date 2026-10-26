//
//  OpenAIPlatformLoginManager.swift
//  OpenRouterCreditMenuBar
//

import Combine
import Foundation
import WebKit

struct OpenAIPlatformOrganization: Decodable, Identifiable {
    let id: String
    let title: String?
    let name: String?
    let isDefault: Bool

    var displayName: String { title ?? name ?? id }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case isDefault = "is_default"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        isDefault = (try? container.decode(Bool.self, forKey: .isDefault)) ?? false
    }
}

struct OpenAIPlatformCostPage: Decodable {
    let data: [OpenAIPlatformCostBucket]
    let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case data
        case nextPage = "next_page"
    }
}

struct OpenAIPlatformCostBucket: Decodable {
    let startTime: TimeInterval
    let results: [OpenAIPlatformCostResult]

    enum CodingKeys: String, CodingKey {
        case startTime = "start_time"
        case results
    }
}

struct OpenAIPlatformCostResult: Decodable {
    let amount: OpenAIPlatformCostAmount
    let lineItem: String?
    let projectID: String?

    enum CodingKeys: String, CodingKey {
        case amount
        case lineItem = "line_item"
        case projectID = "project_id"
    }
}

struct OpenAIPlatformCostAmount: Decodable {
    let value: Double
}

struct OpenAIPlatformCostSummary {
    let total: Double
    let breakdown: [OpenAIAPICostBreakdown]
}

enum OpenAIPlatformCostCalculator {
    static func utcDayRange(for date: Date) -> DateInterval {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return DateInterval(start: start, end: end)
    }

    static func summarize(
        buckets: [OpenAIPlatformCostBucket],
        during day: DateInterval
    ) -> OpenAIPlatformCostSummary {
        var breakdownByKey: [String: OpenAIAPICostBreakdown] = [:]
        let startTime = day.start.timeIntervalSince1970
        let endTime = day.end.timeIntervalSince1970

        for bucket in buckets where bucket.startTime >= startTime && bucket.startTime < endTime {
            for result in bucket.results where result.amount.value.isFinite {
                let lineItem = result.lineItem ?? "Organization spend"
                let key = "\(result.projectID ?? "")|\(lineItem)"
                var entry = breakdownByKey[key] ?? OpenAIAPICostBreakdown(
                    projectID: result.projectID,
                    lineItem: lineItem,
                    amount: 0,
                    todayAmount: 0
                )
                entry.amount += result.amount.value
                entry.todayAmount += result.amount.value
                breakdownByKey[key] = entry
            }
        }

        let breakdown = breakdownByKey.values.sorted {
            if $0.todayAmount == $1.todayAmount { return $0.id < $1.id }
            return $0.todayAmount > $1.todayAmount
        }
        return OpenAIPlatformCostSummary(
            total: breakdown.reduce(0) { $0 + $1.todayAmount },
            breakdown: breakdown
        )
    }
}

enum OpenAISpendResolver {
    static func preferredSpend(webLoginCost: Double?, adminAPIKeyCost: Double?) -> Double? {
        webLoginCost ?? adminAPIKeyCost
    }
}

@MainActor
final class OpenAIPlatformLoginManager: NSObject, ObservableObject {
    private static let websiteDataStoreIdentifierKey = "openAIPlatformWebsiteDataStoreIdentifier"
    private static let selectedOrganizationDefaultsKey = "openAIPlatformSelectedOrganizationID"
    private static let monitoringDefaultsKey = "openai_platform_monitoring_enabled"

    @Published private(set) var isConnected = false {
        didSet {
            guard oldValue != isConnected else { return }
            setMonitoringEnabled(isConnected)
        }
    }
    @Published private(set) var isMonitoringEnabled = UserDefaults.standard.bool(forKey: "openai_platform_monitoring_enabled")
    @Published private(set) var isLoading = false
    @Published private(set) var accountEmail: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var availableCredit: Double?
    @Published private(set) var creditGrantsErrorMessage: String?
    @Published private(set) var todayCost: Double?
    @Published private(set) var costsByLineItem: [OpenAIAPICostBreakdown] = []
    @Published private(set) var costsErrorMessage: String?
    @Published private(set) var organizations: [OpenAIPlatformOrganization] = []
    @Published private(set) var selectedOrganizationID: String?

    let browserView: WKWebView
    private let websiteDataStore: WKWebsiteDataStore
    private var isLoginFlowActive = false
    private var didVisitAuthenticationPage = false
    private var platformSessionToken: String?
    private var isRefreshingCreditGrants = false
    private var hasPendingCreditRefresh = false
    private var isRefreshingOrganizationCosts = false
    private var hasPendingOrganizationCostsRefresh = false
    private var refreshTimer: Timer?
    private var refreshInterval: TimeInterval = {
        let interval = UserDefaults.standard.double(forKey: "refresh_interval")
        return interval > 0 ? interval : 300
    }()

    override init() {
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        let accountMessageHandler = WeakScriptMessageHandler()
        contentController.add(accountMessageHandler, name: "openAIAccount")
        contentController.add(accountMessageHandler, name: "openAIOrganizations")
        contentController.add(accountMessageHandler, name: "openAIPlatformLogin")
        contentController.addUserScript(
            WKUserScript(
                source: Self.accountResponseObserverScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )
        configuration.userContentController = contentController
        websiteDataStore = Self.makeWebsiteDataStore()
        configuration.websiteDataStore = websiteDataStore
        browserView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        selectedOrganizationID = UserDefaults.standard.string(forKey: Self.selectedOrganizationDefaultsKey)
        accountMessageHandler.delegate = self
        browserView.navigationDelegate = self
        openLogin()
    }

    func openLogin() {
        guard browserView.url?.host != "platform.openai.com" else { return }
        guard let url = URL(string: "https://platform.openai.com/usage") else { return }
        browserView.load(URLRequest(url: url))
    }

    func beginLogin() {
        isLoginFlowActive = true
        didVisitAuthenticationPage = false
        errorMessage = nil
        guard let url = URL(string: "https://platform.openai.com/usage") else { return }
        browserView.load(URLRequest(url: url))
    }

    func refreshAccount() {
        guard browserView.url?.host == "platform.openai.com" else {
            openLogin()
            return
        }
        updateAccount()
        refreshCreditGrants()
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

    func disconnect() {
        isLoginFlowActive = false
        didVisitAuthenticationPage = false
        isConnected = false
        accountEmail = nil
        availableCredit = nil
        creditGrantsErrorMessage = nil
        todayCost = nil
        costsByLineItem = []
        costsErrorMessage = nil
        organizations = []
        platformSessionToken = nil
        hasPendingCreditRefresh = false
        hasPendingOrganizationCostsRefresh = false
        isLoading = true
        errorMessage = nil

        let store = websiteDataStore
        store.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { [weak self] records in
            store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) {
                Task { @MainActor in
                    self?.isLoading = false
                    if let url = URL(string: "https://platform.openai.com/usage") {
                        self?.browserView.load(URLRequest(url: url))
                    }
                }
            }
        }
    }

    func selectOrganization(_ organizationID: String) {
        guard organizations.contains(where: { $0.id == organizationID }),
              selectedOrganizationID != organizationID else { return }
        selectedOrganizationID = organizationID
        UserDefaults.standard.set(organizationID, forKey: Self.selectedOrganizationDefaultsKey)
        availableCredit = nil
        creditGrantsErrorMessage = nil
        todayCost = nil
        costsByLineItem = []
        costsErrorMessage = nil
        refreshCreditGrants()
    }

    func refreshCreditGrants() {
        guard browserView.url?.host == "platform.openai.com" else { return }
        if let token = platformSessionToken, let organizationID = selectedOrganizationID {
            refreshOrganizationCosts(
                sessionToken: token,
                organizationID: organizationID,
                retryAfterUnauthorized: true
            )
        }
        guard !isRefreshingCreditGrants else {
            hasPendingCreditRefresh = true
            return
        }
        isRefreshingCreditGrants = true

        if let platformSessionToken {
            guard let organizationID = selectedOrganizationID else {
                creditGrantsErrorMessage = "Choose an OpenAI organization in Settings."
                costsErrorMessage = "Choose an OpenAI organization in Settings."
                availableCredit = nil
                todayCost = nil
                costsByLineItem = []
                finishCreditGrantsRefresh()
                return
            }
            Task {
                await requestCreditGrants(
                    sessionToken: platformSessionToken,
                    organizationID: organizationID,
                    retryAfterUnauthorized: true
                )
            }
            return
        }

        let script = """
          const sessionResponse = await fetch('/api/auth/session', {credentials: 'include'});
          const session = sessionResponse.ok ? await sessionResponse.json() : {};
          if (!session.accessToken) {
            return JSON.stringify({status: 401, body: 'OpenAI Platform login required.'});
          }

          const loginResponse = await fetch('https://api.openai.com/v1/dashboard/onboarding/login', {
            method: 'POST',
            credentials: 'include',
            headers: {
              'accept': 'application/json',
              'authorization': `Bearer ${session.accessToken}`,
              'content-type': 'application/json'
            },
            body: JSON.stringify({app: 'api'})
          });
          if (!loginResponse.ok) {
            return JSON.stringify({status: loginResponse.status, body: await loginResponse.text()});
          }

          const login = await loginResponse.json();
          const user = login?.user || {};
          const sessionToken = user.session?.sensitive_id || '';
          const organizations = user.orgs?.data || [];
          const organizationPayload = organizations.map(item => ({
            id: item.id, title: item.title, name: item.name, is_default: !!item.is_default
          }));
          if (!sessionToken || !organizations.length) {
            return JSON.stringify({
              status: 401,
              body: 'Could not find an OpenAI API organization.',
              accountEmail: user.email,
              sessionToken,
              organizations: organizationPayload
            });
          }

          return JSON.stringify({
            status: 200,
            body: '',
            accountEmail: user.email,
            sessionToken,
            organizations: organizationPayload
          });
        """
        browserView.callAsyncJavaScript(
            script,
            arguments: [:],
            in: nil,
            in: .page
        ) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let value as String):
                    guard let data = value.data(using: .utf8),
                          let login = try? JSONDecoder().decode(CreditGrantsWebResponse.self, from: data) else {
                        self.availableCredit = nil
                        self.creditGrantsErrorMessage = "Could not read OpenAI credit balance."
                        self.finishCreditGrantsRefresh()
                        return
                    }
                    if let email = login.accountEmail, !email.isEmpty {
                        self.accountEmail = email
                        self.isConnected = true
                    }
                    if let token = login.sessionToken, !token.isEmpty {
                        self.platformSessionToken = token
                    }
                    self.updateOrganizations(login.organizations ?? [])
                    guard (200..<300).contains(login.status) else {
                        self.availableCredit = nil
                        self.creditGrantsErrorMessage = "OpenAI login request failed (HTTP \(login.status))."
                        self.todayCost = nil
                        self.costsByLineItem = []
                        self.costsErrorMessage = "OpenAI Platform login request failed (HTTP \(login.status))."
                        self.finishCreditGrantsRefresh()
                        return
                    }
                    guard let token = self.platformSessionToken,
                          let organizationID = self.selectedOrganizationID else {
                        self.availableCredit = nil
                        self.creditGrantsErrorMessage = "Choose an OpenAI organization in Settings."
                        self.costsErrorMessage = "Choose an OpenAI organization in Settings."
                        self.finishCreditGrantsRefresh()
                        return
                    }
                    self.hasPendingCreditRefresh = false
                    self.refreshOrganizationCosts(
                        sessionToken: token,
                        organizationID: organizationID,
                        retryAfterUnauthorized: false
                    )
                    Task {
                        await self.requestCreditGrants(
                            sessionToken: token,
                            organizationID: organizationID,
                            retryAfterUnauthorized: false
                        )
                    }
                case .failure(let error):
                    if let token = self.platformSessionToken,
                       let organizationID = self.selectedOrganizationID {
                        self.hasPendingCreditRefresh = false
                        self.refreshOrganizationCosts(
                            sessionToken: token,
                            organizationID: organizationID,
                            retryAfterUnauthorized: true
                        )
                        Task {
                            await self.requestCreditGrants(
                                sessionToken: token,
                                organizationID: organizationID,
                                retryAfterUnauthorized: true
                            )
                        }
                        return
                    }
                    self.availableCredit = nil
                    self.creditGrantsErrorMessage = "OpenAI login response failed: \(error.localizedDescription)"
                    self.todayCost = nil
                    self.costsByLineItem = []
                    self.costsErrorMessage = "OpenAI login response failed: \(error.localizedDescription)"
                    self.finishCreditGrantsRefresh()
                default:
                    self.availableCredit = nil
                    self.creditGrantsErrorMessage = "Could not read OpenAI credit balance."
                    self.todayCost = nil
                    self.costsByLineItem = []
                    self.costsErrorMessage = "Could not read OpenAI login data."
                    self.finishCreditGrantsRefresh()
                }
            }
        }
    }

    private func requestCreditGrants(
        sessionToken: String,
        organizationID: String,
        retryAfterUnauthorized: Bool
    ) async {
        guard let url = URL(string: "https://api.openai.com/v1/dashboard/billing/credit_grants") else {
            creditGrantsErrorMessage = "Could not create the OpenAI credit request."
            finishCreditGrantsRefresh()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        request.setValue(organizationID, forHTTPHeaderField: "openai-organization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("https://platform.openai.com", forHTTPHeaderField: "Origin")
        request.setValue("https://platform.openai.com/", forHTTPHeaderField: "Referer")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard platformSessionToken == sessionToken,
                  selectedOrganizationID == organizationID else {
                finishCreditGrantsRefresh()
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                creditGrantsErrorMessage = "OpenAI returned an invalid credit response."
                finishCreditGrantsRefresh()
                return
            }
            if httpResponse.statusCode == 401, retryAfterUnauthorized {
                platformSessionToken = nil
                isRefreshingCreditGrants = false
                hasPendingCreditRefresh = false
                refreshCreditGrants()
                return
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                let detail = Self.errorMessage(from: data)
                creditGrantsErrorMessage = detail
                    ?? "OpenAI credit request failed (HTTP \(httpResponse.statusCode))."
                finishCreditGrantsRefresh()
                return
            }
            let credits = try JSONDecoder().decode(OpenAICreditGrants.self, from: data)
            availableCredit = credits.totalAvailable
            creditGrantsErrorMessage = nil
            finishCreditGrantsRefresh()
        } catch {
            guard platformSessionToken == sessionToken,
                  selectedOrganizationID == organizationID else {
                finishCreditGrantsRefresh()
                return
            }
            availableCredit = nil
            creditGrantsErrorMessage = error.localizedDescription
            finishCreditGrantsRefresh()
        }
    }

    private func refreshOrganizationCosts(
        sessionToken: String,
        organizationID: String,
        retryAfterUnauthorized: Bool
    ) {
        guard browserView.url?.host == "platform.openai.com",
              platformSessionToken == sessionToken,
              selectedOrganizationID == organizationID else { return }
        guard !isRefreshingOrganizationCosts else {
            hasPendingOrganizationCostsRefresh = true
            return
        }

        isRefreshingOrganizationCosts = true
        costsErrorMessage = nil
        Task {
            await requestOrganizationCosts(
                sessionToken: sessionToken,
                organizationID: organizationID,
                retryAfterUnauthorized: retryAfterUnauthorized
            )
        }
    }

    private func requestOrganizationCosts(
        sessionToken: String,
        organizationID: String,
        retryAfterUnauthorized: Bool
    ) async {
        let day = OpenAIPlatformCostCalculator.utcDayRange(for: Date())

        do {
            let buckets = try await fetchOrganizationCostBuckets(
                sessionToken: sessionToken,
                organizationID: organizationID,
                during: day
            )
            guard platformSessionToken == sessionToken,
                  selectedOrganizationID == organizationID else {
                finishOrganizationCostsRefresh()
                return
            }

            let summary = OpenAIPlatformCostCalculator.summarize(buckets: buckets, during: day)
            todayCost = summary.total
            costsByLineItem = summary.breakdown
            costsErrorMessage = nil
            finishOrganizationCostsRefresh()
        } catch OpenAIPlatformCostRequestError.unauthorized where retryAfterUnauthorized {
            guard platformSessionToken == sessionToken else {
                finishOrganizationCostsRefresh()
                return
            }
            platformSessionToken = nil
            todayCost = nil
            costsByLineItem = []
            costsErrorMessage = nil
            finishOrganizationCostsRefresh()
            refreshCreditGrants()
        } catch {
            guard platformSessionToken == sessionToken,
                  selectedOrganizationID == organizationID else {
                finishOrganizationCostsRefresh()
                return
            }
            todayCost = nil
            costsByLineItem = []
            costsErrorMessage = error.localizedDescription
            finishOrganizationCostsRefresh()
        }
    }

    private func fetchOrganizationCostBuckets(
        sessionToken: String,
        organizationID: String,
        during day: DateInterval
    ) async throws -> [OpenAIPlatformCostBucket] {
        var page: String?
        var buckets: [OpenAIPlatformCostBucket] = []
        var seenPages = Set<String>()

        repeat {
            guard var components = URLComponents(
                string: "https://api.openai.com/v1/dashboard/organization/costs"
            ) else {
                throw OpenAIPlatformCostRequestError.invalidURL
            }
            components.queryItems = [
                URLQueryItem(name: "start_time", value: String(Int(day.start.timeIntervalSince1970))),
                URLQueryItem(name: "end_time", value: String(Int(day.end.timeIntervalSince1970))),
                URLQueryItem(name: "bucket_width", value: "1d"),
                URLQueryItem(name: "limit", value: "31")
            ]
            if let page {
                components.queryItems?.append(URLQueryItem(name: "page", value: page))
            }
            guard let url = components.url else { throw OpenAIPlatformCostRequestError.invalidURL }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
            request.setValue(organizationID, forHTTPHeaderField: "openai-organization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("https://platform.openai.com", forHTTPHeaderField: "Origin")
            request.setValue("https://platform.openai.com/", forHTTPHeaderField: "Referer")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIPlatformCostRequestError.invalidResponse
            }
            if httpResponse.statusCode == 401 {
                throw OpenAIPlatformCostRequestError.unauthorized
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw OpenAIPlatformCostRequestError.httpStatus(
                    httpResponse.statusCode,
                    Self.errorMessage(from: data)
                )
            }

            let pageResponse = try JSONDecoder().decode(OpenAIPlatformCostPage.self, from: data)
            buckets.append(contentsOf: pageResponse.data)
            guard let nextPage = pageResponse.nextPage, !nextPage.isEmpty else {
                page = nil
                continue
            }
            guard seenPages.insert(nextPage).inserted else {
                throw OpenAIPlatformCostRequestError.paginationLoop
            }
            page = nextPage
        } while page != nil

        return buckets
    }

    private func finishOrganizationCostsRefresh() {
        isRefreshingOrganizationCosts = false
        guard hasPendingOrganizationCostsRefresh else { return }
        hasPendingOrganizationCostsRefresh = false
        guard let token = platformSessionToken,
              let organizationID = selectedOrganizationID else { return }
        refreshOrganizationCosts(
            sessionToken: token,
            organizationID: organizationID,
            retryAfterUnauthorized: true
        )
    }

    private func finishCreditGrantsRefresh() {
        isRefreshingCreditGrants = false
        guard hasPendingCreditRefresh else { return }
        hasPendingCreditRefresh = false
        refreshCreditGrants()
    }

    private static func errorMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = object["error"] as? [String: Any] else { return nil }
        return error["message"] as? String
    }

    private func updateOrganizations(_ organizations: [OpenAIPlatformOrganization]) {
        guard !organizations.isEmpty else { return }
        self.organizations = organizations
        if let selectedOrganizationID,
           organizations.contains(where: { $0.id == selectedOrganizationID }) {
            return
        }
        let selected = organizations.first(where: \.isDefault) ?? organizations[0]
        let organizationChanged = selectedOrganizationID != selected.id
        selectedOrganizationID = selected.id
        UserDefaults.standard.set(selected.id, forKey: Self.selectedOrganizationDefaultsKey)
        if organizationChanged {
            availableCredit = nil
            creditGrantsErrorMessage = nil
            todayCost = nil
            costsByLineItem = []
            costsErrorMessage = nil
        }
    }

    private func setupRefreshTimer() {
        refreshTimer?.invalidate()
        guard isConnected && isMonitoringEnabled else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshAccount() }
        }
    }

    private static func makeWebsiteDataStore() -> WKWebsiteDataStore {
        let defaults = UserDefaults.standard
        let identifier = defaults.string(forKey: websiteDataStoreIdentifierKey)
            .flatMap(UUID.init(uuidString:)) ?? UUID()
        defaults.set(identifier.uuidString, forKey: websiteDataStoreIdentifierKey)
        return WKWebsiteDataStore(forIdentifier: identifier)
    }

    private static let accountResponseObserverScript = #"""
      (() => {
        if (location.hostname !== 'platform.openai.com') return;
        const endpoint = '/v1/dashboard/onboarding/login';
        const report = data => {
          const user = data?.user || {};
          const organizations = user.orgs?.data || [];
          if (organizations.length) {
            window.webkit?.messageHandlers?.openAIOrganizations?.postMessage(
              organizations.map(item => ({
                id: item.id,
                title: item.title,
                name: item.name,
                is_default: !!item.is_default
              }))
            );
          }
          const sessionToken = user.session?.sensitive_id;
          if (sessionToken) {
            window.webkit?.messageHandlers?.openAIPlatformLogin?.postMessage({
              accountEmail: user.email || null,
              sessionToken,
              organizations: organizations.map(item => ({
                id: item.id,
                title: item.title,
                name: item.name,
                is_default: !!item.is_default
              }))
            });
          }
          const email = user.email;
          if (typeof email === 'string' && email.includes('@')) {
            window.webkit?.messageHandlers?.openAIAccount?.postMessage(email);
          }
        };
        const isLoginRequest = value => {
          try { return new URL(value, location.href).pathname.endsWith(endpoint); }
          catch (_) { return false; }
        };

        const originalFetch = window.fetch.bind(window);
        window.fetch = async (...args) => {
          const response = await originalFetch(...args);
          const requestURL = typeof args[0] === 'string' ? args[0] : args[0]?.url;
          if (isLoginRequest(requestURL)) response.clone().json().then(report).catch(() => {});
          return response;
        };

        const originalOpen = XMLHttpRequest.prototype.open;
        const originalSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function(method, url, ...args) {
          this.__openAIAccountRequest = isLoginRequest(url);
          return originalOpen.call(this, method, url, ...args);
        };
        XMLHttpRequest.prototype.send = function(...args) {
          if (this.__openAIAccountRequest) {
            this.addEventListener('load', () => {
              try { report(JSON.parse(this.responseText)); } catch (_) {}
            }, {once: true});
          }
          return originalSend.apply(this, args);
        };
      })();
    """#

    private func updateAccount() {
        isLoading = true
        errorMessage = nil
        let script = """
          const findEmail = value => {
            if (!value || typeof value !== 'object') return null;
            for (const [key, item] of Object.entries(value)) {
              if (key.toLowerCase() === 'email' && typeof item === 'string' && item.includes('@')) return item;
              const nested = findEmail(item);
              if (nested) return nested;
            }
            return null;
          };
          let sessionEmail = null;
          for (let attempt = 0; attempt < 5 && !sessionEmail; attempt++) {
            try {
              const response = await fetch('/api/auth/session', {credentials: 'include'});
              if (response.ok) sessionEmail = findEmail(await response.json());
            } catch (_) {}
            if (!sessionEmail && attempt < 4) await new Promise(resolve => setTimeout(resolve, 400));
          }

          const emailPattern = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}/i;
          const findVisibleEmail = () => {
            const menuText = [...document.querySelectorAll('[role="menu"], [role="dialog"]')]
              .map(element => element.innerText).join(' ');
            return (menuText.match(emailPattern) || document.body.innerText.match(emailPattern) || [])[0] || null;
          };
          let visibleEmail = findVisibleEmail();
          if (!sessionEmail && !visibleEmail) {
            const accountButton = [...document.querySelectorAll('button, [role="button"]')].find(element => {
              const label = [element.getAttribute('aria-label'), element.getAttribute('title'), element.getAttribute('data-testid')]
                .filter(Boolean).join(' ');
              return /account|profile|user|personal/i.test(label);
            }) || [...document.querySelectorAll('button[aria-haspopup="menu"]')].at(-1);
            accountButton?.click();
            await new Promise(resolve => setTimeout(resolve, 500));
            visibleEmail = findVisibleEmail();
          }
          return sessionEmail || visibleEmail;
        """
        browserView.callAsyncJavaScript(script, arguments: [:], in: nil, in: .page) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if case .success(let email) = result, let email = email as? String, !email.isEmpty {
                    self.accountEmail = email
                    self.isConnected = true
                } else {
                    if case .failure = result {
                        self.errorMessage = "Could not read the OpenAI account."
                    }
                }
            }
        }
    }
}

extension OpenAIPlatformLoginManager: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        errorMessage = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        guard webView.url?.host == "platform.openai.com" else {
            if webView.url?.host == "auth.openai.com" {
                if isLoginFlowActive {
                    didVisitAuthenticationPage = true
                }
                isConnected = false
                accountEmail = nil
            }
            return
        }
        if isLoginFlowActive, didVisitAuthenticationPage {
            isConnected = true
            isLoginFlowActive = false
            didVisitAuthenticationPage = false
        }
        updateAccount()
        refreshCreditGrants()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        isLoading = false
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        errorMessage = "Could not load OpenAI Platform. Check your connection and try again."
    }
}

private struct CreditGrantsWebResponse: Decodable {
    let status: Int
    let body: String
    let accountEmail: String?
    let sessionToken: String?
    let organizations: [OpenAIPlatformOrganization]?

    enum CodingKeys: String, CodingKey {
        case status
        case body
        case accountEmail
        case sessionToken
        case organizations
    }
}

private enum OpenAIPlatformCostRequestError: LocalizedError {
    case invalidURL
    case invalidResponse
    case paginationLoop
    case unauthorized
    case httpStatus(Int, String?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Could not create the OpenAI organization costs request."
        case .invalidResponse:
            "OpenAI returned an invalid organization costs response."
        case .paginationLoop:
            "OpenAI returned a repeated organization costs page."
        case .unauthorized:
            "OpenAI Platform session expired. Sign in again."
        case .httpStatus(let status, let message):
            message ?? "OpenAI organization costs request failed (HTTP \(status))."
        }
    }
}

private struct OpenAICreditGrants: Decodable {
    let totalAvailable: Double

    enum CodingKeys: String, CodingKey {
        case totalAvailable = "total_available"
    }
}

extension OpenAIPlatformLoginManager: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "openAIPlatformLogin",
           let data = try? JSONSerialization.data(withJSONObject: message.body),
           let login = try? JSONDecoder().decode(OpenAIPlatformLoginCapture.self, from: data) {
            if let token = login.sessionToken, !token.isEmpty {
                platformSessionToken = token
            }
            if let email = login.accountEmail, !email.isEmpty {
                accountEmail = email
                isConnected = true
            }
            updateOrganizations(login.organizations ?? [])
            if isRefreshingCreditGrants {
                hasPendingCreditRefresh = true
            } else {
                refreshCreditGrants()
            }
            return
        }
        if message.name == "openAIOrganizations",
           let data = try? JSONSerialization.data(withJSONObject: message.body),
           let organizations = try? JSONDecoder().decode([OpenAIPlatformOrganization].self, from: data) {
            updateOrganizations(organizations)
            return
        }
        guard message.name == "openAIAccount", let email = message.body as? String else { return }
        accountEmail = email
        isConnected = true
        isLoading = false
        errorMessage = nil
    }
}

private struct OpenAIPlatformLoginCapture: Decodable {
    let accountEmail: String?
    let sessionToken: String?
    let organizations: [OpenAIPlatformOrganization]?
}

private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
