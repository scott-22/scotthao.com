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

(defmacro content (&rest args)
  `(with-html
     (:div
      :class "text-center w-full md:w-10/12 lg:w-[850px] p-7 md:p-9 mx-auto"
      ,@args)))

(defmacro page-title (title-text &rest args)
  `(with-html
     (:h1
      :class "text-3xl text-zinc-800"
      ,@args
      ,title-text)))
