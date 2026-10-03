;;; -*- Gerbil -*-
;;; Package target-selection regression for native public-entry declarations.

(import (only-in :std/test test-suite test-case check)
        (only-in :gerbil/runtime/system gerbil-path)
        (only-in :std/string/path path-expand)
        (only-in :std/misc/process run-process run-process/batch))

(export native-import-public-closure-scenario-test)

(def +native-import-public-closure-root+
  "t/scenarios/building/native-import-public-closure")

(def +native-import-direct-root-build+ "modules-build.ss")
(def +native-import-public-closure-build+ "build.ss")

(def +native-import-public-closure-contract+
  "t/scenarios/building/native-import-public-closure/scenario-contract.ss")

(def +asp-library-root+ (path-expand "lib" (gerbil-path)))

(def +native-import-public-closure-expected+
  '("fixture-prelude.ss" "syntax-helper.ss" "a.ss" "b.ss" "c.ss"))
;; Compiled import metadata preserves the existing higher-phase-first order.
(def +native-import-compiled-closure-expected+
  '("syntax-helper.ss" "fixture-prelude.ss" "a.ss" "b.ss" "c.ss"))
(def +native-import-direct-root-expected+ '("c.ss"))

(def (native-import-public-closure-contract-ref contract key)
  (let (entry (assq key contract))
    (and entry (cdr entry))))

(def (native-build-command build command)
  ["env" "-u" "DEVELOPER_DIR" "-u" "SDKROOT"
    (string-append "GERBIL_PATH="
                   (path-expand ".gerbil" (current-directory)))
    (string-append "GERBIL_LOADPATH=" +asp-library-root+)
    "gerbil" "interactive" build command])

(def (project-build-spec build)
  (run-process
   (native-build-command build "spec")
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
               => 5)
        ;; Native clean forces source-context projection, then native compile
        ;; produces the interfaces used by the warm metadata projection.
        (displayln "[native-import-public-closure-scenario] phase=clean")
        (force-output)
        (run-process/batch
         (native-build-command +native-import-public-closure-build+ "clean")
         directory: +native-import-public-closure-root+)
        (displayln "[native-import-public-closure-scenario] phase=source-spec")
        (force-output)
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
          (check (member "unrelated.ss" closure-spec) => #f)
          (run-process/batch
           (native-build-command +native-import-public-closure-build+ "compile")
           directory: +native-import-public-closure-root+)
          (let (warm-spec (project-build-spec +native-import-public-closure-build+))
            (displayln "[native-import-public-closure-scenario] phase=compiled target-count="
                       (length warm-spec))
            (check warm-spec => +native-import-compiled-closure-expected+)))))))
