;;; -*- lexical-binding: t -*-
;; Package manager setup
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Vertico: vertical minibuffer completion
(unless (package-installed-p 'vertico)
  (package-refresh-contents)
  (package-install 'vertico))
(vertico-mode 1)

;; Orderless: flexible space-separated filtering
(unless (package-installed-p 'orderless)
  (package-install 'orderless))
(setq completion-styles '(orderless basic))
(setq orderless-smart-case t)

;; Ultra-scroll: smooth scrolling
(unless (package-installed-p 'ultra-scroll)
  (package-install 'ultra-scroll))
(require 'ultra-scroll)
(ultra-scroll-mode 1)

;; Company: autocomplete
(unless (package-installed-p 'company)
  (package-install 'company))
(require 'company)
(global-company-mode 1)
(setq company-idle-delay 0)
(setq company-minimum-prefix-length 1)
(define-key company-active-map (kbd "<tab>") 'company-complete-selection)
(define-key company-active-map (kbd "RET") nil)
(define-key company-active-map (kbd "<return>") nil)

;; Company-posframe: child frame tooltip (border support)
(unless (package-installed-p 'company-posframe)
  (package-install 'company-posframe))
(company-posframe-mode 1)

;; Ligatures (C++ releváns)
(unless (package-installed-p 'ligature)
  (package-install 'ligature))
(require 'ligature)
(ligature-set-ligatures 'c++-ts-mode
  '("->" "->*" ">>" "<<" ">=" "<=" "==" "!=" "||" "&&"
    "::" "..." "/*" "*/" "//" "++"))
(global-ligature-mode t)

;; Tree-sitter: install C++ grammar and remap to ts-mode
(setq treesit-font-lock-level 4)
(setq treesit-language-source-alist
      '((c "https://github.com/tree-sitter/tree-sitter-c")
        (cpp "https://github.com/tree-sitter/tree-sitter-cpp")))
(unless (treesit-language-available-p 'c)
  (treesit-install-language-grammar 'c))
(unless (treesit-language-available-p 'cpp)
  (treesit-install-language-grammar 'cpp))
(add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode))

;; Consult: interactive search with live preview
(unless (package-installed-p 'consult)
  (package-refresh-contents)
  (package-install 'consult))
(require 'consult)
(setq xref-show-xrefs-function #'consult-xref)
(setq xref-show-definitions-function #'consult-xref)

;; Doom themes
(unless (package-installed-p 'doom-themes)
  (package-install 'doom-themes))
(require 'doom-themes)
(load-theme 'doom-shades-of-purple t)

;; Nerd icons
(unless (package-installed-p 'nerd-icons)
  (package-refresh-contents)
  (package-install 'nerd-icons))
(require 'nerd-icons)
(unless (find-font (font-spec :family "Symbols Nerd Font Mono"))
  (nerd-icons-install-fonts t))

;; Doom modeline
(unless (package-installed-p 'doom-modeline)
  (package-refresh-contents)
  (package-install 'doom-modeline))
(require 'doom-modeline)
(setq doom-modeline-icon t
      doom-modeline-major-mode-icon t)

(doom-modeline-def-modeline 'my-minimal
  '(bar buffer-info-simple misc-info buffer-position vcs)
  '())

(defun my-doom-modeline ()
  (doom-modeline-set-modeline 'my-minimal 'default))

(add-hook 'doom-modeline-mode-hook #'my-doom-modeline)
(doom-modeline-mode 1)

;; diff-hl: git diff indicators in the fringe (after theme so faces are correct)
(unless (package-installed-p 'diff-hl)
  (package-refresh-contents)
  (package-install 'diff-hl))
(require 'diff-hl)
(global-diff-hl-mode 1)
(diff-hl-flydiff-mode 1)

;; Magit: git interface
(unless (package-installed-p 'magit)
  (package-refresh-contents)
  (package-install 'magit))
(with-eval-after-load 'magit
  (setq magit-section-initial-visibility-alist '((file . hide)))
  (setq magit-log-section-commit-count 30)
  (setq magit-diff-refine-hunk nil)
  (setq diff-font-lock-syntax 'magit-style)
  (require 'forge))

(unless (package-installed-p 'forge)
  (package-refresh-contents)
  (package-install 'forge))

;; Floating child frame for magit – make-frame alapú, nem posframe
(defvar my/magit-child-frame nil "Floating child frame for magit.")

(defun my/magit-child-frame--make ()
  "Létrehoz egy középre igazított, dísztelen child frame-t látható kerettel."
  (let* ((parent (selected-frame))
         (cw     (frame-char-width  parent))
         (ch     (frame-char-height parent))
         (pcols  (frame-width  parent))
         (prows  (frame-height parent))
         (fcols  (round (* pcols 0.85)))
         (frows  (round (* prows 0.85)))
         (left   (/ (- (* pcols cw) (* fcols cw)) 2))
         (top    (/ (- (* prows ch) (* frows ch)) 2)))
    (let ((frame
           (make-frame
            `((parent-frame             . ,parent)
              (width                    . ,fcols)
              (height                   . ,frows)
              (left                     . ,left)
              (top                      . ,top)
              (undecorated              . t)
              (child-frame-border-width . 3)
              (internal-border-width    . 0)
              (minibuffer               . nil)
              (tool-bar-lines           . 0)
              (menu-bar-lines           . 0)
              (vertical-scroll-bars     . nil)))))
      (set-face-attribute 'child-frame-border frame :background "#9d79d6")
      frame)))

;; display-buffer-alist: minden magit buffer a child frame-be megy
(defun my/magit-child-frame-condition (buf-name _action)
  (and (frame-live-p my/magit-child-frame)
       (with-current-buffer (get-buffer buf-name)
         (derived-mode-p 'magit-mode))))

(defun my/magit-child-frame-action (buf _alist)
  (let ((win (frame-selected-window my/magit-child-frame)))
    (with-selected-window win
      (switch-to-buffer buf))
    win))

(add-to-list 'display-buffer-alist
             '(my/magit-child-frame-condition
               (my/magit-child-frame-action)))

(defun my/magit-child-frame-close ()
  "Bezárja a child frame-t és visszaadja a fókuszt a parent frame-nek."
  (when (frame-live-p my/magit-child-frame)
    (let ((parent (frame-parent my/magit-child-frame)))
      (delete-frame my/magit-child-frame)
      (setq my/magit-child-frame nil)
      (when (frame-live-p parent)
        (select-frame-set-input-focus parent)))))

(defun my/magit-child-frame-toggle ()
  "SPC-y: floating magit-status child frame toggle.
- Nincs frame        → megnyitja magit-statussal
- Frame + status     → bezárja, fókusz vissza a parent frame-be
- Frame + más buffer → visszavált magit-statusra (nem zárja be)"
  (interactive)
  (cond
   ((not (frame-live-p my/magit-child-frame))
    (setq my/magit-child-frame (my/magit-child-frame--make))
    (with-selected-frame my/magit-child-frame
      (magit-status)))
   ((with-current-buffer (window-buffer (frame-selected-window my/magit-child-frame))
      (derived-mode-p 'magit-status-mode))
    (my/magit-child-frame-close))
   (t
    (with-selected-frame my/magit-child-frame
      (magit-status)))))

(defun my/magit-squash-diff-to-head ()
  "Megmutatja az összes diffet a kijelölt committól HEAD-ig (mintha squasholva lennének)."
  (interactive)
  (let ((commit (magit-commit-at-point)))
    (unless commit (user-error "Nincs commit a kurzor alatt"))
    (magit-diff-range (format "%s^..HEAD" commit))))


(with-eval-after-load 'magit
  ;; ~ bármely magit bufferben: squash diff a kijelölt committól HEAD-ig
  (define-key magit-mode-map (kbd "D") #'my/magit-squash-diff-to-head)
  ;; q a status bufferen bezárja a child frame-t;
  ;; sub-buffereken (log, diff) normálisan visszanavigál
  (advice-add 'magit-mode-bury-buffer :around
              (lambda (orig-fn &rest args)
                (if (and (frame-live-p my/magit-child-frame)
                         (eq (selected-frame) my/magit-child-frame)
                         (derived-mode-p 'magit-status-mode))
                    (my/magit-child-frame-close)
                  (apply orig-fn args)))))

;; Evil mode
(unless (package-installed-p 'evil)
  (package-install 'evil))
(setq evil-want-integration t)
(setq evil-want-keybinding nil)
(setq evil-cross-lines t)
(require 'evil)
(evil-mode 1)

;; Cursor shape: thin bar in insert, block in normal
(setq evil-insert-state-cursor '(bar . 2))
(setq evil-normal-state-cursor '(box))

;;(fringe-mode '(8 . 8))

;; Jira
(unless (package-installed-p 'jira)
  (package-refresh-contents)
  (package-install 'jira))
(setq auth-sources '("~/.authinfo"))
(setq jira-base-url "https://shapr3d.atlassian.net")
(setq jira-api-version 3)
(setq jira-detail-show-announcements nil)
(setq jira-issues-table-fields '(:key :issue-type-name :status-name :assignee-name :summary))

;; Floating child frame for jira – same approach as magit
(defvar my/jira-child-frame nil "Floating child frame for jira.")

(defun my/jira-child-frame--make ()
  (let* ((parent (selected-frame))
         (cw     (frame-char-width  parent))
         (ch     (frame-char-height parent))
         (pcols  (frame-width  parent))
         (prows  (frame-height parent))
         (fcols  (round (* pcols 0.85)))
         (frows  (round (* prows 0.85)))
         (left   (/ (- (* pcols cw) (* fcols cw)) 2))
         (top    (/ (- (* prows ch) (* frows ch)) 2)))
    (let ((frame
           (make-frame
            `((parent-frame             . ,parent)
              (width                    . ,fcols)
              (height                   . ,frows)
              (left                     . ,left)
              (top                      . ,top)
              (undecorated              . t)
              (child-frame-border-width . 3)
              (internal-border-width    . 0)
              (minibuffer               . nil)
              (tool-bar-lines           . 0)
              (menu-bar-lines           . 0)
              (vertical-scroll-bars     . nil)))))
      (set-face-attribute 'child-frame-border frame :background "#9d79d6")
      frame)))

(defun my/jira-child-frame-condition (buf-name _action)
  (and (frame-live-p my/jira-child-frame)
       (with-current-buffer (get-buffer buf-name)
         (derived-mode-p 'jira-issues-mode 'jira-detail-mode
                         'jira-edit-mode 'jira-tempo-mode))))

(defun my/jira-child-frame-action (buf _alist)
  (let ((win (frame-selected-window my/jira-child-frame)))
    (with-selected-window win
      (switch-to-buffer buf))
    win))

(add-to-list 'display-buffer-alist
             '(my/jira-child-frame-condition
               (my/jira-child-frame-action)))

(defun my/jira-child-frame-close ()
  (interactive)
  (when (frame-live-p my/jira-child-frame)
    (let ((parent (frame-parent my/jira-child-frame)))
      (delete-frame my/jira-child-frame)
      (setq my/jira-child-frame nil)
      (when (frame-live-p parent)
        (select-frame-set-input-focus parent)))))

(defun my/jira-child-frame-toggle ()
  "SPC-j: floating jira-issues child frame toggle."
  (interactive)
  (cond
   ((not (frame-live-p my/jira-child-frame))
    (setq my/jira-child-frame (my/jira-child-frame--make))
    (with-selected-frame my/jira-child-frame
      (jira-issues)))
   ((with-current-buffer (window-buffer (frame-selected-window my/jira-child-frame))
      (derived-mode-p 'jira-issues-mode))
    (my/jira-child-frame-close))
   (t
    (with-selected-frame my/jira-child-frame
      (jira-issues)))))

(defun my/jira-create-issue ()
  "Create a new issue in the LM project."
  (interactive)
  (let* ((project "LM")
         (types-key (if (= jira-api-version 3) 'issueTypes 'values))
         (response (jira-api-get-project-issue-types project :sync t))
         (types (append (alist-get types-key response) nil))
         (non-subtasks (cl-remove-if (lambda (item) (eq (alist-get 'subtask item) t)) types))
         (choices (mapcar (lambda (item)
                            (cons (alist-get 'name item) (alist-get 'id item)))
                          non-subtasks))
         (chosen-name (completing-read "Issue type: " (mapcar #'car choices) nil t))
         (type-id (cdr (assoc chosen-name choices))))
    (jira-complete-ask-issue-fields
     project type-id
     :callback #'jira-detail--create-issue-from-fields)))

(with-eval-after-load 'jira-issues
  (advice-add 'jira-issues--transient-default-value :override
              (lambda () '("--jql=project = LM ORDER BY created DESC")))
  (evil-define-key 'normal jira-issues-mode-map (kbd "q") #'my/jira-child-frame-close)
  (evil-define-key 'normal jira-issues-mode-map (kbd "N") #'my/jira-create-issue))

(defvar my/jira-current-key nil
  "Non-buffer-local fallback key for jira transient actions.")

(with-eval-after-load 'jira-utils
  (advice-add 'jira-utils-marked-item :around
              (lambda (orig)
                (or (funcall orig) my/jira-current-key))))

(with-eval-after-load 'jira-complete
  (advice-add 'jira-complete--ask-autocomplete :around
              (lambda (orig fname url is-array)
                (if (string= fname "Assignee")
                    (let* ((names (hash-table-keys jira-users))
                           (choices (cons "Unassigned" names))
                           (selected (completing-read "Assignee: " choices nil t)))
                      (if (string= selected "Unassigned")
                          nil
                        `((accountId . ,(gethash selected jira-users)))))
                  (funcall orig fname url is-array)))))

(with-eval-after-load 'jira-detail
  (advice-add 'jira-detail--update-field :override
              (lambda ()
                (let* ((field-alist jira-detail--updatable-fields)
                       (field-names (mapcar #'car field-alist))
                       (chosen (completing-read "Field to update: " field-names nil t))
                       (key jira-detail--current-key))
                  (when chosen
                    (jira-detail--ensure-update-metadata)
                    (cond
                     ((string= chosen "Description")
                      (jira-detail--edit-description-and-update))
                     ((string= chosen "Summary")
                      (let ((current (alist-get 'summary (alist-get 'fields jira-detail--current))))
                        (jira-edit-create-editor-buffer
                         "*Jira Edit Summary*"
                         current
                         (lambda (new-summary)
                           (jira-detail--update-field-action "summary" new-summary key)))))
                     ((or (string= chosen "Original Estimate")
                          (string= chosen "Remaining Estimate"))
                      (let* ((field-id (jira-detail--updatable-field-id chosen))
                             (value (read-string (format "Enter value for %s: " chosen))))
                        (jira-detail--update-timetracking-action field-id value key)))
                     (t
                      (let* ((field-id (jira-detail--updatable-field-id chosen))
                             (fields (alist-get 'fields jira-detail--current-update-metadata))
                             (field-metadata
                              (car (seq-filter
                                    (lambda (f) (string= (alist-get 'fieldId f) field-id))
                                    fields))))
                        (if field-metadata
                            (let ((value (jira-complete-ask-field field-metadata)))
                              (jira-detail--update-field-action field-id value key))
                          (message "Could not find metadata for field %s" field-id)))))))))
  (evil-define-key 'normal jira-detail-mode-map (kbd "C")
    (lambda () (interactive)
      (when jira-detail--current-key
        (setq my/jira-current-key jira-detail--current-key)
        (jira-api-get-transitions (list jira-detail--current-key))
        (transient-setup 'jira-actions-change-issue-menu))))
  (evil-define-key 'normal jira-detail-mode-map (kbd "q")
    (lambda () (interactive)
      (if (and (frame-live-p my/jira-child-frame)
               (get-buffer "*Jira Issues*"))
          (with-selected-frame my/jira-child-frame
            (switch-to-buffer "*Jira Issues*"))
        (kill-buffer (current-buffer))))))
