(defsystem "site"
  :author "Scott Hao"
  :depends-on ("clack"
               "lack"
               "spinneret"
               "parenscript"
               "cl-ppcre")
  :components ((:module "src"
                :components
                ((:file "app" :depends-on ("controllers"))
                 (:file "router")
                 (:file "templater")
                 (:module "controllers" :depends-on ("router" "templater")
                  :components
                  ((:file "index")))))))
