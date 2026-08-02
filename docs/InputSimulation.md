# InputSimulation API

Simulate keyboard and mouse events.

## API Reference

| Method | Description |
|--------|-------------|
| `(.keyPress keyCode modifiers?)` | Press and release a key. `modifiers` is an array like `["cmd", "shift"]`. |
| `(.typeString string)` | Type a string (handles unicode). |
| `(.mouseMove x y)` | Move mouse to coordinates. |
| `(.mouseClick x y button?)` | Click at coordinates. `button` can be `"left"` (default) or `"right"`. |
| `(.getMousePosition)` | Get current mouse position as `{x, y}`. |
| `(.scrollInput deltaY deltaX?)` | Scroll vertically and/or horizontally (in lines). |
| `(.delayInput seconds)` | Blocking delay for the given duration. |

## Examples

```clojure
(def input (require "macos/InputSimulation"))

;; Move mouse
(.mouseMove input 500 500)

;; Left click
(.mouseClick input 500 500)

;; Right click
(.mouseClick input 500 500 "right")

;; Get mouse position
(print (get (.getMousePosition input) "x"))
(print (get (.getMousePosition input) "y"))

;; Type a string (handles unicode)
(.typeString input "Hello World! 🌍")

;; Scroll (Y delta, X delta)
(.scrollInput input 10 0)

;; Delay (seconds)
(.delayInput input 0.5)

;; Press a key with modifiers (Cmd+Shift+A)
(.keyPress input 0 ["cmd" "shift"])
```
