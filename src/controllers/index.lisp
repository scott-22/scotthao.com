(in-package controllers)

;; Helper functions

(defun valid-slug-p (slug)
  (and (stringp slug)
       (plusp (length slug))
       (every #'(lambda (char)
                  (or (alphanumericp char)
                      (char= char #\-)
                      (char= char #\_)))
              slug)))

(defun article-exists-p (article)
  (and (valid-slug-p article)
       (uiop:file-exists-p
         (make-pathname :directory '(:relative "templates" "static" "writing")
                        :name article
                        :type "lisp"))
       t))

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

(defroute "/" :HEAD (env)
  `(200 (:content-type "text/html") nil))

(defroute "/writing" :GET (env)
  `(200
    (:content-type "text/html")
    ,(let* ((featured (read-data "featured"))
            (featured-text (nth (random (length featured)) featured))
            (articles (read-data "articles"))
            (essays (read-data "essays")))
       (template
         "writing" :dynamic featured-text articles essays))))

(defroute "/writing" :HEAD (env)
  `(200 (:content-type "text/html") nil))

(defroute "/writing/:article" :GET (env)
  (let ((article (getf (getf env :route-params) :article)))
    (if (article-exists-p article)
        `(200
          (:content-type "text/html")
          ,(template
             (concatenate 'string "writing/" article)
             :static))
        404)))

(defroute "/writing/:article" :HEAD (env)
  (let ((article (getf (getf env :route-params) :article)))
    (if (article-exists-p article)
        `(200 (:content-type "text/html") nil)
        404)))

;; Default error handlers
(defroute 404 (env)
  `(404 (:content-type "text/html") ,(template "404error" :static)))
