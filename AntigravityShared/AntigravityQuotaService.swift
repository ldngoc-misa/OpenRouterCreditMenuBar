import Foundation

enum AntigravityQuotaError: LocalizedError, Equatable {
    case processNotFound
    case portNotFound
    case serverNotFound
    case httpStatus(Int)
    case invalidResponse
    case processInspectionFailed(Int)
    case processCommandFailed(Int32)
    case networkFailure(Int)
    case requestFailed
    case cliLaunchFailed(Int)
    case cliTimedOut
    case cliCommandFailed(Int32)
    case cliOutputInvalid

    var errorDescription: String? {
        switch self {
        case .processNotFound:
            "Antigravity language server is not running."
        case .portNotFound:
            "Could not find the Antigravity language server port."
        case .serverNotFound:
            "Antigravity did not respond on 127.0.0.1."
        case .httpStatus(let status):
            "Antigravity returned HTTP \(status)."
        case .invalidResponse:
            "Antigravity returned an unreadable quota response."
        case .processInspectionFailed(let code):
            "Could not inspect running processes (error \(code))."
        case .processCommandFailed(let status):
            "Could not inspect running processes (ps/lsof exited \(status))."
        case .networkFailure(let code):
            "Local language server request failed (network error \(code))."
        case .requestFailed:
            "Could not read quota from the Antigravity language server."
        case .cliLaunchFailed(let code):
            "Could not start the agy quota command (error \(code))."
        case .cliTimedOut:
            "The agy quota command timed out."
        case .cliCommandFailed(let status):
            "The agy quota command exited with status \(status)."
        case .cliOutputInvalid:
            "The agy quota command returned an unreadable report."
        }
    }
}

struct AntigravityQuotaService: Sendable {
    private struct ServerProcess {
        let pid: Int32
        let csrfToken: String?
        let extensionServerPort: Int?
        let agyExecutable: String?
    }

    private struct ServerEndpoint {
        let port: Int
        let scheme: String
        let csrfToken: String?
    }

    private static let unleashPath = "/exa.language_server_pb.LanguageServerService/GetUnleashData"
    private static let userStatusPath = "/exa.language_server_pb.LanguageServerService/GetUserStatus"
    private static let unleashBody = Data("{\"wrapper_data\":{}}".utf8)
    private static let userStatusBody = Data(
        "{\"metadata\":{\"ideName\":\"antigravity\",\"extensionName\":\"antigravity\",\"locale\":\"en\"}}".utf8
    )

    func fetchQuota() async throws -> AntigravityQuotaSnapshot {
        let processes = try discoverProcesses()
        guard !processes.isEmpty else { throw AntigravityQuotaError.processNotFound }

        var foundListeningPort = false
        var languageServerSnapshot: AntigravityQuotaSnapshot?
        var languageServerError: Error?
        for process in processes {
            let ports = listeningPorts(for: process.pid)
            let fallbackPort = process.extensionServerPort.flatMap { (1...65_535).contains($0) ? $0 : nil }
            let candidatePorts = ports.isEmpty ? fallbackPort.map { [$0] } ?? [] : ports
            guard !candidatePorts.isEmpty else { continue }
            foundListeningPort = true

            for port in candidatePorts {
                guard let endpoint = await probe(port: port, csrfToken: process.csrfToken) else { continue }
                do {
                    languageServerSnapshot = try await requestUserStatus(from: endpoint)
                    break
                } catch {
                    languageServerError = error
                }
            }
            if languageServerSnapshot != nil { break }
        }

        var cliGroups: [AntigravityQuotaGroup] = []
        var cliError: Error?
        let cliExecutables = Array(Set(processes.compactMap(\.agyExecutable))).sorted()
        for executable in cliExecutables {
            do {
                let output = try run(
                    executable: executable,
                    arguments: ["-p", "/usage", "--output-format", "stream-json"],
                    timeout: 15
                )
                cliGroups = try AntigravityUsageParser.parse(output)
                break
            } catch {
                cliError = error
            }
        }

        guard languageServerSnapshot != nil || !cliGroups.isEmpty else {
            if let languageServerError { throw languageServerError }
            if !foundListeningPort { throw AntigravityQuotaError.portNotFound }
            if let cliError { throw cliError }
            throw AntigravityQuotaError.serverNotFound
        }

        let models = languageServerSnapshot?.models ?? []
        let groups = Self.addLanguageServerResetTimes(to: cliGroups, models: models)
        var warnings: [String] = []
        if groups.isEmpty {
            warnings.append("Shared weekly quota groups are unavailable; showing language-server details.")
        }
        if languageServerSnapshot == nil {
            warnings.append("Prompt credits and language-server model details are unavailable.")
        }

        return AntigravityQuotaSnapshot(
            availablePromptCredits: languageServerSnapshot?.availablePromptCredits,
            monthlyPromptCredits: languageServerSnapshot?.monthlyPromptCredits,
            models: models,
            groups: groups,
            warningMessage: warnings.isEmpty ? nil : warnings.joined(separator: " ")
        )
    }

