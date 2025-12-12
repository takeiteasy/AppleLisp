import JavaScriptCore
import Cocoa
import ApplicationServices

@objc protocol AXWrapperExports: JSExport {
    var role: String { get }
    var title: String { get }
    var value: Any? { get }
    
    func children() -> [AXWrapper]
    func perform(_ action: String) -> Bool
    func attribute(_ name: String) -> Any?
    func setAttribute(_ name: String, _ value: Any)
    
    // New additions
    func actions() -> [String]
    func attributes() -> [String]
    func waitFor(_ attribute: String, _ value: Any, _ timeout: Double) -> Bool
}

@objc class AXWrapper: NSObject, AXWrapperExports {
    let element: AXUIElement
    
    init(element: AXUIElement) {
        self.element = element
    }
    
    var role: String {
        return getAttribute(kAXRoleAttribute) as? String ?? "unknown"
    }
    
    var title: String {
        return getAttribute(kAXTitleAttribute) as? String ?? ""
    }
    
    var value: Any? {
        return getAttribute(kAXValueAttribute)
    }
    
    func children() -> [AXWrapper] {
        guard let children = getAttribute(kAXChildrenAttribute) as? [AXUIElement] else {
            return []
        }
        return children.map { AXWrapper(element: $0) }
    }
    
    func perform(_ action: String) -> Bool {
        let error = AXUIElementPerformAction(element, action as CFString)
        return error == .success
    }
    
    func attribute(_ name: String) -> Any? {
        return getAttribute(name)
    }
    
    func setAttribute(_ name: String, _ value: Any) {
        AXUIElementSetAttributeValue(element, name as CFString, value as CFTypeRef)
    }
    
    // List all available actions
    func actions() -> [String] {
        var names: CFArray?
        let error = AXUIElementCopyActionNames(element, &names)
        if error == .success, let list = names as? [String] {
            return list
        }
        return []
    }
    
    // List all available attributes
    func attributes() -> [String] {
        var names: CFArray?
        let error = AXUIElementCopyAttributeNames(element, &names)
        if error == .success, let list = names as? [String] {
            return list
        }
        return []
    }
    
    // Wait for an attribute to equal a value
    func waitFor(_ attribute: String, _ value: Any, _ timeout: Double) -> Bool {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if let current = getAttribute(attribute) {
                // Compare string representation for simplicity in JS context
                if String(describing: current) == String(describing: value) {
                    return true
                }
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return false
    }
    
    private func getAttribute(_ name: String) -> Any? {
        var ptr: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, name as CFString, &ptr)
        if error == .success, let val = ptr {
            return val
        }
        return nil
    }
    
    override var description: String {
        return "<AXElement role=\(role) title='\(title)'>"
    }
}

public struct UIAutomationAPI: NativeAPIProvider {
    public static var apiName: String { "UIAutomation" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        
        // system() -> AXWrapper (SystemWide)
        let system: @convention(block) () -> AXWrapper = {
            return AXWrapper(element: AXUIElementCreateSystemWide())
        }
        api.setObject(unsafeBitCast(system, to: AnyObject.self),
                      forKeyedSubscript: "system" as NSString)
        
        // app(pid) -> AXWrapper
        let app: @convention(block) (Int32) -> AXWrapper = { pid in
            return AXWrapper(element: AXUIElementCreateApplication(pid))
        }
        api.setObject(unsafeBitCast(app, to: AnyObject.self),
                      forKeyedSubscript: "app" as NSString)
        
        // elementAt(x, y) -> AXWrapper?
        let elementAt: @convention(block) (Float, Float) -> AXWrapper? = { x, y in
            let system = AXUIElementCreateSystemWide()
            var ptr: AXUIElement?
            let error = AXUIElementCopyElementAtPosition(system, x, y, &ptr)
            if error == .success, let el = ptr {
                return AXWrapper(element: el)
            }
            return nil
        }
        api.setObject(unsafeBitCast(elementAt, to: AnyObject.self),
                      forKeyedSubscript: "elementAt" as NSString)
        
        return api
    }
}