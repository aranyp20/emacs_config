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
  '(bar buffer-info-simple buffer-position vcs)
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
