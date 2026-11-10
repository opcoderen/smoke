import Foundation

struct DayBucket: Identifiable {
    let date: String   // yyyy-MM-dd
    let label: String  // 一 二 三 …
    let isToday: Bool
    var id: String { date }
}

enum DateFmt {
    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2   // 周一为一周开始
        c.timeZone = .current
        return c
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = calendar
        f.timeZone = .current
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = .current
        return f
    }()

    private static let headlineFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        f.timeZone = .current
        return f
    }()

    static func dayString(_ d: Date) -> String { dayFormatter.string(from: d) }
    static func timeString(_ d: Date) -> String { timeFormatter.string(from: d) }
    static func headline(_ d: Date) -> String { headlineFormatter.string(from: d) }

    static var todayString: String { dayString(Date()) }

    /// 本周一
    static var weekStartString: String {
        let cal = calendar
        let now = Date()
        let weekday = cal.component(.weekday, from: now) // 1 = 周日
        let back = (weekday + 5) % 7                     // 周一 = 0
        let start = cal.date(byAdding: .day, value: -back, to: cal.startOfDay(for: now)) ?? now
        return dayString(start)
    }

    /// 本月 1 号
    static var monthStartString: String {
        let cal = calendar
        let comps = cal.dateComponents([.year, .month], from: Date())
        return dayString(cal.date(from: comps) ?? Date())
    }

    static var fetchFrom: String { min(weekStartString, monthStartString) }

    static func last7Days() -> [DayBucket] {
        let cal = calendar
        let labels = ["日", "一", "二", "三", "四", "五", "六"]
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset in
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let w = cal.component(.weekday, from: d)
            return DayBucket(date: dayString(d), label: labels[(w - 1) % 7], isToday: offset == 0)
        }
    }
}

extension SmokeRecord {
    var date: Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        if let d = f.date(from: smoked_at) { return d }
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f2.date(from: smoked_at) ?? Date()
    }
}
