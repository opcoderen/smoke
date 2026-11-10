import Foundation
import Combine

@MainActor
final class Store: ObservableObject {
    static let shared = Store()

    @Published private(set) var records: [SmokeRecord] = []
    @Published private(set) var todayCount = 0
    @Published private(set) var weekCount = 0
    @Published private(set) var monthCount = 0
    @Published private(set) var lastError: String?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var busy = false

    private var timer: Timer?

    var headline: String { DateFmt.headline(Date()) }

    var todayRecords: [SmokeRecord] {
        records
            .filter { $0.local_date == DateFmt.todayString }
            .sorted { $0.date > $1.date }
    }

    func count(on day: String) -> Int {
        records.reduce(0) { $0 + ($1.local_date == day ? 1 : 0) }
    }

    func start() {
        Task { await refresh() }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
    }

    func refresh() async {
        dbg("refresh start")
        do {
            let rows = try await ApiClient.list(from: DateFmt.fetchFrom)
            dbg("refresh ok rows=\(rows.count)")
            records = rows
            lastError = nil
            lastUpdated = Date()
        } catch {
            dbg("refresh fail \(error.localizedDescription)")
            lastError = error.localizedDescription
        }
        recompute()
    }

    private func dbg(_ text: String) {
        Diagnostics.log(text)
        guard FileManager.default.fileExists(atPath: "/tmp/smoke-debug") else { return }
        let line = "\(Date()) \(text)\n"
        if let handle = FileHandle(forWritingAtPath: "/tmp/smoke-events.txt") {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            handle.closeFile()
        } else {
            try? line.write(toFile: "/tmp/smoke-events.txt", atomically: true, encoding: .utf8)
        }
    }

    func logOne() async -> SmokeRecord? {
        let now = Date()
        do {
            let rec = try await ApiClient.add(date: DateFmt.dayString(now), at: now)
            if !records.contains(where: { $0.id == rec.id }) {
                records.append(rec)
            }
            lastError = nil
            lastUpdated = Date()
            recompute()
            return rec
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    func remove(_ id: Int) async {
        do {
            try await ApiClient.remove(id: id)
            records.removeAll { $0.id == id }
            lastError = nil
            recompute()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func recompute() {
        let today = DateFmt.todayString
        let week = DateFmt.weekStartString
        let month = DateFmt.monthStartString
        todayCount = records.reduce(0) { $0 + ($1.local_date == today ? 1 : 0) }
        weekCount = records.reduce(0) { $0 + ($1.local_date >= week ? 1 : 0) }
        monthCount = records.reduce(0) { $0 + ($1.local_date >= month ? 1 : 0) }
    }
}
