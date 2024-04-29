(defsystem "site"
  :author "Scott Hao"
  :depends-on ("clack"
               "lack"
               "cl-ppcre")
  :components ((:module "src"
                :components
                ((:file "app")))))
