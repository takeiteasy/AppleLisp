import JavaScriptCore
import Foundation

/// Hook system for editor lifecycle events
public class Hooks {
    public static var shared = Hooks()
    
    private var hooks: [String: [JSValue]] = [:]
    
    public init() {}
    
    /// Add a function to a hook
    public func add(_ hookName: String, _ fn: JSValue) {
        if hooks[hookName] == nil {
            hooks[hookName] = []
        }
        hooks[hookName]?.append(fn)
    }
    
    /// Remove a function from a hook
    public func remove(_ hookName: String, _ fn: JSValue) {
        hooks[hookName]?.removeAll { $0.isEqual(to: fn) }
    }
    
    /// Run all functions in a hook with optional arguments
    public func run(_ hookName: String, args: [Any] = []) {
        guard let fns = hooks[hookName] else { return }
        for fn in fns {
            fn.call(withArguments: args)
        }
    }
    
    /// Clear all functions from a hook
    public func clear(_ hookName: String) {
        hooks[hookName] = []
    }
    
    /// List all hook names
    public var allHooks: [String] {
        Array(hooks.keys)
    }
    
    /// List functions in a hook
    public func list(_ hookName: String) -> [JSValue] {
        hooks[hookName] ?? []
    }
}

/// Hook API for Wisp
public struct HooksAPI {
    public static var apiName: String { "Hooks" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        
        // add-hook: (add-hook "before-save-hook" (fn [] ...))
        let addHook: @convention(block) (String, JSValue) -> Void = { name, fn in
            Hooks.shared.add(name, fn)
        }
        api.setObject(unsafeBitCast(addHook, to: AnyObject.self), 
                      forKeyedSubscript: "add" as NSString)
        
        // remove-hook: (remove-hook "before-save-hook" fn)
        let removeHook: @convention(block) (String, JSValue) -> Void = { name, fn in
            Hooks.shared.remove(name, fn)
        }
        api.setObject(unsafeBitCast(removeHook, to: AnyObject.self), 
                      forKeyedSubscript: "remove" as NSString)
        
        // run-hook: (run-hook "before-save-hook") - for testing
        let runHook: @convention(block) (String) -> Void = { name in
            Hooks.shared.run(name)
        }
        api.setObject(unsafeBitCast(runHook, to: AnyObject.self), 
                      forKeyedSubscript: "run" as NSString)
        
        // list-hooks: (list-hooks) -> all hook names
        let listHooks: @convention(block) () -> [String] = {
            Hooks.shared.allHooks
        }
        api.setObject(unsafeBitCast(listHooks, to: AnyObject.self), 
                      forKeyedSubscript: "list" as NSString)
        
        return api
    }
}

// Standard hook names
public enum HookNames {
    public static let beforeSave = "before-save-hook"
    public static let afterSave = "after-save-hook"
    public static let afterOpen = "after-open-hook"
    public static let beforeQuit = "before-quit-hook"
    public static let afterInit = "after-init-hook"
}
