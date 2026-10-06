//
//  OpenRouterCreditManager.swift
//  OpenRouterCreditMenuBar
//

import Foundation
import SwiftUI

/// Formats a number in abbreviated form (e.g., 1.5K, 2.3M, 1.2B, 3.4T)
func formatAbbreviated(_ number: Int) -> String {
    let value = Double(number)
    switch value {
    case 1_000_000_000_000...:
        return String(format: "%.1fT", value / 1_000_000_000_000)
    case 1_000_000_000...:
        return String(format: "%.1fB", value / 1_000_000_000)
    case 1_000_000...:
        return String(format: "%.1fM", value / 1_000_000)
    case 1_000...:
        return String(format: "%.1fK", value / 1_000)
    default:
        return "\(number)"
    }
}

/// Format tokens with specific rules:
/// - If integer part has >=3 digits: no decimals (e.g., 123K, 1.2M)
/// - If integer part has <3 digits: show decimals so total digits = 3 (e.g., 1.23, 25.6)
func formatTokens(_ number: Int) -> String {
    let value = Double(number)
    let abbreviated = formatAbbreviated(number)

    // Extract the numeric part and suffix
    let suffix: String
    let numericPart: Double
    if abbreviated.hasSuffix("T") {
        suffix = "T"
        numericPart = value / 1_000_000_000_000
    } else if abbreviated.hasSuffix("B") {
        suffix = "B"
        numericPart = value / 1_000_000_000
    } else if abbreviated.hasSuffix("M") {
        suffix = "M"
        numericPart = value / 1_000_000
    } else if abbreviated.hasSuffix("K") {
        suffix = "K"
        numericPart = value / 1_000
    } else {
        // No suffix, just the number
        return "\(number)"
    }

    let intPart = Int(numericPart)
    let intDigits = "\(intPart)".count

    if intDigits >= 3 {
        // >=3 integer digits: no decimals
        return "\(intPart)\(suffix)"
    } else {
        // <3 integer digits: show decimals so total digits = 3
        let decimalPlaces = 3 - intDigits
        let format = "%." + "\(decimalPlaces)" + "f\(suffix)"
        return String(format: format, numericPart)
    }
}

/// Format price: remove trailing zeros after decimal point
func formatPrice(_ priceString: String) -> String {
    guard let price = Double(priceString) else { return priceString }
    let pricePerM = price * 1_000_000
    // Format with up to 4 decimal places, then remove trailing zeros
    let formatted = String(format: "%.4f", pricePerM)
    // Remove trailing zeros and potential trailing decimal point
    return formatted
        .replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
}

/// Format context length: no decimals, round to whole number
func formatContext(_ number: Int) -> String {
    let value = Double(number)
    switch value {
    case 1_000_000_000_000...:
        let rounded = Int((value / 1_000_000_000_000).rounded())
        return "\(rounded)T"
    case 1_000_000_000...:
        let rounded = Int((value / 1_000_000_000).rounded())
        return "\(rounded)B"
    case 1_000_000...:
        let rounded = Int((value / 1_000_000).rounded())
        return "\(rounded)M"
    case 1_000...:
        let rounded = Int((value / 1_000).rounded())
        return "\(rounded)K"
    default:
        return "\(number)"
    }
}

struct ModelSpending: Identifiable {
    let id = UUID()
    let modelName: String
    let providerName: String
    let amount: Double
    
    var providerColor: Color {
        ProviderColors.color(for: providerName)
    }
}

struct ModelRequests: Identifiable {
    let id = UUID()
    let modelName: String
    let providerName: String
    let count: Int

    var providerColor: Color {
        ProviderColors.color(for: providerName)
    }
}

/// Top model entry with token usage and paid/free classification
struct TopModel: Identifiable {
    let id = UUID()
    let modelPermaslug: String
    let displayName: String
    let totalTokens: Int
    let isFree: Bool
    let inputPrice: String?      // Price per 1M tokens (e.g., "0.000000003")
    let outputPrice: String?     // Price per 1M tokens (e.g., "0.0000024")
    let contextLength: Int       // Context length in tokens (e.g., 1048576)

    var providerName: String {
        modelPermaslug.components(separatedBy: "/").first?.lowercased() ?? "unknown"
    }

    var providerColor: Color {
        ProviderColors.color(for: providerName)
    }

    var formattedTokens: String {
        formatTokens(totalTokens)
    }

    /// Formatted pricing string for paid models (e.g., "$0.0395/$1.2")
    var formattedPricing: String? {
        guard !isFree, let input = inputPrice, let output = outputPrice else { return nil }
        let inputFormatted = formatPrice(input)
        let outputFormatted = formatPrice(output)
        return "$\(inputFormatted)/$\(outputFormatted)"
    }

    /// Formatted context length (e.g., "1M", "128K") - no decimals
    var formattedContext: String {
        formatContext(contextLength)
    }
}

/// Public API (frontend) response types
struct PublicAPIResponse: Decodable {
    let data: PublicAPIData
}

