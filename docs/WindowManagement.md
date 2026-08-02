# WindowManagement API

List and manipulate windows across the system.

## API Reference

| Method | Description |
|--------|-------------|
| `(.list)` | List all on-screen windows. Each entry contains `id`, `pid`, `app`, `title`, `x`, `y`, `w`, `h`, `layer`. |
| `(.setFrame pid x y w h)` | Move and resize the main/focused window of an application. Returns `true` on success. |
| `(.focus pid)` | Bring an application to the foreground. |
| `(.raise pid)` | Same as focus — activate an application. |
| `(.minimize pid)` | Hide an application. |
| `(.snapshot windowId)` | Capture a screenshot of a window (or screen if `0`). Returns Base64 PNG. |

## Examples

```clojure
(def wm (require "macos/WindowManagement"))

;; List all windows
(let [windows (.list wm)]
  (map (fn [win]
         (print (get win "app") ":" (get win "title")))
       windows))

;; Focus/minimize by PID
(let [pid 12345]
  (.focus wm pid)
  (.minimize wm pid))

;; Snapshot a window (pass 0 for screen capture)
(let [b64 (.snapshot wm 0)]
  (print (count b64)))

;; Resize a window (pid, x, y, w, h)
;; (.setFrame wm 12345 0 0 800 600)
```
