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

(defun get-cookie (env name)
  (let* ((headers (getf env :headers))
         (header (and headers (gethash "cookie" headers))))
    (when header
      (loop for pair in (cl-ppcre:split ";\\s*" header)
            for (key value) = (cl-ppcre:split "=" pair :limit 2)
            when (string= key name) return value))))

(defun pick-featured (n seen)
  (let* ((full (1- (ash 1 n)))
         (seen (logand seen full))
         (unseen (or (loop for i below n unless (logbitp i seen) collect i)
                     (loop for i below n collect i)))
         (pick (nth (random (length unseen)) unseen))
         (new (logior seen (ash 1 pick))))
    (values pick (if (= new full) (ash 1 pick) new))))

;; Routes
(defroute "/" :GET (env)
  `(200 (:content-type "text/html") ,(template "index" :static)))

(defroute "/" :HEAD (env)
  `(200 (:content-type "text/html") nil))

(defroute "/writing" :GET (env)
  (let* ((featured (read-data "featured"))
         (seen (or (parse-integer (or (get-cookie env "fq") "")
                                  :radix 16 :junk-allowed t)
                   0)))
    (multiple-value-bind (idx mask) (pick-featured (length featured) seen)
      `(200
        (:content-type "text/html"
         :set-cookie ,(format nil "fq=~x; Path=/writing; Max-Age=2592000; SameSite=Lax" mask))
        ,(template
           "writing" :dynamic (nth idx featured) (read-data "articles") (read-data "essays"))))))

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
