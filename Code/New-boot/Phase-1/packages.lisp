(cl:in-package #:common-lisp-user)

(defpackage #:sicl-new-boot-phase-1
  (:use #:common-lisp)
  (:local-nicknames
   (#:sb #:sicl-new-boot)
   (#:cb #:common-boot)
   (#:clo #:clostrum)
   (#:cbae #:common-boot-ast-evaluator)
   (#:cmd #:common-macro-definitions)
   (#:abp #:architecture.builder-protocol))
  (:export))
