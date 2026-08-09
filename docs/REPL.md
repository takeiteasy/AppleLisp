# REPL Features: Cron and KeyBinding

Beyond the 12 core native APIs shipped with the AppleLisp library, the `apll`
executable registers two additional APIs that are specific to the REPL and
daemon. They are defined as Lisp globals (`Cron`, `KeyBinding`) and are also
available via `require`, but they are not part of the `AppleLisp` library
itself.

## Cron API

Schedule recurring tasks using cron expressions.

### API Reference

| Method | Description |
|--------|-------------|
| `(.schedule expression callback)` | Schedule a job with a standard 5-field cron expression. Returns a job ID string. |
| `(.unschedule id)` | Cancel a scheduled job by its ID. |
| `(.list)` | List all scheduled jobs with their IDs, expressions, and last run times. |

### Examples

```clojure
(def Cron (require "macos/Cron"))

;; Schedule a job every 5 minutes
(def jobId (.schedule Cron "*/5 * * * *" (fn []
  (print "Cron job executed: 5 minute mark"))))

;; List scheduled jobs
(print (.list Cron))

;; Unschedule the job
(.unschedule Cron jobId)
```

The scheduler ticks at the start of every minute. Standard cron syntax is supported: `*`, ranges (`1-5`), steps (`*/5`), comma-separated lists (`1,3,5`), and combinations.

## KeyBinding API

Emacs-style multi-key sequence capture and dispatch via `CGEventTap`.

### API Reference

| Method | Description |
|--------|-------------|
| `(.start)` | Start global key capture. Returns `true` if successful. |
| `(.stop)` | Stop key capture. |
| `(.isActive)` | Returns `true` if capture is active. |
| `(.bind notation callback)` | Register a key sequence (e.g. `"C-x C-f"`). Returns a binding ID. |
| `(.unbind notation)` | Unregister a binding by its notation string. |
| `(.unbindById id)` | Unregister a binding by its ID. |
| `(.clearAll)` | Remove all registered bindings. |
| `(.listBindings)` | Returns an array of all registered bindings. |
| `(.getCurrentSequence)` | Returns the current partial sequence (e.g. `"C-x -"`) or `nil`. |
| `(.onSequenceChange callback)` | Set callback for when the partial key sequence changes. |
| `(.onCancel callback)` | Set callback for when a sequence is cancelled (by Escape). |
| `(.onRawKey callback)` | Set callback for raw key events (before binding matching). Return `true` to consume the event. |
| `(.cancel)` | Manually cancel the current key sequence. |
| `(.isInSequence)` | Check if currently in the middle of a multi-key sequence. |
| `(.parseNotation notation)` | Parse a notation string into its components (for debugging). |
| `(.setTimeout seconds)` | Set an auto-timeout. Default is `0` (wait indefinitely). |

### Key Notation

Bindings use Emacs-style string notation:

| Notation | Meaning |
|----------|---------|
| `C-x` | Control + x |
| `M-x` | Meta (Option) + x |
| `S-tab` | Shift + Tab |
| `CMD-s` | Command + s |
| `C-M-x` | Control + Option + x |
| `C-x C-f` | Sequence of `C-x` followed by `C-f` |

#### Modifiers

- `C`, `CTRL`, `CONTROL` — Control
- `M`, `META`, `ALT`, `OPT`, `OPTION` — Option/Meta
- `S`, `SHIFT` — Shift
- `CMD`, `COMMAND`, `SUPER` — Command

#### Special Keys

`return`, `tab`, `space`, `backspace`, `escape`, `delete`, `home`, `end`, `pageup`, `pagedown`, `left`, `right`, `down`, `up`, `f1`–`f12`

### Examples

```clojure
(def KeyBinding (require "macos/KeyBinding"))

;; Simple binding
(.bind KeyBinding "M-x" (fn [] (print "Execute command...")))

;; Multi-key sequence
(.bind KeyBinding "C-x C-f" (fn []
  (let [file (.showOpenFile Interaction)]
    (when file (print (str "Opening " file))))))

;; Window management
(.bind KeyBinding "C-x 2" (fn []
  (let [win (.focusedWindow WindowManagement)]
    (.splitHorizontal win))))

;; UI feedback for partial sequences
(.onSequenceChange KeyBinding (fn [seq]
  (when seq (print (str "Sequence: " seq)))))

;; Cancellation feedback
(.onCancel KeyBinding (fn []
  (print "Cancelled")))

;; Start global capture
(.start KeyBinding)
```
