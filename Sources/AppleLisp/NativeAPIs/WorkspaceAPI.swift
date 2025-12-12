import JavaScriptCore
import AppKit
import UniformTypeIdentifiers

public struct WorkspaceAPI: NativeAPIProvider {
    public static var apiName: String { "Workspace" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        let workspace = NSWorkspace.shared
        let fm = FileManager.default
        
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
            if let url = workspace.urlForApplication(withBundleIdentifier: appName) {
                return url.path
            }
            return workspace.fullPath(forApplication: appName)
        }
        api.setObject(unsafeBitCast(fullPath, to: AnyObject.self),
                      forKeyedSubscript: "fullPath" as NSString)

        // fileIcon(path) -> String? (Base64 PNG)
        let fileIcon: @convention(block) (String) -> String? = { path in
            let icon = workspace.icon(forFile: path)
            guard let tiff = icon.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let png = bitmap.representation(using: .png, properties: [:]) else {
                return nil
            }
            return png.base64EncodedString()
        }
        api.setObject(unsafeBitCast(fileIcon, to: AnyObject.self),
                      forKeyedSubscript: "fileIcon" as NSString)

        // defaultApp(path) -> String? (Path to app)
        let defaultApp: @convention(block) (String) -> String? = { path in
             let url = URL(fileURLWithPath: path)
             return workspace.urlForApplication(toOpen: url)?.path
        }
        api.setObject(unsafeBitCast(defaultApp, to: AnyObject.self),
                      forKeyedSubscript: "defaultApp" as NSString)

        // setDefaultApp(extension, appPath) -> Bool
        let setDefaultApp: @convention(block) (String, String) -> Bool = { ext, appPath in
            guard let type = UTType(filenameExtension: ext) else { return false }
            let appUrl = URL(fileURLWithPath: appPath)
            
            let sema = DispatchSemaphore(value: 0)
            var success = false
            
            workspace.setDefaultApplication(at: appUrl, toOpen: type) { error in
                success = (error == nil)
                sema.signal()
            }
            
            _ = sema.wait(timeout: .now() + 5.0)
            return success
        }
        api.setObject(unsafeBitCast(setDefaultApp, to: AnyObject.self),
                      forKeyedSubscript: "setDefaultApp" as NSString)

        // moveToTrash(path) -> Bool
        let moveToTrash: @convention(block) (String) -> Bool = { path in
            let url = URL(fileURLWithPath: path)
            do {
                try fm.trashItem(at: url, resultingItemURL: nil)
                return true
            } catch {
                return false
            }
        }
        api.setObject(unsafeBitCast(moveToTrash, to: AnyObject.self),
                      forKeyedSubscript: "moveToTrash" as NSString)

        return api
    }
}
