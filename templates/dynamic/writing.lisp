(in-package :templates)
(load "templates/utils.lisp")

(defmacro head ()
  `(with-html
     (:script :type "text/javascript" :src "public/scramble.js")
     (:script
      :type "text/javascript"
      (:raw (ps
        ((@ window add-event-listener)
           "load"
           (lambda ()
             (defparameter *elems ((@ document get-elements-by-class-name) "scramble-text"))
             (defparameter *targets (append (lisp (cons 'list featured-text))
                                            (list "See another")))
             (loop for i from 0 to (1- (min (length *elems) (length *targets)))
               do (progn
                   (defparameter scrambler (new (*scramble (aref *elems i) (aref *targets i))))
                   (set-timeout (@ scrambler start) (* i 1000)))))))))))

(defmacro body ()
  `(content
     (header
       "Scott Hao"
       (dolist
         (i featured-text)
         (page-text :class "scramble-text" (:raw "&nbsp;")))
       (page-small :class "mt-4" (page-link (:raw "&nbsp;") "" "scramble-text hover:underline italic text-cyan-600")))
     (section
       (page-subtitle "Blog")
       (dolist
         (article articles)
         (section-item
           (car article)
           :date (cadr article)
           :heading-page-link (concatenate 'string "writing/" (caddr article)))))
     (section
       (page-subtitle "Essays")
       (dolist
         (essay essays)
         (section-item
           (car essay)
           :date (cadr essay)
           :heading-page-link (concatenate 'string "writing/" (caddr essay)))))
     (footer)))

(defun writing (featured-text articles essays)
  (layout
    :title "Writing - Scott Hao" :head (head) :body (body)))
