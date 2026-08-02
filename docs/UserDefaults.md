# UserDefaults API

Store and retrieve user preferences.

## API Reference

| Method | Description |
|--------|-------------|
| `(.set key value)` | Set a value for a key. |
| `(.get key)` | Get value for a key (returns `Any`). |
| `(.string key)` | Get string value. |
| `(.bool key)` | Get boolean value. |
| `(.integer key)` | Get integer value. |
| `(.double key)` | Get double value. |
| `(.remove key)` | Remove a value. |
| `(.sync)` | Synchronize defaults to disk (usually automatic). |

## Examples

```clojure
(def prefs (require "macos/UserDefaults"))

;; Set values
(.set prefs "username" "jdoe")
(.set prefs "volume" 75)
(.set prefs "darkMode" true)

;; Sync to disk
(.sync prefs)

;; Get values
(print (.string prefs "username"))
(print (.integer prefs "volume"))
(print (.bool prefs "darkMode"))

;; Remove value
(.remove prefs "username")
```
