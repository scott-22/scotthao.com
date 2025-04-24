(in-package :templates)
(load "templates/utils.lisp")

(defmacro body ()
  `(content
     (:header
      :class "mt-12"
      (page-title "Scott Hao")
      (page-text "Systems, AI, Psychology.")
      (page-text "Computer Science and Cognitive Science at the University of Waterloo."))
     (section
       (page-subtitle "Work")
       (section-block
         (section-item
           "Bloomberg"
           "aaaa"
           "Jan 2025 - Apr 2025"
           "https://www.bloomberg.com/")))
     (section
       (page-subtitle "Projects"))
     (section
       (page-subtitle "Contact"))
     (:footer
      :class "mt-12"
      (page-text
        (page-url "Made with λ" "https://github.com/scott-22/scotthao.ca")))))

(defun index ()
  (layout :body (body)))
