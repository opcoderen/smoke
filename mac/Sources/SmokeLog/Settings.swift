import Foundation

enum Settings {
    static let endpointKey = "endpoint"
    static let passwordKey = "password"
    // 默认为空：首次打开不预填任何地址，用户在设置里填自己的 Worker 域名
    static let defaultEndpoint = ""

    // 内存覆盖（仅自测/调试用，不落盘）
    static var overrideEndpoint: String?
    static var overridePassword: String?

    static var endpoint: String {
        get { normalize(overrideEndpoint ?? UserDefaults.standard.string(forKey: endpointKey) ?? defaultEndpoint) }
        set { UserDefaults.standard.set(normalize(newValue), forKey: endpointKey) }
    }

    /// 密码存在 App 自己的偏好设置里（~/Library/Preferences/com.example.smokelog.plist），不使用钥匙串
    static var password: String {
        get { overridePassword ?? UserDefaults.standard.string(forKey: passwordKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: passwordKey) }
    }

    /// 允许用户粘贴 "your-domain.example.com"、"https://x.com/" 甚至带 /api 的地址，统一整理
    static func normalize(_ raw: String) -> String {
        var t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return defaultEndpoint }
        if !t.lowercased().hasPrefix("http") { t = "https://" + t }
        while t.hasSuffix("/") { t.removeLast() }
        if let r = t.range(of: "/api", options: .backwards) { t = String(t[..<r.lowerBound]) }
        if let r = t.range(of: "?", options: .backwards) { t = String(t[..<r.lowerBound]) }
        return t
    }
}
