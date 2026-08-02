# Process API

Access process information and execute commands.

## API Reference

| Method | Description |
|--------|-------------|
| `(.argv)` | Get command-line arguments. |
| `(.env)` | Get environment variables as dictionary. |
| `(.pid)` | Get current process PID. |
| `(.hostName)` | Get system host name. |
| `(.osVersion)` | Get OS version string. |
| `(.uptime)` | Get system uptime in seconds. |
| `(.exit code)` | Exit the current process with status code. |
| `(.exec path args? env?)` | Execute a command synchronously. Returns `{status, stdout, stderr}`. |
| `(.spawn path args? env?)` | Spawn a background process. Returns PID. |
| `(.kill pid signal?)` | Terminate a process by PID. Default signal is `SIGTERM`. |
| `(.launchApp nameOrId options?)` | Launch an application by path or bundle ID. Options: `hide`, `newInstance`. |

## Examples

```clojure
(def proc (require "macos/Process"))

;; Process info
(print (.argv proc))
(print (.env proc))
(print (.pid proc))

;; Execute a command (blocking)
(let [result (.exec proc "/bin/ls" ["-la"])]
  (print (get result "stdout"))
  (print (get result "stderr"))
  (print (get result "status")))

;; Spawn a background process
(let [pid (.spawn proc "/bin/sleep" ["10"])]
  (print (str "Spawned PID: " pid))
  (.kill proc pid))

;; Launch an application
(.launchApp proc "com.apple.Safari" { "newInstance" true "hide" true })

;; Exit
;; (.exit proc 0)
```
