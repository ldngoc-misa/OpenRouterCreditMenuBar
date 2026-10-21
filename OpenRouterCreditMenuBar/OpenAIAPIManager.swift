//
//  OpenAIAPIManager.swift
//  OpenRouterCreditMenuBar
//

import Combine
import Foundation
import Security

struct OpenAIAPIUsageByModel: Identifiable {
    var id: String { "\(projectID ?? "")-\(model)" }
    let model: String
    let projectID: String?
    var tokens: Int
    var requests: Int
    var todayTokens: Int
    var todayRequests: Int
}

struct OpenAIAPICostBreakdown: Identifiable {
    var id: String { "\(projectID ?? "unknown")-\(lineItem ?? "unknown")" }
    let projectID: String?
    let lineItem: String?
    var amount: Double
    var todayAmount: Double
}

private struct OpenAIWeekRange {
    let start: Date
    let todayStart: Date
    let days: Int
}

@MainActor
final class OpenAIAPIManager: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var isConnected = false
    @Published private(set) var usageErrorMessage: String?
    @Published private(set) var costsErrorMessage: String?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var todayCost: Double?
    @Published private(set) var weekCost: Double?
    @Published private(set) var todayTokens: Int?
    @Published private(set) var weekTokens: Int?
    @Published private(set) var todayRequests: Int?
    @Published private(set) var weekRequests: Int?
    @Published private(set) var usageByModel: [OpenAIAPIUsageByModel] = []
    @Published private(set) var costsByLineItem: [OpenAIAPICostBreakdown] = []

    private let keychainService = Bundle.main.bundleIdentifier ?? "OpenRouterCreditMenuBar"
    private let keychainAccount = "openai_admin_api_key"
    private var refreshTimer: Timer?
    private var refreshInterval: TimeInterval = {
        let interval = UserDefaults.standard.double(forKey: "refresh_interval")
        return interval > 0 ? interval : 300
    }()

    var adminAPIKey: String {
        get { readAPIKey() }
        set {
            guard newValue != readAPIKey() else { return }
            saveAPIKey(newValue)
            isConnected = false
            lastUpdated = nil
            usageErrorMessage = nil
            costsErrorMessage = nil
            clearUsageData()
            clearCostsData()
            setupRefreshTimer()
        }
    }

    func setRefreshInterval(_ interval: TimeInterval) {
        refreshInterval = interval
        setupRefreshTimer()
    }

    func refresh() async {
        let apiKey = adminAPIKey
        guard !isLoading, !apiKey.isEmpty else { return }
        isLoading = true
        usageErrorMessage = nil
        costsErrorMessage = nil
        defer { isLoading = false }

        let range = Self.currentWeekRange()
        async let usage = captureResult { try await fetchUsage(from: range.start, limit: range.days, apiKey: apiKey) }
        async let costs = captureResult { try await fetchCosts(from: range.start, limit: range.days, apiKey: apiKey) }

        let (usageResult, costsResult) = await (usage, costs)
        var didLoadData = false

        switch usageResult {
        case .success(let buckets):
            applyUsage(buckets, todayStart: range.todayStart)
            usageErrorMessage = nil
            didLoadData = true
        case .failure(let error):
            usageErrorMessage = error.localizedDescription
            clearUsageData()
        }

        switch costsResult {
        case .success(let buckets):
            applyCosts(buckets, todayStart: range.todayStart)
            costsErrorMessage = nil
            didLoadData = true
        case .failure(let error):
            costsErrorMessage = error.localizedDescription
            clearCostsData()
        }

        isConnected = didLoadData
        if didLoadData { lastUpdated = Date() }
        setupRefreshTimer()
    }

    private func fetchUsage(from start: Date, limit: Int, apiKey: String) async throws -> [OpenAIUsageBucket] {
        try await fetchAllPages(
            endpoint: "usage/completions",
            start: start,
            limit: limit,
            groupBy: ["model", "project_id"],
            apiKey: apiKey,
            responseType: OpenAIUsageResponse.self
        )
    }

    private func captureResult<T>(_ operation: () async throws -> T) async -> Result<T, Error> {
        do {
            return .success(try await operation())
        } catch {
            return .failure(error)
        }
    }

    private func fetchCosts(from start: Date, limit: Int, apiKey: String) async throws -> [OpenAICostBucket] {
        try await fetchAllPages(
            endpoint: "costs",
            start: start,
            limit: limit,
            groupBy: ["line_item", "project_id"],
            apiKey: apiKey,
            responseType: OpenAICostResponse.self
        )
    }

    private func fetchAllPages<Response: OpenAIPaginatedResponse>(
        endpoint: String,
        start: Date,
        limit: Int,
        groupBy: [String],
        apiKey: String,
        responseType: Response.Type
    ) async throws -> [Response.Bucket] {
        var page: String?
        var buckets: [Response.Bucket] = []
        var seenPages = Set<String>()

        repeat {
            guard var components = URLComponents(string: "https://api.openai.com/v1/organization/\(endpoint)") else {
                throw OpenAIAPIError.invalidURL
            }
            components.queryItems = [
                URLQueryItem(name: "start_time", value: String(Int(start.timeIntervalSince1970))),
                URLQueryItem(name: "bucket_width", value: "1d"),
                URLQueryItem(name: "limit", value: String(limit))
            ] + groupBy.map { URLQueryItem(name: "group_by", value: $0) }
            if let page { components.queryItems?.append(URLQueryItem(name: "page", value: page)) }
            guard let url = components.url else { throw OpenAIAPIError.invalidURL }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw OpenAIAPIError.invalidResponse }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw OpenAIAPIError.httpStatus(httpResponse.statusCode, Self.errorMessage(from: data))
            }

            let decoded = try JSONDecoder().decode(Response.self, from: data)
            buckets.append(contentsOf: decoded.data)
            guard let nextPage = decoded.nextPage, !nextPage.isEmpty else { page = nil; continue }
            guard seenPages.insert(nextPage).inserted else { throw OpenAIAPIError.paginationLoop }
            page = nextPage
        } while page != nil

        return buckets
    }

    private func applyUsage(_ buckets: [OpenAIUsageBucket], todayStart: Date) {
        var totalTokensToday = 0
        var totalTokensWeek = 0
        var requestsToday = 0
        var requestsWeek = 0
        var models: [String: OpenAIAPIUsageByModel] = [:]

        for bucket in buckets {
            let isToday = bucket.startTime >= todayStart.timeIntervalSince1970
            for result in bucket.results {
                let tokens = result.inputTokens + result.outputTokens
                totalTokensWeek += tokens
                requestsWeek += result.modelRequests
                if isToday {
                    totalTokensToday += tokens
                    requestsToday += result.modelRequests
                }

                let model = result.model ?? "Unknown model"
                let key = "\(model)|\(result.projectID ?? "")"
                var aggregate = models[key] ?? OpenAIAPIUsageByModel(
                    model: model,
                    projectID: result.projectID,
                    tokens: 0,
                    requests: 0,
                    todayTokens: 0,
                    todayRequests: 0
                )
                aggregate.tokens += tokens
                aggregate.requests += result.modelRequests
                if isToday {
                    aggregate.todayTokens += tokens
                    aggregate.todayRequests += result.modelRequests
                }
                models[key] = aggregate
            }
        }

        todayTokens = totalTokensToday
        weekTokens = totalTokensWeek
        todayRequests = requestsToday
        weekRequests = requestsWeek
        usageByModel = models.values.sorted { $0.tokens > $1.tokens }
    }

    private func applyCosts(_ buckets: [OpenAICostBucket], todayStart: Date) {
        var totalToday = 0.0
        var totalWeek = 0.0
        var breakdown: [String: OpenAIAPICostBreakdown] = [:]

        for bucket in buckets {
            let isToday = bucket.startTime >= todayStart.timeIntervalSince1970
            for result in bucket.results {
                let amount = result.amount.value
                totalWeek += amount
                if isToday { totalToday += amount }
                let lineItem = result.lineItem ?? "Other"
                let projectID = result.projectID
                let key = "\(projectID ?? "")|\(lineItem)"
                var entry = breakdown[key] ?? OpenAIAPICostBreakdown(
                    projectID: projectID,
                    lineItem: lineItem,
                    amount: 0,
                    todayAmount: 0
                )
                entry.amount += amount
                if isToday { entry.todayAmount += amount }
                breakdown[key] = entry
            }
        }

        todayCost = totalToday
        weekCost = totalWeek
        costsByLineItem = breakdown.values.sorted { $0.amount > $1.amount }
    }

    private func clearUsageData() {
        todayTokens = nil
        weekTokens = nil
        todayRequests = nil
        weekRequests = nil
        usageByModel = []
    }

    private func clearCostsData() {
        todayCost = nil
        weekCost = nil
        costsByLineItem = []
    }

    private func setupRefreshTimer() {
        refreshTimer?.invalidate()
        guard isConnected else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
    }

    private static func currentWeekRange(now: Date = Date()) -> OpenAIWeekRange {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        let todayStart = calendar.startOfDay(for: now)
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? todayStart
        let days = max(1, calendar.dateComponents([.day], from: start, to: todayStart).day ?? 0) + 1
        return OpenAIWeekRange(start: start, todayStart: todayStart, days: min(days, 7))
    }

    private static func errorMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = object["error"] as? [String: Any] else { return nil }
        return error["message"] as? String
    }

    private func readAPIKey() -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else { return "" }
        return value
    }

    private func saveAPIKey(_ value: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        guard !value.isEmpty else {
            SecItemDelete(query as CFDictionary)
            return
        }

        let data = Data(value.utf8)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            attributes.forEach { insert[$0.key] = $0.value }
            SecItemAdd(insert as CFDictionary, nil)
        }
    }
}

