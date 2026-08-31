;;; -*- Gerbil -*-
;;; Downstream build.ss integration tests for the POO-shaped testing framework.

(import :std/test
        :asp-gerbil-scheme/src/benchmark/framework
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/build
        :asp-gerbil-scheme/src/testing/build-runner
        :asp-gerbil-scheme/src/testing/gxtest-runner)

(export testing-framework-downstream-test)

;; : (-> (Vector Boolean) Path Void)
(def (load-once! loaded? path)
  (unless (vector-ref loaded? 0)
    (load path)
    (vector-set! loaded? 0 #t)))

(def +downstream-testing-build-loaded?+
  (vector #f))

(def +marlin-speed-build-loaded?+
  (vector #f))

(def +upstream-gxtest-build-loaded?+
  (vector #f))

(def +downstream-api-loading-input-root+
  "t/scenarios/policy/downstream-testing-framework-api-loading/input")

(def +downstream-api-loading-expected-root+
  "t/scenarios/policy/downstream-testing-framework-api-loading/expected")

(def +upstream-gxtest-delegation-root+
  "t/scenarios/policy/upstream-gxtest-delegation")

;; : (-> Path String Boolean)
(def (downstream-source-root-contains? root fragment)
  (benchmark-string-contains-fragment?
   (benchmark-source-tree-text root)
   fragment))

;; : (-> Void)
(def (ensure-downstream-testing-build!)
  (load-once!
   +downstream-testing-build-loaded?+
   "t/scenarios/policy/downstream-testing-framework-api-loading/input/build.ss"))

;; : (-> Void)
(def (ensure-marlin-speed-build!)
  (load-once!
   +marlin-speed-build-loaded?+
   "t/scenarios/policy/marlin-testing-speed-trap/expected/build.ss"))

;; : (-> Void)
(def (ensure-upstream-gxtest-build!)
  (load-once!
   +upstream-gxtest-build-loaded?+
   "t/scenarios/policy/upstream-gxtest-delegation/expected/build.ss"))

;; : (-> TestingBuild)
(def (downstream-testing-project*)
  (ensure-downstream-testing-build!)
  (eval 'downstream-testing-project))

;; : (-> TestingBuild)
(def (marlin-speed-project*)
  (ensure-marlin-speed-build!)
  (eval 'marlin-speed-project))

;; : (-> TestingBuild)
(def (upstream-gxtest-project*)
  (ensure-upstream-gxtest-build!)
  (eval 'upstream-gxtest-project))

;; : (-> (List String) (U #f (-> (List Path) Integer)) TestingReceipt)
(def (downstream-testing-main* args (run-files #f))
  (ensure-downstream-testing-build!)
  ((eval 'downstream-testing-main) args run-files))

;; : (-> (List String) (U #f (-> (List Path) Integer)) TestingReceipt)
(def (marlin-speed-main* args (run-files #f))
  (ensure-marlin-speed-build!)
  ((eval 'marlin-speed-main) args run-files))

;; : (-> (List String) (U #f (-> (List Path) Integer)) TestingReceipt)
(def (upstream-gxtest-main* args (run-files #f))
  (ensure-upstream-gxtest-build!)
  ((eval 'upstream-gxtest-main) args run-files))

;; : (-> Path Path)
(def (downstream-testing-path relative)
  (testing-build-path (downstream-testing-project*) relative))

;; : (-> Path Path)
(def (marlin-speed-path relative)
  (testing-build-path (marlin-speed-project*) relative))

;; : (-> Path Path)
(def (upstream-gxtest-path relative)
  (testing-build-path (upstream-gxtest-project*) relative))

(def testing-framework-downstream-test
  (test-suite "gerbil scheme testing framework downstream build integration"
    (test-case "testing build rejects explicit files outside declared suites"
      (let* ((project (downstream-testing-project*))
             (receipt
              (testing-build-main
               project
               ["t/does-not-exist-test.ss"]
               (testing-build-dry-gxtest-runner project))))
        (check (testing-receipt-ok? receipt) => #f)
        (check (testing-object-ref receipt 'status) => 'failed)))

    (test-case "testing build accepts relative files without dot-prefix drift"
      (let (project (downstream-testing-project*))
        (testing-build-reset! project)
        (let* ((receipt
                (downstream-testing-main*
                 ["t/scenarios/policy/downstream-testing-framework-api-loading/input/t/unit-a-test.ss"]
                 (testing-build-dry-gxtest-runner project)))
               (children (testing-receipt-children receipt)))
          (check (testing-receipt-ok? receipt) => #t)
          (check (length children) => 1)
          (check (testing-object-ref (car children) 'suite)
                 => "unit"))))

    (test-case "downstream build.ss loads public testing API"
      (let* ((project (downstream-testing-project*))
             (_ (testing-build-reset! project))
             (file (downstream-testing-path "t/unit-a-test.ss"))
             (receipt
              (downstream-testing-main*
               (list file)
               (testing-build-dry-gxtest-runner project)))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'suite)
               => "unit")
        (check (testing-build-gxtest-runs project)
               => (list (list file)))))

    (test-case "downstream build keeps performance suite selectable"
      (let* ((project (downstream-testing-project*))
             (_ (testing-build-reset! project))
             (file (downstream-testing-path "t/performance-test.ss"))
             (receipt
              (downstream-testing-main*
               (list file)
               (testing-build-dry-gxtest-runner project)))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'suite)
               => "performance")
        (check (testing-build-gxtest-runs project)
               => (list (list file)))))

    (test-case "downstream explicit files are owned once across overlapping suites"
      (let* ((project (downstream-testing-project*))
             (_ (testing-build-reset! project))
             (unit-file (downstream-testing-path "t/unit-a-test.ss"))
             (scenario-a-file (downstream-testing-path "t/scenario-a-test.ss"))
             (scenario-b-file (downstream-testing-path "t/scenario-b-test.ss"))
             (receipt
              (downstream-testing-main*
               (list unit-file scenario-a-file scenario-b-file)
               (testing-build-dry-gxtest-runner project)))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (map (lambda (child)
                      (testing-object-ref child 'suite))
                    children)
               => ["unit" "scenario-a" "scenario-b"])
        (check (testing-build-gxtest-runs project)
               => (list (list unit-file)
                        (list scenario-a-file)
                        (list scenario-b-file)))))

    (test-case "downstream scenario repairs direct benchmark helper usage"
      (check (downstream-source-root-contains?
              +downstream-api-loading-input-root+
              "(benchmark-run/result")
             => #t)
      (check (downstream-source-root-contains?
              +downstream-api-loading-expected-root+
              "(testing-benchmark-run/result")
             => #t)
      (check (downstream-source-root-contains?
              +downstream-api-loading-expected-root+
              "'benchmark-body")
             => #t))

    (test-case "downstream build.ss can delegate to a real gxtest runner"
      (let* ((project (downstream-testing-project*))
             (_ (testing-build-reset! project))
             (runs (vector []))
             (file (downstream-testing-path "t/unit-a-test.ss"))
             (runner
              (lambda (files)
                (vector-set! runs 0 (cons files (vector-ref runs 0)))
                0))
             (receipt (downstream-testing-main* (list file) runner))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'suite)
               => "unit")
        (check (reverse (vector-ref runs 0))
               => (list (list file)))
        (check (testing-build-gxtest-runs project) => [])))

    (test-case "marlin-like build speed trap stays incremental"
      (let* ((project (marlin-speed-project*))
             (_ (testing-build-reset! project))
             (file (marlin-speed-path "t/config-interface-test.ss"))
             (receipt
              (marlin-speed-main*
               (list file)
               (testing-build-dry-gxtest-runner project)))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'suite)
               => "config-interface")
        (check (testing-build-gxtest-runs project)
               => (list (list file)))))

    (test-case "upstream gxtest delegation selects files before delegate execution"
      (let* ((project (upstream-gxtest-project*))
             (_ (testing-build-reset! project))
             (file (upstream-gxtest-path "t/alpha-test.ss"))
             (selection (testing-build-select project (list file)))
             (suites (testing-selection-suites selection))
             (receipt
              (upstream-gxtest-main*
               (list file)
               (testing-build-dry-gxtest-runner project)))
             (children (testing-receipt-children receipt)))
        (check (testing-selection-ok? selection) => #t)
        (check (length suites) => 1)
        (check (testing-suite-name (car suites)) => "upstream")
        (check (testing-receipt-ok? receipt) => #t)
        (check (testing-receipt-files (car children)) => (list file))
        (check (testing-build-gxtest-runs project)
               => (list (list file)))))

    (test-case "upstream gxtest delegation keeps manifest expansion in one suite"
      (let* ((project (upstream-gxtest-project*))
             (_ (testing-build-reset! project))
             (root (upstream-gxtest-path "t/upstream-tests.ss"))
             (alpha (upstream-gxtest-path "t/alpha-test.ss"))
             (beta (upstream-gxtest-path "t/beta-test.ss"))
             (receipt
              (upstream-gxtest-main*
               (list root)
               (testing-build-dry-gxtest-runner project)))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-receipt-files (car children))
               => (list alpha beta))
        (check (testing-build-gxtest-runs project)
               => (list (list alpha beta)))))

    (test-case "upstream gxtest delegate owns suite and setup cleanup discovery"
      (let* ((alpha (upstream-gxtest-path "t/alpha-test.ss"))
             (symbols (gxtest-file-exported-symbols alpha)))
        (check (member 'test-setup! symbols) ? true)
        (check (member 'test-cleanup! symbols) ? true)
        (check (member 'alpha-test symbols) ? true)
        (check (gxtest-file-exported-suite alpha)
               => 'alpha-test)))

    (test-case "upstream gxtest delegation owns a benchmark gate"
      (check (benchmark-contract-valid/root?
              +upstream-gxtest-delegation-root+)
             => #t)
      (let* ((project (upstream-gxtest-project*))
             (_ (testing-build-reset! project))
             (bench
              (benchmark-contract-run/root
               +upstream-gxtest-delegation-root+
               (lambda ()
                 (upstream-gxtest-main*
                  (list (upstream-gxtest-path "t/alpha-test.ss"))
                  (testing-build-dry-gxtest-runner project))))))
        (check (benchmark-contract-receipt-pass? bench) => #t)))))
