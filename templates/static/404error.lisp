(in-package :templates)

(defun 404error ()
  (with-html
    (:doctype)
    (:html
     (:head
      (:title "Not found"))
     (:body
      (:p "404 Not found")))))
