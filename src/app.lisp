(defpackage site
  (:use :cl)
  (:import-from :lack
                :builder)
  (:import-from :cl-ppcre
                :split)
  (:export :make-app))
(in-package :site)

(defparameter *app*
  (lambda (env)
    (print (getf env :request-uri))
    '(200 (:content-type "text/plain") ("Hello World"))))

(defun make-app ()
  (builder
   :accesslog
   *app*))
