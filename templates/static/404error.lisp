(in-package :templates)
(load "templates/utils.lisp")

(defmacro body ()
  `(content
     (page-title "404")
     (:p "This page was not found")))

(defun 404error ()
  (layout :title "Not found - Scott Hao" :body (body)))
