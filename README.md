# AppleLisp

AppleScript really sucks. I don't like it. AppleLisp is a Clojure-like Lisp dialect for JavaScriptCore. macOS includes the `JavaScriptCore.framework`, so to save a lot of time and reinventing the wheel we use [wisp](https://github.com/wisp-lang/wisp) that transpiles to JavaScript. AppleLisp wraps the wisp compiler and a `JSContext` to give you a Lisp REPL/evaluator, plus a protocol for exposing native Swift APIs to Lisp code.

The package ships three things:

- **`AppleLisp` library** — the interpreter core, a `NativeAPIProvider` protocol for native APIs, and 14 built-in macOS native APIs (FileManager, Process, Clipboard, Workspace, Application, Notification, UIAutomation, InputSimulation, SystemControl, WindowManagement, Interaction, UserDefaults, KeyBinding, Cron).
- **`mlisp`** — a keyboard-driven daemon for macOS providing Emacs-style global keybinding control (via `CGEventTap`), scripted in Wisp.
- **`repl`** — an interactive REPL with history and `:load`/`:help` commands.

## Native APIs

All 14 native APIs are documented individually in [`docs/`](docs/):

- [Application](docs/Application.md) (ScriptingBridge)
- [Clipboard](docs/Clipboard.md)
- [Cron](docs/Cron.md)
- [FileManager](docs/FileManager.md)
- [InputSimulation](docs/InputSimulation.md)
- [Interaction](docs/Interaction.md)
- [KeyBinding](docs/KeyBinding.md)
- [Notification](docs/Notification.md)
- [Process](docs/Process.md)
- [SystemControl](docs/SystemControl.md)
- [UIAutomation](docs/UIAutomation.md)
- [UserDefaults](docs/UserDefaults.md)
- [WindowManagement](docs/WindowManagement.md)
- [Workspace](docs/Workspace.md)

See [docs/AppleScript.md](docs/AppleScript.md) for the AppleScript integration notes.

## Adding custom native APIs

Any Swift type can expose itself to Lisp code by conforming to `NativeAPIProvider`:

```swift
import JavaScriptCore
import AppleLisp

public struct GreeterAPI: NativeAPIProvider {
    public static var apiName: String { "Greeter" }

    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        let greet: @convention(block) (String) -> String = { name in
            "Hello, \(name)!"
        }
        api.setObject(unsafeBitCast(greet, to: AnyObject.self),
                      forKeyedSubscript: "greet" as NSString)
        return api
    }
}
```

Register it against a running `AppleLisp` instance and it becomes available via `require`:

```swift
let lisp = try AppleLisp()
lisp.registerCustomAPI(GreeterAPI.self)
```

```clojure
(def greeter (require "macos/Greeter"))
(print (.greet greeter "World"))
```

To register every built-in API as a Lisp global (`FileManager`, `Clipboard`, etc.) in one call:

```swift
try lisp.registerAllNativeAPIs()
```

## Building

To build the library, REPL, and daemon:

```bash
swift build
```

To run the REPL:

```bash
swift run repl
```

To run the keyboard daemon (requires Accessibility permissions):

```bash
swift run mlisp
```

## Key Notation

Bindings use a familiar Emacs-style string notation:

- `C-x`: Control + x
- `M-x`: Meta (Option) + x
- `S-tab`: Shift + Tab
- `CMD-s`: Command + s
- `C-M-x`: Control + Option + x
- `C-x C-f`: A sequence of `C-x` followed by `C-f`

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
