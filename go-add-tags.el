;;; go-add-tags.el --- Add field tags for struct fields -*- lexical-binding: t; -*-

;; Copyright (C) 2016 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-go-add-tags
;; Version: 0.01
;; Package-Requires: ((emacs "24") (s "1.11.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Add field tags(ex json, yaml, toml, datastore) for struct fields.
;; This package is inspired by vim-go's GoAddTags command

;;; Code:

(require 's)

(defgroup go-add-tags nil
  "Add field tag for struct fields."
  :group 'go)

(defcustom go-add-tags-conversion 'snake-case
  "How to convert field in tag from field name."
  :type '(choice (const :tag "snake_case" snake-case)
                 (const :tag "camelCase" lower-camel-case)
                 (const :tag "UpperCamelCase" upper-camel-case)
                 (const :tag "Use original field name" original)))

(defvar go-add-tags--convertion-function
  '((snake-case . s-snake-case)
    (camel-case . s-lower-camel-case)
    (upper-camel-case . s-upper-camel-case)
    (original . identity)))

(defun go-add-tags--inside-struct-p (begin)
  (save-excursion
    (goto-char begin)
    (ignore-errors
      (backward-up-list))
    (looking-back "struct\\s-*" (line-beginning-position))))

(defun go-add-tags--tag-string (tags field)
  (mapconcat (lambda (tag)
               (format "%s:\"%s\"" tag field))
             tags
             " "))

(defun go-add-tags--tag-exist-p ()
  (let ((line (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
    (string-match-p "`[^`]+`" line)))

(defun go-add-tags--insert-tags (tags begin end conv-func)
  (save-excursion
    (let ((end-line (line-number-at-pos end)))
      (goto-char begin)
      (goto-char (line-beginning-position))
      (while (and (<= (line-number-at-pos) end-line) (not (eobp)))
        (let ((bound (line-end-position)))
          (when (re-search-forward "^\\s-*\\(\\S-+\\)\\s-+\\(\\S-+\\)" nil bound)
            (goto-char (min bound (match-end 2)))
            (let* ((field (funcall conv-func (match-string-no-properties 1)))
                   (tag (go-add-tags--tag-string tags field))
                   (exist-p (go-add-tags--tag-exist-p)))
              (if (not exist-p)
                  (setq tag (format "`%s`" tag))
                (search-forward "`" (line-end-position) t 2)
                (backward-char 1))
              (insert " " tag))))
        (forward-line 1)))))

(defun go-add-tags--read-convertion-function ()
  (let* ((candidates (mapcar #'car go-add-tags--convertion-function))
         (convertion (completing-read "How to convert: " candidates nil t)))
    (assoc-default (intern convertion) go-add-tags--convertion-function)))

;;;###autoload
(defun go-add-tags (tags begin end)
  (interactive
   (list
    (let ((tags (completing-read "Tags: " '(json yaml toml))))
      (if (string-match-p "," tags)
          (mapcar #'s-trim (s-split "," tags t))
        (list tags)))
    (or (and (use-region-p) (region-beginning)) (line-beginning-position))
    (or (and (use-region-p) (region-end)) (line-end-position))))
  (deactivate-mark)
  (let ((inside-struct-p (go-add-tags--inside-struct-p begin)))
    (unless inside-struct-p
      (error "Here is not struct"))
    (let ((conv-func
           (if current-prefix-arg
               (go-add-tags--read-convertion-function)
             (assoc-default go-add-tags-conversion go-add-tags--convertion-function))))
      (go-add-tags--insert-tags tags begin end conv-func))))

(provide 'go-add-tags)

;;; go-add-tags.el ends here
