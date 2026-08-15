(in-package :templates)

(defmacro layout (&key (title "Scott Hao") (head nil) (body nil))
  `(let ((spinneret:*suppress-inserted-spaces* t)
         (spinneret:*fill-column* 100000))
     (with-html
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
        (:body ,body)))))

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
      :class "mt-20 clear-both"
      (page-text
        :class "mb-0"
        (page-url "Made with λ" "https://github.com/scott-22/scotthao.com")))))

(defmacro section (&rest args)
  `(with-html
     (:section
      :class "mt-12 clear-both"
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

(defmacro page-italic (&rest args)
  `(with-html
     (:em :class "italic" ,@args)))

(defmacro page-bold (&rest args)
  `(with-html
     (:strong :class "font-semibold" ,@args)))

;; Raw string reader to make formatting code easier
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun read-raw-string (stream char arg)
    (declare (ignore char arg))
    (coerce (loop for c = (read-char stream)
                  until (and (char= c #\}) (char= (peek-char nil stream) #\#))
                  collect c
                  finally (read-char stream))
            'string))

  (set-dispatch-macro-character #\# #\{ #'read-raw-string))

;; Memoize formatted code/math output to avoid recompiling eacn macro expansion.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter *render-cache* (make-hash-table :test #'equal))

  (defun render-with (program args input)
    (let ((key (list* program input args)))
      (or (gethash key *render-cache*)
          (setf (gethash key *render-cache*)
                (uiop:run-program (cons program args)
                                  :input (make-string-input-stream input)
                                  :output :string
                                  :error-output t)))))

  (defun render-math (tex &optional display)
    (render-with "./qjs"
                 (append (list "-m" "tools/render-math.mjs")
                         (when display (list "display")))
                 tex))

  ; Add a custom lexer for TLA
  (defun render-code (language code)
    (render-with "./chroma"
                 (list "--fail"
                       "--lexer" (if (eq language :tla)
                                     "tools/tla.chroma"
                                     (string-downcase (symbol-name language)))
                       "--style" "github"
                       "--html" "--html-only" "--html-prefix" "hl-")
                 (string-right-trim '(#\Space #\Tab #\Newline)
                                    (string-left-trim '(#\Newline) code)))))

(defmacro page-math-styles ()
  `(with-html
     (:link :rel "stylesheet" :href "/public/katex/katex.min.css")))

(defmacro page-code-styles ()
  `(with-html
     (:link :rel "stylesheet" :href "/public/chroma.css")))

(defmacro page-math (tex)
  `(with-html (:raw ,(render-math tex))))

(defmacro page-display-math (tex)
  `(with-html (:raw ,(render-math tex t))))

(defmacro page-code (&rest args)
  `(with-html
     (:code
      :class "font-mono text-[0.85em] text-zinc-700 bg-zinc-100 rounded px-1 py-0.5"
      ,@args)))

(defmacro page-code-block (language code)
  `(with-html (:raw ,(render-code language code))))

(defmacro page-image (src &key caption alt (size :full) (embed :block))
  `(with-html
     (:figure
      :class ,(concatenate 'string
                           (ecase embed
                             (:left "float-left clear-left mt-1 mb-3 mr-5")
                             (:right "float-right clear-right mt-1 mb-3 ml-5")
                             (:block "clear-both mx-auto my-6"))
                           " "
                           (ecase size
                             (:small "w-1/3")
                             (:medium "w-1/2")
                             (:large "w-3/4")
                             (:full "w-full")))
      (:img
       :src ,src
       :alt ,(or alt caption "")
       :loading "lazy"
       :class "w-full h-auto rounded")
      ,(when caption
         `(:figcaption
           :class "font-emphasis text-xs text-zinc-600 text-center mt-2"
           ,caption)))))
