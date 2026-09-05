;;; -*- Gerbil -*-
;;; Top-level smoke entry for the POO-shaped testing framework.

(import :std/test
        (only-in :clan/poo/object object? .ref .slot?)
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/framework
        :asp-gerbil-scheme/src/testing/performance
        :asp-gerbil-scheme/src/testing/build
        :asp-gerbil-scheme/src/testing/build-runner
        :asp-gerbil-scheme/src/testing/build-process
        :asp-gerbil-scheme/src/testing/build-support
        :asp-gerbil-scheme/src/testing/build-runtime
        :asp-gerbil-scheme/src/building/facade
        :asp-gerbil-scheme/src/testing/building)

(export testing-framework-test
        performance-smoke-work)

;; : (-> (List Path) Integer)
(def (fake-run-files files)
  0)

(def +testing-suite+
  (gxtest-suite
   name: "unit"
   roots: ["t/fixtures/testing-framework"]
   files: ["t/fixtures/testing-framework/alpha-test.ss"
           "t/fixtures/testing-framework/beta-test.ss"]
   batch-size: 1))

(def +testing-project+
  (testing-project
   name: "poo-flow-like"
   suites: [+testing-suite+]
   roots: ["t/fixtures/testing-framework"]))

(def +performance-fixture+
  (call-with-input-file
   "t/scenarios/policy/poo-object-construction-loop-performance/benchmark.ss"
   read))

(def +building-stage-benchmark+
  "t/scenarios/building/std-builder-stage-boundary/benchmark.ss")

(def +building-stage-make-calls+ (vector 0))

