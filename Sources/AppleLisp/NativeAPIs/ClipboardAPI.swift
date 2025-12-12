import JavaScriptCore
import AppKit

public struct ClipboardAPI: NativeAPIProvider {
    public static var apiName: String { "Clipboard" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        
        let getPasteboard: (String?) -> NSPasteboard = { name in
            if let name = name, !name.isEmpty {
                return NSPasteboard(name: NSPasteboard.Name(name))
            }
            return .general
        }
        
        // getString(type?, board?) -> String?
        let getString: @convention(block) (String?, String?) -> String? = { type, board in
            let pb = getPasteboard(board)
            let typeName = type ?? "public.utf8-plain-text"
            return pb.string(forType: NSPasteboard.PasteboardType(typeName))
        }
        api.setObject(unsafeBitCast(getString, to: AnyObject.self),
                      forKeyedSubscript: "getString" as NSString)
        
        // setString(text, type?, board?) -> Bool
        let setString: @convention(block) (String, String?, String?) -> Bool = { text, type, board in
            let pb = getPasteboard(board)
            pb.clearContents()
            let typeName = type ?? "public.utf8-plain-text"
            return pb.setString(text, forType: NSPasteboard.PasteboardType(typeName))
        }
        api.setObject(unsafeBitCast(setString, to: AnyObject.self),
                      forKeyedSubscript: "setString" as NSString)

        // getData(type, board?) -> String? (Base64)
        let getData: @convention(block) (String, String?) -> String? = { type, board in
             let pb = getPasteboard(board)
             guard let data = pb.data(forType: NSPasteboard.PasteboardType(type)) else { return nil }
             return data.base64EncodedString()
        }
        api.setObject(unsafeBitCast(getData, to: AnyObject.self),
                      forKeyedSubscript: "getData" as NSString)
        
        // setData(base64, type, board?) -> Bool
        let setData: @convention(block) (String, String, String?) -> Bool = { base64, type, board in
            let pb = getPasteboard(board)
            guard let data = Data(base64Encoded: base64) else { return false }
            pb.clearContents()
            return pb.setData(data, forType: NSPasteboard.PasteboardType(type))
        }
        api.setObject(unsafeBitCast(setData, to: AnyObject.self),
                      forKeyedSubscript: "setData" as NSString)

        // getTypes(board?) -> [String]
        let getTypes: @convention(block) (String?) -> [String] = { board in
             let pb = getPasteboard(board)
             return pb.types?.map { $0.rawValue } ?? []
        }
        api.setObject(unsafeBitCast(getTypes, to: AnyObject.self),
                      forKeyedSubscript: "getTypes" as NSString)
        
        // clear(board?)
        let clear: @convention(block) (String?) -> Void = { board in
            let pb = getPasteboard(board)
            pb.clearContents()
        }
        api.setObject(unsafeBitCast(clear, to: AnyObject.self),
                      forKeyedSubscript: "clear" as NSString)
        
        return api
    }
}