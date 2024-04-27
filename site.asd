(defsystem "site"
  :author "Scott Hao"
  :depends-on ("clack"
               "lack"
               "trivia")
  :components ((:module "src"
                :components
                ((:file "app")))))
