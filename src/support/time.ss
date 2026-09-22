;;; -*- Gerbil -*-
;;; Small timing helpers for benchmark and snapshot code.

(import :gerbil/runtime/gambit
        (only-in :std/time/precise
                 current-time-precise PreciseTime-seconds PreciseTime-nseconds)
        (only-in :std/string/misc string-index string-suffix?)
        )

(export monotonic-ms
        call-with-timing
        duration-ms
        monotonic-micros
        duration-micros
        micros->nanos
        duration-nanos->ms
        duration-nanos->literal
        duration-nanos->text
        duration-literal->nanos
        duration-literal?
        duration-literal<=?
        average-duration-ms
        average-duration-micros
        duration-state)

;; V19 native nanosecond wall-time measurement for benchmark receipts.
(def (precise-time-nanos)
  (let (now (current-time-precise))
    (+ (* (PreciseTime-seconds now) 1000000000)
       (PreciseTime-nseconds now))))

(def (call-with-timing thunk)
  (let* ((started (precise-time-nanos))
         (result (thunk)))
    (values (- (precise-time-nanos) started) result)))
;; : (-> Unit Integer)
(def (monotonic-ms)
  (inexact->exact (floor (* 1000.0 (##current-time-point)))))
;; : (-> Integer Integer Integer)
(def (duration-ms start-ms end-ms)
  (- end-ms start-ms))
;; : (-> Unit Integer)
(def (monotonic-micros)
  (inexact->exact (floor (* 1000000.0 (##current-time-point)))))
;; : (-> Integer Integer Integer)
(def (duration-micros start-micros end-micros)
  (- end-micros start-micros))
;; : (-> Integer Integer)
(def (micros->nanos micros)
  (* micros 1000))
;; : (-> Integer Number)
(def (duration-nanos->ms nanos)
  (/ nanos 1000000.0))
;; : (-> String Integer String)
(def (duration-left-pad-zero text width)
  (if (>= (string-length text) width)
    text
    (duration-left-pad-zero (string-append "0" text) width)))
;; : (-> String String)
(def (duration-trim-fraction-zero text)
  (let loop ((end (string-length text)))
    (cond
     ((<= end 0) "")
     ((char=? (string-ref text (- end 1)) #\0)
      (loop (- end 1)))
     (else
      (substring text 0 end)))))
;; : (-> Integer Integer String Integer String)
(def (duration-nanos->unit-text nanos unit-nanos suffix digits)
  (let* ((whole (quotient nanos unit-nanos))
         (remainder-nanos (remainder nanos unit-nanos)))
    (if (zero? remainder-nanos)
      (string-append (number->string whole) suffix)
      (string-append
       (number->string whole)
       "."
       (duration-trim-fraction-zero
        (duration-left-pad-zero
         (number->string remainder-nanos)
         digits))
       suffix))))
;; : (-> Integer Symbol)
(def (duration-nanos->literal nanos)
  (let ((magnitude (if (< nanos 0) (- 0 nanos) nanos))
        (sign (if (< nanos 0) "-" "")))
    (string->symbol
     (string-append
      sign
      (cond
       ((zero? magnitude) "0ns")
       ((>= magnitude 1000000000)
        (duration-nanos->unit-text magnitude 1000000000 "s" 9))
       ((>= magnitude 1000000)
        (duration-nanos->unit-text magnitude 1000000 "ms" 6))
       ((>= magnitude 1000)
        (duration-nanos->unit-text magnitude 1000 "us" 3))
       (else
        (string-append (number->string magnitude) "ns")))))))
;; : (-> Integer String)
(def (duration-nanos->text nanos)
  (symbol->string (duration-nanos->literal nanos)))
;; pow10
;;   : (-> Integer Integer)
;;   | doc m%
;;       Return the exact base-10 scale for decimal duration parsing.
;;
;;       # Examples
;;
;;       ```scheme
;;       (pow10 3)
;;       ;; => 1000
;;       ```
;;     %
;; : (-> Integer Integer)
(def (pow10 exponent)
  (expt 10 exponent))
;; : (-> Character Boolean)
(def (duration-digit? ch)
  (and (char>=? ch #\0)
       (char<=? ch #\9)))
;; duration-digits?
;;   : (-> String Boolean)
;;   | doc m%
;;       Return `#t` when `text` is a non-empty ASCII digit sequence.
;;
;;       # Examples
;;
;;       ```scheme
;;       (duration-digits? "125")
;;       ;; => #t
;;       ```
;;     %
;; : (-> String Boolean)
(def (duration-digits? text)
  (let ((len (string-length text)))
    (and (> len 0)
         (andmap duration-digit? (string->list text)))))
;; duration-decimal-dot-index
;;   : (-> String (U Integer False))
;;   | doc m%
;;       Return the index of the decimal point in a duration number, or `#f`
;;       when the number is integral.
;;
;;       # Examples
;;
;;       ```scheme
;;       (duration-decimal-dot-index "1.2")
;;       ;; => 1
;;       ```
;;     %
;; : (-> String (U Integer False))
(def (duration-decimal-dot-index text)
  (string-index text #\.))
;; duration-decimal-numerator/scale
;;   : (-> String (U Pair False))
;;   | type DecimalParts = (Pair Integer Integer)
;;   | doc m%
;;       Return `(numerator . scale)` for an integral or decimal duration
;;       number. Invalid or empty parts return `#f`.
;;     %
;; : (-> String (U Pair False))
(def (duration-decimal-numerator/scale text)
  (let ((dot-index (duration-decimal-dot-index text))
        (len (string-length text)))
    (if dot-index
      (let* ((whole-text (substring text 0 dot-index))
             (fraction-text (substring text (+ dot-index 1) len)))
        (and (duration-digits? whole-text)
             (duration-digits? fraction-text)
             (let* ((scale (pow10 (string-length fraction-text)))
                    (whole (string->number whole-text))
                    (fraction (string->number fraction-text)))
               (cons (+ (* whole scale) fraction) scale))))
      (and (duration-digits? text)
           (cons (string->number text) 1)))))
;; duration-literal-string
;;   : (-> DurationCandidate (U String False))
;;   | type DurationCandidate = (U Symbol String)
;;   | doc m%
;;       Normalize a benchmark duration candidate to text before suffix
;;       parsing. Non literal values return `#f` at the parser boundary.
;;     %
;; : (-> DurationCandidate (U String False))
(def (duration-literal-string value)
  (cond
   ((symbol? value) (symbol->string value))
   ((string? value) value)
   (else #f)))
;; duration-unit-suffix
;;   : (-> String (U Pair False))
;;   | doc m%
;;       Return the unit suffix and exact nanosecond multiplier for a duration
;;       literal, or `#f` when the suffix is unknown.
;;
;;       # Examples
;;
;;       ```scheme
;;       (duration-unit-suffix "1.2ms")
;;       ;; => ("ms" . 1000000)
;;       ```
;;     %
;; : (-> String (U Pair False))
(def (duration-unit-suffix text)
  (cond
   ((string-suffix? "ns" text) (cons "ns" 1))
   ((string-suffix? "us" text) (cons "us" 1000))
   ((string-suffix? "ms" text) (cons "ms" 1000000))
   ((string-suffix? "s" text) (cons "s" 1000000000))
   (else #f)))
;; duration-literal->nanos
;;   : (-> DurationCandidate (U Integer False))
;;   | type DurationCandidate = (U Symbol String)
;;   | doc m%
;;       Parse benchmark duration literals such as `800ns`, `75us`, `1.2ms`,
;;       and `1s` into exact integer nanoseconds. Fractions that cannot be
;;       represented as whole nanoseconds are rejected instead of rounded.
;;     %
;; : (-> DurationCandidate (U Integer False))
(def (duration-literal->nanos value)
  (let (text (duration-literal-string value))
    (and text
         (let (unit (duration-unit-suffix text))
           (and unit
                (let* ((unit-text (car unit))
                       (unit-nanos (cdr unit))
                       (end (- (string-length text)
                               (string-length unit-text)))
                       (number-text (substring text 0 end))
                       (number-parts
                        (duration-decimal-numerator/scale number-text)))
                  (and number-parts
                       (let* ((scaled (* (car number-parts) unit-nanos))
                              (scale (cdr number-parts)))
                         (and (zero? (remainder scaled scale))
                              (quotient scaled scale))))))))))
;; : (-> DurationCandidate Boolean)
(def (duration-literal? value)
  (not (not (duration-literal->nanos value))))
;; : (-> DurationCandidate DurationCandidate Boolean)
(def (duration-literal<=? left right)
  (let ((left-ns (duration-literal->nanos left))
        (right-ns (duration-literal->nanos right)))
    (and left-ns right-ns (<= left-ns right-ns))))
;; : (-> Integer Integer Integer)
(def (average-duration-ms total-ms iterations)
  (quotient total-ms iterations))
;; : (-> Integer Integer Integer)
(def (average-duration-micros total-ms iterations)
  (quotient (* total-ms 1000) iterations))
;; : (-> MeasurementValue String)
(def (duration-state value)
  (if (and (number? value) (>= value 0))
    "measured"
    "missing"))
