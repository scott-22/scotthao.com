(in-package :templates)
(load "templates/utils.lisp")

(defun 404error ()
  (with-html
    (:doctype)
    (:html
     (:head
      (:title "Not found"))
     (:body
      (:p "404 Not found")))))
