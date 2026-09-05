;;; -*- Gerbil -*-
;;; Canonical package-build acceptance scenarios.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/types/facade
        "./fixtures")

(export agent-build-canonical-acceptance-policy-test)

;; PolicyTest
(def agent-build-canonical-acceptance-policy-test
  (test-suite "gerbil scheme harness package build canonical acceptance policy"
    (test-case "agent policy accepts clan/building package build"
      (let ((root ".run/policy-package-build-canonical-clan-building"))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/build-canonical-clan-building)\n")
        (write-text
         (string-append root "/build.ss")
         ";;; -*- Gerbil -*-\n(import :std/make\n        :clan/base\n        :clan/building)\n(def (spec)\n  (!> (all-gerbil-modules)\n      (cut cons \"t/unit/build-runtime\" <>)))\n(init-build-environment!\n name: \"sample-package\"\n deps: '(\"clan\")\n spec: spec)\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index)))
          (check (filter-rule "GERBIL-SCHEME-AGENT-POLICY-025" findings) => [])
          (check (filter-rule "GERBIL-SCHEME-AGENT-POLICY-020" findings) => []))))
    (test-case "agent policy accepts only-in clan/building package build"
      (let ((root ".run/policy-package-build-canonical-only-in-clan-building"))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/build-canonical-only-in-clan-building)\n")
        (write-text
         (string-append root "/build.ss")
         ";;; -*- Gerbil -*-\n(import :std/make\n        :clan/base\n        (only-in :clan/building init-build-environment! all-gerbil-modules))\n(def (spec)\n  (!> (all-gerbil-modules)\n      (cut cons \"t/unit/build-runtime\" <>)))\n(init-build-environment!\n name: \"sample-package\"\n deps: '(\"clan\")\n spec: spec)\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index)))
          (check (filter-rule "GERBIL-SCHEME-AGENT-POLICY-025" findings) => [])
          (check (filter-rule "GERBIL-SCHEME-AGENT-POLICY-020" findings) => []))))
    (test-case "agent policy accepts thin harness build API declarations"
      (let* ((root "t/scenarios/policy/package-build-framework-overreach/expected")
             (index (collect-project root))
             (findings (run-agent-policy index)))
        (check (filter-rule "GERBIL-SCHEME-AGENT-POLICY-025" findings) => [])
        (check (filter-rule "GERBIL-SCHEME-AGENT-POLICY-020" findings) => [])))
    (test-case "agent policy accepts compositional provider build stages"
      (let ((root ".run/policy-package-build-canonical-stage-table"))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/build-canonical-stage-table)\n")
        (write-text
         (string-append root "/build.ss")
         ";;; -*- Gerbil -*-\n(import :std/make\n        :clan/base\n        :clan/building)\n(defstruct provider-build-stage (name action))\n(def (spec)\n  (!> (all-gerbil-modules)\n      (cut cons \"t/unit/build-runtime\" <>)))\n(def (provider-build-stages)\n  [(make-provider-build-stage \"compile\" (lambda (args) args))])\n(def (provider-build-stage-ref name)\n  (find (lambda (stage) (equal? (provider-build-stage-name stage) name)) (provider-build-stages)))\n(def (run-provider-build-stage! stage args)\n  ((provider-build-stage-action stage) args))\n(init-build-environment!\n name: \"sample-package\"\n deps: '(\"clan\")\n spec: spec)\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index)))
          (check (filter-rule "GERBIL-SCHEME-AGENT-POLICY-025" findings) => []))))
    (test-case "agent policy accepts provider build-runtime stage owner"
      (let* ((root ".run/policy-package-build-canonical-provider-build-include")
             (src (string-append root "/src"))
             (support (string-append src "/build-api")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src)
        (ensure-dir support)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/build-canonical-provider-build-include)\n")
        (write-text
         (string-append root "/build.ss")
         ";;; -*- Gerbil -*-\n(import :std/make\n        :clan/base\n        :clan/building)\n(def (spec)\n  (!> (all-gerbil-modules)\n      (cut cons \"t/unit/build-runtime\" <>)))\n(include \"src/build-api/provider-build.ss\")\n(init-build-environment!\n name: \"sample-package\"\n deps: '(\"clan\")\n spec: spec)\n")
        (write-text
         (string-append support "/provider-build.ss")
         ";;; -*- Gerbil -*-\n(def (provider-build-spec)\n  '(\"src/main\"))\n(def (run-build! args)\n  (apply make (provider-build-spec) srcdir: (current-directory) []))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index)))
          (check (filter-rule "GERBIL-SCHEME-AGENT-POLICY-025" findings) => []))))
    (test-case "agent policy accepts native dispatcher build-runtime owner"
      (let* ((root ".run/policy-build-runtime-native-dispatcher")
             (src (string-append root "/src"))
             (support (string-append src "/build-api")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src)
        (ensure-dir support)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/build-runtime-native-dispatcher)\n")
        (write-text
         (string-append support "/provider-cli.ss")
         ";;; -*- Gerbil -*-\n(def (native-dispatcher-source-text config)\n  \"int owner_items_native_main(int argc, char **argv);\\n\")\n(def (write-provider-native-dispatcher-source! path config)\n  (write-file! path (native-dispatcher-source-text config)))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index)))
          (check (filter-rule "GERBIL-SCHEME-AGENT-POLICY-019" findings) => [])
          (check (filter-rule "GERBIL-SCHEME-AGENT-POLICY-020" findings) => []))))))
