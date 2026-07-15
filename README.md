# AppleLisp

AppleScript really sucks. I don't like it. AppleLisp is a Clojure-like Lisp dialect for JavaScriptCore. MacOS includes the `JavaScriptCore.framework`, so to save a lot of time and reinventing the wheel we use [wisp](https://github.com/takeiteasy/wisp) ([forked](https://github.com/wisp-lang/wisp)) that transpiles to JavaScript. AppleLisp wraps the wisp compiler and a `JSContext` to give you a Lisp REPL/evaluator, plus a simple protocol for exposing native Swift APIs to Lisp code.

## Adding native APIs

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

## Building

To build the library and REPL:

```bash
swift build
```

To run the REPL example:

```bash
swift run repl
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
