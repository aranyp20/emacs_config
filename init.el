(tool-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode -1)

(setq mac-command-modifier 'meta)
(setq mac-option-modifier 'none)

(load (expand-file-name "packages.el" (file-name-directory load-file-name)))

(set-face-attribute 'default nil :family "JetBrains Mono" :height 120)

(load (expand-file-name "keybindings.el" (file-name-directory load-file-name)))
(load (expand-file-name "cpp.el" (file-name-directory load-file-name)))
(load (expand-file-name "lsp.el" (file-name-directory load-file-name)))
(load (expand-file-name "style.el" (file-name-directory load-file-name)))

(setq inhibit-startup-screen t)

;; Save minibuffer history between sessions
(savehist-mode 1)

(global-auto-revert-mode 1)
(setq auto-revert-verbose nil)

(projectile-switch-project-by-name "~/research/metal-sandbox")
