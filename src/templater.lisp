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
  (let ((dir (ensure-directories-exist
               (make-pathname :directory '(:relative "templates" "compiled"))))
        (static (ecase template-type (:static t) (:dynamic nil)))
        (file-id (substitute #\_ #\/ file)))
    (if static
        (let ((path (merge-pathnames (make-pathname :name file-id :type "html") dir)))
          (unless (file-exists-p path)
            (with-open-file (spinneret:*html* path :direction :output
                                                   :if-exists :supersede
                                                   :if-does-not-exist :create)
              (load (make-pathname :directory '(:relative "templates" "static")
                                   :name file
                                   :type "lisp"))
              (apply (values (intern (string-upcase file-id) :templates)) args)))
          path)
        (list
          (with-output-to-string (spinneret:*html*)
            (load (make-pathname :directory '(:relative "templates" "dynamic")
                                 :name file
                                 :type "lisp"))
            (apply (values (intern (string-upcase file-id) :templates)) args))))))
