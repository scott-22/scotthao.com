(in-package :templates)
(load "templates/utils.lisp")

(defmacro body ()
  `(content
    (page-title "Scott Hao")))

(defun index ()
  (layout :body (body)))