    private func discoverProcesses() throws -> [ServerProcess] {
        let output = try run(executable: "/bin/ps", arguments: ["aux"])
        var results: [ServerProcess] = []

        for line in output.split(whereSeparator: \.isNewline) {
            let columns = line.split(maxSplits: 10, omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
            guard columns.count > 10,
                  let pid = Int32(columns[1]) else { continue }
            let commandLine = String(columns[10])
            guard Self.isAntigravityServer(commandLine: commandLine) else { continue }

            let arguments = commandLine.split(whereSeparator: \.isWhitespace).map(String.init)
            let executable = arguments.first
            let agyExecutable = executable.flatMap {
                URL(fileURLWithPath: $0).lastPathComponent.lowercased() == "agy" ? $0 : nil
            }
            results.append(ServerProcess(
                pid: pid,
                csrfToken: Self.argumentValue(named: "--csrf_token", in: arguments),
                extensionServerPort: Self.argumentValue(named: "--extension_server_port", in: arguments).flatMap(Int.init),
                agyExecutable: agyExecutable
            ))
        }

        return results
    }

    static func isAntigravityServer(commandLine: String) -> Bool {
        let arguments = commandLine.split(whereSeparator: \.isWhitespace).map(String.init)
        guard let executable = arguments.first else { return false }

        let normalized = commandLine.lowercased()
        let isLanguageServer = normalized.contains("language_server") || normalized.contains("language server")
        if normalized.contains("antigravity"), isLanguageServer {
            return true
        }

        return URL(fileURLWithPath: executable).lastPathComponent.lowercased() == "agy"
            && arguments.contains("--hub")
            && Self.argumentValue(named: "--app_data_dir", in: arguments)?.lowercased() == "antigravity"
    }

    private static func addLanguageServerResetTimes(
        to groups: [AntigravityQuotaGroup],
        models: [AntigravityModelQuota]
    ) -> [AntigravityQuotaGroup] {
        groups.map { group in
            guard group.resetTime == nil,
                  !group.modelNames.isEmpty else { return group }

            let memberModels = group.modelNames.compactMap { member in
                models.first { $0.matches(member) }
            }
            guard memberModels.count == group.modelNames.count,
                  let resetTime = memberModels.first?.resetTime,
                  memberModels.allSatisfy({ $0.resetTime == resetTime }) else { return group }

            return AntigravityQuotaGroup(
                id: group.id,
                name: group.name,
                modelNames: group.modelNames,
                remainingFraction: group.remainingFraction,
                resetTime: resetTime
            )
        }
    }

    private func listeningPorts(for pid: Int32) -> [Int] {
        guard let output = try? run(
            executable: "/usr/sbin/lsof",
            arguments: ["-nP", "-iTCP", "-sTCP:LISTEN", "-a", "-p", String(pid)]
        ) else { return [] }

        let pattern = #":(\d+)\s+\(LISTEN\)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        var ports: [Int] = []

        for line in output.split(whereSeparator: \.isNewline) {
            let value = String(line)
            let range = NSRange(value.startIndex..., in: value)
            guard let match = regex.firstMatch(in: value, range: range),
                  let portRange = Range(match.range(at: 1), in: value),
                  let port = Int(value[portRange]), (1...65_535).contains(port),
                  !ports.contains(port) else { continue }
            ports.append(port)
        }

        return ports
    }

    private static func argumentValue(named name: String, in arguments: [String]) -> String? {
        for (index, argument) in arguments.enumerated() {
            if argument == name, arguments.indices.contains(index + 1) {
                return arguments[index + 1]
            }
            if argument.hasPrefix(name + "=") {
                return String(argument.dropFirst(name.count + 1))
            }
        }
        return nil
    }

    private func run(
        executable: String,
        arguments: [String],
        timeout: TimeInterval? = nil
    ) throws -> String {
        let process = Process()
        let output = Pipe()
        let outputQueue = DispatchQueue(label: "AntigravityQuotaService.processOutput")
        var outputData = Data()
        let maximumOutputBytes = 512 * 1024
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        output.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else {
                handle.readabilityHandler = nil
                return
            }
            outputQueue.sync {
                let remainingCapacity = maximumOutputBytes - outputData.count
                if remainingCapacity > 0 {
                    outputData.append(chunk.prefix(remainingCapacity))
                }
            }
        }
        do {
            try process.run()
        } catch {
            output.fileHandleForReading.readabilityHandler = nil
            if timeout != nil {
                throw AntigravityQuotaError.cliLaunchFailed((error as NSError).code)
            }
            throw AntigravityQuotaError.processInspectionFailed((error as NSError).code)
        }

        var didTimeOut = false
        if let timeout {
            let deadline = Date().addingTimeInterval(timeout)
            while process.isRunning, Date() < deadline {
                Thread.sleep(forTimeInterval: 0.025)
            }
            if process.isRunning {
                didTimeOut = true
                process.terminate()
            }
        }
        process.waitUntilExit()
        output.fileHandleForReading.readabilityHandler = nil
        let remainingOutput = output.fileHandleForReading.readDataToEndOfFile()
        let data = outputQueue.sync {
            let remainingCapacity = maximumOutputBytes - outputData.count
            if remainingCapacity > 0 {
                outputData.append(remainingOutput.prefix(remainingCapacity))
            }
            return outputData
        }
        if didTimeOut { throw AntigravityQuotaError.cliTimedOut }
        guard process.terminationStatus == 0 else {
            if timeout != nil { throw AntigravityQuotaError.cliCommandFailed(process.terminationStatus) }
            throw AntigravityQuotaError.processCommandFailed(process.terminationStatus)
        }
        guard let result = String(data: data, encoding: .utf8) else { throw AntigravityQuotaError.requestFailed }
        return result
    }

