(delete-selection-mode 1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode -1)
(show-paren-mode -1)

(setq scroll-conservatively 101)
(setq scroll-margin 0)

;; Center cursor after any jump
(add-hook 'xref-after-jump-hook #'recenter)
(advice-add 'evil-jump-forward  :after (lambda (&rest _) (recenter)))
(advice-add 'evil-jump-backward :after (lambda (&rest _) (recenter)))

(setq mac-command-modifier 'meta)
(setq mac-option-modifier 'none)

(load (expand-file-name "packages.el" (file-name-directory load-file-name)))

(set-face-attribute 'default nil :family "Iosevka" :weight 'semibold :width 'expanded :height 120)

(load (expand-file-name "keybindings.el" (file-name-directory load-file-name)))
(load (expand-file-name "cpp.el" (file-name-directory load-file-name)))
(load (expand-file-name "lsp.el" (file-name-directory load-file-name)))
(load (expand-file-name "style.el" (file-name-directory load-file-name)))
(load (expand-file-name "marks.el" (file-name-directory load-file-name)))
(load (expand-file-name "projects.el" (file-name-directory load-file-name)))
(load (expand-file-name "debug.el" (file-name-directory load-file-name)))
(load (expand-file-name "python.el" (file-name-directory load-file-name)))

(add-to-list 'load-path "~/.emacs.d/lisp")
(require 'lolipop-mode)
(lolipop-mode 1)

(setq inhibit-startup-screen t)
(setq ring-bell-function 'ignore)
(setq create-lockfiles nil)

;; Save minibuffer history between sessions
(savehist-mode 1)

(global-auto-revert-mode 1)
(setq auto-revert-verbose nil)

;; Silent autosave on every edit (no hooks triggered)
(defun my/silent-save ()
  (when (and buffer-file-name (buffer-modified-p) (not buffer-read-only))
    (write-region (point-min) (point-max) buffer-file-name nil 'nomessage)
    (set-buffer-modified-p nil)
    (set-visited-file-modtime)
    (when (vc-backend buffer-file-name)
      (vc-file-setprop buffer-file-name 'vc-state 'edited))))
(add-hook 'after-change-functions (lambda (&rest _) (my/silent-save)))

(projectile-switch-project-by-name "~/research/metal-sandbox")
