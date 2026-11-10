import Foundation

/// 命令行自测：不启动界面，直接打一遍 读 / 写 / 删
/// 用法：SMOKE_ENDPOINT=https://x.com SMOKE_KEY=xxx SmokeLog.app/Contents/MacOS/SmokeLog --selftest
enum SelfTest {
    static func run() {
        let env = ProcessInfo.processInfo.environment
        if let e = env["SMOKE_ENDPOINT"], !e.isEmpty { Settings.overrideEndpoint = e }
        if let k = env["SMOKE_KEY"], !k.isEmpty { Settings.overridePassword = k }

        print("endpoint : \(Settings.endpoint)")
        print("password : \(Settings.password.isEmpty ? "(空)" : "已设置(\(Settings.password.count) 字符)")")

        let sem = DispatchSemaphore(value: 0)
        Task {
            do {
                let rows = try await ApiClient.list(from: "1970-01-01")
                print("GET      : ok, \(rows.count) rows")
                let rec = try await ApiClient.add(date: DateFmt.todayString, at: Date())
                print("POST     : ok, id=\(rec.id) at \(rec.smoked_at)")
                try await ApiClient.remove(id: rec.id)
                print("DELETE   : ok")
                print("RESULT   : PASS")
            } catch {
                print("RESULT   : FAIL - \(error.localizedDescription)")
            }
            sem.signal()
        }
        sem.wait()
    }
}
