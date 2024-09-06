(ql:quickload "site")

(defparameter *args* (uiop:command-line-arguments))

(defparameter *app* (app:make-app))

;; Load REPL utils to aid in local development
(when (and (member "--debug" *args* :test #'string=)
           (member "--swank-port" *args* :test #'string=))
  (load "devutils.lisp"))

(defparameter *handler*
  (clack:clackup
   *app*
   :server :woo
   :address (if *args*
                (cadr (member "--bind" *args* :test #'string=))
                "127.0.0.1")
   :port (if *args*
             (values (parse-integer (cadr (member "--port" *args* :test #'string=))))
             3000)
   :swank-interface (if *args*
                        (cadr (member "--bind" *args* :test #'string=))
                        "127.0.0.1")
   :swank-port (let ((swank-port (cadr (member "--swank-port" *args* :test #'string=))))
                 (when swank-port (values (parse-integer swank-port))))
   :debug (when *args* (member "--debug" *args* :test #'string=))
   :use-thread t))

;; Prevent thread from exiting right away
(bt2:join-thread
 (find-if #'(lambda (thread)
              (search "clack-handler" (bt2:thread-name thread)))
          (bt2:all-threads)))
