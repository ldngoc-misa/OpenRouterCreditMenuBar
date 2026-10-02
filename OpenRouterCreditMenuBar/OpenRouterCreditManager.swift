//
//  OpenRouterCreditManager.swift
//  OpenRouterCreditMenuBar
//

import Foundation

class OpenRouterCreditManager: ObservableObject {
    @Published var currentCredit: Double?
    @Published var totalUsage: Double?
    @Published var spentToday: Double?
    /// The UTC day that `spentToday` refers to (start of the current UTC day).
    @Published var spentTodayDate: Date?
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
            await MainActor.run {
                self.currentCredit = creditData.total_credits - creditData.total_usage
                self.totalUsage = creditData.total_usage
                self.spentToday = spentToday.amount
                self.spentTodayDate = spentToday.date
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
            )
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
        // Response rows are schemaless in the spec: metric-name → value dictionaries.
        var amount = 0.0
        for row in result.data.data {
            amount += row.objectValues?[Self.spentUsageMetric]?.numberValue ?? 0
        }
        // If the metric key is missing entirely, the name is probably wrong —
        // surface the actual row keys so the correct one can be identified.
        if let firstRowValues = result.data.data.first?.objectValues,
           !firstRowValues.keys.contains(Self.spentUsageMetric) {
            throw OpenRouterAPIError(
                statusCode: 200,
                serverMessage: "No '\(Self.spentUsageMetric)' metric in response. Row keys: \(firstRowValues.keys.sorted().joined(separator: ", "))"
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

    struct TimeRange: Codable {
        /// ISO 8601 UTC with seconds (YYYY-MM-DDTHH:mm:ss'Z')
        let start: String
        let end: String
    }
}

struct AnalyticsQueryResponse: Decodable {
    let data: Payload

    struct Payload: Decodable {
        /// Schemaless rows: metric-name → value
        let data: [JSONValue]
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
