import JavaScriptCore
import AppKit

public struct SystemControlAPI: NativeAPIProvider {
    public static var apiName: String { "SystemControl" }    
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
        
        return api
    }
}
