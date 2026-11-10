import AppKit
import SwiftUI
import Combine

extension Notification.Name {
    static let smokeOpenSettings = Notification.Name("smokeOpenSettings")
    static let smokeSettingsSaved = Notification.Name("smokeSettingsSaved")
}

@MainActor
final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let toast = ToastPanel()
    private var cancellables = Set<AnyCancellable>()
    private var settingsWindow: NSWindow?
    private var escMonitor: Any?
    /// 面板刚刚关闭的时刻。.transient 会在 mouseDown 时自动关闭面板，
    /// 而 mouseUp 才触发按钮 action，此时 isShown 已为 false → 会被误判为「重新打开」。
    private var lastPopoverClose: Date = .distantPast

    override init() {
        super.init()
        configureButton()

        popover.behavior = .transient
        popover.animates = false
        popover.delegate = self
        popover.contentSize = NSSize(width: 320, height: 462)
        popover.contentViewController = NSHostingController(
            rootView: PanelView().environmentObject(Store.shared)
        )

        // 面板打开时按 ESC 也能收起
        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            Task { @MainActor in
                if self?.popover.isShown == true {
                    self?.popover.performClose(nil)
                }
            }
            return event
        }

        Store.shared.$todayCount
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateTitle() }
            .store(in: &cancellables)
        Store.shared.$lastError
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateTitle() }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            forName: .smokeOpenSettings, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.openSettings() }
        }
        NotificationCenter.default.addObserver(
            forName: .smokeSettingsSaved, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateTitle()
                await Store.shared.refresh()
            }
        }

        Store.shared.start()
        updateTitle()
    }

    private func configureButton() {
        guard let button = statusItem.button else {
            Diagnostics.log("❌ statusItem.button 为 nil，无法显示菜单栏图标")
            return
        }
        let image = CigIcon.statusBarTemplate()
        if image.size.width < 1 || image.size.height < 1 {
            // 兜底：图标渲染失败时改用文字，至少能看到东西
            Diagnostics.log("⚠️ 图标渲染失败，降级为文字图标")
            button.image = nil
            button.title = "🚬"
        } else {
            image.isTemplate = true
            button.image = image
        }
        button.imagePosition = .imageLeading
        button.target = self
        button.action = #selector(handleClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        Diagnostics.logLaunch(statusButton: button, image: button.image)
    }

    @objc private func handleClick() {
        let event = NSApp.currentEvent
        let isRight = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true
        if isRight {
            togglePopover()
        } else {
            logOne()
        }
    }

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
            lastPopoverClose = Date()
            return
        }
        // 刚刚才关掉（多半是本次点击的 mouseDown 把面板关掉了），这次点击应视为「关闭」而不是「重新打开」
        if Date().timeIntervalSince(lastPopoverClose) < 0.25 {
            return
        }
        guard let button = statusItem.button else { return }
        // 按内容自适应高度，避免底部「退出」按钮下方留一片空白
        if let vc = popover.contentViewController {
            let fit = vc.view.fittingSize
            if fit.height > 200 {
                popover.contentSize = NSSize(width: 320, height: fit.height)
            }
        }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        Task { await Store.shared.refresh() }
    }

    private func logOne() {
        guard let button = statusItem.button else { return }
        flash(button)   // 先给即时反馈，不等网络
        Task { [weak self] in
            guard let self else { return }
            if let rec = await Store.shared.logOne() {
                self.toast.show(text: "已记 " + DateFmt.timeString(rec.date), onUndo: { [weak self] in
                    Task { await Store.shared.remove(rec.id) }
                    self?.toast.hide()
                }, near: button)
            } else {
                self.toast.show(text: Store.shared.lastError ?? "没记上", onUndo: nil, near: button)
            }
        }
    }

    private func flash(_ button: NSStatusBarButton) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.1
            button.animator().alphaValue = 0.45
        } completionHandler: {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.22
                button.animator().alphaValue = 1
            }
        }
    }

    private func updateTitle() {
        guard let button = statusItem.button else { return }
        let count = Store.shared.todayCount
        button.title = " \(count)"
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        button.imagePosition = .imageLeading
        if let err = Store.shared.lastError {
            button.appearsDisabled = true
            button.toolTip = "连不上服务器：\(err)\n右键打开面板 → 齿轮检查设置"
        } else {
            button.appearsDisabled = false
            button.toolTip = "今日 \(count) 根 · 左键记一根，右键看统计"
        }

        if ProcessInfo.processInfo.environment["SMOKE_LOG"] == "1" {
            let err = Store.shared.lastError ?? "nil"
            let line = "[SmokeLog] today=\(count) week=\(Store.shared.weekCount) month=\(Store.shared.monthCount) err=\(err)\n"
            FileHandle.standardError.write(Data(line.utf8))
        }
    }

    private func openSettings() {
        popover.performClose(nil)
        if let win = settingsWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let hosting = NSHostingController(rootView: SettingsView())
        let win = NSWindow(contentViewController: hosting)
        win.title = "SmokeLog · 设置"
        win.styleMask = [.titled, .closable]
        win.isReleasedWhenClosed = false
        win.center()
        settingsWindow = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension StatusBarController: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        lastPopoverClose = Date()
    }
}
