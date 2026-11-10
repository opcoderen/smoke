import AppKit
import SwiftUI

struct ToastView: View {
    let text: String
    let onUndo: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Text(text)
                .font(.system(size: 12.5))
                .foregroundStyle(.white)
            if let onUndo {
                Button("撤销") { onUndo() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Color(red: 0.95, green: 0.45, blue: 0.28))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: NSColor(calibratedWhite: 0.16, alpha: 0.97)))
        )
        .fixedSize()
    }
}

@MainActor
final class ToastPanel {
    private var panel: NSPanel?
    private var work: DispatchWorkItem?

    func show(text: String, onUndo: (() -> Void)?, near button: NSStatusBarButton) {
        hide()

        let hosting = NSHostingView(rootView: ToastView(text: text, onUndo: onUndo))
        var size = hosting.fittingSize
        if size.width < 60 { size = NSSize(width: 160, height: 34) }

        let p = NSPanel(contentRect: NSRect(origin: .zero, size: size),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered,
                        defer: false)
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.level = .statusBar
        p.isMovableByWindowBackground = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        p.contentView = hosting

        if let window = button.window {
            let rectInWindow = button.convert(button.bounds, to: nil)
            let screenRect = window.convertToScreen(rectInWindow)
            let x = screenRect.midX - size.width / 2
            let y = screenRect.minY - size.height - 8
            p.setFrameOrigin(NSPoint(x: x, y: y))
        }
        p.orderFrontRegardless()
        panel = p

        let item = DispatchWorkItem { [weak self] in self?.hide() }
        work = item
        DispatchQueue.main.asyncAfter(deadline: .now() + (onUndo == nil ? 2.5 : 4.5), execute: item)
    }

    func hide() {
        work?.cancel()
        work = nil
        panel?.orderOut(nil)
        panel = nil
    }
}
