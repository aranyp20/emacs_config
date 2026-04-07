;; LSP mode
(unless (package-installed-p 'lsp-mode)
  (package-install 'lsp-mode))
(unless (package-installed-p 'lsp-ui)
  (package-install 'lsp-ui))

(require 'lsp-mode)
(setq lsp-auto-guess-root t)
(setq lsp-ui-doc-enable nil)
(setq lsp-eldoc-enable-hover nil)
(add-hook 'c++-mode-hook #'lsp)
(setq lsp-clients-clangd-args '("--background-index" "--compile-commands-dir=/Users/peter.arany/emacs_config/metal-sandbox-build"))

;; Projectile: project file search
(unless (package-installed-p 'projectile)
  (package-install 'projectile))
(require 'projectile)
(projectile-mode 1)
(setq projectile-project-search-path '("~/research/"))
(setq projectile-enable-caching t)
(define-key projectile-mode-map (kbd "M-p") 'projectile-command-map)
