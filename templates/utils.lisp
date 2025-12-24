(in-package :templates)

(defmacro layout (&key (title "Scott Hao") (head nil) (body nil))
  `(with-html
     (:doctype)
     (:html
      :class "font-display"
      (:head
       (:title ,title)
       (:meta :name "description" :content "I work on smart and fast systems.")
       (:meta :name "viewport" :content "width=device-width, initial-scale=1")
       (:link :rel "icon" :href "/public/favicon.ico")
       (:link :rel "preload" :href "/public/OpenSans-VariableFont_wdth,wght.ttf" :as "font" :type "font/ttf" :crossorigin "anonymous")
       (:link :rel "preload" :href "/public/OpenSans-Italic-VariableFont_wdth,wght.ttf" :as "font" :type "font/ttf" :crossorigin "anonymous")
       (:link :rel "stylesheet" :href "/public/layout.css")
       ,head)
      (:body ,body))))

(defmacro content (&rest args)
  `(with-html
     (:div
      :class "flex flex-col max-w-[650px] min-h-screen pt-4 sm:pt-7 md:pt-9 pb-3 px-7 md:px-9 mx-auto"
      (:div
       :class "flex-1"
       ,@args)
      (footer))))

(defmacro header (title &rest args)
  `(with-html
     (:header
      :class "mt-12"
      (:div
       :class "flex flex-row justify-between"
       (page-title ,title)
       (:div
        :class "w-1/3 sm:w-1/5 lg:w-1/6 flex flex-row justify-between mt-[15px]"
        (page-small (page-link "Home" "/"))
        (page-small (page-link "Writing" "/writing"))))
      ,@args)))

(defmacro footer ()
  `(with-html
     (:footer
      :class "mt-20"
      (page-text
        :class "mb-0"
        (page-url "Made with λ" "https://github.com/scott-22/scotthao.com")))))

(defmacro section (&rest args)
  `(with-html
     (:section
      :class "mt-12"
      ,@args)))

(defmacro section-item (heading &key description date heading-url heading-page-link)
  `(with-html
     (:div
      :class "flex flex-col"
      ,(let ((info `(:div
                     :class "flex flex-row justify-between"
                     (page-heading
                       ,(if heading-url
                            `(url ,heading ,heading-url "hover:underline")
                            heading))
                     ,(when date `(page-small :class "mt-[24px]" ,date)))))
         (if heading-page-link
             `(page-link ,info ,heading-page-link "hover:underline")
             info))
      (:div (page-description ,description)))))

(defmacro url (text href &optional class)
  `(with-html
     (:a
      :href ,href
      :target "_blank"
      :rel "noopener noreferrer"
      :class ,class
      ,text)))

(defmacro page-link (text path &optional class)
  `(with-html
     (:a
      :href ,path
      :class ,class
      ,text)))

(defmacro page-title (&rest args)
  `(with-html
     (:h1
      :class "font-emphasis text-3xl text-zinc-800"
      ,@args)))

(defmacro page-subtitle (&rest args)
  `(with-html
     (:h2
      :class "text-2xl text-zinc-800 mt-4"
      ,@args)))

(defmacro page-heading (&rest args)
  `(with-html
     (:h3
      :class "font-emphasis text-lg text-zinc-700 mt-4"
      ,@args)))

(defmacro page-text (&rest args)
  `(with-html
     (:p
      :class "text-base my-3"
      ,@args)))

(defmacro page-description (&rest args)
  `(with-html
     (:p
      :class "text-base my-2"
      ,@args)))

(defmacro page-small (&rest args)
  `(with-html
     (:p
      :class "font-emphasis text-xs text-zinc-600"
      ,@args)))

(defmacro page-url (text href)
  `(url ,text ,href "font-emphasis hover:underline italic text-cyan-600"))
