import Foundation

private final class AntigravityProcessServiceDelegate: NSObject, NSXPCListenerDelegate, AntigravityProcessServiceProtocol {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.exportedInterface = NSXPCInterface(with: AntigravityProcessServiceProtocol.self)
        connection.exportedObject = self
        connection.resume()
        return true
    }

    func fetchQuota(withReply reply: @escaping (Data?, String?) -> Void) {
        Task {
            do {
                let snapshot = try await AntigravityQuotaService().fetchQuota()
                reply(try JSONEncoder().encode(snapshot), nil)
            } catch {
                reply(nil, error.localizedDescription)
            }
        }
    }
}

@main
private struct AntigravityProcessServiceMain {
    static func main() {
        let listener = NSXPCListener.service()
        let delegate = AntigravityProcessServiceDelegate()
        listener.delegate = delegate
        listener.resume()
        dispatchMain()
    }
}
