import JavaScriptCore
import Foundation

public struct UserDefaultsAPI: NativeAPIProvider {
    public static var apiName: String { "UserDefaults" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        let defaults = UserDefaults.standard
        
        // get(key) -> Any?
        let get: @convention(block) (String) -> Any? = { key in
            defaults.object(forKey: key)
        }
        api.setObject(unsafeBitCast(get, to: AnyObject.self),
                      forKeyedSubscript: "get" as NSString)
        
        // set(key, value) -> Void
        let set: @convention(block) (String, Any) -> Void = { key, value in
            defaults.set(value, forKey: key)
        }
        api.setObject(unsafeBitCast(set, to: AnyObject.self),
                      forKeyedSubscript: "set" as NSString)
        
        // remove(key) -> Void
        let remove: @convention(block) (String) -> Void = { key in
            defaults.removeObject(forKey: key)
        }
        api.setObject(unsafeBitCast(remove, to: AnyObject.self),
                      forKeyedSubscript: "remove" as NSString)
        
        // string(key) -> String?
        let string: @convention(block) (String) -> String? = { key in
            defaults.string(forKey: key)
        }
        api.setObject(unsafeBitCast(string, to: AnyObject.self),
                      forKeyedSubscript: "string" as NSString)
        
        // bool(key) -> Bool
        let bool: @convention(block) (String) -> Bool = { key in
            defaults.bool(forKey: key)
        }
        api.setObject(unsafeBitCast(bool, to: AnyObject.self),
                      forKeyedSubscript: "bool" as NSString)
        
        // integer(key) -> Int
        let integer: @convention(block) (String) -> Int = { key in
            defaults.integer(forKey: key)
        }
        api.setObject(unsafeBitCast(integer, to: AnyObject.self),
                      forKeyedSubscript: "integer" as NSString)
        
        // double(key) -> Double
        let double: @convention(block) (String) -> Double = { key in
            defaults.double(forKey: key)
        }
        api.setObject(unsafeBitCast(double, to: AnyObject.self),
                      forKeyedSubscript: "double" as NSString)
        
        // sync() -> Bool
        let sync: @convention(block) () -> Bool = {
            defaults.synchronize()
        }
        api.setObject(unsafeBitCast(sync, to: AnyObject.self),
                      forKeyedSubscript: "sync" as NSString)

        return api
    }
}
