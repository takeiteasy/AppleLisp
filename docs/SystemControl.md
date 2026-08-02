# SystemControl API

Control system volume, power management, and networking.

## API Reference

| Method | Description |
|--------|-------------|
| `(.setVolume level)` | Set output volume (`0`–`100`). |
| `(.getVolume)` | Get current output volume. |
| `(.toggleMute)` | Toggle audio mute. |
| `(.preventSleep reason?)` | Prevent system from sleeping using `caffeinate`. Returns an assertion ID. |
| `(.allowSleep id)` | Release a sleep assertion by its ID. Returns `true` on success. |
| `(.setWiFi enabled)` | Turn WiFi on or off. Returns `true` on success. |
| `(.sleep)` | Put the system to sleep. |
| `(.restart)` | Restart the system. |
| `(.shutdown)` | Shut down the system. |

## Examples

```clojure
(def sys (require "macos/SystemControl"))

;; Volume control
(.setVolume sys 50)
(print (.getVolume sys))

;; Toggle mute
(.toggleMute sys)

;; Prevent sleep
(let [id (.preventSleep sys "Downloading huge file")]
  (print (str "Preventing sleep with ID: " id))
  ;; Do work...
  (.allowSleep sys id))

;; WiFi control
(.setWiFi sys false) ;; Turn off
(.setWiFi sys true)  ;; Turn on

;; Power management
;; (.sleep sys)
;; (.restart sys)
;; (.shutdown sys)
```
