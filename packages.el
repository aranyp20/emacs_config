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
(ligature-set-ligatures 'c++-mode
  '("->" "->*" ">>" "<<" ">=" "<=" "==" "!=" "||" "&&"
    "::" "..." "/*" "*/" "//" "++"))
(global-ligature-mode t)

;; Ahungry theme
(unless (package-installed-p 'ahungry-theme)
  (package-install 'ahungry-theme))
(load-theme 'ahungry t)

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
