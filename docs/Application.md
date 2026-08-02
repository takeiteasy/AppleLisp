# Application API

Control other applications using Apple's ScriptingBridge.

## API Reference

| Method | Description |
|--------|-------------|
| `(.create bundleId)` | Create an application proxy by bundle ID. Returns a wrapper object. |

### Application Wrapper

| Property / Method | Description |
|-------------------|-------------|
| `.bundleIdentifier` | The bundle ID of the application |
| `.isRunning` | Whether the application is currently running |
| `(.activate)` | Bring the application to the foreground |
| `(get wrapper "property")` | Access any ScriptingBridge property (e.g. `"documents"`, `"URL"`) |
| `(set wrapper "property" value)` | Set any ScriptingBridge property |

## Examples

```clojure
(def App (require "macos/Application"))

;; Control Safari
(let [safari (.create App "com.apple.Safari")]
  (if (.isRunning safari)
    (do
      (.activate safari)
      ;; Access properties dynamically
      (let [doc (first (get safari "documents"))]
        (if doc
          (print (get doc "URL")))))))
```
