import Foundation

struct SmokeRecord: Codable, Identifiable, Equatable {
    let id: Int
    let local_date: String
    let smoked_at: String
}

enum ApiError: LocalizedError {
    case notConfigured
    case unauthorized
    case http(Int, String)
    case transport(String)
    case badData

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "还没设置服务器地址"
        case .unauthorized:
            return "密码不对，去设置里改一下"
        case .http(let code, let msg):
            return msg.isEmpty ? "服务器返回 \(code)" : "服务器返回 \(code)：\(msg)"
        case .transport(let msg):
            return "网络不通（\(msg)）"
        case .badData:
            return "返回数据看不懂"
        }
    }
}

enum ApiClient {
    private static func request(_ path: String,
                                method: String = "GET",
                                body: [String: Any]? = nil) async throws -> Data {
        let base = Settings.endpoint
        guard !base.isEmpty, base.lowercased().hasPrefix("http"),
              let url = URL(string: base + path) else { throw ApiError.notConfigured }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = 15
        req.cachePolicy = .reloadIgnoringLocalCacheData
        if !Settings.password.isEmpty {
            req.setValue(Settings.password, forHTTPHeaderField: "x-app-key")
        }
        if let body = body {
            req.setValue("application/json", forHTTPHeaderField: "content-type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw ApiError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { throw ApiError.transport("没有响应") }
        if http.statusCode == 401 { throw ApiError.unauthorized }
        guard (200..<300).contains(http.statusCode) else {
            var msg = ""
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let e = obj["error"] as? String { msg = e }
            throw ApiError.http(http.statusCode, msg)
        }
        return data
    }

    static func list(from: String) async throws -> [SmokeRecord] {
        let data = try await request("/api/logs?from=\(from)")
        do {
            return try JSONDecoder().decode([SmokeRecord].self, from: data)
        } catch {
            throw ApiError.badData
        }
    }

    static func add(date: String, at time: Date) async throws -> SmokeRecord {
        let iso = ISO8601DateFormatter().string(from: time)
        let data = try await request("/api/logs", method: "POST",
                                     body: ["local_date": date, "smoked_at": iso])
        do {
            return try JSONDecoder().decode(SmokeRecord.self, from: data)
        } catch {
            throw ApiError.badData
        }
    }

    static func remove(id: Int) async throws {
        _ = try await request("/api/logs/\(id)", method: "DELETE")
    }
}
