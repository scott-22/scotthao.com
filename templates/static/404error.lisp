(in-package :templates)
(load "templates/utils.lisp")

(defmacro body ()
  `(with-html
     (:h1 "404")
     (:p "This page was not found")))

(defun 404error ()
  (layout :title "Not found - Scott Hao" :body (body)))
