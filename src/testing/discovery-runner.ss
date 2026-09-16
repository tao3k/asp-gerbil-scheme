;;; -*- Gerbil -*-
;;; Native clan/testing trampoline for a declarative ASP testing object.
;;;
;;; Projects declare slots and Profile mappings through testing-api.  Only the
;;; package test entrypoint imports this module, so discovery and CLI machinery
;;; are absent from ordinary library consumers.

(import :gerbil/gambit
        (only-in :clan/testing find-test-files %set-test-environment!)
        (only-in :std/cli/multicall
                 define-entry-point
                 define-multicall-main
                 set-default-entry-point!)
        (only-in :std/cli/print-exit silent-exit)
        (only-in :std/source this-source-file)
        (only-in :std/srfi/1 filter)
        (only-in :std/sugar with-id)
        (only-in ./extension
                 testing-interface-test-file-included?
                 testing-interface-run-test-files!))

(export testing-interface-test-files
        init-profiled-test-environment!)

(def (testing-interface-test-files testing test
                                   pkgdir: (pkgdir ".")
                                   regex: (regex "-test.ss$"))
  (filter (cut testing-interface-test-file-included? testing test <>)
          (find-test-files pkgdir regex)))

(def (testing-elapsed-nanoseconds started-jiffy)
  (quotient (* (- (current-jiffy) started-jiffy) 1000000000)
            (jiffies-per-second)))

;;; Macro expansion captures the caller's unit-tests.ss source location.  The
;;; imported runner is merely the native execution trampoline; the supplied
;;; testing object remains the sole declaration of enabled Profiles and slots.
(defrules init-profiled-test-environment! ()
  ((ctx testing)
   (begin
     (def here (this-source-file ctx))
     (with-id ctx (main)
       (define-multicall-main ctx))
     (define-entry-point (asp-profiled-unit-tests)
       (help: "Run clan unit tests through ASP POO profiles"
        getopt: [])
       (%set-test-environment! here)
       (displayln "[asp-testing] phase=entry-ready")
       (force-output)
       (silent-exit
        (let* ((started-jiffy (current-jiffy))
               (test-files
                (testing-interface-test-files testing "unit-tests.ss")))
          (displayln "[asp-testing] phase=discovery-complete elapsedNs="
                     (testing-elapsed-nanoseconds started-jiffy)
                     " fileCount=" (length test-files))
          (force-output)
          (testing-interface-run-test-files! testing test-files))))
     (set-default-entry-point! 'asp-profiled-unit-tests))))
