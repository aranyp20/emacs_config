;; Package manager setup
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Vertico: vertical minibuffer completion
(unless (package-installed-p 'vertico)
  (package-refresh-contents)
  (package-install 'vertico))
(vertico-mode 1)

;; Orderless: flexible space-separated filtering
(unless (package-installed-p 'orderless)
  (package-install 'orderless))
(setq completion-styles '(orderless basic))
(setq orderless-smart-case t)

;; Ultra-scroll: smooth scrolling
(unless (package-installed-p 'ultra-scroll)
  (package-install 'ultra-scroll))
(require 'ultra-scroll)
(ultra-scroll-mode 1)

;; Company: autocomplete
(unless (package-installed-p 'company)
  (package-install 'company))
(require 'company)
(global-company-mode 1)
(setq company-idle-delay 0)
(setq company-minimum-prefix-length 1)
(define-key company-active-map (kbd "<tab>") 'company-complete-selection)
(define-key company-active-map (kbd "RET") nil)
(define-key company-active-map (kbd "<return>") nil)

;; Company-posframe: child frame tooltip (border support)
(unless (package-installed-p 'company-posframe)
  (package-install 'company-posframe))
(company-posframe-mode 1)

;; Ligatures (C++ releváns)
(unless (package-installed-p 'ligature)
  (package-install 'ligature))
(require 'ligature)
(ligature-set-ligatures 'c++-ts-mode
  '("->" "->*" ">>" "<<" ">=" "<=" "==" "!=" "||" "&&"
    "::" "..." "/*" "*/" "//" "++"))
(global-ligature-mode t)

;; Tree-sitter: install C++ grammar and remap to ts-mode
(setq treesit-font-lock-level 4)
(setq treesit-language-source-alist
      '((c "https://github.com/tree-sitter/tree-sitter-c")
        (cpp "https://github.com/tree-sitter/tree-sitter-cpp")))
(unless (treesit-language-available-p 'c)
  (treesit-install-language-grammar 'c))
(unless (treesit-language-available-p 'cpp)
  (treesit-install-language-grammar 'cpp))
(add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode))

;; Consult: interactive search with live preview
(unless (package-installed-p 'consult)
  (package-refresh-contents)
  (package-install 'consult))
(require 'consult)
(setq xref-show-xrefs-function #'consult-xref)
(setq xref-show-definitions-function #'consult-xref)

;; Doom themes
(unless (package-installed-p 'doom-themes)
  (package-install 'doom-themes))
(require 'doom-themes)
(load-theme 'doom-shades-of-purple t)

;; Nerd icons
(unless (package-installed-p 'nerd-icons)
  (package-refresh-contents)
  (package-install 'nerd-icons))
(require 'nerd-icons)
(unless (find-font (font-spec :family "Symbols Nerd Font Mono"))
  (nerd-icons-install-fonts t))

;; Doom modeline
(unless (package-installed-p 'doom-modeline)
  (package-refresh-contents)
  (package-install 'doom-modeline))
(require 'doom-modeline)
(setq doom-modeline-icon t
      doom-modeline-major-mode-icon t)

(doom-modeline-def-modeline 'my-minimal
  '(bar buffer-info-simple misc-info buffer-position vcs)
  '())

(defun my-doom-modeline ()
  (doom-modeline-set-modeline 'my-minimal 'default))

(add-hook 'doom-modeline-mode-hook #'my-doom-modeline)
(doom-modeline-mode 1)

;; diff-hl: git diff indicators in the fringe (after theme so faces are correct)
(unless (package-installed-p 'diff-hl)
  (package-refresh-contents)
  (package-install 'diff-hl))
(require 'diff-hl)
(global-diff-hl-mode 1)
(diff-hl-flydiff-mode 1)

;; Magit: git interface
(unless (package-installed-p 'magit)
  (package-refresh-contents)
  (package-install 'magit))
(with-eval-after-load 'magit
  (setq magit-section-initial-visibility-alist '((file . hide)))
  (setq magit-log-section-commit-count 30)
  (setq magit-diff-refine-hunk t)
  (setq diff-font-lock-syntax 'magit-style)
  (require 'forge))

(unless (package-installed-p 'forge)
  (package-refresh-contents)
  (package-install 'forge))

;; Floating child frame for magit – make-frame alapú, nem posframe
(defvar my/magit-child-frame nil "Floating child frame for magit.")

(defun my/magit-child-frame--make ()
  "Létrehoz egy középre igazított, dísztelen child frame-t."
  (let* ((parent (selected-frame))
         (cw     (frame-char-width  parent))
         (ch     (frame-char-height parent))
         (pcols  (frame-width  parent))
         (prows  (frame-height parent))
         (fcols  (round (* pcols 0.85)))
         (frows  (round (* prows 0.85)))
         (left   (/ (- (* pcols cw) (* fcols cw)) 2))
         (top    (/ (- (* prows ch) (* frows ch)) 2)))
    (make-frame
     `((parent-frame             . ,parent)
       (width                    . ,fcols)
       (height                   . ,frows)
       (left                     . ,left)
       (top                      . ,top)
       (undecorated              . t)
       (child-frame-border-width . 2)
       (internal-border-width    . 2)
       (minibuffer               . nil)
       (tool-bar-lines           . 0)
       (menu-bar-lines           . 0)
       (vertical-scroll-bars     . nil)))))

;; display-buffer-alist: minden magit buffer a child frame-be megy
(defun my/magit-child-frame-condition (buf-name _action)
  (and (frame-live-p my/magit-child-frame)
       (with-current-buffer (get-buffer buf-name)
         (derived-mode-p 'magit-mode))))

(defun my/magit-child-frame-action (buf _alist)
  (let ((win (frame-selected-window my/magit-child-frame)))
    (with-selected-window win
      (switch-to-buffer buf))
    win))

(add-to-list 'display-buffer-alist
             '(my/magit-child-frame-condition
               (my/magit-child-frame-action)))

(defun my/magit-child-frame-toggle ()
  "SPC-y: floating magit-status child frame toggle."
  (interactive)
  (if (frame-live-p my/magit-child-frame)
      (progn
        (delete-frame my/magit-child-frame)
        (setq my/magit-child-frame nil))
    (setq my/magit-child-frame (my/magit-child-frame--make))
    (with-selected-frame my/magit-child-frame
      (magit-status))))

(with-eval-after-load 'magit
  ;; q a status bufferen bezárja a child frame-t;
  ;; sub-buffereken (log, diff) normálisan visszanavigál
  (advice-add 'magit-mode-bury-buffer :around
              (lambda (orig-fn &rest args)
                (if (and (frame-live-p my/magit-child-frame)
                         (eq (selected-frame) my/magit-child-frame)
                         (derived-mode-p 'magit-status-mode))
                    (progn
                      (delete-frame my/magit-child-frame)
                      (setq my/magit-child-frame nil))
                  (apply orig-fn args)))))

;; Evil mode
(unless (package-installed-p 'evil)
  (package-install 'evil))
(setq evil-want-integration t)
(setq evil-want-keybinding nil)
(require 'evil)
(evil-mode 1)

;; Cursor shape: thin bar in insert, block in normal
(setq evil-insert-state-cursor '(bar . 2))
(setq evil-normal-state-cursor '(box))

;;(fringe-mode '(8 . 8))

