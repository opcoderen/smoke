import AppKit
import SwiftUI

struct PanelView: View {
    @EnvironmentObject private var store: Store
    private let accent = Color(red: 0.847, green: 0.353, blue: 0.188)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            stats
            chart
            Divider()
            todaySection
            Spacer(minLength: 0)
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 320, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {        HStack(spacing: 8) {
            Text(store.headline)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                NotificationCenter.default.post(name: .smokeOpenSettings, object: nil)
            } label: {
                Image(systemName: "gearshape").font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("设置")

            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise").font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("刷新")
        }
    }

    private var stats: some View {
        HStack(spacing: 8) {
            statCard(store.todayCount, "今日")
            statCard(store.weekCount, "本周")
            statCard(store.monthCount, "本月")
        }
    }

    private func statCard(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.gray.opacity(0.12))
        )
    }

    private var chart: some View {
        let days = DateFmt.last7Days()
        let maxValue = max(1, days.map { store.count(on: $0.date) }.max() ?? 1)
        return VStack(alignment: .leading, spacing: 6) {
            Text("最近 7 天")
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(days) { day in
                    let value = store.count(on: day.date)
                    VStack(spacing: 4) {
                        Text("\(value)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                            .opacity(value == 0 ? 0.25 : 1)
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(day.isToday ? accent : Color.gray.opacity(0.32))
                            .frame(height: max(4, CGFloat(value) / CGFloat(maxValue) * 32))
                        Text(day.label)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 66, alignment: .bottom)
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("今天的记录")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                Spacer()
                if let err = store.lastError {
                    Text(err)
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }

            if store.todayRecords.isEmpty {
                Text("还没记，点一下菜单栏图标就记一根")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 12)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(store.todayRecords) { rec in
                            HStack {
                                Text(DateFmt.timeString(rec.date))
                                    .font(.system(size: 12.5, design: .monospaced))
                                Spacer()
                                Button {
                                    Task { await store.remove(rec.id) }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9.5, weight: .semibold))
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .help("删掉这条")
                            }
                            .padding(.vertical, 5)
                            if rec.id != store.todayRecords.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Text("记录在云端，退出不会丢")
                .font(.system(size: 9.5))
                .foregroundStyle(.tertiary)
            Spacer()
            Button {
                NSApp.terminate(nil)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                        .font(.system(size: 9.5, weight: .semibold))
                    Text("退出")
                        .font(.system(size: 10.5))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("退出 抽烟记录（⌘Q 也可以）")
        }
    }
}
