;;; init-magit.el --- Initialize magit interface to git
;; -----------------------------------------------------------------------------

(add-to-list 'load-path (expand-file-name  "~/.emacs.d/packages/magit"))
(add-to-list 'Info-directory-list
             (expand-file-name "~/.emacs.d/packages/magit") t)

(require 'magit)

(define-key my-map "g" 'magit-status)

;; -----------------------------------------------------------------------------
;;; init-magit.el ends here