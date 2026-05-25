;;; debug.el — Lightweight C++ debugger for metal-sandbox  -*- lexical-binding: t; -*-

;;; --- Fringe bitmap (used before dape is loaded) --------------------------

(define-fringe-bitmap 'my/bp-dot
  [#b00000000
   #b00111100
   #b01111110
   #b11111111
   #b11111111
   #b01111110
   #b00111100
   #b00000000]
  nil nil 'center)

;;; --- Persistent storage --------------------------------------------------

(defconst my/bp-file (expand-file-name "~/.emacs.d/metal-sandbox-bps.el"))
(defvar my/bp-table (make-hash-table :test 'equal))

(defun my/bp-save ()
  (let (data)
    (maphash (lambda (f ls) (when ls (push (cons f ls) data))) my/bp-table)
    (with-temp-file my/bp-file (prin1 data (current-buffer)))))

(defun my/bp-load ()
  (clrhash my/bp-table)
  (when (file-exists-p my/bp-file)
    (with-temp-buffer
      (insert-file-contents my/bp-file)
      (dolist (e (read (current-buffer)))
        (puthash (car e) (cdr e) my/bp-table)))))

;;; --- Custom fringe overlays (active while dape is not loaded) ------------

(defun my/bp--make-overlay (line)
  (save-excursion
    (goto-char (point-min))
    (forward-line (1- line))
    (let ((ov (make-overlay (line-beginning-position) (line-end-position))))
      (overlay-put ov 'my/bp t)
      (overlay-put ov 'before-string
                   (propertize " " 'display
                               '(left-fringe my/bp-dot (:foreground "#cc3333"))))
      ov)))

(defun my/bp--overlay-at (line)
  (cl-find-if (lambda (ov)
                (and (overlay-get ov 'my/bp)
                     (= (line-number-at-pos (overlay-start ov)) line)))
              (overlays-in (point-min) (point-max))))

;;; --- Toggle (dispatches to dape or custom overlays) ----------------------

(defun my/bp-toggle ()
  "Toggle breakpoint at current line."
  (interactive)
  (let* ((file (or (buffer-file-name) (user-error "Buffer has no file")))
         (line (line-number-at-pos))
         (lines (gethash file my/bp-table)))
    (if (featurep 'dape)
        (progn
          (dape-breakpoint-toggle)
          (if (member line lines)
              (puthash file (remove line lines) my/bp-table)
            (puthash file (cons line lines) my/bp-table)))
      (let ((existing (my/bp--overlay-at line)))
        (if existing
            (progn
              (delete-overlay existing)
              (puthash file (remove line lines) my/bp-table))
          (my/bp--make-overlay line)
          (puthash file (cons line lines) my/bp-table))))
    (my/bp-save)))

(defun my/bp-restore-in-buffer ()
  "Restore breakpoint indicators for the current buffer."
  (when-let ((lines (and (buffer-file-name)
                         (gethash (buffer-file-name) my/bp-table))))
    (if (featurep 'dape)
        (dolist (line lines)
          (save-excursion
            (goto-char (point-min))
            (forward-line (1- line))
            (dape-breakpoint-toggle)))
      (dolist (l lines) (my/bp--make-overlay l)))))

(add-hook 'find-file-hook #'my/bp-restore-in-buffer)
(my/bp-load)

;;; --- Debug run -----------------------------------------------------------

(defun my/debug-run ()
  "Build metal-sandbox in Debug config and start a dape/lldb-dap session."
  (interactive)
  (let ((default-directory my/metal-sandbox-root))
    (add-hook 'compilation-finish-functions #'my/--on-debug-build-done)
    (compile (concat "xcodebuild -project build/xcode/research.xcodeproj"
                     " -scheme App -configuration Debug 2>&1"))))

;;; --- dape ----------------------------------------------------------------

(defconst my/metal-sandbox-root
  (expand-file-name "~/research/metal-sandbox/"))

(defconst my/metal-sandbox-debug-exe
  (expand-file-name
   "build/xcode/src/App/Debug/Research.app/Contents/MacOS/Research"
   my/metal-sandbox-root))

(defconst my/lldb-dap
  "/Applications/Xcode.app/Contents/Developer/usr/bin/lldb-dap")

(unless (package-installed-p 'dape)
  (package-refresh-contents)
  (package-install 'dape))

(with-eval-after-load 'dape
  ;; Variables + stack on the right side
  (setq dape-buffer-window-arrangement 'right)
  ;; Named config for M-x dape manual use
  (add-to-list 'dape-configs
    `(metal-sandbox
      modes (c-ts-mode c++-ts-mode)
      command ,my/lldb-dap
      :type "lldb"
      :request "launch"
      :program ,my/metal-sandbox-debug-exe
      :cwd ,my/metal-sandbox-root
      :stopOnEntry :json-false))
  ;; Migrate custom overlays → dape breakpoints for already-open buffers
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (dolist (ov (cl-remove-if-not (lambda (o) (overlay-get o 'my/bp))
                                    (overlays-in (point-min) (point-max))))
        (let ((line (line-number-at-pos (overlay-start ov))))
          (delete-overlay ov)
          (save-excursion
            (goto-char (point-min))
            (forward-line (1- line))
            (dape-breakpoint-toggle)))))))

(defun my/dape-run ()
  "Start a dape/lldb-dap session for metal-sandbox."
  (require 'dape)
  (dape `(command ,my/lldb-dap
          :type "lldb"
          :request "launch"
          :program ,my/metal-sandbox-debug-exe
          :cwd ,my/metal-sandbox-root
          :stopOnEntry :json-false)))

;;; --- Build + debug integration -------------------------------------------

(defun my/--on-debug-build-done (buf msg)
  (remove-hook 'compilation-finish-functions #'my/--on-debug-build-done)
  (when (string-match-p "finished" msg)
    (when-let ((win (get-buffer-window "*compilation*")))
      (delete-window win))
    (my/dape-run)))

;;; --- Keybindings ---------------------------------------------------------

(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "SPC t") #'my/bp-toggle)
  (define-key evil-normal-state-map (kbd "SPC d") #'my/debug-run)
  (define-key evil-normal-state-map (kbd "SPC c")
    (lambda ()
      (interactive)
      (if (featurep 'dape)
          (call-interactively #'dape-continue)
        (user-error "Dape is not active")))))
