;; Python development setup

;; Tree-sitter: install Python grammar and remap to ts-mode
(add-to-list 'treesit-language-source-alist
             '(python "https://github.com/tree-sitter/tree-sitter-python"))
(unless (treesit-language-available-p 'python)
  (treesit-install-language-grammar 'python))
(add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode))

;; lsp-pyright package
(unless (package-installed-p 'lsp-pyright)
  (package-refresh-contents)
  (package-install 'lsp-pyright))
(require 'lsp-pyright)
(add-to-list 'exec-path (expand-file-name "~/Library/Python/3.9/bin"))

(add-hook 'python-ts-mode-hook #'lsp)

(add-hook 'python-ts-mode-hook
          (lambda ()
            (evil-local-set-key 'normal (kbd "SPC b")
              (lambda ()
                (interactive)
                (compile (concat "python3 " (shell-quote-argument buffer-file-name)))))))

