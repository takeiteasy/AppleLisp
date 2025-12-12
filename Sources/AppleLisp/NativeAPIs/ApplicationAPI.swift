import JavaScriptCore
import ScriptingBridge

@objc protocol SBObjectWrapperExports: JSExport {
    func property(_ key: String) -> Any?
    func setProperty(_ key: String, _ value: Any)
    
    // Support for app["prop"]
    func objectForKeyedSubscript(_ key: String) -> Any?
    func setObject(_ object: Any, forKeyedSubscript key: String)
}

@objc protocol SBApplicationWrapperExports: SBObjectWrapperExports {
    var bundleIdentifier: String { get }
    var isRunning: Bool { get }
    
    func activate()
}

@objc class SBObjectWrapper: NSObject, SBObjectWrapperExports {
    let element: SBObject
    
    init(element: SBObject) {
        self.element = element
    }
    
    func property(_ key: String) -> Any? {
        guard let val = element.value(forKey: key) else { return nil }
        return SBObjectWrapper.wrap(val)
    }
    
    func setProperty(_ key: String, _ value: Any) {
        element.setValue(value, forKey: key)
    }
    
    // Support for app["documents"]
    func objectForKeyedSubscript(_ key: String) -> Any? {
        return property(key)
    }
    
    func setObject(_ object: Any, forKeyedSubscript key: String) {
        setProperty(key, object)
    }
    
    // Support for array subscripting (app["documents"]) via KVC fallback
    override func value(forUndefinedKey key: String) -> Any? {
        return property(key)
    }
    
    override var description: String {
        return "<SBObject: \(element)>"
    }
    
    internal static func wrap(_ value: Any) -> Any {
        if let sbObj = value as? SBObject {
            return SBObjectWrapper(element: sbObj)
        }
        if let sbArray = value as? [Any] { // SBElementArray bridges to Array
             return sbArray.map { wrap($0) }
        }
        return value
    }
}

@objc class SBApplicationWrapper: SBObjectWrapper, SBApplicationWrapperExports {
    let app: SBApplication
    let bundleIdentifier: String
    
    init(app: SBApplication, bundleIdentifier: String) {
        self.app = app
        self.bundleIdentifier = bundleIdentifier
        super.init(element: app)
    }
    
    var isRunning: Bool { app.isRunning }
    
    func activate() {
        app.activate()
    }
}

public struct ApplicationAPI: NativeAPIProvider {
    public static var apiName: String { "Application" }
    
    public static func install(in context: JSContext) -> JSValue {
        
        // Application(nameOrId) -> SBApplicationWrapper?
        let application: @convention(block) (String) -> SBApplicationWrapper? = { nameOrId in
            // Try bundle ID first
            if let app = SBApplication(bundleIdentifier: nameOrId) {
                return SBApplicationWrapper(app: app, bundleIdentifier: nameOrId)
            }
            
            return nil
        }
        
        let api = JSValue(newObjectIn: context)!
        api.setObject(unsafeBitCast(application, to: AnyObject.self),
                      forKeyedSubscript: "create" as NSString)
        
        return api
    }
}