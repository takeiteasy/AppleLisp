# Notification API

Send local macOS notifications.

## API Reference

| Method | Description |
|--------|-------------|
| `(.requestPermission)` | Request notification authorization. Returns `true` if granted. |
| `(.setDelegate callback)` | Set callback for notification actions. Receives `(actionId, notificationId)`. |
| `(.send title body options?)` | Send a notification. Returns the notification ID. Options: `subtitle`, `attachments` (file paths), `actions` (`[{id, title}]`), `category`. |

## Examples

```clojure
(def notify (require "macos/Notification"))

;; Request permission
(.requestPermission notify)

;; Set delegate to handle actions
(.setDelegate notify (fn [action id]
  (print (str "Action: " action " on notification: " id))))

;; Simple notification
(.send notify "Task Done" "The background process has finished." "Success")

;; Notification with options
(let [opts { "subtitle" "Check it out"
             "attachments" ["/path/to/image.png"]
             "actions" [{ "id" "view" "title" "View Image" }
                        { "id" "ignore" "title" "Ignore" }] }]
  (.send notify "New Image" "You have a new image." opts))
```
