# AppleLisp

AppleScript really sucks. I don't like it. AppleScript is a Clojure-like Lisp dialect designed to automate macOS.

## About

MacOS includes the `JavaScriptCore.framework`, so to save a lot of time and reinventing the wheel we use [wisp](https://github.com/wisp-lang/wisp) that transpiles to JavaScript. Native macOS APIs are then exposed to JavaScript.

### Why wisp? Why not JavaScript

I don't like JavaScript. I don't like AppleScript. I don't like Swift. I like Lisp. JavaScript is the core so it supports JavaScript as well but I won't be doing that.

### Supported APIs

- FileManager
- Process + Task
- UserDefaults
- Workspace

## Example

`TODO`

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
