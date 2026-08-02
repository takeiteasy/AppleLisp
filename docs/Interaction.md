# Interaction API

Display alerts and prompt for user input.

## API Reference

| Method | Description |
|--------|-------------|
| `(.alert message optionsOrTitle?)` | Show an alert dialog. Returns the label of the button pressed. Options: `title`, `style` (`"info"`, `"warning"`, `"critical"`), `buttons` (string array). |
| `(.prompt message defaultValue? options?)` | Show an input prompt. Options: `title`, `buttons`, `secure` (boolean for password fields). Returns entered text or `nil`. |
| `(.chooseFile options?)` | Show a file picker. Options: `message`, `multiple` (boolean), `types` (array of extensions), `directory`. Returns path or array of paths. |
| `(.chooseFolder options?)` | Show a folder picker. Options: `message`, `multiple`, `directory`. Returns path or array of paths. |

## Examples

```clojure
(def ui (require "macos/Interaction"))

;; Simple alert
(.alert ui "Task completed successfully!" "Success")

;; Customized alert
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

;; Choose a file
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
