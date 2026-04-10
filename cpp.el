;; Auto-close brackets, quotes, etc.
(unless (package-installed-p 'smartparens)
  (package-install 'smartparens))
(require 'smartparens-config)
(add-hook 'c++-ts-mode-hook #'smartparens-mode)

;; C++ indentation style
(add-hook 'c++-ts-mode-hook
          (lambda ()
            (setq c-basic-offset 4)
            (setq indent-tabs-mode nil)))
