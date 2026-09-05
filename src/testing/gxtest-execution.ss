;;; -*- Gerbil -*-
;;; Gxtest execution and native scheduling helpers.

(import (only-in :std/misc/path path-expand)
        (only-in :std/misc/process run-process)
        (only-in :std/misc/channel
                 make-channel
                 channel-close
                 channel-put)
        (only-in :std/iter for)
        (only-in :std/srfi/1 concatenate iota partition)
        (only-in :std/sugar spawn/name)
        (only-in "../support/time" monotonic-micros duration-micros)
        (only-in "./gxtest-context"
                 package-root)
        (only-in "./gxtest-expression"
                 gxtest-compiled-batch-expression
                 gxtest-source-load-batch-expression
                 gxtest-batch-expression
                 gxtest-batch-label)
        (only-in "./gxtest-report"
                 test-phase-receipt-line
                 display-test-phase-receipt
                 run-test-phase
                 record-gxtest-result
                 display-gxtest-result
                 gxtest-result-file
                 gxtest-result-status
                 gxtest-result-elapsed-micros
                 gxtest-summary-line
                 gxtest-top-line
                 gxtest-failure-line
                 display-gxtest-failures
                 display-gxtest-timing-summary
                 first-failure-status
                 gxtest-runner-mode-label)
        (only-in "./memory-profile"
                 gxtest-file-memory-runtime-options)
        (only-in "./execution-profile"
                 gxtest-file-serial-resource)
        :gerbil/gambit)

(export test-phase-receipt-line
        display-test-phase-receipt
        run-test-phase
        gxtest-compiled-batch-expression
        gxtest-source-load-batch-expression
        gxtest-batch-label
        gxtest-summary-line
        gxtest-top-line
        gxtest-failure-line
        display-gxtest-failures
        run-gxtest-parallel-phase
        run-gxtest-serial-phase
        display-gxtest-timing-summary
        display-gxtest-result
        first-failure-status
        gxtest-runner-mode-label
        gxtest-result-status
        gxtest-native-parallelism
        gxtest-serial-resource-groups
        run-gxtest-file/subprocess)

