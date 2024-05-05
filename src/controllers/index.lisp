(in-package controllers)

;; Routes
(defroute "/" :GET (env)
  '(200 (:content-type "text/plain") ("Hello World")))

;; Default error handlers
(defroute 404 (env)
  `(404 (:content-type "text/html") ,(template "404error" :static)))
