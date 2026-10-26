import Foundation

struct AntigravityModelQuota: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let aliases: [String]
    let remainingFraction: Double
    let resetTime: Date?

    var displayName: String {
        aliases.first ?? id
    }

    func matches(_ name: String) -> Bool {
        ([id] + aliases).contains { $0.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }

    var remainingPercent: Int {
        Int((min(max(remainingFraction, 0), 1) * 100).rounded())
    }
}

struct AntigravityQuotaGroup: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let name: String
    let modelNames: [String]
    let remainingFraction: Double
    let resetTime: Date?

    var remainingPercent: Int {
        Int((min(max(remainingFraction, 0), 1) * 100).rounded())
    }

    var usedPercent: Int {
        100 - remainingPercent
    }
}

struct AntigravityQuotaSnapshot: Codable, Equatable, Sendable {
    let availablePromptCredits: Double?
    let monthlyPromptCredits: Double?
    let models: [AntigravityModelQuota]
    let groups: [AntigravityQuotaGroup]
    let warningMessage: String?

    init(
        availablePromptCredits: Double?,
        monthlyPromptCredits: Double?,
        models: [AntigravityModelQuota],
        groups: [AntigravityQuotaGroup] = [],
        warningMessage: String? = nil
    ) {
        self.availablePromptCredits = availablePromptCredits
        self.monthlyPromptCredits = monthlyPromptCredits
        self.models = models
        self.groups = groups
        self.warningMessage = warningMessage
    }

    var lowestQuotaRemainingPercent: Int? {
        groups.map(\.remainingPercent).min() ?? models.map(\.remainingPercent).min()
    }
}
