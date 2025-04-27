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
             (defparameter *elems ((@ document get-elements-by-class-name) "text-effect"))
             (defparameter *targets (append (lisp (cons 'list (mapcar #'(lambda (lst) (cons 'list lst)) featured-text)))
                                            (list (list "See another" :link "javascript:window.location.reload(true)"))))
             (loop for i from 0 to (1- (min (length *elems) (length *targets)))
               do (case (aref (aref *targets i) 1)
                    (:scramble
                     (progn
                      (defparameter scrambler (new (*scramble (aref *elems i) (aref (aref *targets i) 0))))
                      (set-timeout (@ scrambler start) (* i 1000))))
                    (:fade
                     (progn
                      (defparameter fader (new (*fade (aref (@ (aref *elems i) children) 0) (aref (aref *targets i) 0))))
                      (set-timeout (@ fader start) (* i 1600))))
                    (:link
                     (progn
                      (setf (@ (aref *elems i) href) (aref (aref *targets i) 2))
                      (defparameter scrambler (new (*scramble (aref *elems i) (aref (aref *targets i) 0))))
                      (set-timeout (@ scrambler start) (* i 1600)))))))))))))

(defun repeat-string (n string)
  (with-output-to-string (stream)
    (dotimes (i n) (write-string string stream))))

(defmacro body ()
  `(content
     (header
       "Scott Hao"
       (dolist
         (i featured-text)
         (unless (eql (cadr i) :link)
           (page-text
             :class "text-effect"
             (:span :class "opacity-0 transition-opacity duration-[3000ms]" (car i)))))
       (:div
        :class "flex flex-row w-1/4 justify-between"
        (page-small
          :class "mt-4"
          (page-link
            (:raw "&nbsp;") "" "text-effect hover:underline italic text-cyan-600"))
        (page-small
          :class "mt-4"
          (page-link
            "" "" "text-effect hover:underline italic text-cyan-600"))))
     (when articles
       (section
         (page-subtitle "Blog")
         (dolist
           (article articles)
           (section-item
             (car article)
             :date (cadr article)
             :heading-page-link (concatenate 'string "writing/" (caddr article))))))
     (when essays
       (section
         (page-subtitle "Essays")
         (dolist
           (essay essays)
           (section-item
             (car essay)
             :date (cadr essay)
             :heading-page-link (concatenate 'string "writing/" (caddr essay))))))))

(defun writing (featured-text articles essays)
  (layout
    :title "Writing - Scott Hao" :head (head) :body (body)))
