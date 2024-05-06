(defpackage templater
  (:use :cl)
  (:import-from :uiop
                :file-exists-p)
  (:export :template))

(defpackage templates
  (:use :cl :spinneret :parenscript))

(in-package :templater)

;; Templates generate html using spinneret and must be defined inside the `templates` package

;; Each template defines a function, named the same as the file stem, that generates the html
;; Dynamic data should be passed in as args to this function, there should be no free variables
(defun template (file template-type &rest args)
  (unless (every #'alphanumericp file) (error "Template name must be alphanumeric"))
  (let* ((dir (ensure-directories-exist
               (make-pathname :directory '(:relative "templates" "compiled"))))
         (static (ecase template-type (:static t) (:dynamic nil)))
         (path (merge-pathnames
                (make-pathname :name (concatenate 'string
                                                  (if static "s_" "d_")
                                                  file)
                               :type "html")
                dir)))
    (unless (and static (file-exists-p path))
      (with-open-file (spinneret:*html* path :direction :output
                                             :if-exists :supersede
                                             :if-does-not-exist :create)
        (load (make-pathname :directory `(:relative "templates" ,(if static "static" "dynamic"))
                             :name file
                             :type "lisp"))
        (apply (values (intern (string-upcase file) :templates)) args)))
    path))
