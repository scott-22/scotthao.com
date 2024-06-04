(in-package :templates)

(defmacro layout (&key (title "Scott Hao") (head nil) (body nil))
  `(with-html
     (:doctype)
     (:html
      :class "font-display"
      (:head
       (:title ,title)
       (:link :rel "icon" :href "public/favicon.ico")
       (:link :rel "stylesheet" :href "public/layout.css")
       ,head)
      (:body ,body))))
