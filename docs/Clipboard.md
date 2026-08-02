# Clipboard API

Manage the system clipboard.

## API Reference

| Method | Description |
|--------|-------------|
| `(.getString type? board?)` | Get text from clipboard. `type` defaults to `"public.utf8-plain-text"`. `board` defaults to general pasteboard. |
| `(.setString text type? board?)` | Set clipboard text. Returns `true` on success. |
| `(.getData type board?)` | Get clipboard data as Base64 string. |
| `(.setData base64 type board?)` | Set clipboard data from Base64 string. Returns `true` on success. |
| `(.getTypes board?)` | Get array of available pasteboard types. |
| `(.clear board?)` | Clear the clipboard contents. |

## Examples

```clojure
(def clip (require "macos/Clipboard"))

;; Set clipboard text
(.setString clip "Hello from AppleLisp!")

;; Get clipboard text
(print (.getString clip))

;; Get text of specific type
(print (.getString clip "public.html"))

;; Base64 Data
(let [b64 (.getData clip "public.html")]
  (print b64))

;; Named pasteboard
(.setString clip "Secret" nil "my-secret-board")
(print (.getString clip nil "my-secret-board"))

;; Check available types
(print (.getTypes clip))

;; Clear
(.clear clip)
```
