(in-package #:sicl-stream)

(defclass binary-to-character-input-stream
    (fundamental-character-input-stream)
  ((%binary-stream :initarg :binary-stream :reader binary-stream)))

(defmethod stream-read-char ((stream binary-to-character-input-stream))
  (let* ((input-stream (binary-stream stream))
         (byte1 (stream-read-byte input-stream)))
    (if (< byte1 #b10000000)
        (code-char byte1)
        (let ((byte2 (stream-read-byte input-stream)))
          (assert (<= #b10000000 byte2 #b10111111))
          (if (< byte1 #b11100000)
              (code-char (+ (ash (- byte1 #b11000000) -2)
                            (- byte2 #b10000000)))
              (let ((byte3 (stream-read-byte input-stream)))
                (assert (<= #b10000000 byte3 #b10111111))
                (if (< byte1 #b11110000)
                    (code-char (+ (ash (- byte1 #b11100000) -4)
                                  (ash (- byte2 #b10000000) -2)
                                  (- byte3 #b10000000)))
                    (let ((byte4 (stream-read-byte input-stream)))
                      (assert (<= #b10000000 byte4 #b10111111))
                      (assert (< byte1 #b11111000))
                      (code-char (+ (ash (- byte1 #b11110000) -6)
                                    (ash (- byte2 #b10000000) -4)
                                    (ash (- byte3 #b10000000) -2)
                                    (- byte4 #b10000000)))))))))))
