;;; init-shell.el --- shell-mode settings
;; -----------------------------------------------------------------------------

;;;  Support for getting the cwd from the prompt
(use-package dirtrack
  :ensure t
  :init
  ;; Filter to get the cwd from the prompt
  (setq-default dirtrack-list '("^|\\([^|]*\\)|" 1 nil))

  (defun dirtrack-filter-out-pwd-prompt (string)
    "Remove the CWD from the prompt."
    (if (and (stringp string) (string-match (first dirtrack-list) string))
        (replace-match "" t t string 0)
      string)))

;;;  Show colors in shell windows:
(setq ansi-color-names-vector ; better contrast colors
      ["black" "red4" "green4" "yellow4" "blue3" "magenta4" "cyan4" "white"])

;;;  General settings for `comint'
(setq comint-prompt-read-only t           ; make the prompt read-only
      comint-scroll-to-bottom-on-input t  ; always insert at the bottom
      comint-scroll-to-bottom-on-output t ; always add output at the bottom
      comint-scroll-show-maximum-output t ; scroll to show max possible output
      comint-completion-autolist nil      ; show completion list when ambiguous
      comint-input-ignoredups t           ; no duplicates in command history
      comint-completion-addsuffix t       ; insert space/slash after file completion
      comint-buffer-maximum-size 1024     ; maximum size in lines for Comint buffers.
      )

;; Truncate the shell buffer to 1024 lines
(add-hook 'comint-output-filter-functions 'comint-truncate-buffer)

(defun comint-fix-window-size ()
  "Change process window size."
  (when (derived-mode-p 'comint-mode)
    (let ((process (get-buffer-process (current-buffer))))
      (unless (eq nil process)
        (set-process-window-size process (window-height) (window-width))))))

(use-package shell
  :ensure t
  :init
  (defun my-shell-mode-hook ()

    (font-lock-mode 1)

    ;; Get the cwd from the prompt rather than by tracking 'cd' commands
    (shell-dirtrack-mode -1)
    (dirtrack-mode 1)
    (add-hook 'comint-preoutput-filter-functions
              'dirtrack-filter-out-pwd-prompt t t)

    ;; Show the current directory in the mode-line
    (add-to-list
     'mode-line-buffer-identification
     '(:propertize (" " default-directory " ") face dired-directory))

    ;; Inform the shell of the window size initially and following resize
    (comint-fix-window-size)
    (add-hook 'window-configuration-change-hook 'comint-fix-window-size nil t)

    (use-package readline-complete
      :ensure t
      :init
      (setq explicit-shell-file-name "bash"
            explicit-bash-args '("-c" "export EMACS=; stty echo; bash")
            comint-process-echoes t)
      (push 'company-readline company-backends)
      (add-hook 'rlc-no-readline-hook (lambda () (company-mode -1)))
      :bind (:map shell-mode-map ("<tab>" . company-complete)))

    (company-mode 1))

  (add-hook 'shell-mode-hook 'my-shell-mode-hook))

(defun shell-dwim (&optional create)
  "Start or switch to an inferior shell process, in a smart way.
 If a buffer with a running shell process exists, simply switch to
 that buffer.
 If a shell buffer exists, but the shell process is not running,
 restart the shell.
 If already in an active shell buffer, switch to the next one, if
 any.

 With prefix argument CREATE always start a new shell."
  (interactive "P")
  (let* ((next-shell-buffer
          (catch 'found
            (dolist (buffer (reverse (buffer-list)))
              (when (string-match "^\\*shell\\*" (buffer-name buffer))
                (throw 'found buffer)))))
         (buffer (if create
                     (generate-new-buffer-name "*shell*")
                   next-shell-buffer)))
    (shell buffer)))

;;(global-set-key [f4] 'shell-dwim)

(defun jump-to-compilation-error-in-shell()
  "From a shell buffer, copy the output of the last
command (make, ant, etc.) to a temporary compilation output
buffer and jump to any errors cited in the output using
`compilation-minor-mode'."
  (interactive)
  (assert (eq major-mode 'shell-mode)
          "Can only process compilation errors from a shell buffer")
  (goto-char (point-max))
  (let* ((end (save-excursion (forward-line 0)(point)))
         (start (save-excursion
                  (comint-previous-prompt 1)(forward-line 1)(point)))
         (out (get-buffer-create "*shell-compilation-output*"))
         (output (buffer-substring-no-properties start end))
         (shell-window (get-buffer-window (current-buffer) (selected-frame))))
    (with-current-buffer out
      (erase-buffer)
      (insert "Compilation mode skips the first\n2 lines...\n")
      (setq truncate-lines nil)
      (insert output)
      (compilation-minor-mode 1)
      (goto-char (point-min))
      (display-buffer out shell-window)
      (next-error))))

(define-key shell-mode-map [f9] 'jump-to-compilation-error-in-shell)

;; --------------------------------------------------------------------------
;;; sh-mode: for editing sh/bash scripts

(use-package sh-script
  :ensure t
  :init
  (defun my-sh-mode-hook ()
    (font-lock-mode 1))
  (add-hook 'sh-mode-hook 'my-sh-mode-hook)

  ;; Better commenting/un-commenting
  :bind (:map sh-mode-map ("\C-c\C-c" . comment-dwim-line)))

;;; Make scripts executable on save
(defun my-make-script-executable ()
  "If file starts with a shebang, make `buffer-file-name' executable"
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (when (and (looking-at "^#!")
                 (not (file-executable-p buffer-file-name)))
        (set-file-modes buffer-file-name
                        (logior (file-modes buffer-file-name) #o100))
        (message (concat "Made " buffer-file-name " executable"))))))

(add-hook 'after-save-hook 'my-make-script-executable)

;; --------------------------------------------------------------------------
;;; init-shell.el ends here
