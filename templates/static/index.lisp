(in-package :templates)
(load "templates/utils.lisp")

(defmacro body ()
  `(content
     (header
       "Scott Hao"
       (page-text "I work on smart and fast systems.")
       (page-text "That broadly includes AI, computer systems, and where they intersect. I also love psychology, cooking, writing, art, staying active, and collecting rocks.")
       (page-text "I study Computer Science and Cognitive Science at the University of Waterloo.")
       (:div
        :class "flex flex-row sm:w-1/2 justify-between mt-4"
        (page-url "Linkedin" "https://www.linkedin.com/in/scott-hao/")
        (page-url "Github" "https://github.com/scott-22")
        (page-url "Email" "mailto:scotthao65@gmail.com")))
     (section
       (page-subtitle "Work")
       (section-item
         "University of Waterloo"
         :description "Researching new algorithms for faster GPU matrix multiplication. Supervised by Prof. Xiao Hu and Prof. Victor Zhong."
         :date "May 2025 - Present"
         :heading-url "https://cs.uwaterloo.ca/")
       (section-item
         "Bloomberg"
         :description "Enabled launch of new AI features in the Bloomberg terminal by optimizing pathfinding within a knowledge graph. Reduced latency by nearly 3 orders of magnitude with algorithms and zero-copy strategies."
         :date "Jan 2025 - Apr 2025"
         :heading-url "https://www.bloomberg.com/")
       (section-item
         "Bloomberg"
         :description "Released a debugging tool for distributed systems to over 300 engineers. Fixed an org-wide observability bug causing missing data in distributed traces that went unsolved for 6 months."
         :date "May 2024 - Aug 2024"
         :heading-url "https://www.bloomberg.com/")
       (section-item
         "MIT-PITT-RW"
         :description "Infrastructure work for an autonomous racing team. Created data visualizations used by a team-authored paper accepted to ICRA 2025."
         :date "Oct 2023 - Apr 2024"
         :heading-url "https://www.indyautonomouschallenge.com/mit-pitt-rw")
       (section-item
         "Royal Bank of Canada"
         :description "Prototyped a rule-based system to score the quality of internal APIs. Designed a grammar and parser for scoring guidelines."
         :date "Jul 2023 - Aug 2023"
         :heading-url "https://www.rbcroyalbank.com/"))
     (section
       (page-subtitle "Projects")
       (section-item
         "Intelligent Prover"
         :description "An automated theorem prover supporting full first-order logic with smart premise selection using embedding-based heuristics."
         :date (page-url "Github link" "https://github.com/scott-22/intelligent-prover"))
       (section-item
         "Text Editor"
         :description "Terminal-based text editor built from scratch in C++. Supports most Vim commands, undo, macros, and efficient text manipulation."
         :date (page-url "Email for repo" "mailto:scotthao65@gmail.com")))))

(defun index ()
  (layout :body (body)))
