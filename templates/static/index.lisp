(in-package :templates)
(load "templates/utils.lisp")

(defmacro body ()
  `(with-html
     (:h1 "Scott Hao")))

(defun index ()
  (layout :body (body)))
