(defun my/build-and-run-metal-sandbox ()
  (interactive)
  (let ((default-directory (expand-file-name "~/research/metal-sandbox/")))
    (compile
     (concat "xcodebuild -project build/xcode/research.xcodeproj"
             " -scheme App -configuration Release 2>&1"
             " && open build/xcode/src/App/Release/Research.app"))))

(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "SPC b") 'my/build-and-run-metal-sandbox))
