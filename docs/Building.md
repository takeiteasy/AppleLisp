# Building AppleLisp

The package can be built in two configurations: **core-only** (wisp + JavaScriptCore)
and **full** (core plus the macOS native APIs and the apll daemon).

## Makefile

A `Makefile` at the repo root wraps the two configurations. The default target builds
the full native configuration in release mode; `make core` builds core-only:

```bash
make          # full native build (release)
make core     # core-only build
make install  # full native build, then install apll to ~/.local/bin
make uninstall
make test     # run tests in both configurations
```

`make install` installs the `apll` binary to `~/.local/bin` (no `sudo` needed). To
override the install location or configuration:

```bash
make install PREFIX=/usr/local
make CONFIG=debug
```

## Core-only (default)

A plain `swift build` produces a library that is just the wisp compiler/`JSContext`
wrapping and the generic native-API extension mechanism — no macOS system frameworks
are imported or linked.

```bash
swift build
swift run apll
```

Core-only includes:

- The `AppleLisp` class: `compile`, `evaluate`, `run`, the `registerCustomAPI` methods
  (both the `JSValue`-based and `NativeAPIProvider`-based forms), `hasCustomAPI`, and
  `availableAPIs`.
- The `NativeAPIProvider` protocol, so custom APIs can still be written and registered.
- The generic `require("macos/X")` hook and `__macos_apis` registry.
- The apll `Cron` API (pure Foundation, no macOS frameworks).

Core-only excludes:

- The 12 built-in macOS native APIs (`registerAllNativeAPIs()` and the files under
  `Sources/AppleLisp/NativeAPIs/`).
- The apll `KeyBinding` API and `--daemon` mode (both use `CGEventTap`). Running
  `apll --daemon` in a core-only build prints an error and exits.

## Full build (native APIs enabled)

Pass `-D APLL_NATIVE` to the Swift compiler to compile the native bindings:

```bash
swift build -Xswiftc -D -Xswiftc APLL_NATIVE
swift run -Xswiftc -D -Xswiftc APLL_NATIVE apll
```

This adds the 12 built-in native APIs (`FileManager`, `Clipboard`, `Application`, …),
registers them as Lisp globals via `registerAllNativeAPIs()`, and enables the
`KeyBinding` API and `--daemon` mode.

## Tests

`swift test` runs the core tests only. To include the native API tests, pass the flag:

```bash
swift test
swift test -Xswiftc -D -Xswiftc APLL_NATIVE
```

Note that running the test suite requires a full Xcode install — CommandLineTools
alone lacks `XCTest.framework`.

## Consuming as a dependency

SwiftPM has no feature flags, and a downstream package cannot pass `-Xswiftc` flags
into a dependency's build. Consumers of `AppleLisp` therefore get the core-only build
by default. To ship a build that includes the native APIs, set the define in
`Package.swift` (or vendor/fork the package):

```swift
.target(
    name: "AppleLisp",
    buildSettings: [
        .define("APLL_NATIVE")
    ]
)
```
