;;; -*- Gerbil -*-
;;; Gxtest discovery facade and batch planning.

(import (only-in :std/misc/path path-strip-directory)
        (only-in :std/srfi/1 any)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :std/sugar filter foldl hash-get hash-key? hash-put!)
        (only-in "./gxtest-syntax"
                 gxtest-export-symbols
                 gxtest-file-forms-path
                 gxtest-file-forms
                 gxtest-file-exported-symbols
                 gxtest-file-exported-suite?
                 gxtest-file-exported-suite
                 gxtest-file-self-running?
                 gxtest-file-local-suite?
                 gxtest-files-local-suite?
                 gxtest-file-module-symbol)
        :gerbil/gambit)

(export gxtest-export-symbols
        gxtest-file-forms
        gxtest-file-exported-symbols
        gxtest-file-exported-suite
        gxtest-file-local-suite?
        gxtest-files-local-suite?
        gxtest-file-module-symbol
        compiled-in-process-gxtest-file?
        gxtest-selected-test-files
        source-isolated-gxtest-file?
        parallel-gxtest-files
        serial-gxtest-files)

(import :asp-gerbil-scheme/src/testing/memory-profile)
(import :asp-gerbil-scheme/src/testing/execution-profile)

;; The package build has already established the native source graph. Test
;; planning classifies only explicit runner entries and never reparses imports
;; to manufacture a second build graph.
(def (compiled-in-process-gxtest-file? file)
  (and (gxtest-file-exported-suite? file)
       (not (gxtest-file-self-running? file))))

(def (gxtest-selected-test-files files)
  (filter (lambda (file) (string-prefix? "t/" file)) files))

;; : (-> Form Boolean)
(def (gxtest-benchmark-form? form)
  (and (pair? form)
       (or (memq (car form)
                 '(benchmark-contract-run
                   benchmark-contract-run/root
                   benchmark-run
                   benchmark-run/result
                   policy-scenario-run/timed
                   agent-style-policy-r013-scenario-context))
           (gxtest-benchmark-form? (car form))
           (gxtest-benchmark-form? (cdr form)))))

;; : (-> Path Boolean)
(def (gxtest-file-benchmark? file)
  (any gxtest-benchmark-form? (gxtest-file-forms file)))

;; : (-> Path Boolean)
;; : (-> Path Boolean)
(def (timing-sensitive-gxtest-file? file)
  (or (gxtest-file-benchmark? file)
      (gxtest-file-serial? file)))

;; : (-> Path Boolean)
(def (source-isolated-gxtest-file? file)
  (gxtest-file-memory-exception? file))

;; : (-> Path Boolean)
(def (parallel-gxtest-file? file)
  (not (timing-sensitive-gxtest-file? file)))

;; : (-> (List Path) (List Path))
(def (parallel-gxtest-files files)
  (filter parallel-gxtest-file? files))

;; : (-> (List Path) (List Path))
(def (serial-gxtest-files files)
  (filter timing-sensitive-gxtest-file? files))
