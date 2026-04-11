(set-cursor-color "red")
(setq evil-default-cursor '("red" box))
(global-hl-line-mode 1)
(set-face-attribute 'hl-line nil :background "#4A2060")

(set-face-attribute 'font-lock-keyword-face nil :foreground "#74FAFC")
(set-face-attribute 'font-lock-function-name-face nil :foreground "#FF2E00")
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

;; Black separator line above function definitions (tree-sitter)
(defvar-local my/function-separator-timer nil)

(defun my/make-separator-image ()
  "Create a 3px tall black separator image spanning the window width."
  (create-image
   (format "<svg xmlns='http://www.w3.org/2000/svg' width='%d' height='3'><rect width='100%%' height='100%%' fill='black'/></svg>"
           (window-body-width nil t))
   'svg t))

(defun my/do-update-function-separators (buf)
  "Place full-width black separator overlays above each function definition in BUF."
  (when (buffer-live-p buf)
    (with-current-buffer buf
      (when (treesit-parser-list)
        (remove-overlays (point-min) (point-max) 'function-separator t)
        (let ((sep (concat (propertize " " 'display (my/make-separator-image)) "\n")))
          (dolist (match (treesit-query-capture
                          (treesit-buffer-root-node)
                          '((function_definition) @fn)))
            (when (eq (car match) 'fn)
              (let* ((node (cdr match))
                     (pos (treesit-node-start node))
                     (bol (save-excursion (goto-char pos) (line-beginning-position)))
                     (ov (make-overlay bol bol)))
                (overlay-put ov 'function-separator t)
                (overlay-put ov 'before-string sep)))))))))

(defun my/schedule-function-separators (&rest _)
  "Debounced update of function separator overlays."
  (when (timerp my/function-separator-timer)
    (cancel-timer my/function-separator-timer))
  (setq my/function-separator-timer
        (run-with-idle-timer 0.3 nil #'my/do-update-function-separators (current-buffer))))

(add-hook 'c++-ts-mode-hook
          (lambda ()
            (my/do-update-function-separators (current-buffer))
            (add-hook 'after-change-functions #'my/schedule-function-separators nil t)
            (add-hook 'window-size-change-functions
                      (lambda (_) (my/schedule-function-separators)) nil t)))
