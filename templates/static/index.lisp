(in-package :templates)
(load "templates/utils.lisp")

(defmacro header-image (src width height)
  `(with-html
     (:figure
      :class "relative clear-both mx-auto my-6 w-full"
      (:img
       :src ,src
       :width ,width
       :height ,height
       :fetchpriority "high"
       :draggable "false"
       :class "w-full h-auto rounded select-none")
      (:canvas
       :id "wafer"
       :aria-hidden "true"
       :class "hidden sm:block absolute inset-0 w-full h-full rounded pointer-events-none"))))

(defmacro head ()
  `(with-html
     (:script :type "module" :src "/public/wafer.js")))

(defmacro body ()
  `(content
     (header
       "Scott Hao"
       (header-image "/public/silicon.jpeg" "2044" "668")
       (page-text "I work on smart and fast systems.")
       (page-text "That broadly includes AI, computer systems, and where they intersect. I also love writing, staying active, sewing, the drums, and collecting rocks.")
       (page-text "I study Computer Science and Cognitive Science at the University of Waterloo.")
       (:div
        :class "flex flex-row w-2/3 sm:w-2/5 justify-between mt-4"
        (page-url "Linkedin" "https://www.linkedin.com/in/scott-hao/")
        (page-url "X" "https://x.com/shao256")
        (page-url "Github" "https://github.com/scott-22")))
     (section
       (page-subtitle "Work")
       (section-item
         "Modal"
         :description "Distributed locking for the world's most scalable sandboxes. Designed the ordered event pipeline underlying all sandbox and function lifecycle events."
         :date "May 2026 - Aug 2026"
         :heading-url "https://modal.com/")
       (section-item
         "EnCharge AI"
         :description "Compilers for a novel analog compute chip. Introduced constraint solving to the scheduler and brought while-loops to the kernel programming model."
         :date "Sep 2025 - Dec 2025"
         :heading-url "https://www.enchargeai.com/")
       (section-item
         "Bloomberg"
         :description "Two internships spanning dev tooling for distributed tracing and semantic pathfinding within an ontology, respectively."
         :date "2024, 2025"
         :heading-url "https://www.bloomberg.com/company/"))))

(defun index ()
  (layout
    :title "Scott Hao"
    :description "I work on smart and fast systems."
    :head (head)
    :body (body)))
