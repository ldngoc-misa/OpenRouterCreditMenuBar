//
//  OpenRouterCreditManager.swift
//  OpenRouterCreditMenuBar
//

import Foundation
import SwiftUI

struct ModelSpending: Identifiable {
    let id = UUID()
    let modelName: String
    let providerName: String
    let amount: Double
    
    var providerColor: Color {
        ProviderColors.color(for: providerName)
    }
}

struct ProviderColors {
    static func color(for provider: String) -> Color {
        let lowercased = provider.lowercased()
        if lowercased.contains("anthropic") || lowercased.contains("claude") {
            return Color(red: 0.85, green: 0.45, blue: 0.15)  // Claude orange/brown
        } else if lowercased.contains("openai") {
            return Color(red: 0.0, green: 0.6, blue: 0.2)  // OpenAI green
        } else if lowercased.contains("google") || lowercased.contains("gemini") {
            return Color(red: 0.25, green: 0.52, blue: 0.96)  // Google blue
        } else if lowercased.contains("meta") || lowercased.contains("llama") {
            return Color(red: 0.0, green: 0.5, blue: 0.85)  // Meta blue
        } else if lowercased.contains("mistral") {
            return Color(red: 0.9, green: 0.3, blue: 0.25)  // Mistral red/orange
        } else if lowercased.contains("cohere") {
            return Color(red: 0.5, green: 0.2, blue: 0.8)  // Cohere purple
        } else if lowercased.contains("perplexity") {
            return Color(red: 0.15, green: 0.65, blue: 0.85)  // Perplexity teal
        } else if lowercased.contains("qwen") || lowercased.contains("alibaba") {
            return Color(red: 0.95, green: 0.45, blue: 0.1)  // Qwen orange
        } else if lowercased.contains("deepseek") {
            return Color(red: 0.15, green: 0.7, blue: 0.4)  // DeepSeek green
        } else if lowercased.contains("x.ai") || lowercased.contains("grok") {
            return Color(red: 0.0, green: 0.0, blue: 0.0)  // x.ai black
        } else if lowercased.contains("nvidia") {
            return Color(red: 0.12, green: 0.65, blue: 0.25)  // NVIDIA green
        } else {
            return Color.secondary  // Default gray
        }
    }
}

class OpenRouterCreditManager: ObservableObject {
    @Published var currentCredit: Double?
    @Published var totalUsage: Double?
    @Published var spentToday: Double?
    /// The UTC day that `spentToday` refers to (start of the current UTC day).
    @Published var spentTodayDate: Date?
    @Published var spentTodayByModel: [ModelSpending] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userDefaults = UserDefaults.standard
    private var refreshTimer: Timer?

    var apiKey: String {
        get {
            userDefaults.string(forKey: "openrouter_api_key") ?? ""
        }
        set {
            userDefaults.set(newValue, forKey: "openrouter_api_key")
        }
    }

    var isEnabled: Bool {
        get {
            userDefaults.bool(forKey: "app_enabled")
        }
        set {
            userDefaults.set(newValue, forKey: "app_enabled")
        }
    }

    var refreshInterval: Double {
        get {
            let interval = userDefaults.double(forKey: "refresh_interval")
            return interval > 0 ? interval : 300  // default 5 minutes
        }
        set {
            userDefaults.set(newValue, forKey: "refresh_interval")
            setupTimer()
        }
    }

    init() {
        setupTimer()
    }

