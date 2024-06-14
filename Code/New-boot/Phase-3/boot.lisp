(cl:in-package #:sicl-new-boot-phase-3)

(eval-when (:compile-toplevel) (sb:enable-parcl-symbols client))

(defun boot (boot)
  (format *trace-output* "**************** Phase 3~%")
  (let* ((client (make-instance 'client))
         (environment (create-environment client))
         (global-environment
           (trucler:global-environment client environment))
         (env:*client* client)
         (env:*environment* global-environment))
    (setf (sb:e3 boot) global-environment)
    (reinitialize-instance client
      :environment global-environment)
    (clo:make-variable
     client global-environment '*package* (find-package '#:common-lisp-user))
    (sb:define-package-functions client global-environment)
    (sb:define-backquote-macros client global-environment)
    (import-from-host client global-environment)
    (setf (clo:fdefinition client global-environment 'funcall)
          (lambda (function-or-name &rest arguments)
            (apply #'funcall
                   (if (functionp function-or-name)
                       function-or-name
                       (clo:fdefinition
                        client global-environment function-or-name))
                   arguments)))
    (sb:import-khazern client global-environment)
    (sb:define-client-and-environment-variables client global-environment)
    (sb:define-environment-functions client global-environment)
    (sb:define-clostrophilia-find-method-combination-template
        client global-environment)
    (sb:ensure-asdf-system client environment "clostrophilia-slot-value-etc")
    (sb:define-straddle-functions client global-environment (sb:e2 boot))
    (sb:ensure-asdf-system client environment "sicl-clos-ensure-metaobject")
    (setf (clo:fdefinition
           client (sb:e2 boot) @clostrophilia:ensure-generic-function+1)
          (clo:fdefinition
           client global-environment 'ensure-generic-function))
    (sb:define-ecclesia-functions client (sb:e1 boot) global-environment)
    (sb:ensure-asdf-system
     client environment "clostrophilia-method-combination")
    (setf (clo:fdefinition client (sb:e2 boot) @sicl-clos:subtypep-1)
          (constantly t))
    (setf (clo:fdefinition
           client (sb:e2 boot) @clostrophilia:find-class-t)
          (lambda ()
            (clo:find-class client global-environment 't)))
    (sb:ensure-asdf-system
     client environment "clostrophilia-class-hierarchy")
    (setf (clo:symbol-value client (sb:e2 boot) @clostrophilia:*class-t+1*)
          (clo:find-class client global-environment 't))
        (setf (clo:macro-function
           client global-environment @asdf-user:defsystem)
          (constantly nil))
    (setf (clo:macro-function
           client global-environment @asdf:defsystem)
          (constantly nil))
    (sb:ensure-asdf-system
     client environment "predicament-base" :load-system-file t)
        (sb:ensure-asdf-system
     client environment "predicament-packages-intrinsic")
    (setf (clo:fdefinition
           client (sb:e1 boot)
           @clostrophilia:find-class-standard-object)
          (constantly (clo:find-class
                       client global-environment 'standard-object)))
    (clo:make-variable
     client (sb:e2 boot) @clostrophilia:*standard-object*
     (clo:find-class client global-environment 'standard-object))
    (clo:make-variable
     client (sb:e2 boot) @clostrophilia:*funcallable-standard-object*
     (clo:find-class
      client global-environment @clostrophilia:funcallable-standard-object))
    (let* ((name @clostrophilia:find-method-combination)
           (function (clo:fdefinition client global-environment name)))
      (clo:make-variable client (sb:e1 boot)
                         @sicl-clos:*standard-method-combination*
                         (funcall function client 'standard '())))
    (setf (clo:fdefinition
           client global-environment @sicl-clos:^allocate-instance-using-class)
          (clo:fdefinition
           client (sb:e1 boot) @clostrophilia:allocate-instance-using-class))
    (sb:ensure-asdf-system
     client environment "sicl-new-boot-phase-2-additional-classes")
    (define-class-of-and-stamp client (sb:e2 boot) global-environment))
  boot)
