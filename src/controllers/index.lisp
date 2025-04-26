(in-package controllers)

;; Routes
(defroute "/" :GET (env)
  `(200 (:content-type "text/html") ,(template "index" :static)))

(defroute "/writing" :GET (env)
  `(200
    (:content-type "text/html")
    ,(template
       "writing"
       :dynamic
       '("Featured article line"
         "Featured article line")
       '(("Title" "date" "filename") ("Title2" "date2" "filename2") ("Title2" "date2" "filename2") ("Title2" "date2" "filename2"))
       '(("Title" "date" "filename") ("Title2" "date2" "filename2")))))

(defroute "/writing/:article" :GET (env)
  `(200
    (:content-type "text/html")
    ,(let ((article (getf (getf env :route-params) :article)))
       (template
         (concatenate 'string "writing/" article)
         :static))))

;; Default error handlers
(defroute 404 (env)
  `(404 (:content-type "text/html") ,(template "404error" :static)))