    private func probe(port: Int, csrfToken: String?) async -> ServerEndpoint? {
        for scheme in ["https", "http"] {
            guard let response = try? await post(
                path: Self.unleashPath,
                port: port,
                scheme: scheme,
                body: Self.unleashBody,
                csrfToken: csrfToken,
                timeout: 2
            ), [200, 401].contains(response.statusCode) else { continue }
            return ServerEndpoint(port: port, scheme: scheme, csrfToken: csrfToken)
        }
        return nil
    }

    private func requestUserStatus(from endpoint: ServerEndpoint) async throws -> AntigravityQuotaSnapshot {
        let response = try await post(
            path: Self.userStatusPath,
            port: endpoint.port,
            scheme: endpoint.scheme,
            body: Self.userStatusBody,
            csrfToken: endpoint.csrfToken,
            timeout: 5
        )
        guard (200..<300).contains(response.statusCode) else {
            throw AntigravityQuotaError.httpStatus(response.statusCode)
        }
        return try AntigravityQuotaParser.parse(response.data)
    }

    private func post(
        path: String,
        port: Int,
        scheme: String,
        body: Data,
        csrfToken: String?,
        timeout: TimeInterval
    ) async throws -> (data: Data, statusCode: Int) {
        guard let url = URL(string: "\(scheme)://127.0.0.1:\(port)\(path)") else {
            throw AntigravityQuotaError.requestFailed
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let csrfToken, !csrfToken.isEmpty {
            request.setValue(csrfToken, forHTTPHeaderField: "X-Codeium-Csrf-Token")
        }

        let session = URLSession(
            configuration: .ephemeral,
            delegate: LocalhostTrustDelegate(),
            delegateQueue: nil
        )
        defer { session.invalidateAndCancel() }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AntigravityQuotaError.networkFailure((error as NSError).code)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AntigravityQuotaError.requestFailed
        }
        return (data, httpResponse.statusCode)
    }
}

