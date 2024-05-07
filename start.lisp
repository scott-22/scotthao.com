(ql:quickload :site)

(defparameter *args* (uiop:command-line-arguments))

(defparameter *app* (app:make-app))

(defparameter *handler*
  (clack:clackup
   *app*
   :server :woo
   :address (if *args*
                (values (cadr (member "--bind" *args* :test #'string=)))
                "127.0.0.1")
   :port (if *args*
             (values (parse-integer (cadr (member "--port" *args* :test #'string=))))
             3000)
   :debug (when *args* (member "--debug" *args* :test #'string=))
   :use-thread t))

(bt2:join-thread
 (find-if #'(lambda (thread)
              (search "clack-handler" (bt2:thread-name thread)))
          (bt2:all-threads)))