struct PublicAPIData: Decodable {
    let models: [PublicAPIModel]
    let analytics: PublicAPIAnalytics?
    let categories: PublicAPICategories?
    let benchmark_ranges: PublicAPIBenchmarkRanges?
}

struct PublicAPIAnalytics: Decodable {
    let modelAnalytics: [String: PublicAPIModelAnalytics]
    
    // Decode as a dictionary since keys are dynamic (model permaslugs with variant)
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self.modelAnalytics = try container.decode([String: PublicAPIModelAnalytics].self)
        } catch {
            // If decoding fails, log the raw keys for debugging
            if let jsonDict = try? container.decode([String: JSONValue].self) {
                print("[OpenRouter] Analytics raw keys: \(Array(jsonDict.keys).prefix(20))")
            }
            self.modelAnalytics = [:]
        }
    }
}

struct PublicAPIModelAnalytics: Decodable {
    let date: String
    let model_permaslug: String
    let variant: String
    let variant_permaslug: String
    let count: Int
    let total_usage: Double
    let total_completion_tokens: Int
    let total_prompt_tokens: Int
    let total_native_tokens_reasoning: Int
    let num_media_prompt: Int
    let num_media_completion: Int
    let image_output_requests: Int
    let num_video_prompt: Int
    let video_output_seconds: Double
    let rerank_documents: Int
    let stt_transcript_characters: Int
    let num_audio_prompt: Int
    let total_native_tokens_cached: Int
    let total_tool_calls: Int
    let requests_with_tool_call_errors: Int
    let total_byok_prompt_tokens: Int
    let total_byok_completion_tokens: Int
    
    /// Total tokens = prompt + completion + reasoning
    var totalTokens: Int {
        total_prompt_tokens + total_completion_tokens + total_native_tokens_reasoning
    }
    
    /// The full key used in the analytics dictionary (model_permaslug/variant)
    var analyticsKey: String {
        "\(model_permaslug)/\(variant)"
    }
}

/// Flexible JSON value for decoding varying API structures
enum FlexibleJSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: FlexibleJSONValue])
    case array([FlexibleJSONValue])
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
        } else if let value = try? container.decode([FlexibleJSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: FlexibleJSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.typeMismatch(
                FlexibleJSONValue.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value")
            )
        }
    }
}

/// Categories - handles both paid (model-based arrays) and free (category-name-based ranges) formats
struct PublicAPICategories: Decodable {
    let rawCategories: [String: FlexibleJSONValue]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawCategories = try container.decode([String: FlexibleJSONValue].self)
    }
}

/// Benchmark ranges - handles both paid (full structure) and free (only da_elo) formats
struct PublicAPIBenchmarkRanges: Decodable {
    let rawRanges: [String: FlexibleJSONValue]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawRanges = try container.decode([String: FlexibleJSONValue].self)
    }
}

struct PublicAPIModel: Decodable {
    let slug: String
    let name: String
    let short_name: String?
    let author: String
    let context_length: Int
    let input_modalities: [String]
    let output_modalities: [String]
    let endpoint: PublicAPIEndpoint?
    let is_free: Bool?
    let permaslug: String?
}

struct PublicAPIEndpoint: Decodable {
    let model_variant_slug: String
    let model_variant_permaslug: String?
    let variant: String
    let is_free: Bool
    let pricing: PublicAPIPricing?
}

struct PublicAPIPricing: Decodable {
    let prompt: String
    let completion: String
}

