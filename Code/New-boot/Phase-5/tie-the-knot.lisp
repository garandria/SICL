(cl:in-package #:sicl-new-boot-phase-5)

;;; Create a hash table mapping each classe in E3 to the analogous
;;; class in E4.
(defun create-class-mapping (e3 e4)
  (let ((table3 (clostrum-basic::types e3))
        (table4 (clostrum-basic::types e4))
        (result (make-hash-table :test #'eq)))
    (loop for name being each hash-key of table3 using (hash-value entry3)
          for cell3 = (clostrum-basic::cell entry3)
          for type3 = (car cell3)
          when (typep type3 'sb:header)
            do (let ((entry4 (gethash name table4)))
                 (assert (not (null entry4)))
                 (let* ((cell4 (clostrum-basic::cell entry4))
                        (class4 (car cell4)))
                   (setf (gethash type3 result) class4))))
    result))
