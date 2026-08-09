# AppleLisp

> **WARNING!** Work in progress

A scripting engine for macOS using JavaScriptCore and [a fork of wisp](https://github.com/takeiteasy/wisp) (only updated dependencies and modifed the build a bit). Optional native macOS API bindings are provided.

The package ships two things:

- **`AppleLisp` library** — the interpreter core (wisp + JavaScriptCore), a `NativeAPIProvider` protocol for native APIs, and 12 built-in macOS native APIs (FileManager, Process, Clipboard, Workspace, Application, Notification, UIAutomation, InputSimulation, SystemControl, WindowManagement, Interaction, UserDefaults). The 12 native APIs are optional: the default build is core-only (just wisp + JavaScriptCore, no macOS frameworks) and the native bindings are compiled with the `APLL_NATIVE` build flag. See [docs/Building.md](docs/Building.md).
- **`apll`** — an interactive REPL with history and `:load`/`:help` commands. With the `--daemon` flag it runs as a keyboard-driven daemon for Emacs-style global keybinding control (via `CGEventTap`), scripted in Wisp. It also registers the Cron and KeyBinding APIs, which are REPL/daemon features rather than part of the library.

## Native APIs

All 12 native APIs are documented individually in [`docs/`](docs/):

- [Application](docs/Application.md) (ScriptingBridge)
- [Clipboard](docs/Clipboard.md)
- [FileManager](docs/FileManager.md)
- [InputSimulation](docs/InputSimulation.md)
- [Interaction](docs/Interaction.md)
- [Notification](docs/Notification.md)
- [Process](docs/Process.md)
- [SystemControl](docs/SystemControl.md)
- [UIAutomation](docs/UIAutomation.md)
- [UserDefaults](docs/UserDefaults.md)
- [WindowManagement](docs/WindowManagement.md)
- [Workspace](docs/Workspace.md)

See [docs/AppleScript.md](docs/AppleScript.md) for the AppleScript integration notes.

## REPL features

Beyond the 12 core native APIs, `apll` registers two additional APIs that are
specific to the REPL and daemon: [Cron](docs/REPL.md) (recurring tasks) and
[KeyBinding](docs/REPL.md) (Emacs-style global key sequences). They are defined
as Lisp globals (`Cron`, `KeyBinding`) and are also available via `require`, but
they are not part of the AppleLisp library itself. See
[docs/REPL.md](docs/REPL.md) for their documentation.

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

`registerAllNativeAPIs()` is only available when the package is built with the
`APLL_NATIVE` flag; custom `NativeAPIProvider` APIs work in the core-only build.

## Building

The package builds in two configurations. The default `swift build` produces a
**core-only** build (wisp + JavaScriptCore, no macOS frameworks). Pass the
`APLL_NATIVE` flag to include the 12 built-in native APIs and the apll daemon:

```bash
swift build                                  # core-only
swift build -Xswiftc -D -Xswiftc APLL_NATIVE # full build with native APIs
```

To run the REPL:

```bash
swift run apll
```

See [docs/Building.md](docs/Building.md) for what each configuration includes and
excludes, and how it affects consuming the package as a dependency.

## Daemon mode

`apll --daemon` runs as a keyboard-driven daemon that captures global key events (via
`CGEventTap`) and dispatches Emacs-style multi-key sequences bound with the
[KeyBinding](docs/REPL.md) API. It requires Accessibility permissions at runtime, and
is only available in a full build (with the `APLL_NATIVE` flag).

On startup it registers a set of example bindings scripted in Wisp:

| Binding | Action |
|---------|--------|
| `C-x C-c` | Quit command |
| `C-x C-f` | Find file |
| `M-x` | Execute extended command |

Pending sequences wait indefinitely for completion; pressing Escape cancels the
current sequence and Ctrl+C exits the daemon.

```bash
swift run apll --daemon
```

Note: daemon mode does not currently load the config file (`~/.apll` or `./.apll`),
and the example bindings above are hardcoded in `Sources/apll/apll.swift` rather than
shipped as a default config. Users who want custom bindings must edit the CLI source
until this is addressed.

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
