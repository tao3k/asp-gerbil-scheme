#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import :std/make
        :asp-gerbil-scheme/building-api)

(def +package-build-phase-receipt-schema+ "sample.build.phase.v1")
(def +package-build-cache-stamp+ ".cache/sample/build.stamp")
(def +package-build-worker-count+ 4)

(asp-gerbil-scheme-package-spec!
 (sample-package-spec @ asp-gerbil-scheme-library-package-prototype)
 (spec spec)
 (modules '("src/main.ss")))

(def (package-build-cache-fresh? stage)
  (and (file-exists? +package-build-cache-stamp+)
       stage))

(def (package-build-write-build-stamp! stage)
  (call-with-output-file +package-build-cache-stamp+
    (lambda (out)
      (write stage out))))

(def (package-build-emit-phase-receipt event stage)
  [event stage])

(def (package-build-job-queue modules)
  (map (lambda (module)
         [module +package-build-worker-count+])
       modules))

(def (package-build-run-worker! job options)
  (apply make [(car job)] options))

(def (package-build-run-jobs! jobs options)
  (for-each (lambda (job)
              (package-build-run-worker! job options))
            jobs))

(def (compile-package! options)
  (if (package-build-cache-fresh? (spec))
    (package-build-emit-phase-receipt "phase-skip" (spec))
    (begin
      (package-build-run-jobs! (package-build-job-queue (spec)) options)
      (apply make (spec) options)
      (package-build-write-build-stamp! (spec)))))
