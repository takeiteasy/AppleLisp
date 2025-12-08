import JavaScriptCore
import AppKit

public struct WorkspaceAPI: NativeAPIProvider {
    public static var apiName: String { "Workspace" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        let workspace = NSWorkspace.shared
        
        // open(path) -> Bool
        let open: @convention(block) (String) -> Bool = { path in
            workspace.open(URL(fileURLWithPath: path))
        }
        api.setObject(unsafeBitCast(open, to: AnyObject.self),
                      forKeyedSubscript: "open" as NSString)
        
        // openURL(url) -> Bool
        let openURL: @convention(block) (String) -> Bool = { urlString in
            guard let url = URL(string: urlString) else { return false }
            return workspace.open(url)
        }
        api.setObject(unsafeBitCast(openURL, to: AnyObject.self),
                      forKeyedSubscript: "openURL" as NSString)
        
        // selectFile(path) -> Bool
        let selectFile: @convention(block) (String) -> Bool = { path in
            workspace.selectFile(path, inFileViewerRootedAtPath: "")
            return true
        }
        api.setObject(unsafeBitCast(selectFile, to: AnyObject.self),
                      forKeyedSubscript: "selectFile" as NSString)
        
        // fullPath(forApplication: appName) -> String?
        let fullPath: @convention(block) (String) -> String? = { appName in
            workspace.fullPath(forApplication: appName)
        }
        api.setObject(unsafeBitCast(fullPath, to: AnyObject.self),
                      forKeyedSubscript: "fullPath" as NSString)

        return api
    }
}
