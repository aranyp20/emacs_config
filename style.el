(which-function-mode 1)

;; Thin purple border around all windows
(setq window-divider-default-places t
      window-divider-default-bottom-width 2
      window-divider-default-right-width 2)
(window-divider-mode 1)
(set-face-attribute 'window-divider nil :foreground "#7B6FBF")
(set-face-attribute 'window-divider-first-pixel nil :foreground "#7B6FBF")
(set-face-attribute 'window-divider-last-pixel nil :foreground "#7B6FBF")
;; Frame internal border covers the outer edges (top/left of outermost windows)
(add-to-list 'default-frame-alist '(internal-border-width . 2))
(modify-all-frames-parameters '((internal-border-width . 2)))
(set-face-attribute 'internal-border nil :background "#7B6FBF")

(set-face-attribute 'default nil :background "#402C6B")

(set-cursor-color "white")
(setq evil-default-cursor '("white" box))
(setq evil-insert-state-cursor '("white" (bar . 2)))
(setq evil-cursor-face 'my/cursor-face)
(set-face-attribute 'cursor nil :background "white" :foreground "#402C6B")
(global-hl-line-mode 1)
(set-face-attribute 'hl-line nil :background "#4C3677")

(set-face-attribute 'font-lock-keyword-face nil :foreground "#74FAFC")
(set-face-attribute 'font-lock-function-name-face nil :foreground "yellow")
(set-face-attribute 'font-lock-function-call-face nil :foreground "#80FB4C" :slant 'normal)
(set-face-attribute 'font-lock-variable-use-face nil :foreground "white")
(set-face-attribute 'font-lock-variable-name-face nil :foreground "white")
(set-face-attribute 'font-lock-type-face nil :foreground "#efe4a1")

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


;; Block folding with TAB
(add-to-invisibility-spec '(my/fold . t))
(defvar-local my/fold-overlays nil)

(defun my/block-node-at-point ()
  "Return the narrowest foldable tree-sitter block node around point, or nil."
  (when (treesit-parser-list)
    (let ((node (treesit-node-at (point))))
      (while (and node (not (member (treesit-node-type node)
                                    '("compound_statement"
                                      "field_declaration_list"
                                      "declaration_list"))))
        (setq node (treesit-node-parent node)))
      (when (and node
                 (not (string= "namespace_definition"
                               (treesit-node-type (treesit-node-parent node)))))
        node))))

(defun my/toggle-block-fold ()
  "Toggle fold of the innermost block at point."
  (interactive)
  (let ((node (my/block-node-at-point)))
    (when node
      (let* ((fold-start (save-excursion
                           (goto-char (treesit-node-start node))
                           (line-end-position)))
             (fold-end   (save-excursion
                           (goto-char (1- (treesit-node-end node)))
                           (line-beginning-position)))
             (existing   (cl-find-if (lambda (ov)
                                       (= (overlay-start ov) fold-start))
                                     my/fold-overlays)))
        (if existing
            (progn
              (delete-overlay existing)
              (setq my/fold-overlays (delq existing my/fold-overlays)))
          (let ((ov (make-overlay fold-start fold-end nil t nil)))
            (overlay-put ov 'invisible 'my/fold)
            (overlay-put ov 'evaporate t)
            (push ov my/fold-overlays)))))))

(add-hook 'c++-ts-mode-hook
          (lambda ()
            (evil-local-set-key 'normal (kbd "TAB") #'my/toggle-block-fold)))

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
