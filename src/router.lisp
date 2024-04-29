(in-package :site)

(defun split-route (route)
  (multiple-value-bind
    (match regs)
    (cl-ppcre:scan-to-strings "([^\\?]*)(?:\\?(.*))?" route)
    (if (not match)
        nil
        (let ((path (aref regs 0))
              (query (aref regs 1)))
          (declare (ignore query)) ; Ignore query params for now
          (remove "" (cl-ppcre:split "/" path) :test #'string=)))))

;; Routes are stored in a tree structure
(defstruct path-node
  (handlers nil :type list)
  (children nil :type list))

(defmacro struct-push (list &rest items)
  (labels ((cons-many (list items)
             (if items
                 `(cons ,(car items) ,(cons-many list (cdr items)))
                 list)))
    `(setf ,list ,(cons-many list items))))

(defstruct router
  ())