enum AntigravityQuotaParser {
    static func parse(_ data: Data) throws -> AntigravityQuotaSnapshot {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AntigravityQuotaError.invalidResponse
        }
        let status = root["userStatus"] as? [String: Any] ?? root
        let planStatus = status["planStatus"] as? [String: Any]
        let planInfo = planStatus?["planInfo"] as? [String: Any]
        let modelData = status["cascadeModelConfigData"] as? [String: Any]
        let modelConfigs = modelData?["clientModelConfigs"] as? [[String: Any]] ?? []

        let models = modelConfigs.compactMap { config -> AntigravityModelQuota? in
            guard let modelOrAlias = config["modelOrAlias"] as? [String: Any],
                  let model = modelOrAlias["model"] as? String, !model.isEmpty,
                  let quotaInfo = config["quotaInfo"] as? [String: Any],
                  let remaining = number(quotaInfo["remainingFraction"]), remaining.isFinite else { return nil }
            let aliases = [
                config["label"] as? String,
                modelOrAlias["alias"] as? String,
                modelOrAlias["displayName"] as? String,
                modelOrAlias["name"] as? String,
                modelOrAlias["title"] as? String
            ]
                .compactMap { $0 }
                .filter { !$0.isEmpty && $0.localizedCaseInsensitiveCompare(model) != .orderedSame }
            return AntigravityModelQuota(
                id: model,
                aliases: aliases,
                remainingFraction: min(max(remaining, 0), 1),
                resetTime: date(quotaInfo["resetTime"])
            )
        }
        .sorted {
            if $0.remainingFraction == $1.remainingFraction { return $0.id < $1.id }
            return $0.remainingFraction < $1.remainingFraction
        }

