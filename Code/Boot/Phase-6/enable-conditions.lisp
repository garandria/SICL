(cl:in-package #:sicl-boot-phase-6)

(defun enable-conditions (e5)
  (ensure-asdf-system '#:sicl-conditions e5)
  (let ((client (env:client e5)))
    (setf (env:fdefinition client e5 'find-class)
          (lambda (name &optional (errorp t) env)
            (declare (ignore env))
            (let ((class (env:find-class client e5 name)))
              (when (and (null class) errorp)
                (funcall (env:fdefinition client e5 'error)
                         'sicl-clos::no-such-class-name
                         :name name))
              class)))
    #+(or)(setf (env:fdefinition client e5 'invoke-debugger)
          (lambda (condition)
            (declare (ignore condition))
            (sicl-boot-backtrace-inspector:inspect sicl-hir-evaluator:*call-stack*))))
  (load-source-file "CLOS/conditions.lisp" e5))
