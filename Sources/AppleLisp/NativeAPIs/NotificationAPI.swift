import JavaScriptCore
import UserNotifications

// Singleton delegate to handle notification actions
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    var callback: JSValue?
    
    override init() {
        super.init()
        // Only set delegate if we have a bundle ID and are running as an .app
        if Bundle.main.bundleIdentifier != nil && Bundle.main.bundlePath.hasSuffix(".app") {
            UNUserNotificationCenter.current().delegate = self
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let cb = callback {
             let action = response.actionIdentifier
             let id = response.notification.request.identifier
             // callback(actionId, notificationId)
             cb.call(withArguments: [action, id])
        }
        completionHandler()
    }
    
    // Show notification even if app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}

public struct NotificationAPI: NativeAPIProvider {
    public static var apiName: String { "Notification" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        
        // Ensure delegate is initialized
        _ = NotificationDelegate.shared
        
        // requestPermission() -> Bool
        let requestPermission: @convention(block) () -> Bool = {
            guard Bundle.main.bundleIdentifier != nil && Bundle.main.bundlePath.hasSuffix(".app") else { return false }
            
            let center = UNUserNotificationCenter.current()
            var granted = false
            let semaphore = DispatchSemaphore(value: 0)
            center.requestAuthorization(options: [.alert, .sound, .badge]) { res, error in
                granted = res
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 5.0)
            return granted
        }
        api.setObject(unsafeBitCast(requestPermission, to: AnyObject.self),
                      forKeyedSubscript: "requestPermission" as NSString)
        
        // setDelegate(callback)
        let setDelegate: @convention(block) (JSValue) -> Void = { callback in
            NotificationDelegate.shared.callback = callback
        }
        api.setObject(unsafeBitCast(setDelegate, to: AnyObject.self),
                      forKeyedSubscript: "setDelegate" as NSString)
        
        // send(title, body, options?)
        // options: { 
        //   subtitle: String, 
        //   attachments: [String] (paths), 
        //   actions: [{id: String, title: String}],
        //   category: String (optional category ID, auto-generated if actions present)
        // }
        let send: @convention(block) (String, String, JSValue?) -> String = { title, body, options in
            guard Bundle.main.bundleIdentifier != nil && Bundle.main.bundlePath.hasSuffix(".app") else { return "nil" }
            
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            
            var attachments: [String] = []
            var actions: [[String: String]] = []
            var categoryId: String = "default"
            
            if let opts = options, opts.isObject, let dict = opts.toDictionary() as? [String: Any] {
                if let sub = dict["subtitle"] as? String { content.subtitle = sub }
                if let att = dict["attachments"] as? [String] { attachments = att }
                if let acts = dict["actions"] as? [[String: String]] { actions = acts }
                if let cat = dict["category"] as? String { categoryId = cat }
            }
            
            // Handle Attachments
            for path in attachments {
                if let url = URL(string: "file://" + path), 
                   let attachment = try? UNNotificationAttachment(identifier: UUID().uuidString, url: url, options: nil) {
                    content.attachments.append(attachment)
                } else if let attachment = try? UNNotificationAttachment(identifier: UUID().uuidString, url: URL(fileURLWithPath: path), options: nil) {
                    content.attachments.append(attachment)
                }
            }
            
            // Handle Actions
            if !actions.isEmpty {
                // Define a category with these actions
                let notificationActions = actions.compactMap { act -> UNNotificationAction? in
                    guard let id = act["id"], let title = act["title"] else { return nil }
                    return UNNotificationAction(identifier: id, title: title, options: .foreground)
                }
                
                if !notificationActions.isEmpty {
                    categoryId = "cat-" + UUID().uuidString
                    let category = UNNotificationCategory(identifier: categoryId, actions: notificationActions, intentIdentifiers: [], options: [])
                    center.setNotificationCategories([category])
                }
            }
            content.categoryIdentifier = categoryId
            
            let id = UUID().uuidString
            let request = UNNotificationRequest(identifier: id,
                                                content: content,
                                                trigger: nil) // Deliver immediately
            
            center.add(request) { error in
                if let error = error {
                    print("Error sending notification: \(error.localizedDescription)")
                }
            }
            return id
        }
        api.setObject(unsafeBitCast(send, to: AnyObject.self),
                      forKeyedSubscript: "send" as NSString)
        
        return api
    }
}
