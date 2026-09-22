;;; -*- Gerbil -*-
;;; Native Gerbil testing trampoline for a declarative ASP testing object.
;;;
;;; Projects declare slots and Profile mappings through testing-api.  Only the
;;; package test entrypoint imports this module, so discovery and CLI machinery
;;; are absent from ordinary library consumers.

(import :gerbil/runtime/gambit
        (only-in :std/cli/multicall
                 define-entry-point
                 call-entry-point
                 set-default-entry-point!)
        (only-in :std/cli/print-exit silent-exit)
        (only-in :std/source this-source-file)
        (only-in :std/list/list filter)
        (only-in :std/string/path path-expand path-directory)
        (only-in :std/text/pregexp pregexp-match)
        (only-in ./extension
                 testing-interface-test-file-included?
                 testing-interface-run-test-files!))

(export testing-interface-test-files
        init-profiled-test-environment!)

;;   : (forall (t) (-> t String String (List Path)))
;; testing-interface-test-files
;;   : (-> TestingInterface TestName Path String (List Path))
;;   | doc m%
;;       Discovers Gerbil test files, then applies the declarative ASP
;;       TestingInterface inclusion slots before execution.
;;
;;       # Examples
;;       ```scheme
;;       (testing-interface-test-files testing "unit-tests.ss")
;;       ;; => ("t/example-test.ss")
;;       ```
;;     %
(def (testing-interface-test-files testing test
                                   pkgdir: (pkgdir ".")
                                   regex: (regex "-test.ss$"))
  (filter (cut testing-interface-test-file-included? testing test <>)
          (let (files [])
            (let walk ((path pkgdir) (inside-test-dir? #f))
              (let (info (file-info path #f))
                (cond
                 ((and info (eq? (file-info-type info) 'directory))
                  (unless (equal? (path-strip-directory path) "dep")
                    (for-each
                     (lambda (name)
                       (unless (or (equal? name ".") (equal? name ".."))
                         (walk (path-expand name path)
                               (or inside-test-dir? (equal? name "t")))))
                     (directory-files path))))
                 ((and inside-test-dir? (pregexp-match regex path))
                  (set! files (cons path files))))))
            (list-sort string<? files))))

;; %set-test-environment!
;;   : (-> Path Void)
;;   | doc m%
;;       Install the declaring package root as the native test environment.
;;
;;       # Examples
;;       ```scheme
;;       (%set-test-environment! "/workspace/unit-tests.ss")
;;       ;; => current-directory is /workspace
;;       ```
;;     %
(def (%set-test-environment! script-path)
  (let (root (path-directory script-path))
    (current-directory root)
    (set-load-path! (cons root (load-path)))))

;; testing-elapsed-nanoseconds
;;   : (-> Integer Integer)
;;   | doc m%
;;       Convert a native jiffy interval into nanoseconds for test progress
;;       receipts without changing the test executor's clock or lifecycle.
;;
;;       # Examples
;;       ```scheme
;;       (testing-elapsed-nanoseconds (current-jiffy))
;;       ;; => a nonnegative integer
;;       ```
;;     %
(def (testing-elapsed-nanoseconds started-jiffy)
  (quotient (* (- (current-jiffy) started-jiffy) 1000000000)
            (jiffies-per-second)))

;;; Macro expansion captures the caller's unit-tests.ss source location.  The
;;; imported runner is merely the native execution trampoline; the supplied
;;; testing object remains the sole declaration of enabled Profiles and slots.
;; init-profiled-test-environment!
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       Installs the native gxtest entrypoint around one declarative ASP
;;       TestingInterface value without creating a second test runner.
;;
;;       # Examples
;;       ```scheme
;;       (init-profiled-test-environment! +asp-testing-interface+)
;;       ;; => native gxtest entrypoint declarations
;;       ```
;;     %
(defrules init-profiled-test-environment! ()
  ((ctx testing)
   (begin
     (def here (this-source-file ctx))
     (def main call-entry-point)
     (define-entry-point (asp-profiled-unit-tests)
       (help: "Run Gerbil unit tests through ASP POO profiles"
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
