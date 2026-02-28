;;; sleek-modeline.el --- Minimal and elegant modeline -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Abidán Brito Clavijo

;; Author: Abidán Brito Clavijo <abidan.brito@gmail.com>
;; Version: 1.0
;; Package-Requires: ((emacs "26.1"))
;; Keywords: mode-line, faces
;; URL: https://github.com/abidanBrito/sleek-modeline
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; This package provides a minimal and elegant modeline replacement.

;;; Code:

(require 'sleek-modeline-core)
(require 'sleek-modeline-vc)
(require 'sleek-modeline-diagnostics)

(defvar sleek-modeline-format
  '("%e"
    " "
    (:eval (when-let ((marker (sleek-modeline-modal-state-marker)))
             (concat marker " ")))
    (:eval (sleek-modeline-buffer-name))
    mode-line-format-right-align
    (:eval (when-let ((diag (sleek-modeline-diagnostics)))
             (concat diag (sleek-modeline--separator))))
    (:eval (when-let ((eol (sleek-modeline-line-ending-indicator)))
             (unless (string-empty-p eol)
               (concat eol (sleek-modeline--separator)))))
    (:eval (when-let ((vc (sleek-modeline-vc)))
             (concat vc (sleek-modeline--separator))))
    (:eval (sleek-modeline-major-mode))
    " ")
  "The sleek mode-line format.")

(defvar sleek-modeline--default-mode-line mode-line-format
  "Storage for the default `mode-line-format'.")

(defun sleek-modeline--after-theme-change (&rest _)
  "Update faces after theme change."
  (run-with-timer 0.1 nil #'sleek-modeline--update-faces))

;;;###autoload
(define-minor-mode sleek-modeline-mode
  "Toggle sleek modeline on and off."
  :global t
  :group 'sleek-modeline
  (if sleek-modeline-mode
      (progn
        (setq sleek-modeline--default-mode-line mode-line-format)
        (setq-default mode-line-format sleek-modeline-format)
        
        (add-hook 'after-load-theme-hook #'sleek-modeline--update-faces)
        (advice-add 'load-theme :after #'sleek-modeline--after-theme-change)
        (advice-add 'enable-theme :after #'sleek-modeline--after-theme-change)

	(sleek-modeline-diagnostics-setup)
        (sleek-modeline--update-faces))
    
    (setq-default mode-line-format sleek-modeline--default-mode-line)
    
    (remove-hook 'after-load-theme-hook #'sleek-modeline--update-faces)
    (advice-remove 'load-theme #'sleek-modeline--after-theme-change)
    (advice-remove 'enable-theme #'sleek-modeline--after-theme-change)
    
    (when (facep 'mode-line)
      (set-face-attribute 'mode-line nil
			  :box 'unspecified
			  :overline 'unspecified
			  :underline 'unspecified))

    (when (facep 'mode-line-inactive)
      (set-face-attribute 'mode-line-inactive nil
			  :box 'unspecified
			  :overline 'unspecified
			  :underline 'unspecified)))
  
  (force-mode-line-update t))

(provide 'sleek-modeline)
;;; sleek-modeline.el ends here