private protocol OpenAIPaginatedResponse: Decodable {
    associatedtype Bucket: Decodable
    var data: [Bucket] { get }
    var nextPage: String? { get }
}

private struct OpenAIUsageResponse: OpenAIPaginatedResponse {
    let data: [OpenAIUsageBucket]
    let nextPage: String?
    enum CodingKeys: String, CodingKey { case data, nextPage = "next_page" }
}

private struct OpenAICostResponse: OpenAIPaginatedResponse {
    let data: [OpenAICostBucket]
    let nextPage: String?
    enum CodingKeys: String, CodingKey { case data, nextPage = "next_page" }
}

private struct OpenAIUsageBucket: Decodable {
    let startTime: TimeInterval
    let results: [OpenAIUsageResult]
    enum CodingKeys: String, CodingKey { case startTime = "start_time", results }
}

private struct OpenAIUsageResult: Decodable {
    let inputTokens: Int
    let outputTokens: Int
    let cachedInputTokens: Int
    let modelRequests: Int
    let model: String?
    let projectID: String?

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cachedInputTokens = "input_cached_tokens"
        case modelRequests = "num_model_requests"
        case model
        case projectID = "project_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inputTokens = (try? container.decode(Int.self, forKey: .inputTokens)) ?? 0
        outputTokens = (try? container.decode(Int.self, forKey: .outputTokens)) ?? 0
        cachedInputTokens = (try? container.decode(Int.self, forKey: .cachedInputTokens)) ?? 0
        modelRequests = (try? container.decode(Int.self, forKey: .modelRequests)) ?? 0
        model = try? container.decodeIfPresent(String.self, forKey: .model)
        projectID = try? container.decodeIfPresent(String.self, forKey: .projectID)
    }
}

private struct OpenAICostBucket: Decodable {
    let startTime: TimeInterval
    let results: [OpenAICostResult]
    enum CodingKeys: String, CodingKey { case startTime = "start_time", results }
}

private struct OpenAICostResult: Decodable {
    let amount: OpenAICostAmount
    let lineItem: String?
    let projectID: String?
    enum CodingKeys: String, CodingKey {
        case amount
        case lineItem = "line_item"
        case projectID = "project_id"
    }
}

private struct OpenAICostAmount: Decodable {
    let value: Double
    enum CodingKeys: String, CodingKey { case value }
}

private enum OpenAIAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case paginationLoop
    case httpStatus(Int, String?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not create an OpenAI API request."
        case .invalidResponse:
            return "OpenAI returned an invalid response."
        case .paginationLoop:
            return "OpenAI returned a repeated pagination cursor."
        case .httpStatus(let status, let message):
            if status == 401 || status == 403 {
                return "OpenAI API access denied (HTTP \(status)). Check the Admin API key and organization permissions."
            }
            return message ?? "OpenAI API request failed (HTTP \(status))."
        }
    }
}
