(defpackage app
  (:use :cl)
  (:import-from :lack
                :builder)
  (:import-from :router
                :route)
  (:export :make-app))
(in-package :app)

(defparameter *app*
  #'(lambda (env) (route env)))

(defun make-app ()
  (builder
   :accesslog
   *app*))
