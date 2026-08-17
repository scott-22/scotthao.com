(in-package :templates)
(load "templates/utils.lisp")

(defmacro body ()
  `(content
     (header
       "404"
       (page-text "This page was not found."))))

(defun 404error ()
  (layout
    :title "Not found - Scott Hao"
    :description "This page was not found."
    :body (body)))
