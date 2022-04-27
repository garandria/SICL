(cl:in-package #:sicl-data-and-control-flow)

(let* ((environment (sicl-environment:global-environment))
       (client (sicl-environment:client environment))
       (setf-fdefinition (fdefinition '(setf sicl-environment:fdefinition)))
       (setf-macro-function (fdefinition '(setf sicl-environment:macro-function))))
  (defun fmakunbound (function-name)
    (funcall setf-fdefinition nil client environment function-name)
    (funcall setf-macro-function nil client environment function-name)
    function-name))
