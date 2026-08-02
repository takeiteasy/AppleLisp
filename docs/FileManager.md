# FileManager API

Interact with the file system.

## API Reference

| Method | Description |
|--------|-------------|
| `(.exists path)` | Check if a file exists. |
| `(.isDirectory path)` | Check if path is a directory. |
| `(.readFile path)` | Read a file as UTF-8 string. Returns `nil` on failure. |
| `(.readFileData path)` | Read a binary file as array of bytes. |
| `(.writeFile path content)` | Write a UTF-8 string to a file. Returns `true` on success. |
| `(.listDirectory path)` | List contents of a directory. |
| `(.createDirectory path)` | Create a directory (with intermediate directories). |
| `(.remove path)` | Remove a file or directory. |
| `(.copy src dst)` | Copy a file. |
| `(.move src dst)` | Move a file. |
| `(.currentDirectory)` | Get current working directory. |
| `(.homeDirectory)` | Get user home directory. |
| `(.tempDirectory)` | Get system temporary directory. |
| `(.getAttributes path)` | Get file attributes (size, creation/modification dates, type, permissions, owner). |
| `(.setPermissions path octal)` | Set file permissions (e.g. `511` for `0o777`). |
| `(.glob pattern)` | Recursively find files matching a glob pattern (e.g. `**/*.swift`). |
| `(.getXAttr path name)` | Get extended attribute value. |
| `(.setXAttr path name value)` | Set extended attribute. |
| `(.listXAttrs path)` | List extended attribute names. |
| `(.removeXAttr path name)` | Remove extended attribute. |

## Examples

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

;; File attributes
(let [attrs (.getAttributes fm "/tmp/hello.txt")]
  (if attrs
    (do
      (print (get attrs "size"))
      (print (get attrs "permissions")))))

;; Change permissions
(.setPermissions fm "/tmp/hello.txt" 511)

;; Globbing
(let [swiftFiles (.glob fm "**/*.swift")]
  (print (count swiftFiles)))

;; Extended attributes
(.setXAttr fm "/tmp/hello.txt" "com.myapp.tag" "important")
(print (.getXAttr fm "/tmp/hello.txt" "com.myapp.tag"))
(.removeXAttr fm "/tmp/hello.txt" "com.myapp.tag")

;; Get home directory
(print (.homeDirectory fm))
```
