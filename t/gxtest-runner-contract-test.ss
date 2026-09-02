;;; -*- Gerbil -*-
;;; Gxtest runner and default smoke target contract tests.

(import :gerbil/gambit
        :std/test
        (only-in :std/misc/path path-expand)
        (only-in :std/srfi/1 append-map)
        (only-in :std/srfi/13 string-contains)
        (only-in "../src/build-api/package-spec"
                 asp-gerbil-scheme-package-api-spec
                 asp-gerbil-scheme-package-api-stage-specs)
        (only-in "../src/policy/gxtest"
                 make-gxtest-policy-test)
        "../src/testing/model"
        "../src/testing/gxtest-runner"
        (only-in "../src/testing/gxtest-execution"
                 gxtest-native-parallelism
                 gxtest-serial-resource-groups)
        :asp-gerbil-scheme/src/testing/memory-profile)
(export gxtest-runner-contract-test)

(declare-gxtest-memory-exception
 '((maxHeapMiB . 512)))

;; : (-> (List (List Path)) Path MaybeInteger)
(def (stage-index-containing stages file)
  (let loop ((rest stages) (index 0))
    (cond
     ((null? rest) #f)
     ((member file (car rest)) index)
     (else (loop (cdr rest) (+ index 1))))))

;; : (-> (List (List Path)) (List Path))
(def (stage-files stages)
  (append-map (lambda (stage) stage) stages))

(def gxtest-runner-contract-test
  (test-suite "asp-gerbil-scheme gxtest runner contract"
    (test-case "gxtest entry files are discovered from default test root"
      (configure-build-root! (current-directory))
      (let (files (gxtest-test-files))
        (check (member "t/policy-test.ss" files) ? true)
        (check (member "t/parser-test.ss" files) ? true)
        (check (member "t/project-policy-test.ss" files) => #f)
        (check (member "t/policy/agent-poo-hot-loop-core-test.ss" files)
               ? true)
        (check (member "t/policy/agent-source-scope-test.ss" files) => #f))
      (check (member "policy-test.ss" (gxtest-test-spec)) ? true))
    (test-case "default gxtest files stay on the smoke gate"
      (configure-build-root! (current-directory))
      (let (files (default-gxtest-test-files))
        (check (length files) => 8)
        (check (member "t/agent-poo-scenario-contract-test.ss" files) ? true)
        (check (member "t/build-install-test.ss" files) ? true)
        (check (member "t/source-closure-test.ss" files) ? true)
        (check (member "t/parser-memory-stability-test.ss" files) ? true)
        (check (member "t/self-apply-full-gate.ss" files) => #f)
        (check (member "t/package-build-receipt-test.ss" files) => #f)
        (check (member "t/extensions-test.ss" files) => #f)
        (check (member "t/gxtest-runner-contract-test.ss" files) => #f)
        (check (member "t/source-coverage-test.ss" files) => #f)
        (check (member "t/support-test.ss" files) ? true)
        (check (member "t/testing-memory-profile-test.ss" files) ? true)
        (check (member "t/testing-framework-smoke-test.ss" files) ? true)
        (check (member "t/testing-framework-test.ss" files) => #f)
        (check (member "t/testing-framework-downstream-test.ss" files) => #f)
        (check (member "t/type-validation-facade-test.ss" files) => #f)
        (check (member "t/types-test.ss" files) => #f)
        (check (member "t/parser-test.ss" files) => #f)
        (check (member "t/policy-test.ss" files) => #f)
        (check (member "t/bench-test.ss" files) => #f)
        (check (member "t/benchmark-gate-test.ss" files) => #f)
        (check (member "t/self-apply-test.ss" files) => #f)
        (check (member "t/snapshot-test.ss" files) => #f)))
    (test-case "default gxtest selected closure stays bounded"
      (configure-build-root! (current-directory))
      (let (files (default-gxtest-test-files))
        (check (<= (length (selected-gxtest-build-source-files files)) 160)
               => #t)
        (check (<= (length (selected-gxtest-build-output-files files)) 160)
               => #t)))
    (test-case "gxtest build spec includes top-level entries and POO policy subdir suites"
      (configure-build-root! (current-directory))
      (let (stage (gxtest-test-spec))
        (check (member "policy-test.ss" stage) ? true)
        (check (member "self-apply-full-gate.ss" stage) ? true)
        (check (member "project-policy-test.ss" stage) => #f)
        (check (member "policy/agent-poo-hot-loop-core-test.ss" stage)
               ? true)
        (check (member "policy/agent-build-test.ss" stage) => #f)
        (check (member "unit/schema/conformance.ss" stage) => #f)
        (check (member "snapshot/policy.ss" stage) => #f)))
    (test-case "timing-sensitive gxtest files run outside the native parallel lane"
      (let (files ["t/benchmark-gate-test.ss"
                   "t/agent-poo-scenario-contract-test.ss"
                   "t/build-api-native-stage-boundary-test.ss"
                   "t/building-gxtest-stage-boundary-test.ss"
                   "t/cli-dev-linker-test.ss"
                   "t/fmt-scenario-test.ss"
                   "t/gxtest-runner-contract-test.ss"
                   "t/policy/agent-poo-hot-loop-type-test.ss"
                   "t/policy-test.ss"
                   "t/query-test.ss"])
        (check (serial-gxtest-files files)
               => ["t/benchmark-gate-test.ss"
                   "t/build-api-native-stage-boundary-test.ss"
                   "t/building-gxtest-stage-boundary-test.ss"
                   "t/cli-dev-linker-test.ss"
                   "t/fmt-scenario-test.ss"
                   "t/query-test.ss"])
        (check (parallel-gxtest-files files)
               => ["t/agent-poo-scenario-contract-test.ss"
                   "t/gxtest-runner-contract-test.ss"
                   "t/policy/agent-poo-hot-loop-type-test.ss"
                   "t/policy-test.ss"])))
    (test-case "declared memory-profile files isolate from the shared runner"
      (check (source-isolated-gxtest-file?
              "t/gxtest-runner-contract-test.ss")
             => #t)
      (check (source-isolated-gxtest-file? "t/benchmark-gate-test.ss")
             => #t)
      (check (source-isolated-gxtest-file?
              "t/policy/agent-poo-hot-loop-type-test.ss")
             => #t))
    (test-case "shared resources form independent ordered execution groups"
      (check (gxtest-serial-resource-groups
              ["t/build-api-native-stage-boundary-test.ss"
               "t/cli-dev-linker-test.ss"
               "t/building-gxtest-stage-boundary-test.ss"
               "t/query-test.ss"])
             => [["t/build-api-native-stage-boundary-test.ss"
                  "t/building-gxtest-stage-boundary-test.ss"]
                 ["t/cli-dev-linker-test.ss"]
                 ["t/query-test.ss"]]))
    (test-case "test phase receipts are machine parseable"
      (check (test-phase-receipt-line "run-gxtest" 1234)
             => "[asp-gerbil-scheme-test-phase] name=run-gxtest elapsedMicros=1234 elapsedMs=1\n"))
    (test-case "scoped policy status receipt is machine parseable"
      (check (scoped-policy-status-line
              '((status . stale)
                (reason . dirty-source-or-missing-output)
                (sources . 9)
                (outputs . 1)))
             => "[asp-gerbil-scheme-scoped-policy] status=stale reason=dirty-source-or-missing-output sources=9 outputs=1\n"))
    (test-case "scoped policy phase receipts are machine parseable"
      (check (scoped-policy-phase-line "policy-report" 9876)
             => "[asp-gerbil-scheme-scoped-policy-phase] name=policy-report elapsedMicros=9876 elapsedMs=9\n"))
    (test-case "gxtest timing summaries are machine parseable"
      (check (gxtest-summary-line "serial" 13 29643000 3624000)
             => "[asp-gerbil-scheme-test-summary] kind=serial count=13 sumMs=29643 wallMs=3624\n")
      (check (gxtest-top-line 1 "t/policy-test.ss" 3397000)
             => "[asp-gerbil-scheme-test-top] rank=1 name=t/policy-test.ss elapsedMs=3397\n"))
    (test-case "gxtest failures are visible before verbose output"
      (check (gxtest-failure-line "t/failing-test.ss" 42)
             => "[asp-gerbil-scheme-test-failure] name=t/failing-test.ss status=42\n"))
    (test-case "gxtest batch expression leaves policy to runner phase"
      (configure-build-root! (current-directory))
      (check (gxtest-source-load-batch-expression ["t/build-install-test.ss"])
             => "(begin (add-load-path! \".\") (add-load-path! \"src\") (add-load-path! \"t\") (import :std/test) (load \"t/build-install-test.ss\") (let (ok #t) (let (start (current-jiffy)) (unless (run-test-suite! build-install-test) (set! ok #f)) (display \"[asp-gerbil-scheme-test-file] name=t/build-install-test.ss elapsedMs=\") (display (quotient (* (- (current-jiffy) start) 1000) (jiffies-per-second))) (newline) (force-output)) ok))"))
    (test-case "gxtest policy macro expands literal file scope"
      (let (suite (make-gxtest-policy-test "." ["t/build-install-test.ss"]))
        (check (not (not suite)) => #t)))
    (test-case "scoped policy receipt tracks policy engine and selected files"
      (configure-build-root! (current-directory))
      (let ((sources (scoped-policy-source-files ["t/build-install-test.ss"]))
            (build-receipt
             (scoped-policy-receipt-path ["t/build-install-test.ss"]))
            (bench-receipt
             (scoped-policy-receipt-path ["t/benchmark-gate-test.ss"])))
        (check (not (equal? build-receipt bench-receipt)) => #t)
        (check (member (path-expand "src/policy/gxtest.ss"
                                    (current-directory))
                       sources)
               ? true)
        (check (member (path-expand "t/policy/agent-dependency-adapter-test.ss"
                                    (current-directory))
                       sources)
               ? true)
        (check (member (path-expand "src/testing/gxtest-runner.ss"
                                    (current-directory))
                       sources)
               => #f)
        (check (member (path-expand "t/build-install-test.ss"
                                    (current-directory))
                       sources)
               ? true)))
    (test-case "selected gxtest receipts are keyed by selected file set"
      (configure-build-root! (current-directory))
      (let ((default-receipt
             (selected-gxtest-build-receipt-path
              (default-gxtest-test-files)))
            (focused-receipt
             (selected-gxtest-build-receipt-path
              ["t/testing-framework-downstream-test.ss"])))
        (check (not (equal? default-receipt focused-receipt)) => #t)
        (check (string-contains default-receipt
                                ".gerbil/build/selected-gxtest/")
               ? true)
        (check (string-contains focused-receipt
                                ".gerbil/build/selected-gxtest/")
               ? true)))
    (test-case "source-load gxtest runner derives suite and expression"
      (configure-build-root! (current-directory))
      (check (gxtest-file-exported-suite "t/build-install-test.ss")
             => 'build-install-test)
      (check (gxtest-source-load-batch-expression ["t/build-install-test.ss"])
             => "(begin (add-load-path! \".\") (add-load-path! \"src\") (add-load-path! \"t\") (import :std/test) (load \"t/build-install-test.ss\") (let (ok #t) (let (start (current-jiffy)) (unless (run-test-suite! build-install-test) (set! ok #f)) (display \"[asp-gerbil-scheme-test-file] name=t/build-install-test.ss elapsedMs=\") (display (quotient (* (- (current-jiffy) start) 1000) (jiffies-per-second))) (newline) (force-output)) ok))"))
    (test-case "gxtest delegate contract filters selected suites"
      (configure-build-root! (current-directory))
      (let (contract (gxtest-delegate-contract filter: 'build-install-test))
        (check (gxtest-source-load-batch-expression
                ["t/build-install-test.ss"
                 "t/testing-framework-test.ss"]
                contract)
               => "(begin (add-load-path! \".\") (add-load-path! \"src\") (add-load-path! \"t\") (import :std/test) (load \"t/build-install-test.ss\") (let (ok #t) (let (start (current-jiffy)) (unless (run-test-suite! build-install-test) (set! ok #f)) (display \"[asp-gerbil-scheme-test-file] name=t/build-install-test.ss elapsedMs=\") (display (quotient (* (- (current-jiffy) start) 1000) (jiffies-per-second))) (newline) (force-output)) ok))")))
    (test-case "gxtest delegate contract rejects unsupported switches with receipt"
      (configure-build-root! (current-directory))
      (let* ((contract
              (gxtest-delegate-contract
               quiet: #t
               features: ['slow]))
             (receipt
              (gxtest-delegate-contract-receipt
               contract
               ["t/build-install-test.ss"]))
             (diagnostics
              (cdr (assq 'diagnostics
                         (testing-receipt-details receipt)))))
        (check (testing-receipt-ok? receipt) => #f)
        (check (member 'quiet-option-unsupported diagnostics) ? true)
        (check (member 'feature-options-unsupported diagnostics) ? true)))
    (test-case "source-load gxtest batch expression returns false on suite failure"
      (configure-build-root! (current-directory))
      (let (expression
            (gxtest-source-load-batch-expression
             ["t/fixtures/testing-framework/failing-local-suite.ss"]))
        (check (string-contains expression "(let (ok #t)") ? true)
        (check (string-contains expression "(unless (run-test-suite! failing-local-suite)") ? true)
        (check (string-contains expression "(set! ok #f)") ? true)
        (check (string-contains expression " ok))") ? true)))
    (test-case "top-level smoke wrappers expose local suite bindings"
      (configure-build-root! (current-directory))
      (check (gxtest-file-local-suite? "t/agent-poo-scenario-contract-test.ss")
             ? true)
      (check (gxtest-file-local-suite? "t/testing-framework-test.ss")
             ? true))
    (test-case "selected gxtest receipt includes imported test support files"
      (configure-build-root! (current-directory))
      (let (sources (selected-gxtest-build-source-files
                     ["t/policy/agent-poo-guidance-test.ss"]))
        (check (member (path-expand "t/policy/agent-poo-guidance-test.ss"
                                    (current-directory))
                       sources)
               ? true)
        (check (member (path-expand "t/policy/agent-poo-guidance-support.ss"
                                    (current-directory))
                       sources)
               ? true)))
    (test-case "selected gxtest compile target includes imported test support"
      (configure-build-root! (current-directory))
      (let (files (gxtest-selected-test-files
                   ["t/policy/agent-poo-guidance-test.ss"]))
        (check (member "t/policy/agent-poo-guidance-test.ss" files)
               ? true)
        (check (member "t/policy/agent-poo-guidance-support.ss" files)
               ? true)
        (check (member "src/policy/agent-style.ss" files)
               => #f)))
    (test-case "selected gxtest closure orders imported support before consumer"
      (configure-build-root! (current-directory))
      (let* ((support
              (path-expand "t/policy/agent-poo-support.ss"
                           (current-directory)))
             (consumer
              (path-expand "t/policy/agent-poo-generated-boundary-test.ss"
                           (current-directory)))
             (sources
              (selected-gxtest-build-source-files
               ["t/policy/agent-poo-generated-boundary-test.ss"]))
             (support-tail (member support sources))
             (consumer-tail (member consumer sources)))
        (check support-tail ? true)
        (check consumer-tail ? true)
        (check (and support-tail
                    consumer-tail
                    (> (length support-tail) (length consumer-tail)))
               ? true)))
    (test-case "selected gxtest receipt includes imported source modules"
      (configure-build-root! (current-directory))
      (let (sources (selected-gxtest-build-source-files
                     ["t/extensions-test.ss"]))
        (check (member (path-expand "t/extensions-test.ss"
                                    (current-directory))
                       sources)
               ? true)
        (check (member (path-expand "src/extensions/facade.ss"
                                    (current-directory))
                       sources)
               ? true)
        (check (member (path-expand "src/parser/facade.ss"
                                    (current-directory))
                       sources)
               ? true)))
    (test-case "multi-file gxtest suites require process isolation"
      (check (gxtest-suite-process-isolated? ["t/a-test.ss"])
             => #f)
      (check (gxtest-suite-process-isolated? ["t/a-test.ss"
                                              "t/b-test.ss"])
             => #t))
    (test-case "native gxtest parallelism follows Gerbil build cores"
      (setenv "GERBIL_BUILD_CORES" "4")
      (check (gxtest-native-parallelism) => 4)
      (check (gxtest-native-parallelism 2) => 2)
      (setenv "GERBIL_BUILD_CORES" "0")
      (check (gxtest-native-parallelism 8) => 1)
      (setenv "GERBIL_BUILD_CORES" "invalid")
      (check (gxtest-native-parallelism 8) => 1)
      (setenv "GERBIL_BUILD_CORES" ""))
    (test-case "gxtest labels summarize explicit native invocations"
      (check (gxtest-batch-label ["t/a-test.ss"
                                  "t/b-test.ss"
                                  "t/c-test.ss"])
             => "t/a-test.ss,+2")
      (check (gxtest-batch-label ["t/a-test.ss"])
             => "t/a-test.ss"))
    (test-case "default package spec exposes downstream gxtest support"
      (configure-build-root! (current-directory))
      (let (stage (compile-spec #f #f #f))
        (check (member "build-api/source-coverage.ss" stage) ? true)
        (check (member "build-api/package-receipt.ss" stage) ? true)
        (check (member "build-api/worker-count.ss" stage) => #f)
        (check (member "build-api/build-path-contract.ss" stage) ? true)
        (check (member "benchmark/framework.ss" stage) ? true)
        (check (member "benchmark/gate.ss" stage) ? true)
        (check (member "testing/model.ss" stage) ? true)
        (check (member "testing/scope.ss" stage) ? true)
        (check (member "testing/scenario.ss" stage) ? true)
        (check (member "testing/performance.ss" stage) ? true)
        (check (member "testing/selection.ss" stage) ? true)
        (check (member "testing/batch.ss" stage) ? true)
        (check (member "testing/framework.ss" stage) ? true)
        (check (member "testing/build-paths.ss" stage) ? true)
        (check (member "testing/build-process.ss" stage) ? true)
        (check (member "testing/build-support.ss" stage) ? true)
        (check (member "testing/build.ss" stage) ? true)
        (check (member "testing/gxtest-smoke.ss" stage) ? true)
        (check (member "testing/gxtest-context.ss" stage) ? true)
        (check (member "testing/gxtest-syntax.ss" stage) ? true)
        (check (member "testing/gxtest-imports.ss" stage) ? true)
        (check (member "testing/gxtest-sources.ss" stage) ? true)
        (check (member "testing/gxtest-discovery.ss" stage) ? true)
        (check (member "testing/gxtest-delegate.ss" stage) ? true)
        (check (member "testing/gxtest-expression.ss" stage) ? true)
        (check (member "testing/gxtest-report.ss" stage) ? true)
        (check (member "testing/gxtest-receipts.ss" stage) ? true)
        (check (member "testing/gxtest-policy.ss" stage) ? true)
        (check (member "testing/gxtest-build.ss" stage) ? true)
        (check (member "testing/gxtest-run.ss" stage) ? true)
        (check (member "testing/gxtest-runner.ss" stage) ? true)
        (check (member "extensions/poo-source-ref-validation.ss" stage) ? true)
        (check (member "policy/gxtest-report.ss" stage) ? true)
        (check (member "policy/gxtest.ss" stage) ? true)
        (check (member "support/args.ss" stage) ? true)
        (check (member "support/io.ss" stage) ? true)
        (check (member "commands/query.ss" stage) ? true)
        (check (member "cli-launcher.ss" stage) ? true)))
    (test-case "package api stages keep clean-ci dependency order"
      (let* ((stages (asp-gerbil-scheme-package-api-stage-specs))
             (gate (stage-index-containing stages "benchmark/gate.ss"))
             (benchmark-framework
              (stage-index-containing stages "benchmark/framework.ss"))
             (model (stage-index-containing stages "testing/model.ss"))
             (scope (stage-index-containing stages "testing/scope.ss"))
             (scenario (stage-index-containing stages "testing/scenario.ss"))
             (selection (stage-index-containing stages "testing/selection.ss"))
             (framework (stage-index-containing stages "testing/framework.ss")))
        (check (< gate benchmark-framework) => #t)
        (check (< model scope) => #t)
        (check (< scope scenario) => #t)
        (check (< scenario selection) => #t)
        (check (< selection framework) => #t)))
    (test-case "package api flat spec is derived from ordered stages"
      (check (asp-gerbil-scheme-package-api-spec)
             => (stage-files (asp-gerbil-scheme-package-api-stage-specs))))
    (test-case "binary bootstrap spec includes downstream gxtest support"
      (configure-build-root! (current-directory))
      (let (stage (compile-spec #f #f #t))
        (check (member "build-api/source-coverage.ss" stage) ? true)
        (check (member "build-api/package-receipt.ss" stage) ? true)
        (check (member "build-api/worker-count.ss" stage) => #f)
        (check (member "benchmark/framework.ss" stage) ? true)
        (check (member "benchmark/gate.ss" stage) ? true)
        (check (member "testing/model.ss" stage) => #f)
        (check (member "testing/scope.ss" stage) => #f)
        (check (member "testing/scenario.ss" stage) => #f)
        (check (member "testing/selection.ss" stage) => #f)
        (check (member "testing/batch.ss" stage) => #f)
        (check (member "testing/framework.ss" stage) => #f)
        (check (member "testing/build-paths.ss" stage) => #f)
        (check (member "testing/build-process.ss" stage) => #f)
        (check (member "testing/build-support.ss" stage) => #f)
        (check (member "testing/gxtest-imports.ss" stage) => #f)
        (check (member "testing/gxtest-sources.ss" stage) => #f)
        (check (member "testing/gxtest-build.ss" stage) => #f)
        (check (member "testing/gxtest-run.ss" stage) => #f)
        (check (member "extensions/poo-source-ref-validation.ss" stage) ? true)
        (check (member "policy/gxtest-report.ss" stage) ? true)
        (check (member "policy/gxtest.ss" stage) ? true)
        (check (member "policy/gxtest.ss"
                       (member "build-api/source-coverage.ss" stage))
               ? true)))))
