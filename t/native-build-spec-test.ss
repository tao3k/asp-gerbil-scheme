;;; -*- Gerbil -*-
;;; Native target specifications remain pure and precede execution ownership.

(import :std/test
        (only-in "../src/build-api/native-build-spec"
                 configure-build-root!
                 compile-spec
                 cli-binary-build-spec)
        (only-in "../src/build-api/package-native-plan"
                 asp-gerbil-scheme-package-api-stage-specs)
        (only-in "../src/build-api/source-coverage"
                 asp-gerbil-scheme-load-source-coverage))

(export native-build-spec-test)

(def (module-stage-index stages module)
  (let loop ((remaining stages) (index 0))
    (cond
     ((null? remaining) #f)
     ((member module (car remaining)) index)
     (else (loop (cdr remaining) (+ index 1))))))

(def native-build-spec-test
  (test-suite "native build specification boundary"
    (test-case "spec owner precedes native execution owner"
      (asp-gerbil-scheme-load-source-coverage ".")
      (let* ((stages (asp-gerbil-scheme-package-api-stage-specs))
             (spec-index
              (module-stage-index stages "build-api/native-build-spec.ss"))
             (execution-index
              (module-stage-index stages "build-api/native-build.ss")))
        (check (integer? spec-index) => #t)
        (check (integer? execution-index) => #t)
        (check (< spec-index execution-index) => #t)))
    (test-case "pure specs expose package and binary projections"
      (asp-gerbil-scheme-load-source-coverage ".")
      (configure-build-root! (current-directory))
      (let ((package-spec (compile-spec #f #f #f))
            (binary-spec (cli-binary-build-spec #f)))
        (check (member "build-api/native-build-spec.ss" package-spec) ? true)
        (check (member "build-api/native-build.ss" package-spec) ? true)
        (check (member "constants.ss" binary-spec) ? true)))))

(run-tests! native-build-spec-test)
