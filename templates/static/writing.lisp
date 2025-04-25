(in-package :templates)
(load "templates/utils.lisp")

(defmacro body ()
  `(content
     (header
       "Writing"
       (page-text "This page was not found."))))

(defun writing ()
  (layout :title "Writing - Scott Hao" :body (body)))
