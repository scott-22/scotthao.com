(in-package :site)

(defun split-route (route)
  (multiple-value-bind
    (match regs)
    (cl-ppcre:scan-to-strings "([^\\?]*)(?:\\?(.*))?" route)
    (when match
      (let ((path (aref regs 0))
            (query (aref regs 1)))
        (declare (ignore query)) ; Ignore query params for now
        (remove "" (cl-ppcre:split "/" path) :test #'string=)))))

;; Routes are stored in a tree structure
(defstruct path-node
  (handlers nil :type list)  ; plist mapping method to handler
  (children nil :type list)) ; alist mapping subdir to node

(defmacro struct-push (list &rest items)
  (labels ((cons-many (list items)
             (if items
                 `(cons ,(car items) ,(cons-many list (cdr items)))
                 list)))
    `(setf ,list ,(cons-many list items))))

(defun get-path-node-handler (node method)
  (or (getf (path-node-handlers node) method)
      (getf (path-node-handlers node) :ALL)))

(defun get-path-node-child (node subdir &key (exact nil))
  (or (assoc subdir (path-node-children node) :test #'string=)
      (unless exact (assoc-if #'symbolp (path-node-children node)))))

(defun match-path-node-route (node subdirs params)
  (if subdirs
      (let ((child (get-path-node-child node (car subdirs))))
        (when child
          (match-path-node-route
           (cdr child)
           (cdr subdirs)
           (if (symbolp (car child))
               (cons (car child) (cons (car subdirs) params))
               params))))
      (values node params)))

(defun make-path-node-route (node subdirs method handler)
  (if subdirs
      (let* ((subdir (car subdirs))
             (subdir-token (if (char= (char subdir 0) #\:)
                               (values (intern (string-upcase (remove #\: subdir)) :keyword))
                               subdir))
             (child (get-path-node-child node subdir-token :exact t)))
        (if child
            (make-path-node-route child (cdr subdirs) method handler)
            (let ((new-child (make-path-node)))
              (progn
                (struct-push (path-node-children node) (cons subdir-token new-child))
                (make-path-node-route new-child (cdr subdirs) method handler)))))
      (struct-push (path-node-handlers node) method handler)))

;; Router matches routes to corresponding handlers
(defstruct router
  (index (make-path-node) :type path-node) ; root of route tree
  (errors nil :type list))                 ; alist mapping error code to handler

(defun handle-error (router code env)
  (let ((handler (assoc code (router-errors router))))
    (if handler (funcall handler env) (error "HTTP code ~S has no handler" code))))

(defun handle-route (router path env)
  (multiple-value-bind
    (node params)
    (match-path-node-route
     (router-index router)
     (split-route path)
     empty)
    (or (when node
          (let ((handler (get-path-node-handler node (getf env :request-method))))
            (when handler
              (let ((response (funcall handler (cons :ROUTE-PARAMS (cons params env)))))
                (if (listp response) response (handle-error router response env))))))
        (handle-error router 404 env))))

(defun add-route (router path method handler)
  (make-path-node-route
   (router-index router)
   (split-route path)
   method
   handler))
