# UIAutomation API

Automate user interface interactions via the Accessibility API.

## API Reference

| Method | Description |
|--------|-------------|
| `(.system)` | Get the system-wide accessibility element. |
| `(.app pid)` | Get the accessibility element for a specific application by PID. |
| `(.elementAt x y)` | Get the accessibility element at specific screen coordinates. |

### AXWrapper (accessibility element)

| Property / Method | Description |
|-------------------|-------------|
| `.role` | The element's role (e.g. `"AXWindow"`, `"AXButton"`). |
| `.title` | The element's title. |
| `.value` | The element's value. |
| `(.children)` | Get child elements. |
| `(.perform action)` | Perform an action (e.g. `"AXPress"`). |
| `(.attribute name)` | Get an attribute value. |
| `(.setAttribute name value)` | Set an attribute value. |
| `(.actions)` | List all available actions. |
| `(.attributes)` | List all available attributes. |
| `(.waitFor attribute value timeout)` | Wait for an attribute to match a value within the timeout (seconds). |

## Examples

```clojure
(def ax (require "macos/UIAutomation"))

;; Get system-wide element
(def sys (.system ax))

;; Inspect element
(print (get sys "role"))

;; List available actions and attributes
(print (.actions sys))
(print (.attributes sys))

;; Wait for a condition
;; (.waitFor sys "AXRole" "AXWindow" 5.0)

;; Find element at coordinates
(let [el (.elementAt ax 100 100)]
  (if el
    (do
      (print (get el "role"))
      (print (get el "title"))
      ;; (.perform el "AXPress")
      )))
```
