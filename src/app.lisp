(defpackage site
  (:use :cl)
  (:import-from :lack
                :builder)
  (:export :make-app))
(in-package :site)

(defparameter *app*
  (lambda (env)
    '(200 (:content-type "text/plain") ("Hello World"))))

(defun make-app ()
  (builder
   :accesslog
   *app*))
