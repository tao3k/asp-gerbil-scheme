;;; -*- Gerbil -*-
;;; Observation-only A/B driver. Every build delegates to std/build-script.
(import :gerbil/runtime/gambit
        (only-in :std/misc/process run-process)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/string/path path-expand)
        (only-in :std/string/misc string-contains))
(export main)

(def fixture "t/scenarios/building/native-import-public-closure")
(def targets '("fixture-prelude.ss" "syntax-helper.ss" "a.ss" "b.ss" "c.ss"))
(def inputs (append targets '("unrelated.ss" "gerbil.pkg")))

;; Native declarations differ only in target projection. No private scheduler,
;; currentness check, compiler driver, or clean implementation is introduced.
(def (prepare-lane output name closure-source)
  (let (root (path-expand name output))
    (create-directory root)
    (for-each (lambda (file) (copy-file (path-expand file fixture)
                                       (path-expand file root))) inputs)
    (when closure-source
      (create-directory (path-expand "owner" root))
      (copy-file closure-source (path-expand "owner/native-import-closure.ss" root))
      (copy-file "src/build-api/package-build.ss" (path-expand "owner/package-build.ss" root)))
    (call-with-output-file (path-expand "build.ss" root)
      (lambda (port)
        (display "(import (only-in :std/build-script defbuild-script))\n" port)
        (if closure-source
          (display "(import (only-in \"./owner/native-import-closure\" asp-gerbil-scheme-native-import-closure))\n(defbuild-script (asp-gerbil-scheme-native-import-closure (current-directory) '(\"c.ss\")))\n" port)
          (begin (display "(defbuild-script '" port) (write targets port)
                 (display ")\n" port)))))
    root))

(def (lane-command root command)
  ["env" "-u" "SDKROOT" "-u" "DEVELOPER_DIR"
   "GERBIL_BUILD_CORES=2" "GERBIL_LOADPATH="
   (string-append "GERBIL_PATH=" (path-expand ".gerbil" root))
   "gerbil" "interactive" "build.ss" command])

;; Capture real child output and native compiler jobs without rescheduling them.
(def (measure root command)
  (displayln "AB-START " root " " command)
  (force-output)
  (let* ((started (current-jiffy))
         (jobs 0)
         (output
          (run-process
           (lane-command root command) directory: root stderr-redirection: #t
           coprocess:
           (lambda (process)
             (call-with-output-file (path-expand (string-append command ".log") root)
               (lambda (log)
                 (call-with-output-string
                  (lambda (capture)
                    (let loop ()
                      (let (line (read-line process))
                        (unless (eof-object? line)
                          (display line log) (newline log)
                          (display line capture) (newline capture)
                          (when (string-contains line "... compile ")
                            (set! jobs (+ jobs 1))
                            (displayln "AB-PROGRESS " line)
                            (force-output))
                          (loop)))))))))))
         (elapsed (quotient (* (- (current-jiffy) started) 1000000)
                            (jiffies-per-second))))
    (displayln "AB-END command=" command " elapsedUs=" elapsed " compilerJobs=" jobs)
    (force-output)
    (list elapsed jobs output)))

(def (read-spec result)
  (call-with-input-string (caddr result) read))

(def (require condition message)
  (unless condition (error message)))

;; The reader runs outside the source tree with only the lane's compiled library.
;; gxi can discard expansion failure status, so acceptance requires its marker.
(def (reader-result root output)
  (let (result
        (run-process
         ["env" "GERBIL_LOADPATH="
          (string-append "GERBIL_PATH=" (path-expand ".gerbil" root))
          "gxi" "-e"
          "(import :asp-native-import-public-closure-fixture/c) (displayln \"AB-RUNTIME=\" fixture-c) (exit 0)"]
         directory: output stderr-redirection: #t check-status: #f))
    (call-with-output-file (path-expand "reader.log" root)
      (lambda (port) (display result port)))
    (and (string-contains result "AB-RUNTIME=3") #t)))

(def (run-lane root output expected)
  (let* ((cold-spec (measure root "spec"))
         (_ (require (equal? (read-spec cold-spec) expected) "unexpected cold BuildSpec"))
         (cold-build (measure root "compile"))
         (warm-spec (measure root "spec"))
         (warm-build (measure root "compile"))
         (runtime? (reader-result root output)))
    (require (= (cadr warm-build) 0) "warm build repeated compiler jobs")
    (list (cons 'cold-spec-us (car cold-spec))
          (cons 'cold-build-us (car cold-build))
          (cons 'cold-compiler-jobs (cadr cold-build))
          (cons 'warm-targets (read-spec warm-spec))
          (cons 'warm-spec-us (car warm-spec))
          (cons 'warm-build-us (car warm-build))
          (cons 'warm-compiler-jobs (cadr warm-build))
          (cons 'runtime-from-compiled-only runtime?)
          (cons 'prelude-interface-exists
                (file-exists? (path-expand ".gerbil/lib/asp-native-import-public-closure-fixture/fixture-prelude.ssi" root))))))

(def (main baseline output)
  (set! baseline (path-expand baseline))
  (set! output (path-expand output))
  (require (not (file-exists? output)) "A/B output must be a fresh owned directory")
  (create-directory output)
  (let* ((old (prepare-lane output "A-before" baseline))
         (before (run-lane old output '("syntax-helper.ss" "a.ss" "b.ss" "c.ss")))
         (samples []))
    (require (not (cdr (assq 'prelude-interface-exists before))) "baseline unexpectedly built prelude")
    (require (not (cdr (assq 'runtime-from-compiled-only before))) "baseline unexpectedly loads without sources")
    ;; Four pairs alternate B/C and C/B, with private cold roots per sample.
    (for-each
     (lambda (round)
       (for-each
        (lambda (lane)
          (let* ((name (string-append (symbol->string lane) "-" (number->string round)))
                 (root (prepare-lane output name
                                     (and (eq? lane 'B) "src/build-api/native-import-closure.ss")))
                 (result (run-lane root output targets)))
            (require (cdr (assq 'prelude-interface-exists result)) "prelude interface missing")
            (require (cdr (assq 'runtime-from-compiled-only result)) "compiled-only runtime failed")
            (require (= (cdr (assq 'cold-compiler-jobs result)) 5) "unexpected cold compiler jobs")
            (set! samples (cons (cons name result) samples))))
        (if (odd? round) '(B C) '(C B))))
     '(1 2 3 4))
    (call-with-output-file (path-expand "results.sexp" output)
      (lambda (port)
        (write (list (cons 'gerbil-version (gerbil-version-string))
                     '(cores . 2) (cons 'baseline-source baseline)
                     (cons 'candidate-source (path-expand "src/build-api/native-import-closure.ss"))
                     (cons 'before before) (cons 'matched-samples (reverse samples))) port)
        (newline port)))
    (displayln "NATIVE-IMPORT-AB-OK " output)))
