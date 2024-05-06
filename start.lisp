(ql:quickload :site)
(ql:quickload :clack)

(defparameter *args* (uiop:command-line-arguments))

(defparameter *app* (app:make-app))

(defparameter *handler*
  (clack:clackup
   *app*
   :server :woo
   :port (if *args*
             (values (parse-integer (cadr (member "--port" *args* :test #'string=))))
             3000)
   :debug (when *args* (member "--debug" *args* :test #'string=))))
