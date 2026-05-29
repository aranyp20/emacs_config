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
             " -scheme App -configuration Debug"
             " -parallelizeTargets -jobs $(sysctl -n hw.logicalcpu)"
             " -destination 'platform=macOS' ONLY_ACTIVE_ARCH=YES 2>&1"
             " && open -W build/xcode/src/App/Debug/Research.app")))
  (add-hook 'compilation-finish-functions #'my/close-compilation-on-finish))

(defun my/close-compilation-on-finish (_buf _msg)
  (remove-hook 'compilation-finish-functions #'my/close-compilation-on-finish)
  (when-let ((win (get-buffer-window "*compilation*")))
    (delete-window win)))

(defvar my/neumann-test-filter nil
  "GTest filter string for NeumannTests, e.g. \"SuiteName.TestName\".")

(defun my/set-neumann-test-filter ()
  (interactive)
  (setq my/neumann-test-filter
        (let ((input (read-string "GTest filter (empty to clear): "
                                  my/neumann-test-filter)))
          (if (string-empty-p input) nil input)))
  (message "NeumannTests filter: %s" (or my/neumann-test-filter "<none>")))

(defun my/build-and-run-neumann-tests ()
  (interactive)
  (let* ((buf (get-buffer "*compilation*"))
         (proc (and buf (get-buffer-process buf))))
    (if (and proc (process-live-p proc))
        (kill-process proc)
      (let ((default-directory (expand-file-name "~/research/metal-sandbox/"))
            (filter-arg (if my/neumann-test-filter
                            (concat " --gtest_filter='*" my/neumann-test-filter "*'")
                          "")))
        (compile
         (concat "xcodebuild -project build/xcode/research.xcodeproj"
                 " -scheme NeumannTests -configuration Debug"
                 " -parallelizeTargets -jobs $(sysctl -n hw.logicalcpu)"
                 " -destination 'platform=macOS' ONLY_ACTIVE_ARCH=YES 2>&1"
                 " && build/xcode/src/NeumannTests/Debug/NeumannTests.app/Contents/MacOS/NeumannTests"
                 filter-arg))))))

(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "SPC b") 'my/build-and-run-metal-sandbox)
  (define-key evil-normal-state-map (kbd "SPC B") 'my/build-and-run-neumann-tests)
  (define-key evil-normal-state-map (kbd "SPC U") 'my/set-neumann-test-filter))
