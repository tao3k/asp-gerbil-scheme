;;; -*- Gerbil -*-
;;; Process-level regression for root-only native Import Model projection.

(import (only-in :std/test test-suite test-case check)
        (only-in :gerbil/runtime/system gerbil-path)
        (only-in :std/string/path path-expand)
        (only-in :std/misc/process run-process)
        (only-in ../src/support/time call-with-timing)
        (only-in :asp-gerbil-scheme/src/build-api/native-import-closure
                 asp-gerbil-scheme-native-import-closure))

(export native-import-public-closure-scenario-test)

(def +native-import-public-closure-root+
  "t/scenarios/building/native-import-public-closure")

(def +native-import-direct-root-build+ "modules-build.ss")
(def +native-import-public-closure-build+ "build.ss")

(def +native-import-public-closure-contract+
  "t/scenarios/building/native-import-public-closure/scenario-contract.ss")

(def +asp-library-root+ (path-expand "lib" (gerbil-path)))

(def +native-import-public-closure-expected+
  '("syntax-helper.ss" "a.ss" "b.ss" "c.ss"))
(def +native-import-direct-root-expected+ '("c.ss"))

(def (native-import-public-closure-contract-ref contract key)
  (let (entry (assq key contract))
    (and entry (cdr entry))))

(def (project-build-spec build)
  (call-with-timing
   (lambda ()
     (run-process
      ["env" "-u" "DEVELOPER_DIR" "-u" "SDKROOT"
       (string-append "GERBIL_PATH="
                      (path-expand ".gerbil" (current-directory)))
       (string-append "GERBIL_LOADPATH=" +asp-library-root+)
       "gerbil" "interactive" build "spec"]
      directory: +native-import-public-closure-root+
     coprocess: read))))

(def (build-native-import-fixture!)
  (let* ((root (path-expand +native-import-public-closure-root+
                            (current-directory)))
         (gerbil-path (path-expand ".gerbil" root)))
    (run-process
     ["env" "-u" "DEVELOPER_DIR" "-u" "SDKROOT"
      (string-append "GERBIL_PATH=" gerbil-path)
      (string-append "GERBIL_LOADPATH=" +asp-library-root+)
      "gerbil" "build"]
     directory: root)
    (add-load-path! (path-expand "lib" gerbil-path))))

(def native-import-public-closure-scenario-test
  (test-suite "native Import Model public closure scenario"
    (test-case "modules and public-entry-modules preserve distinct root modes"
      (let (contract
            (call-with-input-file +native-import-public-closure-contract+ read))
        (check (native-import-public-closure-contract-ref
                contract 'scenarioKind)
               => 'native-gerbil-build)
        (check (native-import-public-closure-contract-ref
                contract 'attemptCount)
               => 2)
        (let-values (((direct-nanoseconds direct-spec)
                      (project-build-spec +native-import-direct-root-build+))
                     ((closure-nanoseconds closure-spec)
                      (project-build-spec +native-import-public-closure-build+)))
          (displayln
           "[native-import-public-closure-scenario] phase=projected direct-target-count="
           (length direct-spec)
           " closure-target-count=" (length closure-spec)
           " direct-elapsed-ns=" direct-nanoseconds
           " closure-elapsed-ns=" closure-nanoseconds)
          (check direct-spec => +native-import-direct-root-expected+)
          (check closure-spec => +native-import-public-closure-expected+)
          (check (member "unrelated.ss" closure-spec) => #f))))
    (test-case "current compiled interfaces preserve native closure in milliseconds"
      (let* ((contract
              (call-with-input-file +native-import-public-closure-contract+ read))
             (root (path-expand +native-import-public-closure-root+
                                (current-directory))))
        (build-native-import-fixture!)
        (let-values (((elapsed-nanoseconds closure)
                      (call-with-timing
                       (lambda ()
                         (asp-gerbil-scheme-native-import-closure
                          root '("c.ss"))))))
          (displayln
           "[native-import-public-closure-scenario] phase=current-interface"
           " target-count=" (length closure)
           " elapsed-ns=" elapsed-nanoseconds)
          (check closure => +native-import-public-closure-expected+)
          (check (< elapsed-nanoseconds
                    (native-import-public-closure-contract-ref
                     contract 'maxCurrentInterfaceProjectionNanoseconds))
                 => #t))))))
