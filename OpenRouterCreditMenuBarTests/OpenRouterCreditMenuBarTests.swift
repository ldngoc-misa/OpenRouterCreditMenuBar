//
//  OpenRouterCreditMenuBarTests.swift
//  OpenRouterCreditMenuBarTests
//
//  Created by Kittithat Patepakorn on 24/5/2568 BE.
//

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

    @Test func menuBarGroupsAppearInProviderOrderAndUseTabSymbols() {
        let groups = MenuBarStatusFormatter.makeGroups(
            openRouterCredit: 15.3,
            chatGPTRemainingPercent: 83,
            openAIPlatformCredit: 8.64,
            antigravityCredit: 2.4
        )

        #expect(groups.map(\.provider) == [.openRouter, .openAI, .antigravity])
        #expect(groups.map(\.values) == [["$15"], ["83%", "$8.6"], ["$2.4"]])
        #expect(groups.map(\.provider.iconName) == [
            "point.3.connected.trianglepath.dotted",
            "sparkle",
            "arrow.up.right.and.arrow.down.left"
        ])
        #expect(groups.map(\.provider.iconColorHex) == [0xC8FE03, 0x358AFF, 0x9065B6])

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
