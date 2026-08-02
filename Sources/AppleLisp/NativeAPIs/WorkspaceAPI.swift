import JavaScriptCore
import AppKit
import UniformTypeIdentifiers

class WorkspaceNotificationDelegate: NSObject {
    static let shared = WorkspaceNotificationDelegate()

    // Map: NotificationName -> [Token: Callback]
    private var observers: [NSNotification.Name: [String: JSValue]] = [:]
    private let lock = NSLock()

    // Supported notification names mapping
    private static let supportedNotifications: [String: NSNotification.Name] = [
        "didLaunchApplication": NSWorkspace.didLaunchApplicationNotification,
        "didTerminateApplication": NSWorkspace.didTerminateApplicationNotification,
        "didActivateApplication": NSWorkspace.didActivateApplicationNotification,
        "didDeactivateApplication": NSWorkspace.didDeactivateApplicationNotification,
        "didHideApplication": NSWorkspace.didHideApplicationNotification,
        "didUnhideApplication": NSWorkspace.didUnhideApplicationNotification,
        "didWake": NSWorkspace.didWakeNotification,
        "willSleep": NSWorkspace.willSleepNotification,
        "screensDidSleep": NSWorkspace.screensDidSleepNotification,
        "screensDidWake": NSWorkspace.screensDidWakeNotification,
        "sessionDidBecomeActive": NSWorkspace.sessionDidBecomeActiveNotification,
        "sessionDidResignActive": NSWorkspace.sessionDidResignActiveNotification,
        "didMountVolume": NSWorkspace.didMountNotification,
        "didUnmountVolume": NSWorkspace.didUnmountNotification,
        "willUnmountVolume": NSWorkspace.willUnmountNotification
    ]

    private override init() {
        super.init()
    }

    func addObserver(name: String, callback: JSValue) -> String? {
        guard let notificationName = Self.supportedNotifications[name] else {
            return nil
        }

        let token = UUID().uuidString

        lock.lock()
        defer { lock.unlock() }

        // First observer for this notification type - register with NSWorkspace
        if observers[notificationName] == nil {
            observers[notificationName] = [:]
            NSWorkspace.shared.notificationCenter.addObserver(
                self,
                selector: #selector(handleNotification(_:)),
                name: notificationName,
                object: nil
            )
        }

        observers[notificationName]?[token] = callback
        return token
    }

    func removeObserver(token: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        for (notificationName, callbacks) in observers {
            if callbacks[token] != nil {
                observers[notificationName]?.removeValue(forKey: token)

                // If no more observers for this notification, unregister
                if observers[notificationName]?.isEmpty == true {
                    observers.removeValue(forKey: notificationName)
                    NSWorkspace.shared.notificationCenter.removeObserver(
                        self,
                        name: notificationName,
                        object: nil
                    )
                }
                return true
            }
        }
        return false
    }

    func removeAllObservers() {
        lock.lock()
        defer { lock.unlock() }

        for notificationName in observers.keys {
            NSWorkspace.shared.notificationCenter.removeObserver(
                self,
                name: notificationName,
                object: nil
            )
        }
        observers.removeAll()
    }

    @objc private func handleNotification(_ notification: Notification) {
        // Copy callbacks outside the lock to avoid holding lock during invocation
        lock.lock()
        let callbacks = observers[notification.name] ?? [:]
        lock.unlock()

        let data = extractNotificationData(notification)

        // Invoke callbacks outside the lock
        for (_, callback) in callbacks {
            callback.call(withArguments: [data])
        }
    }

    private func extractNotificationData(_ notification: Notification) -> [String: Any] {
        var data: [String: Any] = [:]

        // Extract application info
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            data["bundleIdentifier"] = app.bundleIdentifier ?? ""
            data["bundlePath"] = app.bundleURL?.path ?? ""
            data["executablePath"] = app.executableURL?.path ?? ""
            data["localizedName"] = app.localizedName ?? ""
            data["processIdentifier"] = app.processIdentifier
            data["isActive"] = app.isActive
            data["isHidden"] = app.isHidden
            data["isTerminated"] = app.isTerminated
        }

        // Extract volume info
        if let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL {
            data["url"] = volumeURL.absoluteString
            data["path"] = volumeURL.path
        }
        if let volumePath = notification.userInfo?["NSDevicePath"] as? String {
            data["path"] = volumePath
        }

        return data
    }
}

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

        // Notification observer methods

        // observe(notificationName, callback) -> String? (observer token)
        let observe: @convention(block) (String, JSValue) -> String? = { name, callback in
            WorkspaceNotificationDelegate.shared.addObserver(name: name, callback: callback)
        }
        api.setObject(unsafeBitCast(observe, to: AnyObject.self),
                      forKeyedSubscript: "observe" as NSString)

        // removeObserver(token) -> Bool
        let removeObserver: @convention(block) (String) -> Bool = { token in
            WorkspaceNotificationDelegate.shared.removeObserver(token: token)
        }
        api.setObject(unsafeBitCast(removeObserver, to: AnyObject.self),
                      forKeyedSubscript: "removeObserver" as NSString)

        // removeAllObservers() -> Void
        let removeAllObservers: @convention(block) () -> Void = {
            WorkspaceNotificationDelegate.shared.removeAllObservers()
        }
        api.setObject(unsafeBitCast(removeAllObservers, to: AnyObject.self),
                      forKeyedSubscript: "removeAllObservers" as NSString)

        // getSupportedNotifications() -> [String]
        let getSupportedNotifications: @convention(block) () -> [String] = {
            [
                "didLaunchApplication",
                "didTerminateApplication",
                "didActivateApplication",
                "didDeactivateApplication",
                "didHideApplication",
                "didUnhideApplication",
                "didWake",
                "willSleep",
                "screensDidSleep",
                "screensDidWake",
                "sessionDidBecomeActive",
                "sessionDidResignActive",
                "didMountVolume",
                "didUnmountVolume",
                "willUnmountVolume"
            ]
        }
        api.setObject(unsafeBitCast(getSupportedNotifications, to: AnyObject.self),
                      forKeyedSubscript: "getSupportedNotifications" as NSString)

        return api
    }
}
