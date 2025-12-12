import JavaScriptCore
import CoreGraphics
import ApplicationServices
import Cocoa

public struct WindowManagementAPI: NativeAPIProvider {
    public static var apiName: String { "WindowManagement" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        
        // list() -> [{id, pid, app, title, x, y, w, h, layer}]
        let list: @convention(block) () -> [[String: Any]] = {
            var windows: [[String: Any]] = []
            let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
            let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
            
            for info in infoList {
                var win: [String: Any] = [:]
                win["id"] = info[kCGWindowNumber as String]
                win["pid"] = info[kCGWindowOwnerPID as String]
                win["app"] = info[kCGWindowOwnerName as String]
                win["title"] = info[kCGWindowName as String]
                win["layer"] = info[kCGWindowLayer as String]
                
                if let bounds = info[kCGWindowBounds as String] as? [String: Any] {
                    win["x"] = bounds["X"]
                    win["y"] = bounds["Y"]
                    win["w"] = bounds["Width"]
                    win["h"] = bounds["Height"]
                }
                
                windows.append(win)
            }
            return windows
        }
        api.setObject(unsafeBitCast(list, to: AnyObject.self),
                      forKeyedSubscript: "list" as NSString)
        
        // setFrame(pid, x, y, w, h) -> Bool
        // Finds the focused or main window of the app with PID and moves/resizes it
        let setFrame: @convention(block) (Int32, Double, Double, Double, Double) -> Bool = { pid, x, y, w, h in
            let appElement = AXUIElementCreateApplication(pid)
            
            // Get focused window first
            var focusedWindow: AnyObject?
            if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success {
                let win = focusedWindow as! AXUIElement
                setWindowFrame(win, x: x, y: y, w: w, h: h)
                return true
            }
            
            // If no focused window, try main window
            var mainWindow: AnyObject?
            if AXUIElementCopyAttributeValue(appElement, kAXMainWindowAttribute as CFString, &mainWindow) == .success {
                let win = mainWindow as! AXUIElement
                setWindowFrame(win, x: x, y: y, w: w, h: h)
                return true
            }
            
            // If neither, get all windows and pick first (that is likely a standard window)
            var windows: AnyObject?
            if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windows) == .success,
               let winList = windows as? [AXUIElement], let first = winList.first {
                setWindowFrame(first, x: x, y: y, w: w, h: h)
                return true
            }
            
            return false
        }
        api.setObject(unsafeBitCast(setFrame, to: AnyObject.self),
                      forKeyedSubscript: "setFrame" as NSString)
        
        // focus(pid) -> Bool
        let focus: @convention(block) (Int32) -> Bool = { pid in
            if let app = NSRunningApplication(processIdentifier: pid) {
                return app.activate(options: .activateIgnoringOtherApps)
            }
            return false
        }
        api.setObject(unsafeBitCast(focus, to: AnyObject.self),
                      forKeyedSubscript: "focus" as NSString)
        
        // minimize(pid) -> Bool (Hides application)
        let minimize: @convention(block) (Int32) -> Bool = { pid in
            if let app = NSRunningApplication(processIdentifier: pid) {
                app.hide()
                return true
            }
            return false
        }
        api.setObject(unsafeBitCast(minimize, to: AnyObject.self),
                      forKeyedSubscript: "minimize" as NSString)
        
        // raise(pid) -> Bool (Same as focus for now)
        let raise: @convention(block) (Int32) -> Bool = { pid in
            if let app = NSRunningApplication(processIdentifier: pid) {
                return app.activate(options: .activateIgnoringOtherApps)
            }
            return false
        }
        api.setObject(unsafeBitCast(raise, to: AnyObject.self),
                      forKeyedSubscript: "raise" as NSString)
        
        // snapshot(windowId) -> String? (Base64 PNG)
        let snapshot: @convention(block) (Int32) -> String? = { windowId in
            let id = CGWindowID(windowId)
            let option: CGWindowListOption = (id == 0) ? .optionOnScreenOnly : .optionIncludingWindow
            let imageId = (id == 0) ? kCGNullWindowID : id
            
            guard let image = CGWindowListCreateImage(.infinite, option, imageId, .bestResolution) else {
                return nil
            }
            
            let bitmap = NSBitmapImageRep(cgImage: image)
            guard let png = bitmap.representation(using: .png, properties: [:]) else {
                return nil
            }
            return png.base64EncodedString()
        }
        api.setObject(unsafeBitCast(snapshot, to: AnyObject.self),
                      forKeyedSubscript: "snapshot" as NSString)

        return api
    }
    
    private static func setWindowFrame(_ element: AXUIElement, x: Double, y: Double, w: Double, h: Double) {
        var position = CGPoint(x: x, y: y)
        var size = CGSize(width: w, height: h)
        
        if let positionVal = AXValueCreate(.cgPoint, &position) {
            AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, positionVal)
        }
        if let sizeVal = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeVal)
        }
    }
}