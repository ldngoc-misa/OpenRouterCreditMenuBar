//
//  OpenRouterCreditMenuBarTests.swift
//  OpenRouterCreditMenuBarTests
//
//  Created by Kittithat Patepakorn on 24/5/2568 BE.
//
import Foundation
import Testing
@testable import OpenRouterCreditMenuBar

struct OpenRouterCreditMenuBarTests {

    @Test func menuBarCurrencyUsesWholeDollarsAtTenAndAboveAndOneDecimalBelowTen() {
        #expect(MenuBarStatusFormatter.formatCurrency(15.3) == "$15")
        #expect(MenuBarStatusFormatter.formatCurrency(8.64) == "$8.6")
        #expect(MenuBarStatusFormatter.formatCurrency(9.99) == "$10.0")
    }

    @Test func chatGPTRemainingPercentIsCalculatedFromUsedPercent() {
        #expect(MenuBarStatusFormatter.remainingPercent(fromUsedPercent: 17) == 83)
    }

    @Test func antigravityParserReadsNestedCreditsAndSortedModelQuotas() throws {
        let data = Data("""
        {
          "userStatus": {
            "planStatus": {
              "availablePromptCredits": 27,
              "planInfo": { "monthlyPromptCredits": 100 }
            },
            "cascadeModelConfigData": {
              "clientModelConfigs": [
                {
                  "modelOrAlias": { "model": "model-b", "displayName": "Model B" },
                  "quotaInfo": { "remainingFraction": 0.4, "resetTime": "2026-11-01T00:00:00Z" }
                },
                {
                  "modelOrAlias": { "model": "model-a" },
                  "quotaInfo": { "remainingFraction": 0.25, "resetTime": 1793491200 }
                }
              ]
            }
          }
        }
        """.utf8)

        let snapshot = try AntigravityQuotaParser.parse(data)

        #expect(snapshot.availablePromptCredits == 27)
        #expect(snapshot.monthlyPromptCredits == 100)
        #expect(snapshot.models.map(\.id) == ["model-a", "model-b"])
        #expect(snapshot.models.map(\.remainingPercent) == [25, 40])
        #expect(snapshot.models.last?.displayName == "Model B")
        #expect(snapshot.models.allSatisfy { $0.resetTime != nil })
        #expect(snapshot.lowestQuotaRemainingPercent == 25)
    }

    @Test func antigravityParserAcceptsRootStatusAndMissingOptionalFields() throws {
        let data = Data("""
        {
          "planStatus": { "availablePromptCredits": "12.5" },
          "cascadeModelConfigData": {
            "clientModelConfigs": [
              {
                "modelOrAlias": { "model": "model-x" },
                "quotaInfo": { "remainingFraction": 1.2 }
              }
            ]
          }
        }
        """.utf8)

        let snapshot = try AntigravityQuotaParser.parse(data)

        #expect(snapshot.availablePromptCredits == 12.5)
        #expect(snapshot.monthlyPromptCredits == nil)
        #expect(snapshot.models.first?.remainingPercent == 100)
        #expect(snapshot.models.first?.resetTime == nil)
    }

    @Test func antigravityProcessMatcherRecognizesTheAgyHubCommand() {
        let hubCommand = "/Users/example/.gemini/bin/agy --hub --hub-port=62552 --app_data_dir=antigravity --csrf_token=redacted"
        let unrelatedHubCommand = "/Users/example/.gemini/bin/agy --hub --app_data_dir=gemini"

        #expect(AntigravityQuotaService.isAntigravityServer(commandLine: hubCommand))
        #expect(!AntigravityQuotaService.isAntigravityServer(commandLine: unrelatedHubCommand))
    }

