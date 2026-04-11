;; LSP mode
(unless (package-installed-p 'lsp-mode)
  (package-install 'lsp-mode))
(unless (package-installed-p 'lsp-ui)
  (package-install 'lsp-ui))

(require 'lsp-mode)
(unless (package-installed-p 'yasnippet)
  (package-refresh-contents)
  (package-install 'yasnippet))
(require 'yasnippet)
(yas-global-mode 1)
(setq lsp-enable-snippet t)
(setq lsp-auto-guess-root t)
(setq lsp-semantic-tokens-enable nil)
(setq lsp-ui-doc-enable nil)
(setq lsp-eldoc-enable-hover nil)
(add-hook 'c++-ts-mode-hook #'lsp)

(add-hook 'company-after-completion-hook
          (lambda (candidate)
            (when (and (derived-mode-p 'c++-ts-mode)
                       (get-text-property 0 'lsp-completion-item candidate))
              (let* ((item (get-text-property 0 'lsp-completion-item candidate))
                     (kind (gethash "kind" item)))
                (when (eq kind 9) ;; 9 = Module/Namespace in LSP
                  (insert "::"))))))
(setq lsp-clients-clangd-args '("--background-index" "--compile-commands-dir=/Users/peter.arany/emacs_config/metal-sandbox-build"))

;; Projectile: project file search
(unless (package-installed-p 'projectile)
  (package-install 'projectile))
(require 'projectile)
(setq projectile-project-search-path '("~/research/"))
(setq projectile-enable-caching 'persistent)
(setq projectile-cache-file (expand-file-name "projectile.cache" user-emacs-directory))
(projectile-mode 1)
(define-key projectile-mode-map (kbd "M-p") 'projectile-command-map)
