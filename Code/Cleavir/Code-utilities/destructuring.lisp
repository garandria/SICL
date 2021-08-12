(cl:in-package #:cleavir-code-utilities)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Function DESTRUCTURE-LAMBDA-LIST.
;;;
;;; Destructuring a tree according to a lambda list.
;;;
;;; The destructuring itself is typically done when a macro function
;;; is run, and the purpose is to take the macro form apart and assign
;;; parts of it to the parameter of the lambda list of the macro.
;;;
;;; The function DESTRUCTURE-LAMBDA-LIST generates the code for doing
;;; the destrucuring.  It is typically run by the expansion of
;;; DEFMACRO.  Recall that DEFMACRO must take the definition of a
;;; macro, in particular its lambda list, and generate a macro
;;; function.  The macro function takes the macro form as input and
;;; generates the expanded form.  Destructuring is done by a LET*
;;; form, and this code generates the bindings of that LET* form.
;;;
;;; The bindings generated will contain generated variables that are
;;; not used in the body of the macro definition, so we want them to
;;; be declared IGNORE.  For that reason, DESTRUCTURE-LAMBDA-LIST
;;; returns two values: the bindings mentioned above, and a list of
;;; variables to declare IGNORE in the beginning of the body of the
;;; macro function.
;;;
;;; We assume that the lambda-list/pattern are syntactically correct.
;;; They should be, because this function takes as input not the raw
;;; lambda list, but a PARSED lambda list in the form of a
;;; standard-object.

;;; The function DESTRUCTURE-REQUIRED and DESTRUCTURE-OPTIONALS return
;;; two values:
;;;
;;;  * A list of binding forms to be used in a LET*.
;;;
;;;  * A variable to be used to destructure the remaining pattern.

;;; Destructure the required parameters of a lambda list.
;;;
;;; Recall that the required parameters of a parsed lambda list is
;;; either the keyword :NONE, or a list of patterns.
(defun destructure-required (required var)
  (if (or (eq required :none) (null required))
      (values '() var)
      (let ((temp1 (gensym))
            (temp2 (gensym)))
        (multiple-value-bind (bindings rest-var)
            (destructure-required (cdr required) temp1)
          (values (append `((,temp1 (if (consp ,var)
                                        (cdr ,var)
                                        (error "required end early")))
                            (,temp2 (car ,var)))
                          (destructure-pattern (car required) temp2)
                          bindings)
                  rest-var)))))

;;; Destructure the optional parameters of a lambda list.
;;;
;;; Recall that the optional parameters of a parsed lambda list is
;;; either the keyword :none, or it is a list of &optional entries.
;;; Each optional entry has one of the two forms:
;;;
;;;  * (pattern init-arg)
;;;
;;;  * (pattern init-arg supplied-p-parameter)
;;;
;;; If the original lambda-list did not have an init-arg, the parsing
;;; process supplied NIL so that the parsed lambda list always has an
;;; init-arg.
;;;
;;; The HyperSpec says that if there is an &optional parameter and the
;;; object to be destructured "ends early", then the init-arg is
;;; evaluated and destructured instead.  We interpret this phrase to
;;; mean that either:
;;;
;;;   * the object to be destructured is NIL, in which case it "ends
;;;     early", and we destructure the init-arg instead.
;;;
;;;   * the object is a CONS, in which case the CAR of the object is
;;;     matched against the pattern.  If it doesn't match, then an
;;;     error is signaled and no attemp is made to match agains the
;;;     init-arg.
;;;
;;;   * the object is an atom other than NIL.  Then an error is
;;;     signaled.
(defun destructure-optionals (optionals var)
  (if (or (eq optionals :none) (null optionals))
      (values '() var)
      (let ((optional (car optionals))
            (temp1 (gensym))
            (temp2 (gensym)))
        (multiple-value-bind (bindings rest-var)
            (destructure-optionals (cdr optionals) temp1)
          (values (append `((,temp1 (if (consp ,var)
                                        (cdr ,var)
                                        (if (null ,var)
                                            '()
                                            (error "optional expected"))))
                            ;; If the object is not a CONS, then it is
                            ;; either NIL in which case we destructure
                            ;; the init-arg instead, or else it is an
                            ;; atom other than NIL and we have already
                            ;; signaled an error before, so we don't
                            ;; need to handle that case again.
                            (,temp2 (if (consp ,var)
                                        (car ,var)
                                        ,(cadr optional)))
                            ;; If a supplied-p-parameter exists, then
                            ;; we give it the value TRUE whenever the
                            ;; object is a CONS, even though later
                            ;; an error might be signaled because there
                            ;; is no match.
                            ,@(if (consp (cddr optional))
                                  `((,(caddr optional) (consp ,var)))))
                          (destructure-pattern (car optional) temp2)
                          bindings)
                  rest-var)))))

;;; Destructure the keyword parameters of a lambda list.
;;;
;;; Recall that the keys part of a compiled lambda list is either
;;; :none, which means that no &key was given at all, or a list if
;;; &key entries.  If the list is empty, it means that &key was given,
;;; but no &key parameters followed.
;;;
;;; A &key entry is either:
;;;
;;;  * ((keyword pattern) init-form)
;;;
;;;  * ((keyword pattern) init-form supplied-p-parameter)
;;;
;;; The HyperSpec is pretty skimpy about what happens with keyword
;;; arguments ("the rest of the list ... is taken apart
;;; appropriately").  What we do is the following:
;;;
;;;  * If there is a keyword argument with the right keyword, then
;;;    its value is matched against the pattern.
;;;
;;;  * Otherwise, the value of the init-form is matched agains the
;;;    pattern.
(defun destructure-keys (keys var)
  (if (or (eq keys :none) (null keys))
      '()
      (let ((key (car keys))
            (temp (gensym)))
        (append `(;; What we do in step 1 depends on whether there is
                  ;; a supplied-p-parameter or not.  If there is, then
                  ;; in step 1, we return a list of two things:
                  ;;
                  ;;  * a boolean indicating whether we found the
                  ;;    keyword.
                  ;;
                  ;;  * either the argument found, or the value of the
                  ;;    init-form if no argument was found.
                  ;;
                  ;; If there is no supplied-p-parameter, then we just
                  ;; return the argument found or the value of the
                  ;; init-form if no argument was found.
                  (,temp
                   ,(if (consp (cddr key))
                        `(loop for rem = ,var then (cddr rem)
                               while (consp rem)
                               when (eq (car rem) ',(caar key))
                                 return (list t (cadr rem))
                               finally (return (list nil ,(cadr key))))
                        `(loop for rem = ,var then (cddr rem)
                               while (consp rem)
                               when (eq (car rem) ',(caar key))
                                 return (cadr rem)
                               finally (return ,(cadr key)))))
                  ;; If there is no supplied-p-parameter, then we are
                  ;; done.  If there is, we must get it from the first
                  ;; element of the list computed in step 1, and we must
                  ;; replace that list with its second element.
                  ,@(if (consp (cddr key))
                        `((,(caddr key)
                           (prog1 (car ,temp)
                             (setf ,temp (cadr ,temp)))))
                        '()))
                (destructure-pattern (cadar key) temp)
                (destructure-keys (cdr keys) var)))))

;;; We return two values.  The first value is a list of bindings to be
;;; used with a LET* and the purpose of which is to destructure the
;;; arguments in VAR according to the LAMBDA-LIST.  The second value
;;; is a list of variables that ar bound in the bindings, but that
;;; should be declared IGNORE because they are introduced for
;;; technical reasons and not used anywhere.
;;;
;;; This code is used in macro functions, so we want to avoid using
;;; macros in the expansion for the simple case of no keyword
;;; arguments.
(defun destructure-lambda-list (lambda-list var)
  (multiple-value-bind (required-bindings var1)
      (destructure-required (required lambda-list) var)
    (multiple-value-bind (optional-bindings var2)
        (destructure-optionals (optionals lambda-list) var1)
      (let ((error-check-bindings '())
            (variables-to-ignore '()))
        ;; Generate bindings that check some conditions.
        (cond ((and (eq (rest-body lambda-list) :none)
                    (eq (keys lambda-list) :none))
               ;; If there is neither a &rest/&body nor any keyword
               ;; parameters, then the remaining list must be NIL, or
               ;; else we signal an error.
               (let ((temp (gensym)))
                 (push temp variables-to-ignore)
                 (push `(,temp (if (not (null ,var2))
                                   (error "too many arguments supplied")))
                       error-check-bindings)))
              ((not (eq (keys lambda-list) :none))
               ;; If there are keyword parameters, then we must check
               ;; several things.  First, we must check that the
               ;; remaining list is a proper list and that it has an
               ;; even number of elements.
               (let ((temp (gensym)))
                 (push temp variables-to-ignore)
                 (push `(,temp (multiple-value-bind (length structure)
                                   (list-structure ,var2)
                                 ;; First, the remaining list must be
                                 ;; a proper list.
                                 (unless (eq structure :proper)
                                   (error "with keyword parameters, ~
                                           the arguments must be a ~
                                           proper list."))
                                 ;; Second, it must have an even
                                 ;; number of elements.
                                 (unless (evenp length)
                                   (error "with keyword parameters, ~
                                           the keyword part of the ~
                                            arguments must have an ~
                                            even number of elements."))))
                       error-check-bindings))
               ;; If &allow-other keys was not given, more checks have
               ;; to be made.
               (unless (allow-other-keys lambda-list)
                 (let ((temp (gensym))
                       (allowed-keywords (mapcar #'caar (keys lambda-list))))
                   (push temp variables-to-ignore)
                   ;; Perhaps there was a :allow-other-keys <true> in
                   ;; the argument list.  As usual, if there are
                   ;; several pairs :allow-other-keys <mumble> then it
                   ;; is the first one that counts.  This happens to
                   ;; be exactly what GETF checks for so use it.
                   (push `(,temp (unless (getf ,var2 :allow-other-keys)
                                   ;; Either no :allow-other-keys was
                                   ;; found, or the first one found
                                   ;; had a value of NIL.  Then every
                                   ;; keyword in the argument list
                                   ;; must be one of the ones supplied
                                   ;; in the parameters.
                                   (let ()
                                     (loop for keyword in ,var2 by #'cddr
                                           unless (member keyword
                                                          ',allowed-keywords)
                                             do (error "unknown keyword ~s"
                                                       keyword)))))
                         error-check-bindings))))
              (t
               ;; If there are no keyword parameters, but there is a
               ;; &rest/&body, then we do no checks, which means that
               ;; the argument list can have any structure, including
               ;; circular.  the remaining list is simply matched with
               ;; the &rest/&body pattern.
               nil))
        (let ((rest-bindings
                (if (eq (rest-body lambda-list) :none)
                    '()
                    (destructure-pattern (rest-body lambda-list) var2)))
              (key-bindings
                (destructure-keys (keys lambda-list) var2)))
          (values (append required-bindings
                          optional-bindings
                          rest-bindings
                          (reverse error-check-bindings)
                          key-bindings
                          (if (eq (aux lambda-list) :none)
                              '()
                              (aux lambda-list)))
                  variables-to-ignore))))))

;;; Destructure a pattern.
;;; FIXME: say more.
(defun destructure-pattern (pattern var)
  (cond ((null pattern)
         `((,(gensym) (unless (null ,var)
                        (error "tree should be NIL")))))
        ((symbolp pattern)
         `((,pattern ,var)))
        ((consp pattern)
         (let ((temp1 (gensym))
               (temp2 (gensym)))
           (append `((,temp1 (if (consp ,var)
                                 (car ,var)
                                 (error "no match"))))
                   (destructure-pattern (car pattern) temp1)
                   `((,temp2 (cdr ,var)))
                   (destructure-pattern (cdr pattern) temp2))))
        (t
         (destructure-lambda-list pattern var))))
