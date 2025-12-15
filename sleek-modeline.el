;;; sleek-modeline.el --- TODO -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Abidán Brito Clavijo

;; Author: Abidán Brito Clavijo <abidan.brito@gmail.com>
;; Version: 1.0
;; Package-Requires: ((emacs "26.1"))
;; Keywords: mode-line, faces
;; URL: https://github.com/abidanBrito/sleek-modeline
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; TODO(abi): this package provides a ...

;;; Code:

(defvar sleek-modeline-format
  '("%e"
    (:eval (buffer-name))
    "  "
    (:eval (symbol-name major-mode)))
  "The sleek mode-line format.")

(defvar sleek-modeline--default-mode-line mode-line-format
  "Storage for the default `mode-line-format'.")

;;;###autoload
(define-minor-mode sleek-modeline-mode
  "Toggle sleek mode-line on or off."
  :global t
  :group 'sleek-modeline
  (if sleek-modeline-mode
      (progn
        (setq sleek-modeline--default-mode-line mode-line-format)
        (setq-default mode-line-format sleek-modeline-format))
    (setq-default mode-line-format sleek-modeline--default-mode-line))
  (force-mode-line-update t))

(provide 'sleek-modeline)

;;; sleek-modeline.el ends here
