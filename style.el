(set-face-attribute 'font-lock-keyword-face nil :foreground "#2F53EC")
(set-face-attribute 'font-lock-function-name-face nil :foreground "#DB3371")
(set-face-attribute 'font-lock-function-call-face nil :foreground "#80FB4C")
(set-face-attribute 'font-lock-variable-use-face nil :foreground "white")
(set-face-attribute 'font-lock-variable-name-face nil :foreground "white")

(add-hook 'c++-ts-mode-hook
          (lambda ()
            (setq treesit-font-lock-settings
                  (append treesit-font-lock-settings
                          (treesit-font-lock-rules
                           :language 'cpp
                           :feature 'function
                           :override t
                           '((call_expression
                              function: (qualified_identifier
                                         name: (identifier) @font-lock-function-call-face))))))
            (treesit-font-lock-recompute-features)))