        guard planStatus != nil || !models.isEmpty else { throw AntigravityQuotaError.invalidResponse }
        return AntigravityQuotaSnapshot(
            availablePromptCredits: number(planStatus?["availablePromptCredits"]),
            monthlyPromptCredits: number(planInfo?["monthlyPromptCredits"]),
            models: models
        )
    }

    private static func number(_ value: Any?) -> Double? {
        if let number = value as? NSNumber {
            let doubleValue = number.doubleValue
            return doubleValue.isFinite ? doubleValue : nil
        }
        if let string = value as? String, let doubleValue = Double(string), doubleValue.isFinite {
            return doubleValue
        }
        return nil
    }

    private static func date(_ value: Any?) -> Date? {
        if let timestamp = number(value) {
            let seconds = timestamp > 100_000_000_000 ? timestamp / 1_000 : timestamp
            return Date(timeIntervalSince1970: seconds)
        }
        guard let string = value as? String else { return nil }
        if let timestamp = Double(string) {
            let seconds = timestamp > 100_000_000_000 ? timestamp / 1_000 : timestamp
            return Date(timeIntervalSince1970: seconds)
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}

enum AntigravityUsageParser {
    private struct GroupDraft {
        var name: String
        var modelNames: [String] = []
        var remainingFraction: Double?
        var resetTime: Date?
        var waitingForWeeklyPercentage = false

        func build() -> AntigravityQuotaGroup? {
            guard let remainingFraction else { return nil }
            return AntigravityQuotaGroup(
                id: name,
                name: name,
                modelNames: modelNames,
                remainingFraction: min(max(remainingFraction, 0), 1),
                resetTime: resetTime
            )
        }
    }

    static func parse(_ output: String) throws -> [AntigravityQuotaGroup] {
        let structuredGroups = groupsFromStreamJSON(output)
        if !structuredGroups.isEmpty { return structuredGroups }

        let report = reportText(from: output)
        let cleanedReport = stripANSI(report)
        var groups: [AntigravityQuotaGroup] = []
        var current: GroupDraft?

        func saveCurrent() {
            if let group = current?.build() { groups.append(group) }
        }

        for rawLine in cleanedReport.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            if let tabularGroup = groupFromTabSeparatedLine(line) {
                saveCurrent()
                current = nil
                groups.append(tabularGroup)
                continue
            }

            if let heading = groupHeading(from: line) {
                saveCurrent()
                current = GroupDraft(name: heading)
                continue
            }

            guard var draft = current else { continue }
            let lowercased = line.lowercased()
            if lowercased.contains("models within this group") {
                if let colon = line.firstIndex(of: ":") {
                    draft.modelNames = line[line.index(after: colon)...]
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                }
            }

            if lowercased.contains("weekly limit remaining") {
                draft.waitingForWeeklyPercentage = true
            }
            if draft.waitingForWeeklyPercentage,
               let percentage = percentage(in: line) {
                draft.remainingFraction = percentage / 100
                draft.waitingForWeeklyPercentage = false
            }
            if draft.resetTime == nil {
                draft.resetTime = explicitDate(in: line)
            }
            current = draft
        }
        saveCurrent()

        guard !groups.isEmpty else { throw AntigravityQuotaError.cliOutputInvalid }
        return groups
    }

    private static func groupsFromStreamJSON(_ output: String) -> [AntigravityQuotaGroup] {
        var groups: [AntigravityQuotaGroup] = []
        var seenGroupNames = Set<String>()

        for line in output.components(separatedBy: .newlines) {
            guard let data = line.data(using: .utf8),
                  let event = try? JSONSerialization.jsonObject(with: data) else { continue }
            collectStructuredGroups(in: event, groups: &groups, seenGroupNames: &seenGroupNames)
        }

        return groups
    }

    private static func collectStructuredGroups(
        in value: Any,
        groups: inout [AntigravityQuotaGroup],
        seenGroupNames: inout Set<String>
    ) {
        if let dictionary = value as? [String: Any] {
            if let rawGroups = dictionary["groups"] as? [[String: Any]] {
                for rawGroup in rawGroups {
                    guard let group = structuredGroup(from: rawGroup),
                          seenGroupNames.insert(group.name.lowercased()).inserted else { continue }
                    groups.append(group)
                }
            }
            for nestedValue in dictionary.values {
                collectStructuredGroups(in: nestedValue, groups: &groups, seenGroupNames: &seenGroupNames)
            }
        } else if let array = value as? [Any] {
            for nestedValue in array {
                collectStructuredGroups(in: nestedValue, groups: &groups, seenGroupNames: &seenGroupNames)
            }
        }
    }

    private static func structuredGroup(from value: [String: Any]) -> AntigravityQuotaGroup? {
        guard let rawName = value["name"] as? String, !rawName.isEmpty,
              let buckets = value["buckets"] as? [[String: Any]],
              let bucket = buckets.first(where: {
                  ($0["window"] as? String)?.localizedCaseInsensitiveCompare("weekly") == .orderedSame
                      || ($0["name"] as? String)?.localizedCaseInsensitiveContains("weekly") == true
              }),
              let remaining = number(bucket["remaining_fraction"] ?? bucket["remainingFraction"]),
              remaining.isFinite else { return nil }

        let name = normalizedGroupName(rawName)
        let description = value["description"] as? String ?? ""
        let modelNames = modelNames(from: description)
        return AntigravityQuotaGroup(
            id: name,
            name: name,
            modelNames: modelNames,
            remainingFraction: min(max(remaining, 0), 1),
            resetTime: quotaDate(bucket["reset_time"] ?? bucket["resetTime"])
        )
    }

    private static func groupFromTabSeparatedLine(_ line: String) -> AntigravityQuotaGroup? {
        let columns = line.split(separator: "\t", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard columns.count >= 3,
              columns[1].localizedCaseInsensitiveContains("weekly limit remaining"),
              let percentage = percentage(in: columns[2]) else { return nil }
        return AntigravityQuotaGroup(
            id: normalizedGroupName(columns[0]),
            name: normalizedGroupName(columns[0]),
            modelNames: [],
            remainingFraction: min(max(percentage / 100, 0), 1),
            resetTime: columns.count > 3 ? quotaDate(columns[3]) : nil
        )
    }

    private static func number(_ value: Any?) -> Double? {
        if let number = value as? NSNumber { return number.doubleValue }
        if let string = value as? String { return Double(string) }
        return nil
    }

    private static func quotaDate(_ value: Any?) -> Date? {
        if let timestamp = number(value), timestamp.isFinite {
            let seconds = timestamp > 100_000_000_000 ? timestamp / 1_000 : timestamp
            return Date(timeIntervalSince1970: seconds)
        }
        guard let string = value as? String else { return nil }
        if let timestamp = Double(string) {
            let seconds = timestamp > 100_000_000_000 ? timestamp / 1_000 : timestamp
            return Date(timeIntervalSince1970: seconds)
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    private static func modelNames(from description: String) -> [String] {
        guard let colon = description.firstIndex(of: ":"),
              description[..<colon].localizedCaseInsensitiveContains("models within this group") else { return [] }
        return description[description.index(after: colon)...]
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func normalizedGroupName(_ rawName: String) -> String {
        var value = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let suffix = value.range(of: #"\s+models$"#, options: [.regularExpression, .caseInsensitive]) {
            value.removeSubrange(suffix)
        }
        value = value.replacingOccurrences(of: #"\band\b"#, with: "&", options: [.regularExpression, .caseInsensitive])
        return value.split(whereSeparator: \.isWhitespace).map { token in
            let uppercased = token.uppercased()
            if ["GPT", "OSS", "GPT-OSS", "AI"].contains(uppercased) { return uppercased }
            return token.prefix(1).uppercased() + token.dropFirst().lowercased()
        }
        .joined(separator: " ")
    }

    private static func reportText(from output: String) -> String {
        let lines = output.components(separatedBy: .newlines)
        var resultResponses: [String] = []
        var textDeltas: [String] = []
        var genericText: [String] = []

        for line in lines where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard let data = line.data(using: .utf8),
                  let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                genericText.append(line)
                continue
            }

            let type = (event["type"] as? String)?.lowercased()
            collectText(
                in: event,
                isResultEvent: type == "result",
                resultResponses: &resultResponses,
                textDeltas: &textDeltas
            )
        }

        if !resultResponses.isEmpty { return resultResponses.joined(separator: "\n") }
        if !textDeltas.isEmpty { return textDeltas.joined() }
        return genericText.joined(separator: "\n")
    }

    private static func collectText(
        in value: Any,
        isResultEvent: Bool,
        resultResponses: inout [String],
        textDeltas: inout [String]
    ) {
        if let dictionary = value as? [String: Any] {
            if let response = dictionary["response"] as? String {
                resultResponses.append(response)
            }
            if let result = dictionary["result"] as? String {
                if isResultEvent {
                    resultResponses.append(result)
                } else {
                    textDeltas.append(result)
                }
            }
            if let delta = dictionary["text_delta"] as? String { textDeltas.append(delta) }
            if let text = dictionary["text"] as? String { textDeltas.append(text) }
            for nestedValue in dictionary.values {
                collectText(
                    in: nestedValue,
                    isResultEvent: isResultEvent,
                    resultResponses: &resultResponses,
                    textDeltas: &textDeltas
                )
            }
        } else if let array = value as? [Any] {
            for nestedValue in array {
                collectText(
                    in: nestedValue,
                    isResultEvent: isResultEvent,
                    resultResponses: &resultResponses,
                    textDeltas: &textDeltas
                )
            }
        }
    }

    private static func groupHeading(from line: String) -> String? {
        let candidate = line
            .trimmingCharacters(in: CharacterSet(charactersIn: "│| ─━\t"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard candidate.range(of: #"^[A-Z][A-Z0-9 &+/-]* MODELS$"#, options: .regularExpression) != nil else {
            return nil
        }
        return normalizedGroupName(String(candidate.dropLast(" MODELS".count)))
    }

    private static func percentage(in line: String) -> Double? {
        guard let range = line.range(of: #"(\d+(?:\.\d+)?)\s*%"#, options: .regularExpression),
              let numberRange = line[range].range(of: #"\d+(?:\.\d+)?"#, options: .regularExpression) else {
            return nil
        }
        return Double(line[range][numberRange])
    }

    private static func explicitDate(in line: String) -> Date? {
        guard let range = line.range(of: #"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})"#,
                                     options: .regularExpression) else { return nil }
        let value = String(line[range])
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    private static func stripANSI(_ value: String) -> String {
        value.replacingOccurrences(of: #"\u{001B}\[[0-?]*[ -/]*[@-~]"#, with: "", options: .regularExpression)
    }
}

private final class LocalhostTrustDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              challenge.protectionSpace.host == "127.0.0.1",
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
