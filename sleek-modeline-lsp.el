;;; sleek-modeline-lsp.el --- LSP segment for sleek-modeline -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Abidán Brito Clavijo
;; Author: Abidán Brito Clavijo <abidan.brito@gmail.com>
;; SPDX-License-Identifier: MIT

;;; Commentary:
;; Language Server Protocol segment for the `sleek-modeline' package.
;; Displays a small indicator when an LSP server is active in the current
;; buffer.  Supports both the built-in `eglot' and `lsp-mode' backends.
;;
;; The indicator is hook-driven and cached, so redraws cost nothing.

;;; Code:

(require 'sleek-modeline-core)

;; Optional dependencies, declared to silence the byte-compiler
;; NOTE(abi): these get loaded only if available.
(eval-when-compile
  (declare-function eglot-managed-p "eglot")
  (declare-function lsp-workspaces "lsp-mode")
  (declare-function nerd-icons-codicon "nerd-icons")
  (defvar eglot--managed-mode)
  (defvar lsp-mode))

(defvar sleek-modeline-lsp--enabled nil
  "Non-nil means LSP integration is enabled globally.
Used as a sentinel to ensure hooks are only installed once.")

(defvar-local sleek-modeline-lsp--cache nil
  "Cached propertized string for the LSP segment.
Nil means no LSP server is active in the current buffer.")

(defcustom sleek-modeline-lsp-symbol "LSP"
  "Symbol used to indicate an active LSP server.
Displayed when `nerd-icons' is not available or icons are disabled."
  :type 'string
  :group 'sleek-modeline)

(defcustom sleek-modeline-hide-lsp-inactive nil
  "Hide the LSP indicator in inactive modelines."
  :type 'boolean
  :group 'sleek-modeline)

(defface sleek-modeline-lsp-face
  '((t (:inherit success :weight bold)))
  "Face for the LSP indicator in `sleek-modeline'."
  :group 'sleek-modeline-faces)

(defconst sleek-modeline-lsp--lsp-mode-hooks
  '(lsp-before-initialize-hook
    lsp-after-initialize-hook
    lsp-after-uninitialized-functions
    lsp-before-open-hook
    lsp-after-open-hook)
  "Every `lsp-mode' hook we listen to for state changes.")

(defun sleek-modeline-lsp--icon ()
  "Return the LSP indicator glyph.
Uses a nerd-icon when available and icons are enabled, otherwise
falls back to `sleek-modeline-lsp-symbol'."
  (if (and sleek-modeline-show-icons (featurep 'nerd-icons))
      (nerd-icons-codicon "nf-cod-plug")
    sleek-modeline-lsp-symbol))

(defun sleek-modeline-lsp--format ()
  "Build the propertized LSP indicator string."
  (propertize (sleek-modeline-lsp--icon)
              'face 'sleek-modeline-lsp-face
              'help-echo "LSP server active"))

(defun sleek-modeline-lsp--eglot-update (&rest _)
  "Recompute the LSP cache from the current eglot state."
  (setq sleek-modeline-lsp--cache
        (when (and (featurep 'eglot)
                   (bound-and-true-p eglot--managed-mode))
          (sleek-modeline-lsp--format)))
  (force-mode-line-update))

(defun sleek-modeline-lsp--lsp-mode-update (&rest _)
  "Recompute the LSP cache from the current `lsp-mode' state.
Accepts any number of args so it can be used on both normal hooks
and abnormal hooks (like `lsp-after-uninitialized-functions',
which passes a workspace argument)."
  (setq sleek-modeline-lsp--cache
        (when (and (featurep 'lsp-mode)
                   (bound-and-true-p lsp-mode)
                   (lsp-workspaces))
          (sleek-modeline-lsp--format)))
  (force-mode-line-update))

(defun sleek-modeline-lsp ()
  "Return the propertized LSP indicator for the current buffer, or nil.
The value is read from a hook-driven cache; no work is done on redraw."
  (when sleek-modeline-lsp--cache
    (sleek-modeline--maybe-dim-or-hide
     sleek-modeline-lsp--cache
     sleek-modeline-hide-lsp-inactive)))

;;;###autoload
(defun sleek-modeline-lsp-enable ()
  "Enable LSP segment wiring.
Attaches to `eglot' and `lsp-mode' hooks so that LSP activity is
reflected automatically.  Call this once inside `sleek-modeline-mode'
activation.

Also seeds the cache in any buffer that is already LSP-managed at
enable time, so that existing connections show the marker without
the user having to restart the server."
  (unless sleek-modeline-lsp--enabled
    (setq sleek-modeline-lsp--enabled t)
    ;; eglot
    (add-hook 'eglot-managed-mode-hook
              #'sleek-modeline-lsp--eglot-update)

    ;; lsp-mode
    (dolist (hook sleek-modeline-lsp--lsp-mode-hooks)
      (add-hook hook #'sleek-modeline-lsp--lsp-mode-update))

    ;; Seed any buffer that's already LSP-managed before hooking in
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (cond
         ((bound-and-true-p eglot--managed-mode)
          (sleek-modeline-lsp--eglot-update))
         ((and (bound-and-true-p lsp-mode)
               (featurep 'lsp-mode)
               (fboundp 'lsp-workspaces)
               (lsp-workspaces))
          (sleek-modeline-lsp--lsp-mode-update)))))))

(defun sleek-modeline-lsp-disable ()
  "Disable LSP segment integration.
Removes global hooks and clears cached state in all buffers."
  (when sleek-modeline-lsp--enabled
    (setq sleek-modeline-lsp--enabled nil)
    (remove-hook 'eglot-managed-mode-hook
                 #'sleek-modeline-lsp--eglot-update)
    (dolist (hook sleek-modeline-lsp--lsp-mode-hooks)
      (remove-hook hook #'sleek-modeline-lsp--lsp-mode-update))
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (setq sleek-modeline-lsp--cache nil)))))

(provide 'sleek-modeline-lsp)
;;; sleek-modeline-lsp.el ends here
