;;;; Helpers to use within the REPL (e.g SLIME) for local development.
;;;; This file is meant to be loaded by start script.

(defun clear-templates ()
  (uiop:delete-directory-tree
   (make-pathname :directory '(:relative "templates" "compiled"))
   :validate t
   :if-does-not-exist :ignore))

(defun generate-styles ()
  ;; Tailwind --watch flag isn't working in Docker
  (uiop:run-program "./tailwindcss -i ./public/styles.css -o ./public/layout.css"))

(defun reload-site ()
  (progn
    (clear-templates)
    (generate-styles)))

;; Aliases for easier typing
(setf (fdefinition 'clrt) #'clear-templates)
(setf (fdefinition 'gnst) #'generate-styles)
(setf (fdefinition 'rl) #'reload-site)
