;;; marks.el --- Visual mark bar in header-line  -*- lexical-binding: t; -*-
(defface my/mark-tab-face
  '((t :background "#3B3363" :foreground "#CCCCCC" :box (:line-width (4 . 2) :color "#3B3363")))
  "Face for mark tabs in the header line.")

(defface my/mark-tab-active-face
  '((t :background "#5D3FD3" :foreground "white" :box (:line-width (4 . 2) :color "#5D3FD3")))
  "Face for the nearest mark tab in the header line.")

(defvar my/marks nil
  "Global list of markers placed by the user.")

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
      (let ((m (point-marker)))
        (setq my/marks (append my/marks (list m)))
        (message "Mark placed")))
    (my/marks-cleanup)
    (force-mode-line-update t)))

(defun my/marks-cleanup ()
  "Remove dead markers, preserving creation order."
  (setq my/marks (cl-remove-if-not #'marker-buffer my/marks)))

(defun my/mark-clear-all ()
  "Remove all marks."
  (interactive)
  (dolist (m my/marks) (set-marker m nil))
  (setq my/marks nil)
  (force-mode-line-update t)
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

(defun my/mark-nearest ()
  "Return the marker in the current buffer nearest to point, or nil."
  (let ((buf (current-buffer))
        (pos (point))
        best best-dist)
    (dolist (m my/marks)
      (when (eq (marker-buffer m) buf)
        (let ((d (abs (- (marker-position m) pos))))
          (when (or (null best) (< d best-dist))
            (setq best m best-dist d)))))
    best))

(defun my/mark-header-line ()
  "Build the header-line string showing all marks across all buffers."
  (if (null my/marks)
      nil
    (let ((nearest (my/mark-nearest))
          (cur-buf (current-buffer))
          (parts nil))
      (dolist (m my/marks)
        (when (marker-buffer m)
          (let* ((mbuf (marker-buffer m))
                 (ln (with-current-buffer mbuf
                       (line-number-at-pos (marker-position m))))
                 (fname (file-name-nondirectory
                         (or (buffer-file-name mbuf) (buffer-name mbuf))))
                 (preview (my/mark-line-preview m))
                 (label (if (eq mbuf cur-buf)
                            (format "L%d: %s" ln preview)
                          (format "%s:%d: %s" fname ln preview)))
                 (face (if (eq m nearest) 'my/mark-tab-active-face 'my/mark-tab-face))
                 (map (make-sparse-keymap)))
            (define-key map [header-line mouse-1]
                        (let ((marker m))
                          (lambda (e)
                            (interactive "e")
                            (when (marker-buffer marker)
                              (switch-to-buffer (marker-buffer marker))
                              (goto-char (marker-position marker))))))
            (push (propertize label 'face face
                              'mouse-face 'highlight
                              'local-map map
                              'help-echo (format "%s:%d - click to jump" fname ln))
                  parts))))
      (mapconcat #'identity (nreverse parts) " "))))

(defun my/mark-setup-header-line ()
  "Set header-line-format to show marks."
  (setq header-line-format '(:eval (my/mark-header-line))))

(add-hook 'prog-mode-hook #'my/mark-setup-header-line)
(add-hook 'text-mode-hook #'my/mark-setup-header-line)

;; Update header line when point moves so the active mark updates
(defun my/mark-update-header (&rest _)
  (when my/marks (force-mode-line-update t)))
(add-hook 'post-command-hook #'my/mark-update-header)

;; Clean up marks when a buffer is killed
(defun my/mark-cleanup-killed-buffer ()
  (let ((buf (current-buffer)))
    (setq my/marks (cl-remove-if (lambda (m) (eq (marker-buffer m) buf)) my/marks)))
  (force-mode-line-update t))
(add-hook 'kill-buffer-hook #'my/mark-cleanup-killed-buffer)

(defvar my/mark-index -1
  "Current index in the global mark list.")

(defun my/mark-jump-next ()
  "Jump to the next mark in the global list."
  (interactive)
  (my/marks-cleanup)
  (when my/marks
    (setq my/mark-index (mod (1+ my/mark-index) (length my/marks)))
    (let ((m (nth my/mark-index my/marks)))
      (switch-to-buffer (marker-buffer m))
      (goto-char (marker-position m)))))

(defun my/mark-jump-prev ()
  "Jump to the previous mark in the global list."
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
          (force-mode-line-update t)
          (message "Mark removed"))
      (message "No marks in this buffer"))))

;; Keybindings in evil normal mode
(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "m") #'my/mark-toggle)
  (define-key evil-normal-state-map (kbd "k") #'my/mark-remove-nearest)
  (define-key evil-normal-state-map (kbd "SPC k") #'my/mark-clear-all))

;; cmd-up/down to navigate between marks
(global-set-key (kbd "M-<up>") #'my/mark-jump-next)
(global-set-key (kbd "M-<down>") #'my/mark-jump-prev)
