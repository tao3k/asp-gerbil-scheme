;;; -*- Gerbil -*-
;;; Parser-owned reader facts shared by formatter and policy code.

(import :gerbil/runtime/gambit)

(export parser-reader-initial-state
        parser-reader-literal-line?
        parser-reader-literal-open-at-line-end?
        parser-reader-scan-line-state
        parser-reader-scan-line/indent
        parser-reader-leading-close-count
        parser-reader-leading-whitespace-count
        parser-reader-whitespace?)

(defstruct parser-reader-state
  (in-string escape in-symbol symbol-escape block-depth)
  transparent: #t)

(def (parser-reader-initial-state)
  (parser-reader-make-state #f #f #f #f 0))

(def (parser-reader-make-state in-string escape in-symbol symbol-escape block-depth)
  (make-parser-reader-state in-string escape in-symbol symbol-escape block-depth))

(def (parser-reader-literal-line? state)
  (or (parser-reader-state-in-string state)
      (parser-reader-state-in-symbol state)
      (> (parser-reader-state-block-depth state) 0)))

(def (parser-reader-literal-open-at-line-end? state)
  (ormap (lambda (predicate)
           (predicate state))
         (list parser-reader-state-in-string
               parser-reader-state-in-symbol)))

;; parser-reader-scan-line/indent
;; : (-> String ParserReaderState (List Datum))
;; | doc m%
;;   Scan one source line while preserving lexical state and reporting the
;;   parenthesis-depth delta for the caller's indentation model.
;;   # Examples
;;   ```scheme
;;   (parser-reader-scan-line/indent "(form)" state)
;;   ;; => (list state 0)
;;   ```
(def (parser-reader-scan-line/indent line state)
  (let ((len (string-length line)))
    (let scan ((index 0)
               (current state)
               (delta 0))
      (if (>= index len)
        (list current delta)
        (call-with-values
          (lambda ()
            (parser-reader-scan-line/indent-step line len index current delta))
          (lambda (next-index next-state next-delta)
            (scan next-index next-state next-delta)))))))

(def (parser-reader-scan-line/indent-step line len index state delta)
  (cond
   ((parser-reader-state-in-string state)
    (call-with-values
      (lambda ()
        (parser-reader-scan-string-step line index state))
      (lambda (next-index next-state)
        (values next-index next-state delta))))
   ((parser-reader-state-in-symbol state)
    (call-with-values
      (lambda ()
        (parser-reader-scan-symbol-step line index state))
      (lambda (next-index next-state)
        (values next-index next-state delta))))
   ((> (parser-reader-state-block-depth state) 0)
    (call-with-values
      (lambda ()
        (parser-reader-scan-block-comment-step line index state))
      (lambda (next-index next-state)
        (values next-index next-state delta))))
   (else
    (let (ch (string-ref line index))
      (cond
       ((char=? ch #\;)
        (values len state delta))
       ((char=? ch #\")
        (values (+ index 1) (parser-reader-make-state #t #f #f #f 0) delta))
       ((char=? ch #\|)
        (values (+ index 1) (parser-reader-make-state #f #f #t #f 0) delta))
       ((and (char=? ch #\#)
             (parser-reader-next-char? line index #\|))
        (values (+ index 2) (parser-reader-make-state #f #f #f #f 1) delta))
       ((char=? ch #\()
        (values (+ index 1) state (+ delta 1)))
       ((char=? ch #\))
        (values (+ index 1) state (- delta 1)))
       (else
        (values (+ index 1) state delta)))))))

;; parser-reader-scan-line-state
;; : (-> String ParserReaderState ParserReaderState)
;; | doc m%
;;   Advance lexical reader state across one source line without computing
;;   indentation, so callers can carry state into the next line.
;;   # Examples
;;   ```scheme
;;   (parser-reader-scan-line-state "(form)" state)
;;   ;; => state
;;   ```
(def (parser-reader-scan-line-state line state)
  (let ((len (string-length line)))
    (let scan ((index 0)
               (current state))
      (if (>= index len)
        current
        (call-with-values
          (lambda ()
            (parser-reader-scan-line-step line len index current))
          (lambda (next-index next-state)
            (scan next-index next-state)))))))

(def (parser-reader-scan-line-step line len index state)
  (let ((dispatch
         (find (lambda (entry)
                 ((car entry) state))
               (list (cons parser-reader-state-in-string
                           (lambda ()
                             (parser-reader-scan-string-step line index state)))
                     (cons parser-reader-state-in-symbol
                           (lambda ()
                             (parser-reader-scan-symbol-step line index state)))
                     (cons (lambda (current)
                             (> (parser-reader-state-block-depth current) 0))
                           (lambda ()
                             (parser-reader-scan-block-comment-step line index state)))))))
    (if dispatch
      ((cdr dispatch))
      (parser-reader-scan-source-step line len index state))))

(def (parser-reader-scan-string-step line index state)
  (let ((ch (string-ref line index))
        (block-depth (parser-reader-state-block-depth state)))
    (cond
     ((parser-reader-state-escape state)
      (values (+ index 1) (parser-reader-make-state #t #f #f #f block-depth)))
     ((char=? ch #\\)
      (values (+ index 1) (parser-reader-make-state #t #t #f #f block-depth)))
     ((char=? ch #\")
      (values (+ index 1) (parser-reader-make-state #f #f #f #f block-depth)))
     (else
      (values (+ index 1) (parser-reader-make-state #t #f #f #f block-depth))))))

(def (parser-reader-scan-symbol-step line index state)
  (let ((ch (string-ref line index))
        (block-depth (parser-reader-state-block-depth state)))
    (cond
     ((parser-reader-state-symbol-escape state)
      (values (+ index 1) (parser-reader-make-state #f #f #t #f block-depth)))
     ((char=? ch #\\)
      (values (+ index 1) (parser-reader-make-state #f #f #t #t block-depth)))
     ((char=? ch #\|)
      (values (+ index 1) (parser-reader-make-state #f #f #f #f block-depth)))
     (else
      (values (+ index 1) (parser-reader-make-state #f #f #t #f block-depth))))))

(def (parser-reader-scan-block-comment-step line index state)
  (let ((ch (string-ref line index))
        (block-depth (parser-reader-state-block-depth state)))
    (cond
     ((and (char=? ch #\#)
           (parser-reader-next-char? line index #\|))
      (values (+ index 2) (parser-reader-make-state #f #f #f #f (+ block-depth 1))))
     ((and (char=? ch #\|)
           (parser-reader-next-char? line index #\#))
      (values (+ index 2) (parser-reader-make-state #f #f #f #f (- block-depth 1))))
     (else
      (values (+ index 1) state)))))

(def (parser-reader-scan-source-step line len index state)
  (let (ch (string-ref line index))
    (cond
     ((char=? ch #\;)
      (values len state))
     ((char=? ch #\")
      (values (+ index 1) (parser-reader-make-state #t #f #f #f 0)))
     ((char=? ch #\|)
      (values (+ index 1) (parser-reader-make-state #f #f #t #f 0)))
     ((and (char=? ch #\#)
           (parser-reader-next-char? line index #\|))
      (values (+ index 2) (parser-reader-make-state #f #f #f #f 1)))
     (else
      (values (+ index 1) state)))))

;; parser-reader-leading-close-count
;; : (-> String Fixnum)
;; | doc m%
;;   Count leading close parentheses after whitespace for indentation recovery.
;;   # Examples
;;   ```scheme
;;   (parser-reader-leading-close-count "  )) form")
;;   ;; => 2
;;   ```
(def (parser-reader-leading-close-count line)
  (let ((len (string-length line)))
    (let loop ((index 0)
               (count 0)
               (seen-source? #f))
      (cond
       ((>= index len) count)
       (else
        (let (ch (string-ref line index))
          (cond
           ((and (not seen-source?) (parser-reader-whitespace? ch))
            (loop (+ index 1) count #f))
           ((char=? ch #\))
            (loop (+ index 1) (+ count 1) #t))
           (else count))))))))

;; parser-reader-leading-whitespace-count
;; : (-> String Fixnum)
;; | doc m%
;;   Count leading whitespace before the first source character on a line.
;;   # Examples
;;   ```scheme
;;   (parser-reader-leading-whitespace-count "  form")
;;   ;; => 2
;;   ```
(def (parser-reader-leading-whitespace-count line)
  (let ((len (string-length line)))
    (let loop ((index 0))
      (cond
       ((>= index len) index)
       ((parser-reader-whitespace? (string-ref line index))
        (loop (+ index 1)))
       (else index)))))

(def (parser-reader-next-char? text index expected)
  (let ((next (+ index 1)))
    (and (< next (string-length text))
         (char=? (string-ref text next) expected))))

(def (parser-reader-whitespace? ch)
  (ormap (lambda (expected)
           (char=? ch expected))
         (list #\space #\tab #\return)))