(def +building-stage-plan-request+
  (let* ((builder
          (make-std-builder
           "testing-scenario-adapter"
           (lambda args
             (vector-set! +building-stage-make-calls+
                          0
                          (+ 1 (vector-ref +building-stage-make-calls+ 0)))
             'made)
           'std-builder
           "testing scenario adapter builder"
           #f
           []
           (native-toolchain-default)))
         (profile (make-std-builder-profile builder)))
    (make-std-builder-request
     "testing-scenario-adapter"
     profile
     [["alpha.ss"] ["beta.ss"]]
     (lambda (spec context) #t)
     'testing-scenario-adapter)))

(def (performance-smoke-work)
  (let loop ((index 0) (sum 0))
    (if (= index 10)
      sum
      (loop (+ index 1) (+ sum index)))))

(def (benchmark-receipt-ref receipt key default)
  (let (entry (assq key receipt))
    (if entry (cdr entry) default)))

(def (performance-case-benchmark-status receipt)
  (benchmark-receipt-ref
   (testing-receipt-detail receipt 'benchmark default: [])
   'status
   #f))

(def +performance-suite+
  (performance-suite
   name: "performance"
   cases: [(performance-case
            name: "poo-smoke"
            fixture: +performance-fixture+
            runner: performance-smoke-work)
           (make-build-request-performance-case
            +building-stage-plan-request+
            +building-stage-benchmark+
            name: "building-stage-plan")]))

(def +performance-project+
  (testing-project
   name: "poo-flow-like-performance"
   suites: [+performance-suite+]
   roots: ["t/scenarios/policy" "t/scenarios/building"]))

(def testing-framework-test
  (test-suite "gerbil scheme POO-shaped testing framework smoke"
    (test-case "testing project and suite are user-facing POO-shaped objects"
      (check (object? +testing-project+) => #t)
      (check (.slot? +testing-project+ 'name) => #t)
      (check (.ref +testing-project+ 'name) => "poo-flow-like")
      (check (testing-object-kind +testing-project+) => 'testing-project)
      (check (testing-project-name +testing-project+) => "poo-flow-like")
      (check (object? +testing-suite+) => #t)
      (check (testing-object-kind +testing-suite+) => 'gxtest-suite)
      (check (testing-suite-name +testing-suite+) => "unit"))

    (test-case "suite batches files without downstream runner code"
      (check (testing-batches
              ["a.ss" "b.ss" "c.ss"]
              2)
             => '(("a.ss" "b.ss") ("c.ss"))))

    (test-case "suite split exposes batch rest without second traversal"
      (let-values (((batch rest)
                    (testing-split-batch
                     ["a.ss" "b.ss" "c.ss"]
                     2)))
        (check batch => ["a.ss" "b.ss"])
        (check rest => ["c.ss"])))

    (test-case "project run selects matching gxtest files"
      (let* ((receipt
              (testing-run-project
               +testing-project+
               ["t/fixtures/testing-framework/alpha-test.ss"]
               fake-run-files))
             (named-receipt
              (testing-run-project
               +testing-project+
               ["unit"]
               fake-run-files))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'receiptKind)
               => 'gxtest-suite)
        (check (testing-receipt-files
                (car (testing-receipt-children named-receipt)))
               => ["t/fixtures/testing-framework/alpha-test.ss"
                   "t/fixtures/testing-framework/beta-test.ss"])))

    (test-case "gxtest suite receipt exposes framework-owned timing phases"
      (let* ((receipt
              (testing-run-project
               +testing-project+
               ["unit"]
               fake-run-files))
             (suite-receipt (car (testing-receipt-children receipt)))
             (phases (testing-receipt-phases suite-receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (testing-receipt-elapsed-micros suite-receipt)
               ? number?)
        (check (map (lambda (phase)
                      (testing-object-ref phase 'elapsedMicros))
                    phases)
               ? (lambda (values)
                   (and (not (null? values))
                        (andmap number? values))))
        (check (map (lambda (phase)
                      (let (details (testing-receipt-details phase))
                        (cdr (assq 'phase details))))
                    phases)
               => '(expand-manifest delegate-gxtest))))

    (test-case "project selection is POO-native"
      (let* ((selection
              (testing-select-project
               +testing-project+
               ["t/fixtures/testing-framework/alpha-test.ss"]))
             (named-selection
              (testing-select-project
               +testing-project+
               ["unit"]))
             (suites (testing-selection-suites selection)))
        (check (object? selection) => #t)
        (check (testing-object-kind selection) => 'testing-selection)
        (check (testing-selection-ok? selection) => #t)
        (check (length suites) => 1)
        (check (testing-suite-name (car suites)) => "unit")
        (check (testing-selection-ok? named-selection) => #t)
        (check (map testing-suite-name
                    (testing-selection-suites named-selection))
               => ["unit"])))

    (test-case "project selection preserves explicit unowned gxtest files"
      (let* ((file "t/testing-framework-test.ss")
             (selection (testing-select-project +testing-project+ [file]))
             (suites (testing-selection-suites selection)))
        (check (testing-selection-ok? selection) => #t)
        (check (length suites) => 1)
        (check (testing-suite-name (car suites)) => file)
        (check (testing-suite-files (car suites)) => [file])))

    (test-case "project selection assigns explicit files to one owner suite"
      (let* ((project
              (testing-project
               name: "dedupe-project"
               suites: [(gxtest-suite
                         name: "unit"
                         roots: ["t/fixtures/testing-framework/unit-tests.ss"]
                         files: ["t/fixtures/testing-framework/alpha-test.ss"
                                 "t/fixtures/testing-framework/exported-mismatch-test.ss"])
                        (gxtest-suite
                         name: "scenario-exported"
                         roots: ["t/fixtures/testing-framework/exported-mismatch-test.ss"]
                         files: 'auto)]
               roots: ["t/fixtures/testing-framework"]))
             (receipt
              (testing-run-project
               project
               ["t/fixtures/testing-framework/alpha-test.ss"
                "t/fixtures/testing-framework/exported-mismatch-test.ss"]
               fake-run-files))
             (children (testing-receipt-children receipt)))
        (check (map (lambda (child)
                      (testing-object-ref child 'suite))
                    children)
               => ["unit" "scenario-exported"])
        (check (map testing-receipt-files children)
               => [["t/fixtures/testing-framework/alpha-test.ss"]
                   ["t/fixtures/testing-framework/exported-mismatch-test.ss"]])))

    (test-case "project selection keeps unselected POO suites lazy"
      (let* ((forced (vector []))
             (lazy-unit
              (testing-lazy-object
               'gxtest-suite
               `((name . "unit")
                 (roots . ,(list "t/fixtures/testing-framework")))
               (lambda ()
                 (vector-set! forced 0 (cons 'unit (vector-ref forced 0)))
                 (gxtest-suite
                  name: "unit"
                  roots: ["t/fixtures/testing-framework"]
                  files: ["t/fixtures/testing-framework/alpha-test.ss"]))))
             (lazy-slow
              (testing-lazy-object
               'gxtest-suite
               `((name . "slow")
                 (roots . ,(list "t/fixtures/testing-framework/slow")))
               (lambda ()
                 (vector-set! forced 0 (cons 'slow (vector-ref forced 0)))
                 (gxtest-suite
                  name: "slow"
                  roots: ["t/fixtures/testing-framework/slow"]
                  files: ["t/fixtures/testing-framework/slow-test.ss"]))))
             (project
              (testing-project
               name: "lazy-suite-project"
               suites: [lazy-unit lazy-slow]
               roots: ["t/fixtures/testing-framework"]))
             (selection (testing-select-project project ["unit"]))
             (forced-after-select (vector-ref forced 0))
             (receipt (testing-run-selection selection fake-run-files)))
        (check (map testing-suite-name
                    (testing-selection-suites selection))
               => ["unit"])
        (check forced-after-select => [])
        (check (testing-receipt-ok? receipt) => #t)
        (check (reverse (vector-ref forced 0)) => '(unit))))

    (test-case "POO lazy values are memoized across accessor reads"
      (let* ((forced (vector 0))
             (lazy-suite
              (testing-lazy
               (lambda ()
                 (vector-set! forced 0 (+ 1 (vector-ref forced 0)))
                 (gxtest-suite
                  name: "memoized"
                  roots: ["t/fixtures/testing-framework"]
                  files: ["t/fixtures/testing-framework/alpha-test.ss"])))))
        (check (testing-suite-name lazy-suite) => "memoized")
        (check (testing-suite-files lazy-suite)
               => ["t/fixtures/testing-framework/alpha-test.ss"])
        (check (vector-ref forced 0) => 1)))

    (test-case "performance suite runs benchmark receipts without gxtest files"
      (let* ((receipt
              (testing-run-project
               +performance-project+
               ["performance"]
               fake-run-files))
             (suite-receipt (car (testing-receipt-children receipt)))
             (case-receipt (car (testing-receipt-children suite-receipt)))
             (body-phase (car (testing-receipt-phases case-receipt))))
        (check (testing-receipt-ok? receipt) => #t)
        (check (testing-object-ref suite-receipt 'receiptKind)
               => 'performance-suite)
        (check (testing-object-ref case-receipt 'receiptKind)
               => 'performance-case)
        (check (testing-receipt-kind body-phase) => 'testing-phase)
        (check (testing-receipt-detail body-phase 'phase) => 'benchmark-body)
        (check (testing-receipt-elapsed-micros body-phase) ? number?)
        (check (performance-case-benchmark-status case-receipt) => 'pass)))

    (test-case "performance project selects the shared building scenario"
      (let* ((receipt
              (testing-run-project
               +performance-project+
               ["building-stage-plan"]
               fake-run-files))
             (suite-receipt (car (testing-receipt-children receipt)))
             (case-receipt (car (testing-receipt-children suite-receipt))))
        (check (build-request-stage-plan-valid?
                (build-request-stage-plan +building-stage-plan-request+))
               => #t)
        (check (testing-receipt-ok? receipt) => #t)
        (check (testing-object-ref suite-receipt 'receiptKind)
               => 'performance-suite)
        (check (testing-object-ref case-receipt 'receiptKind)
               => 'performance-case)
        (check (performance-case-benchmark-status case-receipt) => 'pass)
        (check (vector-ref +building-stage-make-calls+ 0) => 0)))

    (test-case "testing benchmark helper exposes body timing to gxtest-style tests"
      (let-values (((receipt result body-phase)
                    (testing-benchmark-run/result
                     "poo-smoke"
                     +performance-fixture+
                     performance-smoke-work
                     '((case . poo-smoke)))))
        (check (benchmark-receipt-ref receipt 'status #f) => 'pass)
        (check result => 45)
        (check (testing-receipt-kind body-phase) => 'testing-phase)
        (check (testing-receipt-detail body-phase 'phase) => 'benchmark-body)
        (check (testing-receipt-detail body-phase 'case) => 'poo-smoke)
        (check (testing-receipt-elapsed-micros body-phase) ? number?)))

    (test-case "testing build declares performance suites as first-class API"
      (let* ((build (testing-build
                     name: "poo-flow"
                     root: "."
                     performance: [+performance-suite+]))
             (receipt
              (testing-run-selection
               (testing-build-select build ["poo-smoke"])
               fake-run-files))
             (suite-receipt (car (testing-receipt-children receipt)))
             (case-receipt (car (testing-receipt-children suite-receipt))))
        (check (testing-receipt-ok? receipt) => #t)
        (check (testing-object-ref suite-receipt 'receiptKind)
               => 'performance-suite)
        (check (performance-case-benchmark-status case-receipt) => 'pass)))

    (test-case "performance suite supports lazy module runners"
      (let* ((suite
              (performance-suite
               name: "lazy-performance"
               cases: [(performance-case
                        name: "lazy-poo-smoke"
                        fixture-path:
                        "t/scenarios/policy/poo-object-construction-loop-performance/benchmark.ss"
                        runner-module: ':asp-gerbil-scheme/src/building/native-toolchain
                        runner-symbol: 'native-toolchain-default)]))
             (project
              (testing-project
               name: "lazy-performance-project"
               suites: [suite]
               roots: ["t/scenarios/policy"]))
             (receipt
              (testing-run-project
               project
               ["lazy-poo-smoke"]
               fake-run-files))
             (suite-receipt (car (testing-receipt-children receipt)))
             (case-receipt (car (testing-receipt-children suite-receipt))))
        (check (testing-receipt-ok? receipt) => #t)
        (check (testing-object-ref case-receipt 'receiptKind)
               => 'performance-case)
        (check (performance-case-benchmark-status case-receipt) => 'pass)))

    (test-case "testing build maps package-prefixed symbol imports"
      (let (build (testing-build
                   name: "poo-flow"
                   root: "."))
        (check (testing-build-import->file
                build
                ':poo-flow/t/cli-test)
               => "./t/cli-test.ss")))

    (test-case "testing build prefers compiled gxtest module shape"
      (let (build (testing-build
                   name: "poo-flow"
                   root: "."))
        (check (testing-build-gxtest-module-symbol
                build
                "./t/foo-test.ss")
               => ':poo-flow/t/foo-test)
        (check (testing-build-gxtest-compiled-expression
                build
                "t/foo-test.ss"
                'foo-test)
               => "(begin (import :std/test (only-in :poo-flow/t/foo-test foo-test)) (run-test-suite! foo-test))")))

    (test-case "testing build default delegate owns scoped policy command shape"
      (let (build (testing-build
                   name: "poo-flow"
                   root: "."
                   policy: #t))
        (check (testing-build-gxtest-command
                build
                ["t/unit-a-test.ss"])
               => ["env"
                   "gxtest"
                   "t/unit-a-test.ss"
                   "./.gerbil/asp-gerbil-scheme/testing/poo-flow-policy-test.ss"])))

    (test-case "testing build can omit policy file after first delegate batch"
      (let (build (testing-build
                   name: "poo-flow"
                   root: "."
                   policy: #t))
        (check (testing-build-gxtest-command
                build
               ["t/unit-b-test.ss"]
               #f)
               => ["env"
                   "gxtest"
                   "t/unit-b-test.ss"])))

    (test-case "testing build treats equal source and output time as stale"
      (check (testing-build-file-current?
              "t/fixtures/testing-framework/alpha-test.ss"
              "t/fixtures/testing-framework/alpha-test.ss")
             => #f))

    (test-case "testing build cache tracks dependency stamps"
      (let (build (testing-build
                   name: "poo-flow"
                   root: "."
                   compile-dependency-stamps:
                   ["t/fixtures/testing-framework/alpha-test.ss"]))
        (check (testing-build-compile-dependencies-current?
                build
                "t/fixtures/testing-framework/alpha-test.ss")
               => #f)))

    (test-case "testing build cache tracks split framework dependency stamps"
      (let* ((build (testing-build name: "poo-flow" root: "."))
             (stamps (testing-build-compile-dependency-stamp-paths build)))
        (check (testing-any?
                (lambda (stamp)
                  (testing-string-suffix?
                   "asp-gerbil-scheme/src/testing/scope.ssi"
                   stamp))
                stamps)
               => #t)
        (check (testing-any?
                (lambda (stamp)
                  (testing-string-suffix?
                   "asp-gerbil-scheme/src/testing/selection.ssi"
                   stamp))
                stamps)
               => #t)
        (check (testing-any?
                (lambda (stamp)
                  (testing-string-suffix?
                   "asp-gerbil-scheme/src/testing/batch.ssi"
                   stamp))
                stamps)
               => #t)))

    (test-case "testing build guards gxtest textual failures"
      (check (testing-build-gxtest-failure-line?
              "*** FAILED: (check equal? x y)")
             => #t)
      (check (testing-build-gxtest-failure-line?
              "... All tests OK")
             => #f))

    (test-case "testing build quotes delegate shell commands"
      (check (testing-build-shell-command
              ["env"
               "POO_FLOW_TEST_FILES=(\"t/a test.ss\")"
               "gxtest"
               "t/a test.ss"])
             => "env 'POO_FLOW_TEST_FILES=(\"t/a test.ss\")' gxtest 't/a test.ss'"))

    (test-case "testing build inline runner uses native gxtest suite symbols"
      (let (build (testing-build
                   name: "poo-flow"
                   root: "."))
        (check (testing-build-gxtest-suite-symbol
                "t/fixtures/testing-framework/alpha-test.ss")
               => 'alpha-test)
        (check (testing-build-run-gxtest-inline
                build
                ["t/fixtures/testing-framework/alpha-test.ss"]
                #f)
               => 0)))

    (test-case "testing build inline runner accepts self-running gxtest files"
      (let ((build (testing-build
                    name: "poo-flow"
                    root: "."))
            (file "t/fixtures/testing-framework/self-running-test.ss"))
        (check (testing-build-gxtest-file-exported-suite? build file) => #f)
        (check (testing-build-gxtest-file-self-running? build file) => #t)
        (check (testing-build-gxtest-file-compiled-runnable? build file) => #f)
        (check (testing-build-run-gxtest-inline build [file] #f) => 0)))

    (test-case "testing build inline runner uses exported suite symbols"
      (let ((build (testing-build
                    name: "poo-flow"
                    root: "."))
            (file "t/fixtures/testing-framework/exported-mismatch-test.ss"))
        (check (testing-build-gxtest-suite-symbol file)
               => 'exported-mismatch-test)
        (check (testing-build-gxtest-file-exported-suite build file)
               => 'poo-role-test)
        (check (testing-build-run-gxtest-inline build [file] #f) => 0)))

    (test-case "testing build injects loadpath only when explicitly configured"
      (let (build (testing-build
                   name: "poo-flow"
                   root: "."
                   loadpath: ".:.gerbil/lib"))
        (check (testing-build-gxtest-command
                build
                ["t/unit-a-test.ss"])
               => ["env"
                   "GERBIL_LOADPATH=.:.gerbil/lib"
                   "gxtest"
                   "t/unit-a-test.ss"])))

    (test-case "testing build declares support modules without build.ss expansion"
      (let (build (testing-build
                   name: "poo-flow"
                   root: "."
                   support-files: ["t/support/performance.ss"]
                   support-output-root: ".gerbil/lib/poo-flow"))
        (check (testing-build-support-command
                build
                "t/support/performance.ss")
               => ["gxc" "./t/support/performance.ss"])
        (check (testing-build-support-output-directory
                build
                "t/support/performance.ss")
               => "./.gerbil/lib/poo-flow/t/support/")))

    (test-case "testing build compiles only selected suite support"
      (let* ((build (testing-build
                     name: "poo-flow"
                     root: "."
                     gxtest: [["fast" "t/fixtures/testing-framework/alpha-test.ss"]
                              ["slow" "t/fixtures/testing-framework/beta-test.ss"]]
                     suite-support-files: [["fast" "t/support/fast.ss"]
                                           ["slow" "t/support/slow.ss"]]
                     suite-support-directories:
                     [["fast" "t/fixtures/testing-framework"]]))
             (selection (testing-build-select build ["fast"])))
        (check (testing-build-support-files-for-suites
                build
                (map testing-suite-name (testing-selection-suites selection)))
               => ["t/support/fast.ss"
                   "t/fixtures/testing-framework/alpha-test.ss"
                   "t/fixtures/testing-framework/beta-test.ss"
                   "t/fixtures/testing-framework/delta-test.ss"
                   "t/fixtures/testing-framework/exported-mismatch-test.ss"
                   "t/fixtures/testing-framework/failing-local-suite.ss"
                   "t/fixtures/testing-framework/gamma-test.ss"
                   "t/fixtures/testing-framework/integration-tests.ss"
                   "t/fixtures/testing-framework/self-running-test.ss"
                   "t/fixtures/testing-framework/unit-tests.ss"])))

    (test-case "testing build precompiles selected gxtest files"
      (let* ((build (testing-build
                     name: "poo-flow"
                     root: "."
                     gxtest: [["unit" "t/fixtures/testing-framework/unit-tests.ss"]]))
             (selection (testing-build-select build ["unit"])))
        (check (testing-build-selected-gxtest-files selection)
               => ["./t/alpha-test.ss"
                   "./t/beta-test.ss"])))

    (test-case "testing build derives support modules from directories"
      (let (build (testing-build
                   name: "poo-flow"
                   root: "."
                   support-directories: ["t/fixtures/testing-framework"]))
        (check (testing-build-support-files build)
               => ["t/fixtures/testing-framework/alpha-test.ss"
                   "t/fixtures/testing-framework/beta-test.ss"
                   "t/fixtures/testing-framework/delta-test.ss"
                   "t/fixtures/testing-framework/exported-mismatch-test.ss"
                   "t/fixtures/testing-framework/failing-local-suite.ss"
                   "t/fixtures/testing-framework/gamma-test.ss"
                   "t/fixtures/testing-framework/integration-tests.ss"
                   "t/fixtures/testing-framework/self-running-test.ss"
                   "t/fixtures/testing-framework/unit-tests.ss"])))))
