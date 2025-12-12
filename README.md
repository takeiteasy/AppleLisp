# AppleLisp

AppleScript really sucks. I don't like it. AppleScript is a Clojure-like Lisp dialect designed to automate macOS.

## About

MacOS includes the `JavaScriptCore.framework`, so to save a lot of time and reinventing the wheel we use [wisp](https://github.com/wisp-lang/wisp) that transpiles to JavaScript. Native macOS APIs are then exposed to JavaScript.

### Why wisp? Why not JavaScript

I don't like JavaScript. I don't like AppleScript. I don't like Swift. I like Lisp. JavaScript is the core so it supports JavaScript as well but I won't be doing that.

## Supported APIs

- FileManager
- Process
- UserDefaults
- Workspace
- Application (ScriptingBridge)
- Clipboard
- Interaction (UI)
- Notification
- SystemControl
- WindowManagement
- UIAutomation
- InputSimulation

## Examples

### Application (ScriptingBridge)

Control other applications using Apple's ScriptingBridge.

```clojure
(def App (require "macos/Application"))

;; Control Safari
(let [safari (.create App "com.apple.Safari")]
  (if (.isRunning safari)
    (do
      (.activate safari)
      ;; Access properties dynamically
      (let [doc (first (.property safari "documents"))]
        (if doc
          (print (.property doc "URL")))))))
```

### Notification

Send local notifications.

```clojure
(def notify (require "macos/Notification"))

;; Request permission
(.requestPermission notify)

;; Send a notification
(.send notify "Task Done" "The background process has finished." "Success")
```

### UIAutomation

Automate user interface interactions (Accessibility API).

```clojure
(def ax (require "macos/UIAutomation"))

;; Get system-wide element
(def sys (.system ax))

;; Inspect element
(print (.role sys))

;; Find element at specific screen coordinates
(let [el (.elementAt ax 100 100)]
  (if el
    (do
      (print (.role el))
      (print (.title el))
      ;; (.perform el "AXPress")
      )))
```

### WindowManagement

List and manipulate windows.

```clojure
(def wm (require "macos/WindowManagement"))

;; List all windows
(let [windows (.list wm)]
  (map (fn [win] 
         (print (get win "app") ":" (get win "title"))) 
       windows))

;; Resize a window (pid, x, y, w, h)
;; Finds the main window of the application with given PID
;; (.setFrame wm 12345 0 0 800 600)
```

### SystemControl

Control system volume and power.

```clojure
(def sys (require "macos/SystemControl"))

;; Volume control (0-100)
(.setVolume sys 50)
(print (.getVolume sys))

;; Toggle mute
(.toggleMute sys)

;; Power management
;; (.sleep sys)
;; (.restart sys)
;; (.shutdown sys)
```

### InputSimulation

Simulate keyboard and mouse events.

```clojure
(def input (require "macos/InputSimulation"))

;; Move mouse
(.mouseMove input 500 500)

;; Click (left button)
(.mouseClick input 500 500)

;; Right click
(.mouseClick input 500 500 "right")

;; Get mouse position
(print (.getMousePosition input))

;; Press a key (e.g., 'a' is 0, 's' is 1)
;; (.keyPress input 0)

;; Press with modifiers (Cmd+Shift+A)
;; (.keyPress input 0 ["cmd" "shift"])
```

### Clipboard

Manage the system clipboard.

```clojure
(def clip (require "macos/Clipboard"))

;; Set clipboard text
(.setString clip "Hello from AppleLisp!")

;; Get clipboard text
(print (.getString clip))

;; Clear clipboard
(.clear clip)
```

### Interaction

Display alerts and prompt for user input.

```clojure
(def ui (require "macos/Interaction"))

;; Show a simple alert
(.alert ui "Task completed successfully!" "Success")

;; Show a customized alert
(let [btn (.alert ui "Delete this file?" 
            {"style" "critical" "buttons" ["Delete" "Cancel"]})]
  (if (= btn "Delete")
    (print "Deleting...")))

;; Prompt for input
(let [name (.prompt ui "What is your name?" "User")]
  (if name
    (print (str "Hello, " name "!"))))

;; Secure prompt (password)
(let [pw (.prompt ui "Enter Password:" nil {"secure" true})]
  (print "Password received"))

;; Choose a file (simple)
(let [file (.chooseFile ui "Select a file to process")]
  (if file
    (print (str "Selected: " file))))

;; Choose multiple files with type filter
(let [files (.chooseFile ui {"message" "Select images" 
                             "multiple" true 
                             "types" ["png" "jpg"]})]
  (if files
    (print (str "Selected " (count files) " files"))))

;; Choose a folder
(let [folder (.chooseFolder ui "Select output directory")]
  (if folder
    (print (str "Output to: " folder))))
```

### FileManager

Interact with the file system.

```clojure
(def fm (require "macos/FileManager"))

;; Check if a file exists
(if (.exists fm "Package.swift")
  (print "File exists")
  (print "File not found"))

;; Read a file
(let [content (.readFile fm "Package.swift")]
  (print content))

;; Write to a file
(.writeFile fm "/tmp/hello.txt" "Hello, AppleLisp!")

;; List directory
(let [files (.listDirectory fm "/Applications")]
  (print files))

;; Get home directory
(print (.homeDirectory fm))
```

### Process

Access process information and execute commands.

```clojure
(def proc (require "macos/Process"))

;; Get process arguments
(print (.argv proc))

;; Get environment variables
(print (.env proc))

;; Get PID
(print (.pid proc))

;; Execute a command
(let [result (.exec proc "/bin/ls" ["-la"])]
  (print (get result "stdout"))
  (print (get result "stderr"))
  (print (get result "status")))

;; Exit
;; (.exit proc 0)
```

### UserDefaults

Store and retrieve user preferences.

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

### Workspace

Interact with the macOS workspace (launching apps, opening files).

```clojure
(def ws (require "macos/Workspace"))

;; Open a file with default application
(.open ws "/path/to/document.pdf")

;; Open a URL
(.openURL ws "https://apple.com")

;; Select file in Finder
(.selectFile ws "/Applications/Safari.app")

;; Find full path for application
(print (.fullPath ws "Terminal"))
```

## Building

To build the library and examples:

```bash
swift build
```

To run the REPL example:

```bash
swift run repl
```

To run the Editor example:

```bash
swift run editor
```

## License

```
AppleLisp

Copyright (C) 2025 George Watson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```