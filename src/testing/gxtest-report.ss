;;; -*- Gerbil -*-
;;; Gxtest result and timing report helpers.

(import (only-in :std/sort sort)
        (only-in :std/srfi/1 filter find iota)
        (only-in :std/sugar foldl)
        (only-in "../support/time"
                 monotonic-micros
                 duration-micros
                 micros->nanos
                 duration-nanos->text)
        :gerbil/gambit)

(export test-phase-receipt-line
        display-test-phase-receipt
        run-test-phase
        gxtest-progress-line
        display-gxtest-progress
        display-gxtest-stream-line
        record-gxtest-result
        display-gxtest-result
        gxtest-result-file
        gxtest-result-status
        gxtest-result-output
        gxtest-result-elapsed-micros
        gxtest-result-streamed?
        gxtest-summary-line
        gxtest-top-line
        gxtest-failure-line
        display-gxtest-failures
        display-gxtest-timing-summary
        first-failure-status
        gxtest-runner-mode-label)

;; : (-> String Integer String)
(def (test-phase-receipt-line name elapsed-micros)
  (let (elapsed-nanos (micros->nanos elapsed-micros))
    (string-append "[asp-gerbil-scheme-test-phase] name=" name
                   " elapsedNs=" (number->string elapsed-nanos)
                   " elapsed=" (duration-nanos->text elapsed-nanos)
                   "\n")))

;; : (-> String Integer Void)
(def (display-test-phase-receipt name elapsed-micros)
  (display (test-phase-receipt-line name elapsed-micros))
  (force-output))

;; run-test-phase
;;   : (forall (a) (-> String (-> a) a))
;;   | doc m%
;;       `run-test-phase` measures one named runner phase and emits a machine
;;       parseable receipt after the thunk returns.  It keeps timing evidence
;;       close to the phase boundary without changing the thunk's result.
;;
;;       # Examples
;;
;;       ```scheme
;;       (run-test-phase "phase" (lambda () 1))
;;       ;; => 1
;;       ```
;;     %
(def (run-test-phase name thunk)
  (let (start-micros (monotonic-micros))
    (let (result (thunk))
      (display-test-phase-receipt
       name
       (duration-micros start-micros (monotonic-micros)))
      result)))

