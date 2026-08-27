import MCP
import Foundation

/// Once per MCP-server process, checks whether the daemon it forwards to is
/// attached to an interactive window-server session and, if not, warns the
/// connected client via an MCP log notification — the classic remote-testing
/// trap where an agent SSHed into this Mac auto-spawns the daemon from that
/// non-interactive shell before any GUI login, so it can't actually see or
/// drive the desktop. Checks the *daemon's* status (not this process's own),
/// since the daemon is a separate long-lived process that may have been
/// auto-spawned earlier under different session conditions than whatever
/// invoked `uictl mcp` this time.
enum SessionInteractivityCheck {
    /// Tools that don't touch the desktop at all — checking before these
    /// would warn before the agent has even attempted anything that could
    /// fail, and `uictl_permissions` itself already surfaces the same signal
    /// directly in its response.
    /// `uictl_displays` is deliberately *not* here despite querying no
    /// specific window: `Displays.list()` calls `SCShareableContent.current`
    /// (ScreenCaptureKit), which talks to the window server and can fail or
    /// return unusable data in exactly the non-interactive session this
    /// check targets.
    private static let desktopIndependentTools: Set<String> = [
        "uictl_permissions", "uictl_apps",
        "uictl_feedback_create", "uictl_feedback_list", "uictl_feedback_get",
        "uictl_feedback_update", "uictl_feedback_delete", "uictl_feedback_check_duplicates",
        "uictl_feedback_submit", "uictl_log_export",
    ]

    private static let guard_ = OnceGuard()

    static func warnIfNonInteractive(server: Server, toolName: String) async {
        guard !desktopIndependentTools.contains(toolName) else { return }
        guard guard_.claim() else { return }

        let response = DaemonClient.send(command: "permissions.status", params: [:])
        guard (response["ok"] as? Bool) == true,
              let data = response["data"] as? JSONDict,
              (data["interactive"] as? Bool) == false else { return }

        let message = "uictl's daemon has no interactive window-server session attached — " +
            "clicks, screenshots, and Accessibility queries can silently no-op or return " +
            "empty/stale results. This usually means the daemon was auto-spawned from a " +
            "non-interactive SSH shell before any GUI login. If you're driving this Mac " +
            "remotely, log in at the console (or via Screen Sharing) and run " +
            "`uictl daemon start` from there first, before any SSH-triggered call can " +
            "auto-spawn it cold."
        try? await server.log(level: .warning, logger: "uictl", data: .string(message))
    }
}

/// One-shot claim flag — the first caller to `claim()` gets `true`, every
/// later caller gets `false`, forever. Mirrors the `NSLock`-guarded-flag
/// pattern already used by `FeedbackSubmission.swift`'s `ResumeOnce`.
private final class OnceGuard: @unchecked Sendable {
    private let lock = NSLock()
    private var claimed = false

    func claim() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !claimed else { return false }
        claimed = true
        return true
    }
}
