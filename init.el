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
(load (expand-file-name "projects.el" (file-name-directory load-file-name)))

(setq inhibit-startup-screen t)

;; Save minibuffer history between sessions
(savehist-mode 1)

(global-auto-revert-mode 1)
(setq auto-revert-verbose nil)

;; Silent autosave on every edit (no hooks triggered)
(defun my/silent-save ()
  (when (and buffer-file-name (buffer-modified-p) (not buffer-read-only))
    (write-region (point-min) (point-max) buffer-file-name nil 'nomessage)
    (set-buffer-modified-p nil)
    (set-visited-file-modtime)))
(add-hook 'after-change-functions (lambda (&rest _) (my/silent-save)))

(projectile-switch-project-by-name "~/research/metal-sandbox")