    @Test func antigravityUsageParserReadsSharedWeeklyQuotaGroups() throws {
        let report = """
        Account: user@example.com

        GEMINI MODELS
          Models within this group: Gemini Flash, Gemini Pro

          Weekly Limit Remaining
            [██████████████████████████████████████████████████] 100.00%
            Quota available

        CLAUDE AND GPT MODELS
          Models within this group: Claude Opus, Claude Sonnet, GPT-OSS

          Weekly Limit Remaining
            [██████████████████████████████████████████████████] 63.50%
            Quota available

        """

        let groups = try AntigravityUsageParser.parse(report)

        #expect(groups.map(\.name) == ["Gemini", "Claude & GPT"])
        #expect(groups.map(\.modelNames) == [
            ["Gemini Flash", "Gemini Pro"],
            ["Claude Opus", "Claude Sonnet", "GPT-OSS"]
        ])
        #expect(groups.map(\.remainingPercent) == [100, 64])
        #expect(groups.map(\.usedPercent) == [0, 36])
        #expect(groups.allSatisfy { $0.resetTime == nil })
    }

    @Test func antigravityUsageParserReadsHeadlessResultEnvelope() throws {
        let output = #"{"type":"result","response":"GEMINI MODELS\n  Models within this group: Gemini Flash, Gemini Pro\n  Weekly Limit Remaining\n  [████] 82.25%\n"}"#

        let groups = try AntigravityUsageParser.parse(output)

        #expect(groups.count == 1)
        #expect(groups.first?.name == "Gemini")
        #expect(groups.first?.remainingPercent == 82)
    }

    @Test func antigravityUsageParserReadsStructuredStreamJSONGroups() throws {
        let quotaGroups: [[String: Any]] = [
            [
                "name": "Gemini Models",
                "description": "Models within this group: Gemini Flash, Gemini Pro",
                "buckets": [[
                    "id": "gemini-weekly",
                    "name": "Weekly Limit Remaining",
                    "window": "weekly",
                    "remaining_fraction": 1.0,
                    "reset_time": "2026-11-02T03:56:52Z"
                ]]
            ],
            [
                "name": "Claude and GPT models",
                "description": "Models within this group: Claude Opus, Claude Sonnet, GPT-OSS",
                "buckets": [[
                    "id": "3p-weekly",
                    "name": "Weekly Limit Remaining",
                    "window": "weekly",
                    "remaining_fraction": 0.625,
                    "reset_time": "2026-11-02T03:56:52Z"
                ]]
            ]
        ]
        let commandData: [String: Any] = ["name": "usage", "data": ["groups": quotaGroups]]
        let commandResult: [String: Any] = ["event": "command_result", "command": commandData]
        let result: [String: Any] = [
            "event": "result",
            "result": [
                "status": "SUCCESS",
                "response": "Gemini Models\\tWeekly Limit Remaining\\t100%",
                "command": commandData
            ]
        ]
        let output = try [commandResult, result]
            .map { try JSONSerialization.data(withJSONObject: $0) }
            .map { String(decoding: $0, as: UTF8.self) }
            .joined(separator: "\n")

        let groups = try AntigravityUsageParser.parse(output)

        #expect(groups.map(\.name) == ["Gemini", "Claude & GPT"])
        #expect(groups.map(\.modelNames) == [
            ["Gemini Flash", "Gemini Pro"],
            ["Claude Opus", "Claude Sonnet", "GPT-OSS"]
        ])
        #expect(groups.map(\.remainingPercent) == [100, 63])
        #expect(groups.allSatisfy { $0.resetTime != nil })
    }

    @Test func antigravityUsageParserRejectsOutputWithoutQuotaGroups() {
        #expect(throws: AntigravityQuotaError.cliOutputInvalid) {
            try AntigravityUsageParser.parse("agy completed successfully")
        }
    }

    @MainActor
    @Test func antigravityProcessHelperCanInspectProcesses() async {
        let manager = AntigravityManager()

        await manager.refresh()

        #expect(manager.errorMessage?.hasPrefix("Could not contact the Antigravity process helper") != true)
        #expect(manager.errorMessage?.hasPrefix("Could not inspect running processes") != true)
    }

    @Test func menuBarGroupsAppearInProviderOrderAndUseTabSymbols() {
        let groups = MenuBarStatusFormatter.makeGroups(
            openRouterCredit: 15.3,
            chatGPTRemainingPercent: 83,
            openAIPlatformCredit: 8.64,
            antigravityRemainingPercent: 24
        )

        #expect(groups.map(\.provider) == [.openRouter, .openAI, .googleAI])
        #expect(groups.map(\.provider.accessibilityName) == ["OpenRouter", "OpenAI", "Antigravity"])
        #expect(groups.map(\.values) == [["$15"], ["83%", "$8.6"], ["24%"]])
        #expect(groups.map(\.provider.iconName) == [
            "point.3.connected.trianglepath.dotted",
            "sparkle",
            "sparkles"
        ])
        #expect(groups.map(\.provider.iconColorHex) == [0xC8FE03, 0x358AFF, 0x4285F4])

        let title = MenuBarStatusFormatter.attributedTitle(for: groups).string
        #expect(title.hasPrefix("{ "))
        #expect(title.hasSuffix(" }"))
        #expect(title.contains("  |  "))
        #expect(title.components(separatedBy: "|").count == 3)
    }

    @Test func menuBarOmitsGroupsWithoutAvailableDataAndKeepsOpenAIMetricsIndependent() {
        let onlyChatGPT = MenuBarStatusFormatter.makeGroups(
            openRouterCredit: nil,
            chatGPTRemainingPercent: 83,
            openAIPlatformCredit: nil
        )
        #expect(onlyChatGPT.map(\.provider) == [.openAI])
        #expect(onlyChatGPT.first?.values == ["83%"])
        #expect(!MenuBarStatusFormatter.attributedTitle(for: onlyChatGPT).string.contains("|"))

        let onlyPlatform = MenuBarStatusFormatter.makeGroups(
            openRouterCredit: nil,
            chatGPTRemainingPercent: nil,
            openAIPlatformCredit: 8.64
        )
        #expect(onlyPlatform.map(\.provider) == [.openAI])
        #expect(onlyPlatform.first?.values == ["$8.6"])

        let noData = MenuBarStatusFormatter.makeGroups(
            openRouterCredit: nil,
            chatGPTRemainingPercent: nil,
            openAIPlatformCredit: nil
        )
        #expect(noData.isEmpty)
        #expect(MenuBarStatusFormatter.attributedTitle(for: noData).string.isEmpty)
    }

}
