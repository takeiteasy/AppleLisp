import JavaScriptCore
import ScriptingBridge

@objc protocol SBWrapperExports: JSExport {
    var bundleIdentifier: String { get }
    var isRunning: Bool { get }
    
    func activate()
    func property(_ key: String) -> Any?
    func setProperty(_ key: String, _ value: Any)
}

@objc class SBWrapper: NSObject, SBWrapperExports {
    let app: SBApplication
    let bundleIdentifier: String
    
    init(app: SBApplication, bundleIdentifier: String) {
        self.app = app
        self.bundleIdentifier = bundleIdentifier
    }
    
    var isRunning: Bool { app.isRunning }
    
    func activate() {
        app.activate()
    }
    
    func property(_ key: String) -> Any? {
        // Retrieve property using KVC
        // SBObject returns objects that need further wrapping if they are SBObjects
        guard let val = app.value(forKey: key) else { return nil }
        return val
    }
    
    func setProperty(_ key: String, _ value: Any) {
        app.setValue(value, forKey: key)
    }
    
    // Support for array subscripting (app["documents"])
    override func value(forUndefinedKey key: String) -> Any? {
        return property(key)
    }
}

public struct ApplicationAPI: NativeAPIProvider {
    public static var apiName: String { "Application" }
    
    public static func install(in context: JSContext) -> JSValue {
        
        // Application(nameOrId) -> SBWrapper?
        let application: @convention(block) (String) -> SBWrapper? = { nameOrId in
            // Try bundle ID first
            if let app = SBApplication(bundleIdentifier: nameOrId) {
                return SBWrapper(app: app, bundleIdentifier: nameOrId)
            }
            
            return nil
        }
        
        let api = JSValue(newObjectIn: context)!
        api.setObject(unsafeBitCast(application, to: AnyObject.self),
                      forKeyedSubscript: "create" as NSString)
        
        return api
    }
}