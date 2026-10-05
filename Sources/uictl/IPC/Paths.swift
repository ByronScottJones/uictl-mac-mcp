import Foundation

/// All daemon state lives under ~/.uictl, per the project convention of storing
/// app config/state under "$HOME/.<app_name>/".
enum UICtlPaths {
    /// `UICTL_HOME` overrides the location (used by tests to isolate state).
    static var homeDir: String {
        if let override = ProcessInfo.processInfo.environment["UICTL_HOME"], !override.isEmpty {
            return override
        }
        return NSHomeDirectory() + "/.uictl"
    }

    static var socketPath: String {
        homeDir + "/uictl.sock"
    }

    static var pidFilePath: String {
        homeDir + "/uictl.pid"
    }

    static var logFilePath: String {
        homeDir + "/daemon.log"
    }

    static var feedbackFilePath: String {
        homeDir + "/feedback.json"
    }

    static func ensureHomeDir() throws {
        try FileManager.default.createDirectory(atPath: homeDir, withIntermediateDirectories: true)
    }
}
