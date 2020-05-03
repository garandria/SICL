(cl:in-package #:sicl-boot)

(defun enable-object-initialization (load-fasl ea eb)
  (setf (sicl-genv:special-variable 'sicl-clos:+unbound-slot-value+ ea t)
        10000000)
  (funcall load-fasl "CLOS/slot-bound-using-index.fasl" ea)
  (funcall load-fasl "CLOS/slot-value-etc-support.fasl" ea)
  (funcall load-fasl "CLOS/instance-slots-offset-defconstant.fasl" ea)
  (sicl-boot:with-straddled-function-definitions
      ((sicl-clos::shared-initialize-default-using-class)
       eb)
    (funcall load-fasl "CLOS/shared-initialize-support.fasl" ea))
  (funcall load-fasl "CLOS/shared-initialize-defgenerics.fasl" eb)
  (funcall load-fasl "CLOS/shared-initialize-defmethods.fasl" eb)
  (funcall load-fasl "CLOS/initialize-instance-support.fasl" eb)
  (funcall load-fasl "CLOS/initialize-instance-defgenerics.fasl" eb)
  (funcall load-fasl "CLOS/initialize-instance-defmethods.fasl" eb)
  (define-make-instance ea eb))
