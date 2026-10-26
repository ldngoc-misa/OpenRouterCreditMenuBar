//
//  AntigravityManager.swift
//  OpenRouterCreditMenuBar
//

import Combine
import Foundation

@MainActor
final class AntigravityManager: ObservableObject {
    @Published private(set) var snapshot: AntigravityQuotaSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?

    private var refreshTimer: Timer?
    private var refreshInterval: TimeInterval {
        let interval = UserDefaults.standard.double(forKey: "refresh_interval")
        return interval > 0 ? interval : 300
    }

    func startMonitoring() {
        setupRefreshTimer()
        Task { await refresh() }
    }

    func setRefreshInterval(_ interval: TimeInterval) {
        UserDefaults.standard.set(interval, forKey: "refresh_interval")
        setupRefreshTimer()
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            snapshot = try await AntigravityQuotaXPCClient.fetchQuota()
            lastUpdated = Date()
        } catch let error as AntigravityQuotaClientError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = AntigravityQuotaClientError.connectionFailed((error as NSError).code).localizedDescription
        }

        isLoading = false
    }

    private func setupRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }
}

private enum AntigravityQuotaClientError: LocalizedError {
    case connectionFailed(Int)
    case service(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let code):
            "Could not contact the Antigravity process helper (error \(code))."
        case .service(let message):
            message
        case .invalidResponse:
            "The Antigravity process helper returned invalid quota data."
        }
    }
}

private enum AntigravityQuotaXPCClient {
    private static let serviceName = "com.kttizz.OpenRouterCreditMenuBar.AntigravityProcessService"

    static func fetchQuota() async throws -> AntigravityQuotaSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            let connection = NSXPCConnection(serviceName: serviceName)
            let completionGate = XPCCompletionGate()
            connection.remoteObjectInterface = NSXPCInterface(with: AntigravityProcessServiceProtocol.self)
            connection.resume()

            let proxy = connection.remoteObjectProxyWithErrorHandler { error in
                guard completionGate.claim() else { return }
                connection.invalidate()
                continuation.resume(throwing: AntigravityQuotaClientError.connectionFailed((error as NSError).code))
            } as? AntigravityProcessServiceProtocol

            guard let proxy else {
                guard completionGate.claim() else { return }
                connection.invalidate()
                continuation.resume(throwing: AntigravityQuotaClientError.invalidResponse)
                return
            }

            proxy.fetchQuota { data, message in
                guard completionGate.claim() else { return }
                connection.invalidate()
                if let message {
                    continuation.resume(throwing: AntigravityQuotaClientError.service(message))
                    return
                }
                guard let data, let snapshot = try? JSONDecoder().decode(AntigravityQuotaSnapshot.self, from: data) else {
                    continuation.resume(throwing: AntigravityQuotaClientError.invalidResponse)
                    return
                }
                continuation.resume(returning: snapshot)
            }
        }
    }
}

private final class XPCCompletionGate: @unchecked Sendable {
    private let lock = NSLock()
    private var completed = false

    func claim() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !completed else { return false }
        completed = true
        return true
    }
}
