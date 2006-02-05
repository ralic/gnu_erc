;;; erc-spelling.el --- use flyspell in ERC

;; Copyright (C) 2005, 2006  Free Software Foundation, Inc.

;; Author: Jorgen Schaefer <forcer@forcix.cx>
;; Keywords: irc
;; URL: http://www.emacswiki.org/cgi-bin/wiki.pl?ErcSpelling

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This is an ERC module to enable flyspell mode in ERC buffers. This
;; ensures correct behavior of flyspell, and even sets up a
;; channel-local dictionary if so required.

;;; Code:

(require 'erc)
(require 'flyspell)

(defconst erc-spelling-version "$Revision: 1.10 $"
  "ERC spelling revision.")

;;;###autoload (autoload 'erc-spelling-mode "erc-spelling" nil t)
(define-erc-module spelling nil
  "Enable flyspell mode in ERC buffers."
  ;; Use erc-connect-pre-hook instead of erc-mode-hook as pre-hook is
  ;; called AFTER the server buffer is initialized.
  ((add-hook 'erc-connect-pre-hook 'erc-spelling-init)
   (mapc (lambda (buffer)
           (with-current-buffer buffer (erc-spelling-init)))
         (erc-buffer-list)))
  ((remove-hook 'erc-connect-pre-hook 'erc-spelling-init)
   (mapc (lambda (buffer)
           (with-current-buffer buffer (flyspell-mode 0)))
         (erc-buffer-list))))

(defcustom erc-spelling-dictionaries nil
  "An alist mapping buffer names to dictionaries.
The `car' of every cell is a buffer name, the `cadr' is the
string name of an associated dictionary.
The dictionary is inherited from server buffers, so if you want a
default dictionary for some server, you can use a server buffer
name here."
  :type '(choice (const nil)
                 (repeat (cons (string :tag "Buffer name")
                               (string :tag "Dictionary"))))
  :group 'erc-spelling)

(defun erc-spelling-init ()
  "Enable flyspell mode in an ERC buffer."
  (let ((name (downcase (buffer-name)))
        (dicts erc-spelling-dictionaries))
    (when dicts
      (while (and dicts
                  (not (string= name (downcase (caar dicts)))))
        (setq dicts (cdr dicts)))
      (setq ispell-local-dictionary
            (if dicts
                (cadr (car dicts))
              (let ((server (erc-server-buffer)))
                (if server
                    (with-current-buffer server
                      ispell-local-dictionary)
                  nil))))))
  (setq flyspell-generic-check-word-p 'erc-spelling-flyspell-verify)
  (flyspell-mode 1))

(defun erc-spelling-unhighlight-word (word)
  "Unhighlight the given WORD.
The cadr is the beginning and the caddr is the end."
  (let ((beg (nth 1 word))
        (end (nth 2 word)))
    (flyspell-unhighlight-at beg)
    (when (> end beg)
      (flyspell-unhighlight-at (1- end)))))

(defun erc-spelling-flyspell-verify ()
  "Flyspell only the input line, nothing else."
  (let ((word-data (and (boundp 'flyspell-word)
                        flyspell-word)))
    (when word-data
      (cond ((< (point) erc-input-marker)
             nil)
            ;; don't spell-check names of users
            ((and erc-channel-users
                  (erc-get-channel-user (car word-data)))
             (erc-spelling-unhighlight-word word-data)
             nil)
            ;; if '/' occurs before the word, don't spell-check it
            ((eq (char-before (nth 1 word-data)) ?/)
             (erc-spelling-unhighlight-word word-data)
             nil)
            (t t)))))

(put 'erc-mode
     'flyspell-mode-predicate
     'erc-spelling-flyspell-verify)

(provide 'erc-spelling)

;; arch-tag: 04ae1c46-0fd1-4e1a-8b80-55bfa471c945
;;; erc-spelling.el ends here
