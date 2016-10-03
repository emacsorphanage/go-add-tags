;;; test.el --- test of go-add-tags

;; Copyright (C) 2016 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>

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

;;; Code:

(require 'ert)
(require 'go-add-tags)

(defmacro with-go-temp-buffer (code &rest body)
  "Insert `code'. cursor is beginning of buffer"
  (declare (indent 0) (debug t))
  `(with-temp-buffer
     (insert ,code)
     (goto-char (point-min))
     ,@body))

(ert-deftest tag-string ()
  "internal function go-add-tags--tags-string"
  (let ((got (go-add-tags--tag-string '("datastore") "foo_bar"))
        (expected "datastore:\"foo_bar\""))
    (should (string= got expected)))

  (let ((got (go-add-tags--tag-string '("json" "yaml") "foo_bar"))
        (expected "json:\"foo_bar\" yaml:\"foo_bar\""))
    (should (string= got expected))))

(ert-deftest tag-exist-p ()
  "internal function go-add-tags--tag-exist-p"
  (with-go-temp-buffer
    "
type Foo struct {
        BarBaz string `json:\"bar_baz\"`
        Apple  Fruit
}
"
    (search-forward "BarBaz")
    (should (go-add-tags--tag-exist-p))

    (forward-line +1)
    (should-not (go-add-tags--tag-exist-p))))

(ert-deftest insert-tags ()
  "internal function go-add-tags--insert-tags"
  (with-go-temp-buffer
    "
type Foo struct {
        BarBaz string
        Apple  Fruit  `yaml:\"apple\"`
}
"
    (search-forward "BarBaz")
    (go-add-tags--insert-tags
     '("json") (line-beginning-position) (line-end-position) #'s-lower-camel-case)
    (let ((line (buffer-substring (line-beginning-position) (line-end-position))))
      (should (s-contains? "`json:\"barBaz\"`" line)))

    (forward-line +1)
    (go-add-tags--insert-tags
     '("json") (line-beginning-position) (line-end-position) #'s-snake-case)
    (let ((line (buffer-substring (line-beginning-position) (line-end-position))))
      (should (s-contains? "`yaml:\"apple\" json:\"apple\"`" line)))))

(ert-deftest replace-tags ()
  "internal function go-add-tags--insert-tags in replacing case"
  (with-go-temp-buffer
    "
type Foo struct {
        BarBaz string `json:\"barbaz\"`
        AppleOrange  Fruit  `yaml:\"apple_orange\" json:\"apple_orange\"`
}
"
    (search-forward "BarBaz")
    (go-add-tags--insert-tags
     '("json") (line-beginning-position) (line-end-position) #'s-lower-camel-case)
    (let ((line (buffer-substring (line-beginning-position) (line-end-position))))
      (should (s-contains? "`json:\"barBaz\"`" line)))

    (forward-line +1)
    (go-add-tags--insert-tags
     '("json" "yaml") (line-beginning-position) (line-end-position) #'s-snake-case)
    (let ((line (buffer-substring (line-beginning-position) (line-end-position))))
      (should (s-contains? "`yaml:\"apple_orange\" json:\"apple_orange\"`" line)))))

(ert-deftest nested-tag ()
  "Insert tag for nested struct
https://github.com/syohex/emacs-go-add-tags/issues/4"
  (with-go-temp-buffer
    "
type APIErr struct {
    Message string
    Errors  []struct {
        Resource string
        Code     string
    }
}
"
    (let ((expected "
type APIErr struct {
    Message string `json:\"message\"`
    Errors  []struct {
        Resource string `json:\"resource\"`
        Code     string `json:\"code\"`
    } `json:\"errors\"`
}
"))

      (forward-line 1)
      (go-add-tags--insert-tags
       '("json") (point) (point-max) #'s-lower-camel-case)
      (should (string= (buffer-string) expected)))))

;;; test.el ends here
