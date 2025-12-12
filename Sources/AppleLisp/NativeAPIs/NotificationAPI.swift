import JavaScriptCore
import UserNotifications

public struct NotificationAPI: NativeAPIProvider {
    public static var apiName: String { "Notification" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        
        // requestPermission() -> Bool
        let requestPermission: @convention(block) () -> Bool = {
            let center = UNUserNotificationCenter.current()
            var granted = false
            let semaphore = DispatchSemaphore(value: 0)
            center.requestAuthorization(options: [.alert, .sound]) { res, error in
                granted = res
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 5.0)
            return granted
        }
        api.setObject(unsafeBitCast(requestPermission, to: AnyObject.self),
                      forKeyedSubscript: "requestPermission" as NSString)
        
        // send(title, body, subtitle?)
        let send: @convention(block) (String, String, String?) -> Void = { title, body, subtitle in
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            if let sub = subtitle { content.subtitle = sub }
            
            let request = UNNotificationRequest(identifier: UUID().uuidString,
                                                content: content,
                                                trigger: nil) // Deliver immediately
            
            center.add(request) { error in
                if let error = error {
                    print("Error sending notification: \(error.localizedDescription)")
                }
            }
        }
        api.setObject(unsafeBitCast(send, to: AnyObject.self),
                      forKeyedSubscript: "send" as NSString)
        
        return api
    }
}