    private func setupTimer() {
        refreshTimer?.invalidate()

        guard isEnabled && !apiKey.isEmpty else { return }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            Task {
                await self.fetchCredit()
            }
        }
    }

    func startMonitoring() {
        setupTimer()
        Task {
            await fetchCredit()
        }
    }

    func stopMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func fetchCredit() async {
        guard !apiKey.isEmpty && isEnabled else { return }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let creditData = try await fetchCreditFromAPI()
            let spentToday = try await fetchSpentTodayFromAPI()
            let spentTodayByModel = try await fetchSpentTodayByModelFromAPI()
            await MainActor.run {
                self.currentCredit = creditData.total_credits - creditData.total_usage
                self.totalUsage = creditData.total_usage
                self.spentToday = spentToday.amount
                self.spentTodayDate = spentToday.date
                self.spentTodayByModel = spentTodayByModel
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func fetchCreditFromAPI() async throws -> CreditData {
        guard let url = URL(string: "https://openrouter.ai/api/v1/credits") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw OpenRouterAPIError(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1,
                serverMessage: Self.decodeServerErrorMessage(from: data)
            )
        }

        let creditResponse = try JSONDecoder().decode(CreditResponse.self, from: data)
        return creditResponse.data
    }

    // MARK: - Spend Today

    /// Metric name for total credits spent (USD) in /analytics/query responses.
    /// Per the docs: spend metrics (`total_usage`, `usage_*`) are in USD.
    private static let spentUsageMetric = "total_usage"

    /// Fetches the live "spent today" total (USD) via POST /analytics/query,
    /// querying the range UTC today 00:00:00 → now.
    ///
    /// Unlike GET /activity (only *completed* UTC days), the analytics endpoint
    /// accepts an arbitrary time range, so the current in-progress day is included.
    /// NOTE: the spec marks this endpoint as requiring a Management key; a regular
    /// inference key may get HTTP 403.
    private func fetchSpentTodayFromAPI() async throws -> (amount: Double, date: Date) {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let startOfTodayUTC = utcCalendar.startOfDay(for: Date())

        let body = AnalyticsQueryRequest(
            metrics: [Self.spentUsageMetric],
            time_range: .init(
                start: Self.iso8601SecondsString(for: startOfTodayUTC),
                end: Self.iso8601SecondsString(for: Date())
            ),
            dimensions: nil,
            granularity: nil
        )

        guard let url = URL(string: "https://openrouter.ai/api/v1/analytics/query") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw OpenRouterAPIError(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1,
                serverMessage: Self.decodeServerErrorMessage(from: data)
            )
        }

        let result = try JSONDecoder().decode(AnalyticsQueryResponse.self, from: data)
        // Response rows are flat objects with dimension values and metric values as properties.
        var amount = 0.0
        for row in result.data.data {
            amount += row.value(forKey: Self.spentUsageMetric)?.numberValue ?? 0
        }
        // If the metric key is missing entirely, the name is probably wrong —
        // surface the actual row keys so the correct one can be identified.
        if let firstRow = result.data.data.first,
           firstRow.value(forKey: Self.spentUsageMetric) == nil {
            throw OpenRouterAPIError(
                statusCode: 200,
                serverMessage: "No '\(Self.spentUsageMetric)' metric in response. Row keys: \(firstRow.rawValues.keys.sorted().joined(separator: ", "))"
            )
        }
        return (amount, startOfTodayUTC)
    }

    /// ISO 8601 UTC timestamp with seconds (`YYYY-MM-DDTHH:mm:ss'Z'`).
    /// The /analytics/query endpoint rejects minute-precision timestamps.
    private static func iso8601SecondsString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter.string(from: date)
    }

    // MARK: - Spend Today by Model

    /// Fetches the live "spent today" breakdown by model (USD) via POST /analytics/query,
    /// querying the range UTC today 00:00:00 → now, grouped by model.
    private func fetchSpentTodayByModelFromAPI() async throws -> [ModelSpending] {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let startOfTodayUTC = utcCalendar.startOfDay(for: Date())

        let body = AnalyticsQueryRequest(
            metrics: [Self.spentUsageMetric],
            time_range: .init(
                start: Self.iso8601SecondsString(for: startOfTodayUTC),
                end: Self.iso8601SecondsString(for: Date())
            ),
            dimensions: ["model"],
            granularity: nil
        )

        guard let url = URL(string: "https://openrouter.ai/api/v1/analytics/query") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw OpenRouterAPIError(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1,
                serverMessage: Self.decodeServerErrorMessage(from: data)
            )
        }

        let result = try JSONDecoder().decode(AnalyticsQueryResponse.self, from: data)

        var modelSpending: [ModelSpending] = []
        for row in result.data.data {
            // Extract model name from the row (dimension value)
            let modelName = row.value(forKey: "model")?.stringValue ?? "Unknown"
            
            // Extract spend amount (metric value) - include free models with $0 spend
            let amount = row.value(forKey: Self.spentUsageMetric)?.numberValue ?? 0
            
            // Extract provider name from model (e.g., "anthropic/claude-3.5-sonnet" -> "anthropic")
            let providerName = modelName.components(separatedBy: "/").first?.lowercased() ?? "unknown"
            
            modelSpending.append(ModelSpending(
                modelName: modelName,
                providerName: providerName,
                amount: amount
            ))
        }
        
        // Sort by amount descending (free models with $0 will be at the bottom)
        return modelSpending.sorted { $0.amount > $1.amount }
    }

    /// Extracts `error.message` from an OpenRouter error body, if present.
    private static func decodeServerErrorMessage(from data: Data) -> String? {
        struct ErrorBody: Decodable {
            struct Error: Decodable { let message: String? }
            let error: Error
        }
        return (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error.message
    }
}

struct CreditResponse: Codable {
    let data: CreditData
}

struct CreditData: Codable {
    let total_credits: Double
    let total_usage: Double
}

// MARK: - /analytics/query

struct AnalyticsQueryRequest: Codable {
    let metrics: [String]
    let time_range: TimeRange
    let dimensions: [String]?
    let granularity: String?

    struct TimeRange: Codable {
        /// ISO 8601 UTC with seconds (YYYY-MM-DDTHH:mm:ss'Z')
        let start: String
        let end: String
    }
}

struct AnalyticsQueryResponse: Decodable {
    let data: Payload

    struct Payload: Decodable {
        /// Each row is a flat object with dimension values and metric values as properties
        let data: [AnalyticsRow]
    }
}

struct AnalyticsRow: Decodable {
    // Dynamic properties - dimension values and metric values
    // We'll decode this manually
    let rawValues: [String: JSONValue]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dict = try container.decode([String: JSONValue].self)
        self.rawValues = dict
    }
    
    func value(forKey key: String) -> JSONValue? {
        return rawValues[key]
    }
}

/// Minimal JSON value type for decoding schemaless /analytics/query rows.
enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.typeMismatch(
                JSONValue.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value")
            )
        }
    }

    var numberValue: Double? {
        switch self {
        case .number(let value):
            return value
        case .string(let value):
            // The docs note some metrics may come back as strings.
            return Double(value)
        default:
            return nil
        }
    }

    var objectValues: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
}

/// API error carrying the HTTP status code, with a friendly message for common failures.
struct OpenRouterAPIError: LocalizedError {
    let statusCode: Int
    let serverMessage: String?

    var errorDescription: String? {
        let base: String
        switch statusCode {
        case 401:
            base = "Authentication failed (HTTP 401). Check your API key."
        case 403:
            base = "Access denied (HTTP 403). The API may require a Management API key."
        default:
            base = "Request failed (HTTP \(statusCode))."
        }
        return serverMessage.map { base + " Server: \($0)" } ?? base
    }
}
