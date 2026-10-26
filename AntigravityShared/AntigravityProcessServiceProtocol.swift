import Foundation

@objc(AntigravityProcessServiceProtocol)
protocol AntigravityProcessServiceProtocol {
    func fetchQuota(withReply reply: @escaping (Data?, String?) -> Void)
}
