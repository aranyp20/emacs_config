(tool-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode -1)

(setq mac-command-modifier 'meta)
(setq mac-option-modifier 'none)

(load (expand-file-name "packages.el" (file-name-directory load-file-name)))

(set-face-attribute 'default nil :family "JetBrains Mono" :height 120)
(set-face-attribute 'company-tooltip nil :background "gray20" :foreground "white")
(set-face-attribute 'company-tooltip-selection nil :background "gray40" :foreground "white")
(set-face-attribute 'company-tooltip-common nil :foreground "lawn green")
(setq company-posframe-show-params
      '(:internal-border-width 2
        :internal-border-color "#39ff14"
        :background-color "gray20"))

(load (expand-file-name "keybindings.el" (file-name-directory load-file-name)))
(load (expand-file-name "cpp.el" (file-name-directory load-file-name)))
(load (expand-file-name "lsp.el" (file-name-directory load-file-name)))
(load (expand-file-name "style.el" (file-name-directory load-file-name)))

(setq inhibit-startup-screen t)

(global-auto-revert-mode 1)
(setq auto-revert-verbose nil)

(projectile-switch-project-by-name "~/research/metal-sandbox")
