(setq compilation-scroll-output t)

(add-to-list 'display-buffer-alist
             '("\\*compilation\\*"
               (display-buffer-in-side-window)
               (side . bottom)
               (slot . 0)
               (window-height . 0.15)))

(defun my/build-and-run-metal-sandbox ()
  (interactive)
  (let ((default-directory (expand-file-name "~/research/metal-sandbox/")))
    (compile
     (concat "xcodebuild -project build/xcode/research.xcodeproj"
             " -scheme App -configuration Release 2>&1"
             " && open -W build/xcode/src/App/Release/Research.app")))
  (add-hook 'compilation-finish-functions #'my/close-compilation-on-finish))

(defun my/close-compilation-on-finish (_buf _msg)
  (remove-hook 'compilation-finish-functions #'my/close-compilation-on-finish)
  (when-let ((win (get-buffer-window "*compilation*")))
    (delete-window win)))

(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "SPC b") 'my/build-and-run-metal-sandbox))
