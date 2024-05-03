(defsystem "site"
  :author "Scott Hao"
  :depends-on ("clack"
               "lack"
               "cl-ppcre")
  :components ((:module "src"
                :components
                ((:file "app" :depends-on ("controllers"))
                 (:file "router")
                 (:module "controllers" :depends-on ("router")
                  :components
                  ((:file "index")))))))
