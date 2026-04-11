;; Auto-close brackets, quotes, etc.
(unless (package-installed-p 'smartparens)
  (package-install 'smartparens))
(require 'smartparens-config)
(add-hook 'c++-ts-mode-hook #'smartparens-mode)

;; C++ indentation style
(add-hook 'c++-ts-mode-hook
          (lambda ()
            (setq c-ts-mode-indent-offset 4)
            (setq c-basic-offset 4)
            (setq indent-tabs-mode nil)
            (electric-indent-local-mode -1)))

(with-eval-after-load 'evil
  (define-key evil-insert-state-map (kbd "RET")
    (lambda ()
      (interactive)
      (newline)
      (indent-according-to-mode))))