;; Keep concurrent subprocess output line-atomic. The test runner may own more
;; than one native lane, so an unguarded sequence of display/newline calls can
;; otherwise splice two independently useful traces into one unreadable line.
(def +gxtest-report-output-lock+ (make-mutex 'gxtest-report-output))

;; : (-> String String String Integer String)
(def (gxtest-progress-line name mode state elapsed-micros)
  (let (elapsed-nanos (micros->nanos elapsed-micros))
    (string-append "[asp-gerbil-scheme-test-progress] name=" name
                   " mode=" mode
                   " state=" state
                   " elapsedNs=" (number->string elapsed-nanos)
                   " elapsed=" (duration-nanos->text elapsed-nanos)
                   "\n")))

;; : (-> String String String Integer Void)
(def (display-gxtest-progress name mode state elapsed-micros)
  (with-lock +gxtest-report-output-lock+
    (lambda ()
      (display (gxtest-progress-line name mode state elapsed-micros))
      (force-output))))

;; : (-> String Void)
(def (display-gxtest-stream-line line)
  (with-lock +gxtest-report-output-lock+
    (lambda ()
      (display line)
      (newline)
      (force-output))))

;; : (-> GxTestResult Path)
(def (gxtest-result-file result)
  (list-ref result 0))

;; : (-> GxTestResult Integer)
(def (gxtest-result-status result)
  (list-ref result 1))

;; : (-> GxTestResult String)
(def (gxtest-result-output result)
  (list-ref result 2))

;; : (-> GxTestResult Integer)
(def (gxtest-result-elapsed-micros result)
  (list-ref result 3))

;; The fifth field is an internal delivery marker. Older four-field results are
;; intentionally treated as buffered so existing in-process callers preserve
;; their output behavior.
;; : (-> GxTestResult Boolean)
(def (gxtest-result-streamed? result)
  (and (> (length result) 4)
       (list-ref result 4)))

;; : (-> GxTestResult GxTestResult)
(def (record-gxtest-result result)
  (display-test-phase-receipt
   (string-append "run:" (gxtest-result-file result))
   (gxtest-result-elapsed-micros result))
  result)

;; : (-> GxTestResult Void)
(def (display-gxtest-result result)
  (unless (gxtest-result-streamed? result)
    (display (gxtest-result-output result))))

;; : (-> Integer Integer)
(def (gxtest-micros->nanos micros)
  (micros->nanos micros))

;; : (-> (List GxTestResult) Integer)
(def (gxtest-results-elapsed-micros-sum results)
  (foldl (lambda (result total)
           (+ total (gxtest-result-elapsed-micros result)))
         0
         results))

;; : (-> (List GxTestResult) Integer)
(def (gxtest-results-elapsed-micros-max results)
  (foldl (lambda (result max-micros)
           (max max-micros
                (gxtest-result-elapsed-micros result)))
         0
         results))

;; : (-> (List GxTestResult) (List GxTestResult))
(def (gxtest-results-slowest-first results)
  (sort results
        (lambda (left right)
          (> (gxtest-result-elapsed-micros left)
             (gxtest-result-elapsed-micros right)))))

;; : (forall (a) (-> (List a) Integer (List a)))
(def (gxtest-take values count)
  (cond
   ((or (<= count 0) (null? values)) [])
   (else (cons (car values)
               (gxtest-take (cdr values) (- count 1))))))

;; : (-> String (List GxTestResult) Integer Void)
(def (display-gxtest-result-group-summary kind results wall-micros)
  (display (gxtest-summary-line
            kind
            (length results)
            (gxtest-results-elapsed-micros-sum results)
            wall-micros)))

;; : (-> String Integer Integer Integer String)
(def (gxtest-summary-line kind count sum-micros wall-micros)
  (let ((sum-nanos (gxtest-micros->nanos sum-micros))
        (wall-nanos (gxtest-micros->nanos wall-micros)))
    (string-append "[asp-gerbil-scheme-test-summary] kind=" kind
                   " count=" (number->string count)
                   " sumNs=" (number->string sum-nanos)
                   " sum=" (duration-nanos->text sum-nanos)
                   " wallNs=" (number->string wall-nanos)
                   " wall=" (duration-nanos->text wall-nanos)
                   "\n")))

;; : (-> Integer GxTestResult Void)
(def (display-gxtest-top-result rank result)
  (display (gxtest-top-line rank
                            (gxtest-result-file result)
                            (gxtest-result-elapsed-micros result))))

;; : (-> Integer String Integer String)
(def (gxtest-top-line rank name elapsed-micros)
  (let (elapsed-nanos (gxtest-micros->nanos elapsed-micros))
    (string-append "[asp-gerbil-scheme-test-top] rank=" (number->string rank)
                   " name=" name
                   " elapsedNs=" (number->string elapsed-nanos)
                   " elapsed=" (duration-nanos->text elapsed-nanos)
                   "\n")))

;; : (-> String Integer String)
(def (gxtest-failure-line name status)
  (string-append "[asp-gerbil-scheme-test-failure] name=" name
                 " status=" (number->string status)
                 "\n"))

;; : (-> (List GxTestResult) Void)
(def (display-gxtest-failures results)
  (for-each
   (lambda (result)
     (display (gxtest-failure-line
               (gxtest-result-file result)
               (gxtest-result-status result))))
   (filter failed-gxtest-result? results)))

;; : (-> (List GxTestResult) Void)
(def (display-gxtest-top-results results)
  (let (top-results
        (gxtest-take (gxtest-results-slowest-first results) 8))
    (for-each display-gxtest-top-result
              (iota (length top-results) 1)
              top-results)))

;; : (-> (List GxTestResult) (List GxTestResult) Integer Integer Void)
(def (display-gxtest-timing-summary parallel-results serial-results
                                    parallel-wall-micros
                                    serial-wall-micros)
  (display-gxtest-result-group-summary "parallel"
                                       parallel-results
                                       parallel-wall-micros)
  (display-gxtest-result-group-summary "serial"
                                       serial-results
                                       serial-wall-micros)
  (display-gxtest-top-results (append parallel-results serial-results)))

;; : (-> (List GxTestResult) Integer)
(def (first-failure-status results)
  (let (failure (find failed-gxtest-result? results))
    (if failure (gxtest-result-status failure) 0)))

;; : (-> GxTestResult Boolean)
(def (failed-gxtest-result? result)
  (not (zero? (gxtest-result-status result))))

;; : (-> Boolean Boolean String)
(def (gxtest-runner-mode-label source-in-process? compiled-in-process?)
  (cond
   (compiled-in-process? "compiled-in-process")
   (source-in-process? "source-in-process")
   (else "subprocess")))
