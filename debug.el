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
  ;; Don't pop up the lldb REPL command window automatically
  (add-to-list 'display-buffer-alist
    '("\\*dape-repl\\*" (display-buffer-no-window) (allow-no-window . t)))
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

;;; --- Inline variable inspection ------------------------------------------

(defun my/dape--sync-vars (conn varref)
  "Synchronously fetch children of VARREF via CONN. Returns list or nil."
  (let (done result)
    (jsonrpc-async-request
     conn 'variables (list :variablesReference varref)
     :success-fn (lambda (r)
                   (setq result (plist-get (plist-get r :body) :variables)
                         done t))
     :error-fn   (lambda (_) (setq done t)))
    (let ((t0 (float-time)))
      (while (and (not done) (< (- (float-time) t0) 2.0))
        (accept-process-output nil 0.02 nil t)))
    result))

(defun my/dape--var-widget (conn var)
  "Return widget spec for dape variable VAR."
  (let ((name   (plist-get var :name))
        (value  (or (plist-get var :value) ""))
        (varref (or (plist-get var :variablesReference) 0)))
    (if (> varref 0)
        `(tree-widget
          :tag ,(format "%s = %s" name value)
          :expander ,(let ((vr varref))
                       (lambda (_w)
                         (mapcar (apply-partially #'my/dape--var-widget conn)
                                 (my/dape--sync-vars conn vr)))))
      `(item :tag ,(format "%s = %s" name value)))))

(defun my/dape--find-var-in-scope (conn varref expr callback)
  "Async search for EXPR in the variables of VARREF, call CALLBACK with var or nil."
  (jsonrpc-async-request
   conn 'variables (list :variablesReference varref)
   :success-fn (lambda (res)
                 (let* ((vars  (append (plist-get (plist-get res :body) :variables) nil))
                        (found (seq-find (lambda (v)
                                           (equal (plist-get v :name) expr))
                                         vars)))
                   (funcall callback found)))
   :error-fn (lambda (_) (funcall callback nil))))

(defun my/dape--evaluate-fallback (conn frame-id expr)
  "Fall back to evaluate request when EXPR is not found in scope variables."
  (jsonrpc-async-request
   conn 'evaluate
   (list :expression expr :frameId frame-id :context "watch")
   :success-fn
   (lambda (res)
     (let* ((body   (plist-get res :body))
            (value  (or (plist-get body :result) ""))
            (varref (or (plist-get body :variablesReference) 0)))
       (my/dape--show-inspect
        conn expr
        (list :name expr :value value :variablesReference varref))))
   :error-fn
   (lambda (err)
     (message "dape-inspect: %s" (or (plist-get err :message) "failed")))))

(defun my/dape--search-scopes (conn scopes expr frame-id)
  "Search SCOPES in order for EXPR; fall back to evaluate if not found."
  (if (null scopes)
      (my/dape--evaluate-fallback conn frame-id expr)
    (my/dape--find-var-in-scope
     conn (plist-get (car scopes) :variablesReference) expr
     (lambda (var)
       (if var
           (my/dape--show-inspect conn expr var)
         (my/dape--search-scopes conn (cdr scopes) expr frame-id))))))

(defun my/dape-inspect--toggle-line ()
  "Activate the first widget button on the current line."
  (interactive)
  (let ((end (line-end-position)))
    (save-excursion
      (beginning-of-line)
      (catch 'done
        (while (< (point) end)
          (let ((w (widget-at (point))))
            (when (and w (widget-get w :action))
              (widget-apply-action w)
              (throw 'done nil)))
          (forward-char 1))))))

(defun my/dape--show-inspect (conn expr var)
  "Display VAR in the inspect popup buffer."
  (let ((buf (get-buffer-create "*dape-inspect*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (kill-all-local-variables))
      (setq-local header-line-format
                  (concat " " (propertize expr 'face 'bold)))
      (require 'tree-widget)
      (let ((inhibit-read-only t))
        (apply #'widget-create (my/dape--var-widget conn var))
        (widget-setup))
      (let ((km (make-sparse-keymap)))
        (set-keymap-parent km widget-keymap)
        (define-key km (kbd "RET") #'my/dape-inspect--toggle-line)
        (define-key km (kbd "q")   #'quit-window)
        (use-local-map km))
      (when (fboundp 'evil-emacs-state)
        (evil-emacs-state))
      (goto-char (point-min)))
    (display-buffer buf '((display-buffer-in-side-window)
                          (side . bottom)
                          (window-height . 12)))))

(defun my/dape-inspect-at-point ()
  "Show dape value for symbol at point in an expandable popup."
  (interactive)
  (unless (featurep 'dape) (user-error "No active dape session"))
  (let* ((conn     (condition-case e
                       (dape--live-connection 'last t)
                     (error (user-error "%s" (error-message-string e)))))
         (frame-id (plist-get (dape--current-stack-frame conn) :id))
         (expr     (or (thing-at-point 'symbol t)
                       (user-error "No symbol at point"))))
    (jsonrpc-async-request
     conn 'scopes (list :frameId frame-id)
     :success-fn (lambda (res)
                   (my/dape--search-scopes
                    conn
                    (append (plist-get (plist-get res :body) :scopes) nil)
                    expr
                    frame-id))
     :error-fn (lambda (err)
                 (message "dape-inspect: %s"
                          (or (plist-get err :message) "failed"))))))

;;; --- Keybindings ---------------------------------------------------------

(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "SPC t") #'my/bp-toggle)
  (define-key evil-normal-state-map (kbd "SPC d") #'my/debug-run)
  (define-key evil-normal-state-map (kbd "SPC e") #'my/dape-inspect-at-point)
  (define-key evil-normal-state-map (kbd "SPC c")
    (lambda ()
      (interactive)
      (if (featurep 'dape)
          (call-interactively #'dape-continue)
        (user-error "Dape is not active")))))