;; Keep test execution aligned with std/make without introducing a second
;; public concurrency policy. Gerbil treats an unset value as one active lane.
(def (gxtest-native-parallelism (file-count #f))
  (let* ((configured
          (let (value (string->number (getenv "GERBIL_BUILD_CORES" "0")))
            (if (integer? value) value 0)))
         (active (max 1 configured)))
    (if file-count
      (min active (max 1 file-count))
      active)))

;; : (-> Integer Integer)
(def (normalized-exit-status status)
  (cond
   ((and (integer? status) (> status 255))
    (quotient status 256))
   ((integer? status) status)
   (else 1)))

;; : (-> (List Path) String GxTestResult)
(def (run-gxtest-batch/process files expression)
  (let ((status 0)
        (start-micros (monotonic-micros))
        (label (gxtest-batch-label files)))
    (let (output
          (run-process (append ["gxi"]
                               (if (and (pair? files)
                                        (null? (cdr files)))
                                 (gxtest-file-memory-runtime-options (car files))
                                 [])
                               ["-e" expression])
                       directory: package-root
                       stderr-redirection: #t
                       check-status:
                       (lambda (exit-status _settings)
                         (set! status
                           (normalized-exit-status exit-status)))))
      (list label
            status
            output
            (duration-micros start-micros (monotonic-micros))))))

;; : (-> (List Path) GxTestResult)
(def (run-gxtest-batch/subprocess files)
  (run-gxtest-batch/process files
                             (gxtest-batch-expression files)))

;; : (-> (List Path) GxTestResult)
(def (run-gxtest-batch/compiled-subprocess files)
  (run-gxtest-batch/process files
                             (gxtest-compiled-batch-expression files)))

;; : (-> Mutex)
(def +compiled-gxtest-eval-lock+ (make-mutex 'compiled-gxtest-eval))

;; : (-> (List Path) Boolean)
(def (eval-compiled-gxtest-batch! files)
  (with-lock +compiled-gxtest-eval-lock+
    (lambda ()
      (eval (call-with-input-string
              (gxtest-compiled-batch-expression files)
              read)))))

;; : (-> (List Path) Boolean)
(def (eval-source-gxtest-batch! files)
  (with-lock +compiled-gxtest-eval-lock+
    (lambda ()
      (eval (call-with-input-string
              (gxtest-source-load-batch-expression files)
              read)))))

;; : (-> (-> Boolean) (Values Integer String))
(def (write-gxtest-exception exn port)
  (parameterize ((dump-stack-trace? #f))
    (display-exception exn port)))

;; : (-> (-> Boolean) (Values Integer String))
(def (capture-gxtest-eval thunk)
  (let (status 0)
    (let (output
          (call-with-output-string
            (lambda (port)
              (with-catch
               (lambda (exn)
                 (set! status 1)
                 (write-gxtest-exception exn port)
                 (newline port))
               (lambda ()
                 (parameterize ((current-output-port port)
                                (current-error-port port))
                   (unless (thunk)
                     (set! status 1))))))))
      (values status output))))

;; : (-> (List Path) (-> (List Path) Boolean) GxTestResult)
(def (run-gxtest-batch/in-process files eval-thunk)
  (let ((start-micros (monotonic-micros))
        (label (gxtest-batch-label files)))
    (call-with-values
      (lambda ()
        (capture-gxtest-eval
         (lambda ()
           (eval-thunk files))))
      (lambda (status output)
        (list label
              status
              output
              (duration-micros start-micros (monotonic-micros)))))))

;; : (-> (List Path) GxTestResult)
(def (run-gxtest-batch/compiled-in-process files)
  (add-load-path! (path-expand ".gerbil/lib" package-root))
  (run-gxtest-batch/in-process files eval-compiled-gxtest-batch!))

;; : (-> (List Path) GxTestResult)
(def (run-gxtest-batch/source-in-process files)
  (run-gxtest-batch/in-process files eval-source-gxtest-batch!))

;; : (-> Path GxTestResult)
(def (run-gxtest-file/subprocess file)
  (run-gxtest-batch/subprocess [file]))

;; : (-> (List Path) (List GxTestResult))
(def (serial-gxtest-results files)
  (map (lambda (file)
         (record-gxtest-result (run-gxtest-file/subprocess file)))
       files))

;; : (-> (List Path) (List (List Path)))
(def (gxtest-serial-resource-groups files)
  (if (null? files)
    []
    (let (resource (gxtest-file-serial-resource (car files)))
      (let-values (((matching remaining)
                    (partition
                     (lambda (file)
                       (eq? (gxtest-file-serial-resource file) resource))
                     files)))
        (cons matching (gxtest-serial-resource-groups remaining))))))

;; Each resource group owns one lane. Files in a group remain strictly ordered;
;; independent resources can progress without serializing the whole suite.
;; : (-> (List (List Path)) (List GxTestResult))
(def (resource-group-gxtest-results groups)
  (if (null? groups)
    []
    (let* ((tasks (make-channel))
           (results (make-vector (length groups) #f))
           (run-task
            (lambda (task)
              (vector-set! results
                           (car task)
                           (serial-gxtest-results (cdr task)))))
           (run-lane
            (lambda ()
              (for (task tasks)
                (run-task task))))
           (lanes
            (map (lambda (index)
                   (spawn/name `(gxtest-resource-lane ,index) run-lane))
                 (iota (gxtest-native-parallelism (length groups))))))
      (let enqueue ((rest groups) (index 0))
        (unless (null? rest)
          (channel-put tasks (cons index (car rest)))
          (enqueue (cdr rest) (+ index 1))))
      (channel-close tasks)
      (for-each thread-join! lanes)
      (concatenate (vector->list results)))))

;; Each file owns one native gxtest process. Gerbil channels and named threads
;; provide the same scheduling primitives used by std/make, while process exit
;; reclaims module state after every file.
(def (isolated-gxtest-results files)
  (if (null? files)
    []
    (let* ((tasks (make-channel))
           (results (make-vector (length files) #f))
           (run-task
            (lambda (task)
              (vector-set! results
                           (car task)
                           (run-gxtest-file/subprocess (cdr task)))))
           (run-lane
            (lambda ()
              (for (task tasks)
                (run-task task))))
           (lanes
            (map (lambda (index)
                   (spawn/name `(gxtest-native-lane ,index) run-lane))
                 (iota (gxtest-native-parallelism (length files))))))
      (let enqueue ((rest files) (index 0))
        (unless (null? rest)
          (channel-put tasks (cons index (car rest)))
          (enqueue (cdr rest) (+ index 1))))
      (channel-close tasks)
      (for-each thread-join! lanes)
      (map record-gxtest-result (vector->list results)))))

;; : (-> (List Path) Boolean GxTestResult)
(def (run-gxtest-in-process-batch files compiled-in-process?)
  (if compiled-in-process?
    (run-gxtest-batch/compiled-in-process files)
    (run-gxtest-batch/source-in-process files)))

;; : (-> (List Path) (List Path) Boolean Boolean (List GxTestResult))
(def (run-gxtest-parallel-phase files parallel-files
                                source-in-process? compiled-in-process?)
  (if source-in-process?
    (list (record-gxtest-result
           (run-gxtest-in-process-batch files compiled-in-process?)))
    (isolated-gxtest-results parallel-files)))

;; : (-> (List Path) Boolean (List GxTestResult))
(def (run-gxtest-serial-phase serial-files source-in-process?)
  (if source-in-process?
    []
    (let-values (((resource-files benchmark-files)
                  (partition gxtest-file-serial-resource serial-files)))
      (append
       (resource-group-gxtest-results
        (gxtest-serial-resource-groups resource-files))
       (serial-gxtest-results benchmark-files)))))
