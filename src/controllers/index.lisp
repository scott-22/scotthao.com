(defpackage controllers
  (:use :cl)
  (:import-from :router
                :defroute))
(in-package controllers)

;; Routes
(defroute "/" :GET (env)
  '(200 (:content-type "text/plain") ("Hello World")))

;; Default error handlers
(defroute 404 (env)
  '(404 (:content-type "text/plain") ("404 Error")))
