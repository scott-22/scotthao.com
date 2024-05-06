(in-package :templates)

(defmacro layout (&key (title "Scott Hao") (head nil) (body nil))
  `(with-html
     (:doctype)
     (:html
      (:head
       (:title ,title)
       (:link :rel "icon" :href "public/favicon.ico")
       ,head)
      (:body ,body))))
