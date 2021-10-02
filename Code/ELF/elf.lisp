(cl:in-package #:sicl-elf)

(defparameter *file-class*
  '((1 . :32-bit) (2 . :64-bit)))

(defun encode (keyword dictionary)
  (let ((entry (rassoc keyword dictionary)))
    (assert (not (null entry)))
    (car entry)))

(defun decode (code dictionary)
  (let ((entry (assoc code dictionary)))
    (assert (not (null entry)))
    (cdr entry)))

(defparameter *data-encoding*
  '((1 . :little-endian) (2 . :big-endian)))

(defparameter *file-version*
  '((1 . :original-version)))

(defparameter *os/abi-identification*
  '((#x00 . :system-v)
    (#x01 . :hp-ux)
    (#x02 . :netbsd)
    (#x03 . :linux)
    (#x04 . :gnu-hurd)
    ;; No #x05 apparently.
    (#x06 . :solaris)
    (#x07 . :aix)
    (#x08 . :irix)
    (#x09 . :freebsd)
    (#x0a . :tru64)
    (#x0b . :novell-modesto)
    (#x0c . :openbsd)
    (#x0d . :openvms)
    (#x0e . :nonstop-kernel)
    (#x0f . :aros)
    (#x10 . :fenix-os)
    (#x11 . :cloudabi)
    (#x12 . :stratus-technologies-openvos)))

(defparameter *file-type*
  '((#x00 . :no-type)
    (#x01 . :relocatable)
    (#x02 . :executable)
    (#x03 . :shared-object)
    (#x04 . :core)
    (#xfe00 . :low-os)
    (#xfeff . :high-os)
    (#xff00 . :low-process)
    (#xffff . :high-process)))

(defparameter *machine*
  '((#x00 . :no-specific-instruction-set)
    ;; etc.
    (#x02 . :sparc)
    ;; etc.
    (#x3e . :amd-x86-64)
    ;; etc.
    (#xf3 . :risc-v)
    ;; etc.
    ))

(defclass elf ()
  ((%file-class
    :initarg :file-class
    :accessor file-class)
   (%data-encoding
    :initarg :data-encoding
    :accessor data-encoding)
   (%file-version
    :initarg :file-version
    :accessor file-version)
   (%os/abi-identification
    :initarg :os/abi-identification
    :accessor os/abi-identification)
   (%abi-version
    :initarg :abi-version
    :accessor abi-version)
   (%file-type
    :initarg :file-type
    :accessor file-type)
   (%machine
    :initarg :machine
    :accessor machine)
   (%entry-point-address
    :initarg :entry-point-address
    :accessor entry-point-address)))

(defun store (elf)
  (let* ((bytes (make-array 100 :element-type '(unsigned-byte 8)))
         (pos (make-instance 'vector-position :bytes bytes))
         (encoding (data-encoding elf)))
    (store-byte 0 pos)
    (store-byte (char-code #\E) pos)
    (store-byte (char-code #\L) pos)
    (store-byte (char-code #\F) pos)
    (store-byte (encode (file-class elf) *file-class*) pos)
    (store-byte (encode encoding *data-encoding*) pos)
    (store-byte (encode (file-version elf) *file-version*) pos)
    (store-byte (encode (os/abi-identification elf) *os/abi-identification*) pos)
    (store-byte (abi-version elf) pos)
    (loop repeat 8 do (store-byte 0 pos))
    (store-value (encode (file-type elf) *file-type*) 16 pos encoding)
    (store-value (encode (machine elf) *machine*) 16 pos encoding)
    (store-value (encode (file-version elf) *file-version*) 32 pos encoding)
    (store-value (entry-point-address elf) 64 pos encoding)
    bytes))
    
