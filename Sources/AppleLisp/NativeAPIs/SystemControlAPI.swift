import JavaScriptCore
import AppKit
import Foundation

public struct SystemControlAPI: NativeAPIProvider {
    public static var apiName: String { "SystemControl" }
    
    // Store power assertions (caffeinate PIDs)
    private static var powerAssertions: [String: Int32] = [:]
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        
        func runAppleScript(_ source: String) -> String? {
            var error: NSDictionary?
            if let script = NSAppleScript(source: source) {
                let descriptor = script.executeAndReturnError(&error)
                if error == nil {
                    return descriptor.stringValue
                }
            }
            return nil
        }
        
        // sleep()
        let sleep: @convention(block) () -> Void = {
            _ = runAppleScript("tell application \"System Events\" to sleep")
        }
        api.setObject(unsafeBitCast(sleep, to: AnyObject.self),
                      forKeyedSubscript: "sleep" as NSString)
        
        // restart()
        let restart: @convention(block) () -> Void = {
            _ = runAppleScript("tell application \"System Events\" to restart")
        }
        api.setObject(unsafeBitCast(restart, to: AnyObject.self),
                      forKeyedSubscript: "restart" as NSString)
        
        // shutdown()
        let shutdown: @convention(block) () -> Void = {
            _ = runAppleScript("tell application \"System Events\" to shut down")
        }
        api.setObject(unsafeBitCast(shutdown, to: AnyObject.self),
                      forKeyedSubscript: "shutdown" as NSString)
        
        // setVolume(level) - level is 0-100
        let setVolume: @convention(block) (Int) -> Void = { level in
            _ = runAppleScript("set volume output volume \(level)")
        }
        api.setObject(unsafeBitCast(setVolume, to: AnyObject.self),
                      forKeyedSubscript: "setVolume" as NSString)
        
        // getVolume() -> Int
        let getVolume: @convention(block) () -> Int = {
            if let res = runAppleScript("output volume of (get volume settings)") {
                return Int(res) ?? 0
            }
            return 0
        }
        api.setObject(unsafeBitCast(getVolume, to: AnyObject.self),
                      forKeyedSubscript: "getVolume" as NSString)
        
        // toggleMute()
        let toggleMute: @convention(block) () -> Void = {
            _ = runAppleScript("set volume output muted not (output muted of (get volume settings))")
        }
        api.setObject(unsafeBitCast(toggleMute, to: AnyObject.self),
                      forKeyedSubscript: "toggleMute" as NSString)
        
                // preventSleep(reason?) -> String (Assertion ID)
                let preventSleep: @convention(block) (String?) -> String = { reason in
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
                    // -i: prevent idle sleep, -d: prevent display sleep
                    task.arguments = ["-i", "-d"]
                    
                    // Redirect output to avoid hanging test runners
                    task.standardOutput = FileHandle.nullDevice
                    task.standardError = FileHandle.nullDevice
                    
                    do {
                        try task.run()
                        let id = UUID().uuidString
                        SystemControlAPI.powerAssertions[id] = task.processIdentifier
                        return id
                    } catch {
                return "0"
            }
        }
        api.setObject(unsafeBitCast(preventSleep, to: AnyObject.self),
                      forKeyedSubscript: "preventSleep" as NSString)
        
        // allowSleep(id) -> Bool
        let allowSleep: @convention(block) (String) -> Bool = { id in
            guard let pid = SystemControlAPI.powerAssertions[id] else { return false }
            let result = kill(pid, SIGTERM)
            if result == 0 {
                SystemControlAPI.powerAssertions.removeValue(forKey: id)
                return true
            }
            return false
        }
        api.setObject(unsafeBitCast(allowSleep, to: AnyObject.self),
                      forKeyedSubscript: "allowSleep" as NSString)
        
        // setWiFi(enabled) -> Bool
        let setWiFi: @convention(block) (Bool) -> Bool = { enabled in
            // Try en0 and en1
            let state = enabled ? "on" : "off"
            for interface in ["en0", "en1"] {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
                task.arguments = ["-setairportpower", interface, state]
                try? task.run()
                task.waitUntilExit()
                if task.terminationStatus == 0 { return true }
            }
            return false
        }
        api.setObject(unsafeBitCast(setWiFi, to: AnyObject.self),
                      forKeyedSubscript: "setWiFi" as NSString)

        return api
    }
}