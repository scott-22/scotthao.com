(ql:quickload :site)
(ql:quickload :clack)

(defparameter *args* (uiop:command-line-arguments))

(defparameter *app* (site:make-app))

(defparameter *handler*
  (clack:clackup
   *app*
   :server :woo
   :port (values (parse-integer (cadr (member "--port" *args* :test #'string=))))
   :debug (member "--debug" *args* :test #'string=)))
