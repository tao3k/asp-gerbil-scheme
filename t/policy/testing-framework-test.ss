;;; -*- Gerbil -*-
;;; POO-shaped testing framework contracts.

(import :gerbil/gambit
        :std/test
        (only-in :clan/poo/object object? .o .ref .slot?)
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/framework
        :asp-gerbil-scheme/src/testing/build
        :policy/testing-framework-support)

(export testing-framework-test)

(def testing-framework-test
  (test-suite "gerbil scheme POO-shaped testing framework"
    (test-case "testing project is a user-facing POO-shaped object"
      (check (object? +testing-project+) => #t)
      (check (.slot? +testing-project+ 'name) => #t)
      (check (.ref +testing-project+ 'name) => "poo-flow-like")
      (check (testing-object-kind +testing-project+) => 'testing-project)
      (check (testing-project-name +testing-project+) => "poo-flow-like")
      (check (object? +testing-suite+) => #t)
      (check (testing-object-kind +testing-suite+) => 'gxtest-suite)
      (check (testing-suite-name +testing-suite+) => "unit")
      (check (object? +testing-scenario-suite+) => #t)
      (check (testing-object-kind +testing-scenario-suite+) => 'scenario-suite)
      (check (testing-suite-name +testing-scenario-suite+) => "policy-scenarios"))

    (test-case "native POO projection enters the same testing model"
      (check (object? +fake-native-poo-testing-project+) => #t)
      (check (.ref +fake-native-poo-testing-project+ 'name)
             => "native-poo-project")
      (check (object? +testing-project-from-native-poo+) => #t)
      (check (testing-object-kind +testing-project-from-native-poo+)
             => 'testing-project)
      (check (testing-project-name +testing-project-from-native-poo+)
             => "native-poo-project")
      (check (testing-project-batch-size +testing-project-from-native-poo+)
             => 2))

    (test-case "build runtime shell command keeps stable quoting"
      (check (testing-build-shell-quote "plain-token_1") => "plain-token_1")
      (check (testing-build-shell-quote "") => "''")
      (check (testing-build-shell-quote "needs space") => "'needs space'")
      (check (testing-build-shell-quote "can't") => "'can'\\''t'")
      (check (testing-build-shell-command
              ["env" "A=B C" "gxtest" "can't"])
             => "env 'A=B C' gxtest 'can'\\''t'"))

    (test-case "empty args expand through default manifest root"
      (check (testing-expand-suite-args +testing-suite+ [])
             => (list (fixture-path "alpha-test.ss")
                      (fixture-path "beta-test.ss"))))

    (test-case "declared root args expand like poo-flow manifests"
      (check (testing-expand-suite-args
              +testing-suite+
              (list (fixture-path "unit-tests.ss")))
             => (list (fixture-path "alpha-test.ss")
                      (fixture-path "beta-test.ss"))))

    (test-case "explicit files remain explicit"
      (check (testing-expand-suite-args
              +testing-suite+
              (list (fixture-path "alpha-test.ss")))
             => (list (fixture-path "alpha-test.ss"))))

    (test-case "suite batches files without downstream runner code"
      (check (testing-batches
              (list "a.ss" "b.ss" "c.ss")
              2)
             => '(("a.ss" "b.ss") ("c.ss"))))

    (test-case "batch splitting returns head and tail in one pass"
      (let-values (((batch rest)
                    (testing-split-batch
                     (list "a.ss" "b.ss" "c.ss")
                     2)))
        (check batch => '("a.ss" "b.ss"))
        (check rest => '("c.ss"))))

    (test-case "scenario suite expands declared policy scenarios"
      (let (scenarios
            (testing-expand-scenario-args +testing-scenario-suite+ []))
        (check (length scenarios) => 1)
        (check (testing-scenario-id (car scenarios))
               => "poo-construction-performance")
        (check (testing-scenario-root +testing-scenario-suite+ (car scenarios))
               => "t/scenarios/policy/poo-construction-performance")))

    (test-case "suite run returns machine-readable receipts"
      (let* ((receipt
              (testing-run-suite
               +testing-project+
               +testing-suite+
               []
               fake-run-files))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 2)
        (check (testing-receipt-files (car children))
               => (list (fixture-path "alpha-test.ss")))
        (check (testing-receipt-files (cadr children))
               => (list (fixture-path "beta-test.ss")))))

    (test-case "scenario suite run returns the same receipt shape"
      (let* ((receipt
              (testing-run-suite
               +testing-project+
               +testing-scenario-suite+
               []
               fake-run-files))
             (children (testing-receipt-children receipt))
             (batch (car children))
             (scenario-receipt
              (car (testing-receipt-children batch))))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-receipt-files scenario-receipt)
               => (list "t/scenarios/policy/poo-construction-performance"))
        (check (testing-receipt-detail scenario-receipt 'id)
               => "poo-construction-performance")))

    (test-case "project run manages gxtest and scenario suites together"
      (let (receipt
            (testing-run-project
             +testing-project+
             []
             fake-run-files))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length (testing-receipt-children receipt)) => 2)))

    (test-case "project receipt separates scope selection as a phase"
      (let* ((receipt
              (testing-run-project
               +testing-project+
               (list (fixture-path "alpha-test.ss"))
               fake-run-files))
             (phase-names (testing-test-phase-names receipt)))
        (check (member 'select-scope phase-names) ? true)))

    (test-case "gxtest suite receipt separates expansion and delegate phases"
      (let* ((receipt
              (testing-run-project
               +testing-project+
               (list (fixture-path "unit-tests.ss"))
               fake-run-files))
             (suite-receipt (car (testing-receipt-children receipt)))
             (phase-names (testing-test-phase-names suite-receipt)))
        (check (member 'expand-manifest phase-names) ? true)
        (check (member 'delegate-gxtest phase-names) ? true)))

    (test-case "scenario suite receipt separates policy delegate phase"
      (let* ((receipt
              (testing-run-project
               +testing-project+
               (list "poo-construction-performance")
               fake-run-files))
             (suite-receipt (car (testing-receipt-children receipt)))
             (phase-names (testing-test-phase-names suite-receipt))
             (delegate-phase
              (testing-test-phase suite-receipt 'delegate-policy)))
        (check (member 'delegate-policy phase-names) ? true)
        (check (testing-receipt-files delegate-phase)
               => (testing-receipt-files suite-receipt))))

    (test-case "project run selects only the matching gxtest suite"
      (let* ((receipt
              (testing-run-project
               +testing-project+
               (list (fixture-path "alpha-test.ss"))
               fake-run-files))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'receiptKind)
               => 'gxtest-suite)))

    (test-case "project selection is a POO object before execution"
      (let* ((selection
              (testing-select-project
               +testing-project+
               (list (fixture-path "alpha-test.ss"))))
             (suites (testing-selection-suites selection)))
        (check (object? selection) => #t)
        (check (testing-object-kind selection) => 'testing-selection)
        (check (testing-selection-ok? selection) => #t)
        (check (testing-selection-project selection) => +testing-project+)
        (check (testing-selection-args selection)
               => (list (fixture-path "alpha-test.ss")))
        (check (length suites) => 1)
        (check (testing-suite-name (car suites)) => "unit")))

    (test-case "project run consumes POO selection without widening"
      (let* ((selection
              (testing-select-project
               +testing-project+
               (list (fixture-path "alpha-test.ss"))))
             (receipt
              (testing-run-selection selection fake-run-files))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'receiptKind)
               => 'gxtest-suite)
        (check (testing-receipt-files (car children))
               => (list (fixture-path "alpha-test.ss")))))

    (test-case "project selection reports rejected scopes before execution"
      (let (selection
            (testing-select-project
             +testing-project+
             (list "unknown-scope")))
        (check (object? selection) => #t)
        (check (testing-object-kind selection) => 'testing-selection)
        (check (testing-selection-ok? selection) => #f)
        (check (testing-selection-suites selection) => [])
        (check (testing-selection-detail selection 'reason)
               => 'no-selected-suites)))

    (test-case "project run does not widen explicit files across gxtest suites"
      (let* ((other-suite
              (gxtest-suite
               name: "other-unit"
               roots: (list (fixture-path "other-unit-tests.ss"))
               files: (list (fixture-path "gamma-test.ss"))))
             (project
              (testing-project
               name: "multi-gxtest"
               suites: (list +testing-suite+ other-suite)))
             (receipt
              (testing-run-project
               project
               (list (fixture-path "alpha-test.ss"))
               fake-run-files))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'suite)
               => "unit")))

    (test-case "project run selects only the matching scenario suite"
      (let* ((receipt
              (testing-run-project
               +testing-project+
               (list "poo-construction-performance")
               fake-run-files))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'receiptKind)
               => 'scenario-suite)))

    (test-case "project run reports unknown incremental scopes"
      (let (receipt
            (testing-run-project
             +testing-project+
             (list "unknown-scope")
             fake-run-files))
        (check (testing-receipt-ok? receipt) => #f)
        (check (testing-receipt-detail receipt 'reason)
               => 'no-selected-suites)))))
