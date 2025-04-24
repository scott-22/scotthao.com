(in-package :templates)

(defmacro layout (&key (title "Scott Hao") (head nil) (body nil))
  `(with-html
     (:doctype)
     (:html
      :class "font-display"
      (:head
       (:title ,title)
       (:link :rel "icon" :href "/public/favicon.ico")
       (:link :rel "stylesheet" :href "/public/layout.css")
       ,head)
      (:body ,body))))

(defmacro content (&rest args)
  `(with-html
     (:div
      :class "w-full sm:w-[600px] min-h-screen p-7 md:p-9 mx-auto"
      ,@args)))

(defmacro section (&rest args)
  `(with-html
     (:section
      :class "mt-12"
      ,@args)))

(defmacro section-block (&rest args)
  `(with-html
     (:div
      :class "flex flex-col gap-8"
      ,@args)))

(defmacro section-item (heading description date &optional heading-url)
  `(with-html
     (:div
      :class "flex flex-col"
      (:div
       :class "flex flex-row justify-between"
        (page-heading
          ,(if heading-url
               `(url ,heading ,heading-url "hover:underline")
               heading))
        (page-small ,date :class "mt-[24px]"))
      (:div (page-description ,description)))))

(defmacro url (text href &optional class)
  `(with-html
     (:a
      :href ,href
      :target "_blank"
      :rel "noopener noreferrer"
      :class ,class
      ,text)))

(defmacro page-title (title-text &rest args)
  `(with-html
     (:h1
      :class "text-3xl text-zinc-800 mt-8 font-emphasis"
      ,@args
      ,title-text)))

(defmacro page-subtitle (title-text &rest args)
  `(with-html
     (:h2
      :class "text-2xl text-zinc-800 mt-4"
      ,@args
      ,title-text)))

(defmacro page-heading (title-text &rest args)
  `(with-html
     (:h3
      :class "text-lg text-zinc-700 mt-4"
      ,@args
      ,title-text)))

(defmacro page-text (text &rest args)
  `(with-html
     (:p
      :class "text-base my-3"
      ,@args
      ,text)))

(defmacro page-description (text &rest args)
  `(with-html
     (:p
      :class "text-base my-2"
      ,@args
      ,text)))

(defmacro page-small (title-text &rest args)
  `(with-html
     (:p
      :class "text-xs text-zinc-600"
      ,@args
      ,title-text)))

(defmacro page-url (text href)
  `(url ,text ,href "font-emphasis hover:underline italic text-cyan-600"))
