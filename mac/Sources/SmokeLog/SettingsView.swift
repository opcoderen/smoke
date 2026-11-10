import SwiftUI

struct SettingsView: View {
    @State private var endpoint = Settings.endpoint
    @State private var password = Settings.password
    @State private var status: String?
    @State private var statusOK = false
    @State private var testing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("服务器地址")
                .font(.system(size: 12, weight: .semibold))
            TextField("https://your-domain.example.com", text: $endpoint)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))
            Text("换域名/换服务器只改这里，保存即生效，不用重新编译 App。可以只填域名，不用带 https://")
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("密码")
                .font(.system(size: 12, weight: .semibold))
                .padding(.top, 4)
            SecureField("APP_KEY", text: $password)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
            Text("保存在本机 App 自己的配置里，不上传、不使用钥匙串。")
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Text("开源地址")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                Link("github.com/opcoderen/smoke",
                     destination: URL(string: "https://github.com/opcoderen/smoke")!)
                    .font(.system(size: 10.5))
            }
            .padding(.top, 2)

            Spacer(minLength: 4)

            HStack(spacing: 10) {
                Button(testing ? "测试中…" : "测试连接") { test() }
                    .disabled(testing)
                Spacer()
                Button("保存") { save() }
                    .keyboardShortcut(.defaultAction)
            }

            if let status {
                Text(status)
                    .font(.system(size: 11))
                    .foregroundStyle(statusOK ? Color.green : Color.red)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(width: 400, height: 316, alignment: .topLeading)
    }

    private func test() {
        Settings.endpoint = endpoint
        Settings.password = password
        endpoint = Settings.endpoint
        testing = true
        status = nil
        Task { @MainActor in
            do {
                let rows = try await ApiClient.list(from: DateFmt.monthStartString)
                statusOK = true
                status = "✅ 连接正常，本月已有 \(rows.count) 条记录"
            } catch {
                statusOK = false
                status = "❌ " + error.localizedDescription
            }
            testing = false
        }
    }

    private func save() {
        Settings.endpoint = endpoint
        Settings.password = password
        endpoint = Settings.endpoint
        statusOK = true
        status = "✅ 已保存"
        NotificationCenter.default.post(name: .smokeSettingsSaved, object: nil)
    }
}