struct ProviderColors {
    static func color(for provider: String) -> Color {
        let lowercased = provider.lowercased()
        if lowercased.contains("deepseek") {
            return Color(hex: "4f6afd")  // DeepSeek
        } else if lowercased.contains("z.ai") || lowercased.contains("z-ai") || lowercased.contains("glm") {
            return Color(hex: "d2d2d2")  // Z.ai
        } else if lowercased.contains("xiaomi") {
            return Color(hex: "ec6617")  // Xiaomi
        } else if lowercased.contains("tencent") {
            return Color(hex: "43baff")  // Tencent
        } else if lowercased.contains("nvidia") {
            return Color(hex: "74b700")  // NVIDIA
        } else if lowercased.contains("typesafe") {
            return Color(hex: "e551ba")  // Typesafe
        } else if lowercased.contains("anthropic") || lowercased.contains("claude") {
            return Color(hex: "cc9b7a")  // Anthropic
        } else if lowercased.contains("google") || lowercased.contains("gemini") {
            return Color(hex: "7276c9")  // Google
        } else if lowercased.contains("moonshotai") || lowercased.contains("moonshot") {
            return Color(hex: "c7c7c7")  // Moonshot AI
        } else if lowercased.contains("meta") || lowercased.contains("llama") {
            return Color(hex: "3c87ec")  // Meta
        } else if lowercased.contains("minimax") {
            return Color(hex: "f44854")  // MiniMax
        } else if lowercased.contains("poolside") {
            return Color(hex: "4337ff")  // Poolside
        } else if lowercased.contains("openrouter") {
            return Color(hex: "c8fe03")  // OpenRouter
        } else if lowercased.contains("upstage") {
            return Color(hex: "8c8ddf")  // Upstage
        } else if lowercased.contains("qwen") || lowercased.contains("alibaba") {
            return Color(hex: "6c62f8")  // Qwen
        } else if lowercased.contains("dots-studio") || lowercased.contains("dotsstudio") {
            return Color(hex: "a4e7da")  // Dots Studio
        } else if lowercased.contains("inclusionai") || lowercased.contains("inclusion") {
            return Color(hex: "ffffff")  // InclusionAI
        } else if lowercased.contains("x.ai") || lowercased.contains("grok") {
            return Color(hex: "ffffff")  // x.ai
        } else if lowercased.contains("openai") {
            return Color(hex: "f7f7f7")  // OpenAI white
        } else if lowercased.contains("mistral") {
            return Color(red: 0.9, green: 0.3, blue: 0.25)  // Mistral red/orange
        } else if lowercased.contains("cohere") {
            return Color(red: 0.5, green: 0.2, blue: 0.8)  // Cohere purple
        } else if lowercased.contains("perplexity") {
            return Color(red: 0.15, green: 0.65, blue: 0.85)  // Perplexity teal
        } else {
            return Color.secondary  // Default gray
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (128, 128, 128)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

class OpenRouterCreditManager: ObservableObject {
    @Published var currentCredit: Double?
    @Published var totalUsage: Double?
    @Published var spentToday: Double?
    /// The UTC day that `spentToday` refers to (start of the current UTC day).
    @Published var spentTodayDate: Date?
    @Published var spentTodayByModel: [ModelSpending] = []
    @Published var requestsToday: Int?
    @Published var requestsTodayDate: Date?
    @Published var requestsTodayByModel: [ModelRequests] = []
    @Published var requestsThisWeek: Int?
    @Published var requestsThisWeekByModel: [ModelRequests] = []
    @Published var tokensToday: Int?
    @Published var tokensTodayDate: Date?
    @Published var tokensTodayByModel: [ModelRequests] = []
    @Published var tokensThisWeek: Int?
    @Published var tokensThisWeekByModel: [ModelRequests] = []
    @Published var topModelsPaid: [TopModel] = []
    @Published var topModelsFree: [TopModel] = []
    @Published var topModelsDate: Date?
    @Published var isLoading = false
    
    // Independent error messages for each data block
    @Published var creditErrorMessage: String?
    @Published var requestsErrorMessage: String?
    @Published var tokensErrorMessage: String?
    @Published var topModelsErrorMessage: String?
    
    // Legacy property for backwards compatibility
    @Published var errorMessage: String? {
        didSet {
            // Keep legacy property in sync with the first non-nil error
            // This maintains backwards compatibility for any existing code
        }
    }

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
            // Clear all block-specific error messages
            creditErrorMessage = nil
            requestsErrorMessage = nil
            tokensErrorMessage = nil
            topModelsErrorMessage = nil
            errorMessage = nil
        }

        // MARK: - CREDIT block
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
            }
        } catch {
            await MainActor.run {
                self.creditErrorMessage = error.localizedDescription
                self.errorMessage = error.localizedDescription // Legacy compatibility
            }
        }

        // MARK: - REQUESTS block
        do {
            let requestsToday = try await fetchRequestsTodayFromAPI()
            let requestsTodayByModel = try await fetchRequestsTodayByModelFromAPI()
            let requestsThisWeek = try await fetchWeekRequestsFromAPI()
            let requestsThisWeekByModel = try await fetchWeekRequestsByModelFromAPI()
            await MainActor.run {
                self.requestsToday = requestsToday.count
                self.requestsTodayDate = requestsToday.date
                self.requestsTodayByModel = requestsTodayByModel
                self.requestsThisWeek = requestsThisWeek
                self.requestsThisWeekByModel = requestsThisWeekByModel
            }
        } catch {
            await MainActor.run {
                self.requestsErrorMessage = error.localizedDescription
                // Only set legacy error if it's not already set
                if self.errorMessage == nil {
                    self.errorMessage = error.localizedDescription
                }
            }
        }

        print("[OpenRouter] Starting TOKENS block")
        // MARK: - TOKENS block
        do {
            let tokensToday = try await fetchTokensTodayFromAPI()
            let tokensTodayByModel = try await fetchTokensTodayByModelFromAPI()
            let tokensThisWeek = try await fetchWeekTokensFromAPI()
            let tokensThisWeekByModel = try await fetchWeekTokensByModelFromAPI()
            await MainActor.run {
                self.tokensToday = tokensToday.count
                self.tokensTodayDate = tokensToday.date
                self.tokensTodayByModel = tokensTodayByModel
                self.tokensThisWeek = tokensThisWeek
                self.tokensThisWeekByModel = tokensThisWeekByModel
            }
            print("[OpenRouter] TOKENS block completed successfully")
        } catch {
            await MainActor.run {
                self.tokensErrorMessage = error.localizedDescription
                if self.errorMessage == nil {
                    self.errorMessage = error.localizedDescription
                }
            }
        }

