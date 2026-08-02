# Workspace API

Interact with the macOS workspace — launching apps, opening files, observing system events.

## API Reference

| Method | Description |
|--------|-------------|
| `(.open path)` | Open a file with its default application. |
| `(.openURL urlString)` | Open a URL in the default browser. |
| `(.selectFile path)` | Reveal a file in Finder. |
| `(.fullPath appName)` | Find the full path for an application (by bundle ID or name). |
| `(.fileIcon path)` | Get file icon as Base64 PNG. |
| `(.defaultApp path)` | Get the default application for a file. |
| `(.setDefaultApp extension appPath)` | Set the default application for a file extension. |
| `(.moveToTrash path)` | Move a file to Trash. |
| `(.observe name callback)` | Observe system events. Returns an observer token. |
| `(.removeObserver token)` | Remove a specific observer. |
| `(.removeAllObservers)` | Remove all observers. |
| `(.getSupportedNotifications)` | List all supported notification names. |

### Supported Notifications

| Name | Description |
|------|-------------|
| `didLaunchApplication` | An application was launched. |
| `didTerminateApplication` | An application terminated. |
| `didActivateApplication` | An application was activated. |
| `didDeactivateApplication` | An application was deactivated. |
| `didHideApplication` | An application was hidden. |
| `didUnhideApplication` | An application was unhidden. |
| `didWake` | System woke from sleep. |
| `willSleep` | System is about to sleep. |
| `screensDidSleep` | Screens turned off. |
| `screensDidWake` | Screens turned on. |
| `sessionDidBecomeActive` | User session became active. |
| `sessionDidResignActive` | User session resigned active. |
| `didMountVolume` | A volume was mounted. |
| `didUnmountVolume` | A volume was unmounted. |
| `willUnmountVolume` | A volume is about to be unmounted. |

## Examples

```clojure
(def ws (require "macos/Workspace"))

;; Open a file
(.open ws "/path/to/document.pdf")

;; Open a URL
(.openURL ws "https://apple.com")

;; Select file in Finder
(.selectFile ws "/Applications/Safari.app")

;; Get file icon (Base64 PNG)
(let [icon (.fileIcon ws "/Applications/Safari.app")]
  (print (count icon)))

;; Default app for a file
(print (.defaultApp ws "/path/to/document.pdf"))

;; Set default app for extension
(.setDefaultApp ws "txt" "/Applications/Visual Studio Code.app")

;; Move to Trash
(.moveToTrash ws "/tmp/garbage.txt")

;; Find app path
(print (.fullPath ws "Terminal"))

;; Observe system events
(def token (.observe ws "didLaunchApplication"
  (fn [data]
    (print (str "App launched: " (get data "localizedName")))
    (print (str "PID: " (get data "processIdentifier"))))))

(.observe ws "didTerminateApplication"
  (fn [data]
    (print (str "App terminated: " (get data "localizedName")))))

(.observe ws "willSleep" (fn [] (print "System going to sleep...")))
(.observe ws "didWake" (fn [] (print "System woke up!")))

(.observe ws "didMountVolume"
  (fn [data]
    (print (str "Volume mounted: " (get data "path")))))

;; Get list of supported notifications
(print (.getSupportedNotifications ws))

;; Remove observers
(.removeObserver ws token)
(.removeAllObservers ws)
```
