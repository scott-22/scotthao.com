(in-package controllers)

;; Helper functions
(defun read-data (data-file)
  (with-open-file (stream
                   (make-pathname
                     :directory '(:relative "templates" "data")
                     :name data-file
                     :type "lisp")
                   :if-does-not-exist nil)
     (when stream (read stream nil nil))))

;; Routes
(defroute "/" :GET (env)
  `(200 (:content-type "text/html") ,(template "index" :static)))

(defroute "/writing" :GET (env)
  `(200
    (:content-type "text/html")
    ,(let* ((featured (read-data "featured"))
            (featured-text (nth (random (length featured)) featured))
            (articles (read-data "articles"))
            (essays (read-data "essays")))
       (template
         "writing" :dynamic featured-text articles essays))))

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
