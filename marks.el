;;; marks.el --- Visual mark sidebar on the left  -*- lexical-binding: t; -*-

(defface my/mark-tab-face
  '((t :foreground "#CCCCCC"))
  "Face for inactive mark tabs in the sidebar.")

(defface my/mark-tab-active-face
  '((t :foreground "white" :weight bold))
  "Face for the active mark tab in the sidebar.")

(defvar my/marks nil
  "Global list of markers placed by the user.")

;;; Core -----------------------------------------------------------------------

(defun my/mark-toggle ()
  "Toggle a mark on the current line."
  (interactive)
  (let* ((buf (current-buffer))
         (ln (line-number-at-pos))
         (existing (cl-find-if
                    (lambda (m)
                      (and (eq (marker-buffer m) buf)
                           (= (line-number-at-pos (marker-position m)) ln)))
                    my/marks)))
    (if existing
        (progn
          (setq my/marks (delq existing my/marks))
          (set-marker existing nil)
          (message "Mark removed"))
      (setq my/marks (append my/marks (list (point-marker))))
      (message "Mark placed"))
    (my/marks-cleanup)
    (my/marks-update)))

(defun my/marks-cleanup ()
  "Remove dead markers."
  (setq my/marks (cl-remove-if-not #'marker-buffer my/marks)))

(defun my/mark-clear-all ()
  "Remove all marks."
  (interactive)
  (dolist (m my/marks) (set-marker m nil))
  (setq my/marks nil)
  (my/marks-update)
  (message "All marks cleared"))

(defun my/mark-line-preview (marker)
  "Return a short preview string for the line at MARKER."
  (when (marker-buffer marker)
    (with-current-buffer (marker-buffer marker)
      (save-excursion
        (goto-char (marker-position marker))
        (let ((text (string-trim (buffer-substring-no-properties
                                  (line-beginning-position) (line-end-position)))))
          (if (> (length text) 30)
              (concat (substring text 0 27) "...")
            text))))))

(defun my/mark-nearest-in (buf pos)
  "Return the marker in BUF nearest to POS, or nil."
  (let (best best-dist)
    (dolist (m my/marks)
      (when (eq (marker-buffer m) buf)
        (let ((d (abs (- (marker-position m) pos))))
          (when (or (null best) (< d best-dist))
            (setq best m best-dist d)))))
    best))

(defun my/mark-nearest ()
  "Return the marker in the current buffer nearest to point."
  (my/mark-nearest-in (current-buffer) (point)))

;;; Sidebar --------------------------------------------------------------------

(defconst my/marks-left-buf "*marks-left*")

(defun my/marks-window-setup (window)
  "Initialize a marks side window."
  (with-selected-window window
    (setq-local truncate-lines t)
    (setq-local mode-line-format nil)
    (setq-local header-line-format nil)
    (setq-local cursor-type nil)
    (buffer-disable-undo)
    (set-window-start window (point-min))
    (set-window-parameter window 'fixed-window-start t)
    (set-window-parameter window 'window-fixed-size 'width)
    (force-mode-line-update)))

(defun my/marks-render-left (editing-buf editing-pos)
  "Re-render the sidebar for EDITING-BUF at EDITING-POS."
  (let* ((nearest (my/mark-nearest-in editing-buf editing-pos))
         (valid-marks (cl-remove-if-not #'marker-buffer my/marks))
         (n (length valid-marks))
         (active-idx (and nearest (cl-position nearest valid-marks)))
         (win (get-buffer-window my/marks-left-buf)))
    (when win
      (with-current-buffer (get-buffer-create my/marks-left-buf)
        (let* ((inhibit-read-only t)
               (width (- (window-width win) 5))
               (bar (make-string (+ width 2) ?─)))
          (erase-buffer)
          (dotimes (i n)
            (let* ((m (nth i valid-marks))
                   (mbuf (marker-buffer m))
                   (ln (with-current-buffer mbuf
                         (line-number-at-pos (marker-position m))))
                   (fname (file-name-nondirectory
                           (or (buffer-file-name mbuf) (buffer-name mbuf))))
                   (preview (or (my/mark-line-preview m) ""))
                   (is-active (and active-idx (= i active-idx)))
                   (is-first (= i 0))
                   (is-prev-active (and active-idx (> i 0) (= (1- i) active-idx)))
                   (face (if is-active 'my/mark-tab-active-face 'my/mark-tab-face))
                   (kmap (make-sparse-keymap)))
              (define-key kmap [mouse-1]
                (let ((marker m))
                  (lambda (e)
                    (interactive "e")
                    (when (marker-buffer marker)
                      (select-window (window-main-window))
                      (switch-to-buffer (marker-buffer marker))
                      (goto-char (marker-position marker))
                      (my/marks-update)))))
              (unless is-first
                (insert "├" bar
                        (cond (is-active      "┘")
                              (is-prev-active "┐")
                              (t              "┤"))
                        "\n"))
              (insert "│ "
                      (propertize (truncate-string-to-width preview width 0 ?\s)
                                  'face face
                                  'mouse-face 'highlight
                                  'help-echo (format "%s:%d" fname ln)
                                  'local-map kmap)
                      (if is-active "  " " │")
                      "\n")))
          (when (> n 0)
            (insert "└" bar
                    (if (and active-idx (= (1- n) active-idx)) "┐" "┤")
                    "\n"))
          (dotimes (_ 1024)
            (insert (make-string (+ width 3) ?\s) "│\n")))))))

(defun my/marks-ensure-window ()
  "Open the sidebar window if not already visible."
  (unless (get-buffer-window my/marks-left-buf)
    (display-buffer-in-side-window
     (get-buffer-create my/marks-left-buf)
     `((side . left)
       (window-width . 22)
       (window-parameters . ((no-other-window . t)
                             (no-delete-other-windows . t)))
       (body-function . my/marks-window-setup)))))

(defun my/marks-update ()
  "Show/refresh sidebar, or close it when no marks remain."
  (my/marks-cleanup)
  (let ((editing-buf (current-buffer))
        (editing-pos (point)))
    (if my/marks
        (progn
          (my/marks-ensure-window)
          (my/marks-render-left editing-buf editing-pos))
      (when-let ((win (get-buffer-window my/marks-left-buf)))
        (delete-window win)))))

;;; Hooks ----------------------------------------------------------------------

(defun my/marks-post-command ()
  "Update active-mark highlight on cursor movement."
  (unless (string= (buffer-name) my/marks-left-buf)
    (when (and my/marks (get-buffer-window my/marks-left-buf))
      (my/marks-render-left (current-buffer) (point)))))

(add-hook 'post-command-hook #'my/marks-post-command)

(defun my/mark-cleanup-killed-buffer ()
  "Clean up marks when a buffer is killed."
  (let ((buf (current-buffer)))
    (setq my/marks (cl-remove-if (lambda (m) (eq (marker-buffer m) buf)) my/marks)))
  (my/marks-update))

(add-hook 'kill-buffer-hook #'my/mark-cleanup-killed-buffer)

;;; Navigation -----------------------------------------------------------------

(defvar my/mark-index -1
  "Current index in the global mark list.")

(defun my/mark-jump-next ()
  "Jump to the next mark."
  (interactive)
  (my/marks-cleanup)
  (when my/marks
    (setq my/mark-index (mod (1+ my/mark-index) (length my/marks)))
    (let ((m (nth my/mark-index my/marks)))
      (switch-to-buffer (marker-buffer m))
      (goto-char (marker-position m)))))

(defun my/mark-jump-prev ()
  "Jump to the previous mark."
  (interactive)
  (my/marks-cleanup)
  (when my/marks
    (setq my/mark-index (mod (1- my/mark-index) (length my/marks)))
    (let ((m (nth my/mark-index my/marks)))
      (switch-to-buffer (marker-buffer m))
      (goto-char (marker-position m)))))

(defun my/mark-remove-nearest ()
  "Remove the nearest mark to point in the current buffer."
  (interactive)
  (let ((nearest (my/mark-nearest)))
    (if nearest
        (progn
          (setq my/marks (delq nearest my/marks))
          (set-marker nearest nil)
          (my/marks-update)
          (message "Mark removed"))
      (message "No marks in this buffer"))))

;;; Keybindings ----------------------------------------------------------------

(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "m") #'my/mark-toggle)
  (define-key evil-normal-state-map (kbd "k") #'my/mark-remove-nearest)
  (define-key evil-normal-state-map (kbd "SPC k") #'my/mark-clear-all))

(global-set-key (kbd "M-<up>") #'my/mark-jump-next)
(global-set-key (kbd "M-<down>") #'my/mark-jump-prev)
