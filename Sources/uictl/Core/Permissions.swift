import AppKit
import ApplicationServices
import CoreGraphics

enum Permissions {
    static func accessibilityTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    static func screenRecordingGranted() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Triggers the OS permission prompts (a no-op if already granted/denied
    /// previously — macOS only prompts once per app, after that the user must
    /// use System Settings).
    static func request() {
        _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)
        _ = CGRequestScreenCaptureAccess()
    }

    /// Whether this process is attached to an interactive Quartz/window-server
    /// session, i.e. a GUI user is logged in at the console (or via Screen
    /// Sharing) rather than the process running headless. The classic trap:
    /// an agent SSHes into this Mac and that SSH shell is what auto-spawns
    /// the daemon (`DaemonClient.ensureRunning()`) before any GUI login has
    /// happened — the daemon then inherits a session with no window server
    /// attached, and Accessibility/CoreGraphics calls silently no-op or
    /// return empty results instead of raising a clear error.
    static func interactiveSession() -> Bool {
        guard let dict = CGSessionCopyCurrentDictionary() as? [String: Any] else { return false }
        return (dict[kCGSessionOnConsoleKey as String] as? Bool) ?? true
    }

    static func status() -> JSONDict {
        let interactive = interactiveSession()
        var hint = accessibilityTrusted() && screenRecordingGranted()
            ? "all required permissions granted"
            : "grant via System Settings > Privacy & Security > Accessibility / Screen Recording for the terminal app (or process) running uictl; run `uictl permissions --request` to trigger the prompts"
        if !interactive {
            hint += "; \"interactive\" is false — this process (or the daemon it talks to) has no window-server session attached, likely because it was started from a non-interactive SSH shell before any GUI login. Log in at the console (or via Screen Sharing) and start the daemon from there first (`uictl daemon start`) before automating over SSH."
        }
        return [
            "accessibility": accessibilityTrusted(),
            "screenRecording": screenRecordingGranted(),
            "interactive": interactive,
            "hint": hint,
        ]
    }
}
