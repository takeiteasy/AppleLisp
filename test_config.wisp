;; Editor config - loaded on startup

(def km (require "macos/KeyMap"))
(def ed (require "macos/Editor"))
(def hooks (require "macos/Hooks"))

(km.bind "M-f" ed.forwardSexp)
(km.bind "M-b" ed.backwardSexp)
(km.bind "C-M-k" ed.killSexp)

(km.bind "C-e" ed.moveEnd)
(km.bind "C-a" ed.moveHome)

(km.bind "C-l" (fn [] (ed.setStatusMessage "Refreshed!")))

(hooks.add "before-save-hook" (fn [] (console.log "Saving...")))
(hooks.add "after-save-hook" (fn [] (ed.setStatusMessage "Saved!")))
(hooks.add "after-init-hook" (fn [] (ed.setStatusMessage "Config loaded!")))

(console.log "Config loaded! Woooo!")