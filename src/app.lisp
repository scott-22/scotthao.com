(defpackage app
  (:use :cl)
  (:import-from :lack
                :builder)
  (:export :make-app))
(in-package :app)

(defparameter *app*
  (lambda (env)
    (print (getf env :request-uri))
    '(200 (:content-type "text/plain") ("Hello World"))))

(defun make-app ()
  (builder
   :accesslog
   *app*))
