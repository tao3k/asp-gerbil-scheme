;;; -*- Gerbil -*-
;;; Package target-selection regression for native public-entry declarations.

(import (only-in :std/test test-suite test-case check)
        (only-in :gerbil/runtime/system gerbil-path)
        (only-in :std/string/path path-expand)
        (only-in :std/misc/process run-process))

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
  (run-process
   ["env" "-u" "DEVELOPER_DIR" "-u" "SDKROOT"
    (string-append "GERBIL_PATH="
                   (path-expand ".gerbil" (current-directory)))
    (string-append "GERBIL_LOADPATH=" +asp-library-root+)
    "gerbil" "interactive" build "spec"]
   directory: +native-import-public-closure-root+
   coprocess: read))

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
        (let ((direct-spec
               (project-build-spec +native-import-direct-root-build+))
              (closure-spec
               (project-build-spec +native-import-public-closure-build+)))
          (displayln
           "[native-import-public-closure-scenario] phase=projected direct-target-count="
           (length direct-spec)
           " closure-target-count=" (length closure-spec))
          (check direct-spec => +native-import-direct-root-expected+)
          (check closure-spec => +native-import-public-closure-expected+)
          (check (member "unrelated.ss" closure-spec) => #f))))))
