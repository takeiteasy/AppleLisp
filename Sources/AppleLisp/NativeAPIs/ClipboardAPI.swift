import JavaScriptCore
import AppKit

public struct ClipboardAPI: NativeAPIProvider {
    public static var apiName: String { "Clipboard" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        let pb = NSPasteboard.general
        
        // getString() -> String?
        let getString: @convention(block) () -> String? = {
            pb.string(forType: .string)
        }
        api.setObject(unsafeBitCast(getString, to: AnyObject.self),
                      forKeyedSubscript: "getString" as NSString)
        
        // setString(text) -> Bool
        let setString: @convention(block) (String) -> Bool = { text in
            pb.clearContents()
            return pb.setString(text, forType: .string)
        }
        api.setObject(unsafeBitCast(setString, to: AnyObject.self),
                      forKeyedSubscript: "setString" as NSString)
        
        // clear()
        let clear: @convention(block) () -> Void = {
            pb.clearContents()
        }
        api.setObject(unsafeBitCast(clear, to: AnyObject.self),
                      forKeyedSubscript: "clear" as NSString)
        
        return api
    }
}