        print("[OpenRouter] TOKENS block completed, starting TOP MODELS block")
        // MARK: - TOP MODELS block (Public API only)
        do {
            let topModels = try await fetchTopModelsFromPublicAPI()
            await MainActor.run {
                self.topModelsPaid = topModels.paid
                self.topModelsFree = topModels.free
                self.topModelsDate = topModels.date
            }
        } catch {
            await MainActor.run {
                self.topModelsErrorMessage = error.localizedDescription
                if self.errorMessage == nil {
                    self.errorMessage = error.localizedDescription
                }
            }
        }

        await MainActor.run {
            self.isLoading = false
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

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Log the response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("[OpenRouter] Credits response (\(httpResponse.statusCode)): \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenRouterAPIError(
                statusCode: httpResponse.statusCode,
                serverMessage: Self.decodeServerErrorMessage(from: data)
            )
        }

        let creditResponse = try JSONDecoder().decode(CreditResponse.self, from: data)
        return creditResponse.data
    }

    // MARK: - Spend Today

    /// Metric name for total credits spent (USD) in /analytics/query responses.
    /// Based on OpenRouter API: could be "cost", "total_usage", "spend", or "usage"
    private static let spentUsageMetric = "total_usage"
    
    /// Metric name for total requests count in /analytics/query responses.
    /// Per OpenRouter analytics API: "request_count"
    private static let requestsMetric = "request_count"
    
    /// Metric name for total tokens in /analytics/query responses.
    /// Per OpenRouter analytics API: "tokens_prompt" and "tokens_completion"
    private static let promptTokensMetric = "tokens_prompt"
    private static let completionTokensMetric = "tokens_completion"

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

        print("[OpenRouter] DEBUG: Request encoded successfully, about to send")
        // Log the request body for debugging
        if let httpBody = request.httpBody,
           let requestString = String(data: httpBody, encoding: .utf8) {
            print("[OpenRouter] Analytics query request: \(requestString)")
        }
        print("[OpenRouter] DEBUG: Request logged, sending...")

        let (data, response) = try await URLSession.shared.data(for: request)

        print("[OpenRouter] DEBUG: Response received")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Log the response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("[OpenRouter] Analytics query response (\(httpResponse.statusCode)): \(responseString)")
        }

        guard httpResponse.statusCode == 200 else {
            // Log detailed error for 400 and other errors
            if let errorString = String(data: data, encoding: .utf8) {
                print("[OpenRouter] ERROR \(httpResponse.statusCode): \(errorString)")
            }
            throw OpenRouterAPIError(
                statusCode: httpResponse.statusCode,
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

        // Log the request body for debugging
        if let httpBody = request.httpBody,
           let requestString = String(data: httpBody, encoding: .utf8) {
            print("[OpenRouter] Analytics query request: \(requestString)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Log the response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("[OpenRouter] Analytics query response (\(httpResponse.statusCode)): \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenRouterAPIError(
                statusCode: httpResponse.statusCode,
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
    
    // MARK: - Requests Today
    
    /// Fetches the live "requests today" total count via POST /analytics/query,
    /// querying the range UTC today 00:00:00 → now.
    private func fetchRequestsTodayFromAPI() async throws -> (count: Int, date: Date) {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let startOfTodayUTC = utcCalendar.startOfDay(for: Date())
        
        let body = AnalyticsQueryRequest(
            metrics: [Self.requestsMetric],
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Log the response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("[OpenRouter] Analytics query response (\(httpResponse.statusCode)): \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenRouterAPIError(
                statusCode: httpResponse.statusCode,
                serverMessage: Self.decodeServerErrorMessage(from: data)
            )
        }
        
        let result = try JSONDecoder().decode(AnalyticsQueryResponse.self, from: data)
        // Response rows are flat objects with dimension values and metric values as properties.
        var count = 0
        for row in result.data.data {
            count += Int(row.value(forKey: Self.requestsMetric)?.numberValue ?? 0)
        }
        // If the metric key is missing entirely, the name is probably wrong —
        // surface the actual row keys so the correct one can be identified.
        if let firstRow = result.data.data.first,
           firstRow.value(forKey: Self.requestsMetric) == nil {
            throw OpenRouterAPIError(
                statusCode: 200,
                serverMessage: "No '\(Self.requestsMetric)' metric in response. Row keys: \(firstRow.rawValues.keys.sorted().joined(separator: ", "))"
            )
        }
        return (count, startOfTodayUTC)
    }
    
    /// Fetches the live "requests today" breakdown by model via POST /analytics/query,
    /// querying the range UTC today 00:00:00 → now, grouped by model.
    private func fetchRequestsTodayByModelFromAPI() async throws -> [ModelRequests] {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let startOfTodayUTC = utcCalendar.startOfDay(for: Date())
        
        let body = AnalyticsQueryRequest(
            metrics: [Self.requestsMetric],
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Log the response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("[OpenRouter] Analytics query response (\(httpResponse.statusCode)): \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenRouterAPIError(
                statusCode: httpResponse.statusCode,
                serverMessage: Self.decodeServerErrorMessage(from: data)
            )
        }
        
        let result = try JSONDecoder().decode(AnalyticsQueryResponse.self, from: data)
        
        var modelRequests: [ModelRequests] = []
        for row in result.data.data {
            // Extract model name from the row (dimension value)
            let modelName = row.value(forKey: "model")?.stringValue ?? "Unknown"
            
            // Extract request count (metric value)
            let count = Int(row.value(forKey: Self.requestsMetric)?.numberValue ?? 0)
            
            // Extract provider name from model (e.g., "anthropic/claude-3.5-sonnet" -> "anthropic")
            let providerName = modelName.components(separatedBy: "/").first?.lowercased() ?? "unknown"
            
            modelRequests.append(ModelRequests(
                modelName: modelName,
                providerName: providerName,
                count: count
            ))
        }
        
        // Sort by count descending
        return modelRequests.sorted { $0.count > $1.count }
    }

    /// Fetches the requests count for the last 7×24 hours (168 hours) via POST /analytics/query.
    private func fetchWeekRequestsFromAPI() async throws -> Int {
        // Last 7 × 24 hours = 168 hours ago from now
        let now = Date()
        let startDate = now.addingTimeInterval(-7 * 24 * 60 * 60) // 168 hours ago

        let body = AnalyticsQueryRequest(
            metrics: [Self.requestsMetric],
            time_range: .init(
                start: Self.iso8601SecondsString(for: startDate),
                end: Self.iso8601SecondsString(for: now)
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

        // Log the request body for debugging
        if let httpBody = request.httpBody,
           let requestString = String(data: httpBody, encoding: .utf8) {
            print("[OpenRouter] Analytics query request: \(requestString)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Log the response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("[OpenRouter] Total requests query response (\(httpResponse.statusCode)): \(responseString)")
        }

        guard httpResponse.statusCode == 200 else {
            throw OpenRouterAPIError(
                statusCode: httpResponse.statusCode,
                serverMessage: Self.decodeServerErrorMessage(from: data)
            )
        }

        let result = try JSONDecoder().decode(AnalyticsQueryResponse.self, from: data)
        var count = 0
        for row in result.data.data {
            count += Int(row.value(forKey: Self.requestsMetric)?.numberValue ?? 0)
        }
        return count
    }

    /// Fetches the requests count breakdown by model for the last 7×24 hours via POST /analytics/query.
    private func fetchWeekRequestsByModelFromAPI() async throws -> [ModelRequests] {
        let now = Date()
        let startDate = now.addingTimeInterval(-7 * 24 * 60 * 60) // 168 hours ago

        let body = AnalyticsQueryRequest(
            metrics: [Self.requestsMetric],
            time_range: .init(
                start: Self.iso8601SecondsString(for: startDate),
                end: Self.iso8601SecondsString(for: now)
            ),
            dimensions: ["model"]
        )

        guard let url = URL(string: "https://openrouter.ai/api/v1/analytics/query") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        // Log the request body for debugging
        if let httpBody = request.httpBody,
           let requestString = String(data: httpBody, encoding: .utf8) {
            print("[OpenRouter] Analytics query request: \(requestString)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Log the response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("[OpenRouter] Week requests by model response (\(httpResponse.statusCode)): \(responseString)")
        }

        guard httpResponse.statusCode == 200 else {
            throw OpenRouterAPIError(
                statusCode: httpResponse.statusCode,
                serverMessage: Self.decodeServerErrorMessage(from: data)
            )
        }

        let result = try JSONDecoder().decode(AnalyticsQueryResponse.self, from: data)

        var modelRequests: [ModelRequests] = []
        for row in result.data.data {
            let modelName = row.value(forKey: "model")?.stringValue ?? "Unknown"
            let count = Int(row.value(forKey: Self.requestsMetric)?.numberValue ?? 0)
            let providerName = modelName.components(separatedBy: "/").first?.lowercased() ?? "unknown"

            modelRequests.append(ModelRequests(
                modelName: modelName,
                providerName: providerName,
                count: count
            ))
        }

        return modelRequests.sorted { $0.count > $1.count }
    }

    // MARK: - Tokens Today

    /// Fetches the live "tokens today" total count via POST /analytics/query,
    /// querying the range UTC today 00:00:00 → now.
    private func fetchTokensTodayFromAPI() async throws -> (count: Int, date: Date) {
        print("[OpenRouter] fetchTokensTodayFromAPI called")
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let startOfTodayUTC = utcCalendar.startOfDay(for: Date())

        let body = AnalyticsQueryRequest(
            metrics: [Self.promptTokensMetric, Self.completionTokensMetric],
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

        print("[OpenRouter] DEBUG: Request encoded successfully, about to send")
        // Log the request body for debugging
        if let httpBody = request.httpBody,
           let requestString = String(data: httpBody, encoding: .utf8) {
            print("[OpenRouter] Analytics query request: \(requestString)")
        }
        print("[OpenRouter] DEBUG: Request logged, sending...")

        let (data, response) = try await URLSession.shared.data(for: request)

        print("[OpenRouter] DEBUG: Response received")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Log the response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("[OpenRouter] Analytics query response (\(httpResponse.statusCode)): \(responseString)")
        }

        // Log detailed error for non-200 responses
        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("[OpenRouter] ERROR \(httpResponse.statusCode): \(errorString)")
            }
            throw OpenRouterAPIError(
                statusCode: httpResponse.statusCode,
                serverMessage: Self.decodeServerErrorMessage(from: data)
            )
        }

        let result = try JSONDecoder().decode(AnalyticsQueryResponse.self, from: data)
        var count = 0
        for row in result.data.data {
            count += Int(row.value(forKey: Self.promptTokensMetric)?.numberValue ?? 0)
            count += Int(row.value(forKey: Self.completionTokensMetric)?.numberValue ?? 0)
        }
        return (count, startOfTodayUTC)
    }

    /// Fetches the live "tokens today" breakdown by model via POST /analytics/query,
    /// querying the range UTC today 00:00:00 → now, grouped by model.
    private func fetchTokensTodayByModelFromAPI() async throws -> [ModelRequests] {
        print("[OpenRouter] fetchTokensTodayByModelFromAPI called")
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let startOfTodayUTC = utcCalendar.startOfDay(for: Date())

        let body = AnalyticsQueryRequest(
            metrics: [Self.promptTokensMetric, Self.completionTokensMetric],
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

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Log the response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("[OpenRouter] Analytics query response (\(httpResponse.statusCode)): \(responseString)")
        }

        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("[OpenRouter] ERROR \(httpResponse.statusCode): \(errorString)")
            }
            throw OpenRouterAPIError(
                statusCode: httpResponse.statusCode,
                serverMessage: Self.decodeServerErrorMessage(from: data)
            )
        }

        let result = try JSONDecoder().decode(AnalyticsQueryResponse.self, from: data)

        var modelRequests: [ModelRequests] = []
        for row in result.data.data {
            let modelName = row.value(forKey: "model")?.stringValue ?? "Unknown"
            let promptCount = Int(row.value(forKey: Self.promptTokensMetric)?.numberValue ?? 0)
            let completionCount = Int(row.value(forKey: Self.completionTokensMetric)?.numberValue ?? 0)
            let count = promptCount + completionCount
            let providerName = modelName.components(separatedBy: "/").first?.lowercased() ?? "unknown"

            modelRequests.append(ModelRequests(
                modelName: modelName,
                providerName: providerName,
                count: count
            ))
        }

        return modelRequests.sorted { $0.count > $1.count }
    }

    /// Fetches the tokens count for the last 7×24 hours (168 hours) via POST /analytics/query.
    private func fetchWeekTokensFromAPI() async throws -> Int {
        print("[OpenRouter] fetchWeekTokensFromAPI called")
        let now = Date()
        let startDate = now.addingTimeInterval(-7 * 24 * 60 * 60) // 168 hours ago

        let body = AnalyticsQueryRequest(
            metrics: [Self.promptTokensMetric, Self.completionTokensMetric],
            time_range: .init(
                start: Self.iso8601SecondsString(for: startDate),
                end: Self.iso8601SecondsString(for: now)
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

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Log the response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("[OpenRouter] Total tokens query response (\(httpResponse.statusCode)): \(responseString)")
        }

        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("[OpenRouter] ERROR \(httpResponse.statusCode): \(errorString)")
            }
            throw OpenRouterAPIError(
                statusCode: httpResponse.statusCode,
                serverMessage: Self.decodeServerErrorMessage(from: data)
            )
        }

        let result = try JSONDecoder().decode(AnalyticsQueryResponse.self, from: data)
        var count = 0
        for row in result.data.data {
            count += Int(row.value(forKey: Self.promptTokensMetric)?.numberValue ?? 0)
            count += Int(row.value(forKey: Self.completionTokensMetric)?.numberValue ?? 0)
        }
        return count
    }

    /// Fetches the tokens count breakdown by model for the last 7×24 hours via POST /analytics/query.
    private func fetchWeekTokensByModelFromAPI() async throws -> [ModelRequests] {
        print("[OpenRouter] fetchWeekTokensByModelFromAPI called")
        let now = Date()
        let startDate = now.addingTimeInterval(-7 * 24 * 60 * 60) // 168 hours ago

        let body = AnalyticsQueryRequest(
            metrics: [Self.promptTokensMetric, Self.completionTokensMetric],
            time_range: .init(
                start: Self.iso8601SecondsString(for: startDate),
                end: Self.iso8601SecondsString(for: now)
            ),
            dimensions: ["model"]
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

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Log the response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("[OpenRouter] Week tokens by model response (\(httpResponse.statusCode)): \(responseString)")
        }

        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("[OpenRouter] ERROR \(httpResponse.statusCode): \(errorString)")
            }
            throw OpenRouterAPIError(
                statusCode: httpResponse.statusCode,
                serverMessage: Self.decodeServerErrorMessage(from: data)
            )
        }

        let result = try JSONDecoder().decode(AnalyticsQueryResponse.self, from: data)

        var modelRequests: [ModelRequests] = []
        for row in result.data.data {
            let modelName = row.value(forKey: "model")?.stringValue ?? "Unknown"
            let promptCount = Int(row.value(forKey: Self.promptTokensMetric)?.numberValue ?? 0)
            let completionCount = Int(row.value(forKey: Self.completionTokensMetric)?.numberValue ?? 0)
            let count = promptCount + completionCount
            let providerName = modelName.components(separatedBy: "/").first?.lowercased() ?? "unknown"

            modelRequests.append(ModelRequests(
                modelName: modelName,
                providerName: providerName,
                count: count
            ))
        }

        return modelRequests.sorted { $0.count > $1.count }
    }

    /// Extracts `error.message` from an OpenRouter error body, if present.
    private static func decodeServerErrorMessage(from data: Data) -> String? {
        struct ErrorBody: Decodable {
            struct Error: Decodable { let message: String? }
            let error: Error
        }
        return (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error.message
    }

    // MARK: - Top Models (Data API)

    /// Result of top models fetch containing paid and free model lists
    private struct TopModelsResult {
        let paid: [TopModel]
        let free: [TopModel]
        let date: Date
    }

    // MARK: - Top Models (Public API / Frontend)

    /// Fetches top models from the Public API (frontend) using 2 separate requests:
    /// - Paid: order=top-weekly
    /// - Free: order=top-weekly&variant=free
    /// This is a public endpoint that does NOT require authentication.
    private func fetchTopModelsFromPublicAPI() async throws -> TopModelsResult {
        print("[OpenRouter] fetchTopModelsFromPublicAPI called")
        do {
            async let paidModels = fetchPaidTopModelsFromPublicAPI()
            async let freeModels = fetchFreeTopModelsFromPublicAPI()
            let (paid, free) = try await (paidModels, freeModels)

            return TopModelsResult(
                paid: paid,
                free: free,
                date: Date()
            )
        } catch {
            print("[OpenRouter] ERROR in fetchTopModelsFromPublicAPI: \(error)")
            print("[OpenRouter] ERROR type: \(type(of: error))")
            if let decodingError = error as? DecodingError {
                print("[OpenRouter] DecodingError details: \(decodingError)")
            }
            throw error
        }
    }

    /// Fetches paid top models using order=top-weekly from frontend API
    private func fetchPaidTopModelsFromPublicAPI() async throws -> [TopModel] {
        let urlString = "https://openrouter.ai/api/frontend/v1/models/find?active=true&fmt=cards&order=top-weekly"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Public API is open - no authentication required
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if let responseString = String(data: data, encoding: .utf8) {
            print("[OpenRouter] Public API paid top models (\(httpResponse.statusCode)): \(responseString.prefix(2000))")
        }

        guard httpResponse.statusCode == 200 else {
            throw OpenRouterAPIError(
                statusCode: httpResponse.statusCode,
                serverMessage: Self.decodeServerErrorMessage(from: data)
            )
        }

        do {
            let publicResponse = try JSONDecoder().decode(PublicAPIResponse.self, from: data)
            print("[OpenRouter] Successfully decoded PublicAPIResponse for paid models")
            return try processPublicAPIModels(publicResponse, isFree: false)
        } catch {
            print("[OpenRouter] ERROR decoding paid models: \(error)")
            if let decodingError = error as? DecodingError {
                print("[OpenRouter] DecodingError details: \(decodingError)")
            }
            throw error
        }
    }

    /// Process PublicAPIResponse to extract TopModel array
    private func processPublicAPIModels(_ publicResponse: PublicAPIResponse, isFree: Bool) throws -> [TopModel] {
        // Build a lookup of analytics by model permaslug/variant
        var analyticsLookup: [String: PublicAPIModelAnalytics] = [:]
        if let analytics = publicResponse.data.analytics {
            analyticsLookup = analytics.modelAnalytics
            // Debug: log available analytics keys
            print("[OpenRouter] Available analytics keys (\(isFree ? "free" : "paid")): \(Array(analyticsLookup.keys).prefix(20))")
        }

        // Filter models based on free/paid
        let filteredModels = publicResponse.data.models.filter { model in
            let modelIsFree = model.endpoint?.is_free == true || model.is_free == true
            return isFree ? modelIsFree : !modelIsFree
        }

        // Take first 15 (already sorted by totalTokens descending from the API)
        let models = filteredModels
            .prefix(15)
            .map { model in
                let permaslug = model.permaslug ?? model.slug
                // Try multiple key formats to match analytics
                let possibleKeys = [
                    "\(permaslug)/standard",
                    "\(permaslug)/free",
                    model.endpoint?.model_variant_permaslug ?? "",
                    model.endpoint?.model_variant_slug ?? ""
                ].filter { !$0.isEmpty }

                var totalTokens = 0
                for key in possibleKeys {
                    if let tokens = analyticsLookup[key]?.totalTokens {
                        totalTokens = tokens
                        break
                    }
                }

                if totalTokens == 0 {
                    print("[OpenRouter] No analytics match for \(isFree ? "free" : "paid") model: \(permaslug), tried keys: \(possibleKeys)")
                }

                // Extract pricing and context from endpoint
                let inputPrice = model.endpoint?.pricing?.prompt
                let outputPrice = model.endpoint?.pricing?.completion

                return TopModel(
                    modelPermaslug: permaslug,
                    displayName: model.short_name ?? model.name,
                    totalTokens: totalTokens,
                    isFree: isFree,
                    inputPrice: inputPrice,
                    outputPrice: outputPrice,
                    contextLength: model.context_length
                )
            }

        return Array(models)
    }

    /// Fetches free top models using order=top-weekly&variant=free from frontend API
    private func fetchFreeTopModelsFromPublicAPI() async throws -> [TopModel] {
        let urlString = "https://openrouter.ai/api/frontend/v1/models/find?active=true&fmt=cards&order=top-weekly&variant=free"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Public API is open - no authentication required
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if let responseString = String(data: data, encoding: .utf8) {
            print("[OpenRouter] Public API free top models (\(httpResponse.statusCode)): \(responseString)")
        }

        guard httpResponse.statusCode == 200 else {
            throw OpenRouterAPIError(
                statusCode: httpResponse.statusCode,
                serverMessage: Self.decodeServerErrorMessage(from: data)
            )
        }

        do {
            let publicResponse = try JSONDecoder().decode(PublicAPIResponse.self, from: data)
            print("[OpenRouter] Successfully decoded PublicAPIResponse for free models")

            // Build a lookup of analytics by model permaslug/variant
            var analyticsLookup: [String: PublicAPIModelAnalytics] = [:]
            if let analytics = publicResponse.data.analytics {
                analyticsLookup = analytics.modelAnalytics
                // Debug: log available analytics keys
                print("[OpenRouter] Available analytics keys (free): \(Array(analyticsLookup.keys).prefix(20))")
            }

        // Debug: log model permaslugs and variant permaslugs
        for model in publicResponse.data.models.prefix(10) {
            print("[OpenRouter] Model: permaslug=\(model.permaslug ?? "nil"), slug=\(model.slug), variant_permaslug=\(model.endpoint?.model_variant_permaslug ?? "nil"), variant=\(model.endpoint?.variant ?? "nil"), is_free=\(model.endpoint?.is_free ?? false)")
        }

        // Take first 15 (already filtered for free by variant=free)
        // Models are already sorted by totalTokens descending from the API
        let freeModels = publicResponse.data.models
            .prefix(15)
            .map { model in
                let permaslug = model.permaslug ?? model.slug
                // Try multiple key formats to match analytics
                let possibleKeys = [
                    "\(permaslug)/free",
                    "\(permaslug)/standard",
                    model.endpoint?.model_variant_permaslug ?? "",
                    model.endpoint?.model_variant_slug ?? ""
                ].filter { !$0.isEmpty }

                var totalTokens = 0
                for key in possibleKeys {
                    if let tokens = analyticsLookup[key]?.totalTokens {
                        totalTokens = tokens
                        break
                    }
                }

                if totalTokens == 0 {
                    print("[OpenRouter] No analytics match for free model: \(permaslug), tried keys: \(possibleKeys)")
                }

                // Extract pricing and context from endpoint (free models have pricing of "0")
                let inputPrice = model.endpoint?.pricing?.prompt
                let outputPrice = model.endpoint?.pricing?.completion

                return TopModel(
                    modelPermaslug: permaslug,
                    displayName: model.short_name ?? model.name,
                    totalTokens: totalTokens,
                    isFree: true,
                    inputPrice: inputPrice,
                    outputPrice: outputPrice,
                    contextLength: model.context_length
                )
            }

        return Array(freeModels)
        } catch {
            print("[OpenRouter] ERROR decoding free models: \(error)")
            if let decodingError = error as? DecodingError {
                print("[OpenRouter] DecodingError details: \(decodingError)")
            }
            throw error
        }
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
    let dimensions: [String]
    let granularity: String?

    struct TimeRange: Codable {
        /// ISO 8601 UTC with seconds (YYYY-MM-DDTHH:mm:ss'Z')
        let start: String
        let end: String
    }
    
    init(metrics: [String], time_range: TimeRange, dimensions: [String] = [], granularity: String? = nil) {
        self.metrics = metrics
        self.time_range = time_range
        self.dimensions = dimensions
        self.granularity = granularity
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
