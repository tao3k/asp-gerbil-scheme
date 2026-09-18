;;; -*- Gerbil -*-

(import :std/test
        (only-in :clan/poo/object .call .cc .ref object?)
        "../src/testing/extension"
        "../src/testing/discovery-runner"
        "../src/testing/source-admission"
        (only-in ../src/build-api/native-import-closure
                 asp-gerbil-scheme-prepared-native-import-closure)
        (only-in "./fixtures/resident-import-footprint/root"
                 resident-footprint-root-witness)
        "../src/testing/performance")

(export testing-extension-test)

(def +testing-entry-witness+
  (testing-interface-add-profile
   +asp-testing-interface+
   (.cc +testing-discovery-profile+
        ignoreDirectories: '("nested-package"))))

;; Executable source witness for the public package-entry macro. The generated
;; entry remains clan-owned and is not invoked while gxtest loads this module.
(init-profiled-test-environment! +testing-entry-witness+)

(def testing-extension-test
  (test-suite "POO extensions for upstream testing"
    (test-case "the object names the upstream executor without replacing it"
      (check (object? +asp-testing-interface+) => #t)
      (check (.ref +asp-testing-interface+ 'upstream) => ':clan/testing)
      (check (.ref +asp-testing-interface+ 'command) => 'gerbil-test))

    (test-case "scenario profiles are enabled by default"
      (check (testing-interface-profile-names +asp-testing-interface+)
             => '(memory performance debug-trace discovery))
      (check (testing-interface-profile-enabled?
              +asp-testing-interface+
              'performance)
             => #t)
      (check (.ref +testing-debug-trace-profile+ 'library)
             => ':clan/poo/debug)
      (check (.ref +testing-debug-trace-profile+ 'operation)
             => 'trace-poo)
      (check (.ref +testing-performance-profile+ 'timingLibrary)
             => ':clan/timestamp)
      (check (.ref +testing-performance-profile+ 'metrics)
             => '(wall-time cpu-time allocation gc managed-heap)))

    (test-case "clan discovery results can be filtered by a POO profile"
      (let* ((discovery
              (.cc +testing-discovery-profile+
                   ignoreDirectories: '("lambda-episteme" "vendor/generated")))
             (testing
              (testing-interface-add-profile
               +asp-testing-interface+
               discovery)))
        (check (testing-interface-ignore-directories-for
                testing
                "unit-tests.ss")
               => '("lambda-episteme" "vendor/generated"))
        (check (testing-interface-test-file-included?
                testing
                "unit-tests.ss"
                "./t/core-test.ss")
               => #t)
        (check (testing-interface-test-file-included?
                testing
                "unit-tests.ss"
                "./lambda-episteme/t/sdlc-test.ss")
               => #f)
        (check (testing-interface-test-file-included?
                testing
                "unit-tests.ss"
                "vendor/generated/t/generated-test.ss")
               => #f)))

    (test-case "POO import footprint profile rejects repeated heavy owners"
      (let* ((profile
              (testing-import-footprint-profile
               '(:fixture/heavy-a :fixture/heavy-b)
               1
               'reject))
             (testing
              (testing-interface-add-profile
               +asp-testing-interface+ profile)))
        (check
         (testing-import-footprint-datum-owners
          '(import (only-in :fixture/heavy-a value)
                   :fixture/heavy-b))
         => '(:fixture/heavy-a :fixture/heavy-b))
        (check-exception
         (testing-interface-admit-test-imports!
          testing "t/fixtures/import-footprint-over-budget.ss")
         true)
        (let (receipt
              (testing-interface-admit-test-imports!
               testing "t/fixtures/import-footprint-admitted.ss"))
          (check (.ref receipt 'admitted?) => #t)
          (check (.ref receipt 'heavyOwners) => '(:fixture/heavy-a)))))

    (test-case "resident registry rejects overlapping large import closures"
      (check resident-footprint-root-witness
             => '(resident-shared resident-shared))
      (let* ((profile
              (testing-import-footprint-profile
               [] 0 'reject
               large-closure-module-count: 2
               max-shared-closure-modules: 0
               ignored-module-prefixes: []))
             (testing
              (testing-interface-add-profile
               +asp-testing-interface+ profile)))
        (check-exception
         (testing-interface-admit-resident-import-footprints!
          testing
          "t/testing-extension-test.ss"
          '("t/fixtures/resident-import-footprint/root.ss"))
         true)
        (let* ((observed
                (testing-interface-add-profile
                 +asp-testing-interface+
                 (.cc profile action: 'observe)))
               (receipt
                (testing-interface-admit-resident-import-footprints!
                 observed
                 "t/testing-extension-test.ss"
                 '("t/fixtures/resident-import-footprint/root.ss"))))
          (check (.ref receipt 'admitted?) => #f)
          (check (length (.ref receipt 'violations)) => 1)
          (check (.ref (car (.ref receipt 'violations))
                       'sharedModuleCount)
                 => 1))))

    (test-case "the profiled package entry is backed by executable test data"
      (check (testing-interface-ignore-directories-for
              +testing-entry-witness+
              "unit-tests.ss")
             => '("nested-package")))

    (test-case "a downstream POO extension can observe without ASP semantics"
      (let* ((events '())
             (testing
              (.cc +asp-testing-interface+
                   around-operation:
                   (lambda (operation thunk)
                     (set! events (cons operation events))
                     (thunk)))))
        (check (call-with-values
                 (lambda ()
                   (testing-interface-call-with-operation
                    testing 'native-test-batch
                    (lambda () (values 'left 'right))))
                 list)
               => '(left right))
        (check events => '(native-test-batch))))

    (test-case "prepared source admission is an explicit POO profile method"
      (let* ((calls '())
             (testing
              (.cc (testing-interface-add-profile
                    +asp-testing-interface+
                    +testing-source-admission-profile+)
                   .admit-prepared-source-graph:
                   (lambda (test roots)
                     (set! calls (cons (list test roots) calls))
                     'admitted))))
        (check (testing-interface-profile-enabled?
                +asp-testing-interface+
                'source-admission)
               => #f)
        (check (testing-interface-profile-enabled?
                testing
                'source-admission)
               => #t)
        (check (testing-interface-call-with-prepared-source-graph
                testing
                "t/source-admission-test.ss"
                '("src/domain.ss" "src/policy.ss"))
               => 'admitted)
        (check calls
               => '(("t/source-admission-test.ss"
                     ("src/domain.ss" "src/policy.ss"))))))

    (test-case "prepared source admission fails closed without its profile"
      (check-exception
       (testing-interface-call-with-prepared-source-graph
        +asp-testing-interface+
        "t/source-admission-test.ss"
        '("src/domain.ss"))
       true))

    (test-case "prepared closure capability fails outside source admission"
      (check-exception
       (asp-gerbil-scheme-prepared-native-import-closure
        "." '("t/testing-extension-test.ss"))
       true))

    (test-case "prepared source admission rejects an empty root declaration"
      (let (testing
            (.cc (testing-interface-add-profile
                  +asp-testing-interface+
                  +testing-source-admission-profile+)
                 .admit-prepared-source-graph:
                 (lambda (_test _roots) 'unreachable)))
        (check-exception
         (testing-interface-call-with-prepared-source-graph
          testing "t/source-admission-test.ss" '())
         true)))

    (test-case "profile transforms preserve downstream POO observation slots"
      (let* ((events '())
             (observed
              (.cc +asp-testing-interface+
                   around-operation:
                   (lambda (operation thunk)
                     (set! events (cons operation events))
                     (thunk))))
             (added
              (testing-interface-add-profile
               observed
               (.cc +testing-memory-profile+ maxHeapMiB: 256)))
             (mapped
              (testing-interface-map-profile
               added
               (testing-test-selector 'contains "slow-test.ss")
               +testing-serial-resource-profile+))
             (transformed
              (testing-interface-remove-profile mapped 'performance)))
        (check
         (testing-interface-call-with-operation
          transformed 'native-test-batch (lambda () 'completed))
         => 'completed)
        (check events => '(native-test-batch))
        (check (testing-interface-profile-enabled? transformed 'memory) => #t)
        (check (testing-interface-profile-enabled? transformed 'performance) => #f)
        (check (testing-interface-test-file-serial?
                transformed "suite/slow-test.ss")
               => #t)
        (set! events '())
        (let (called
              (.call transformed .add +testing-performance-profile+))
          (check
           (testing-interface-call-with-operation
            called 'native-test-batch (lambda () 'called))
           => 'called)
          (check events => '(native-test-batch)))))

    (test-case "invalid discovery boundaries fail closed"
      (let (testing
            (testing-interface-add-profile
             +asp-testing-interface+
             (.cc +testing-discovery-profile+
                  ignoreDirectories: '("../outside"))))
        (check-exception
         (testing-interface-ignore-directories-for testing "unit-tests.ss")
         true)))

    (test-case "POO remove returns a new interface without mutating defaults"
      (let (without-performance
            (testing-interface-remove-profile
             +asp-testing-interface+
             'performance))
        (check (object? without-performance) => #t)
        (check (testing-interface-profile-enabled?
                without-performance
                'performance)
               => #f)
        (check (testing-interface-profile-names without-performance)
               => '(memory debug-trace discovery))
        (check (testing-interface-profile-enabled?
                +asp-testing-interface+
                'performance)
               => #t)))

    (test-case "a removed profile can be composed back"
      (let* ((without-memory
              (testing-interface-remove-profile
               +asp-testing-interface+
               'memory))
             (restored
              (testing-interface-add-profile
               without-memory
               +testing-memory-profile+)))
        (check (testing-interface-profile-enabled? without-memory 'memory)
               => #f)
        (check (testing-interface-profile-enabled? restored 'memory)
               => #t)))

    (test-case "one POO profile can be specialized and mapped per test"
      (let* ((small-memory
              (.cc +testing-memory-profile+ maxHeapMiB: 256))
             (large-memory
              (.cc +testing-memory-profile+ maxHeapMiB: 2048))
             (testing
              (testing-interface-map-profile
               (testing-interface-map-profile
                +asp-testing-interface+
                "t/small-test.ss"
                small-memory)
               "t/large-test.ss"
               large-memory)))
        (check (testing-interface-max-heap-mib-for
                testing
                "t/small-test.ss")
               => 256)
        (check (testing-interface-max-heap-mib-for
                testing
                "t/large-test.ss")
               => 2048)
        (check (testing-interface-max-heap-mib-for
                testing
                "t/default-test.ss")
               => 1024)
        (check (testing-interface-command-for
                testing
                "t/large-test.ss"
                ["-q"])
               => ["gerbil"
                   "-:max-heap=2048M"
                   "test"
                   "-q"
                   "t/large-test.ss"])))

    (test-case "resource profiles select a serial lane declaratively"
      (let* ((performance-tests
              (testing-test-selector 'contains "performance-test"))
             (mapped
              (testing-interface-map-profile
               +asp-testing-interface+
               performance-tests
               +testing-serial-resource-profile+)))
        (check (testing-interface-test-file-serial?
                mapped
                "t/graph-performance-test.ss")
               => #t)
        (check (testing-interface-test-file-serial?
                mapped
                "t/graph-test.ss")
               => #f))
      (check (testing-interface-worker-count 0) => 0)
      (let (previous-build-cores (getenv "GERBIL_BUILD_CORES" #f))
        (dynamic-wind
          (lambda () (setenv "GERBIL_BUILD_CORES" "12"))
          (lambda ()
            (check (testing-interface-worker-count 20) => 12)
            (check (testing-interface-worker-count 1) => 1)
            (check (testing-interface-test-file-batches
                    +asp-testing-interface+
                    '("t/a-test.ss" "t/b-test.ss" "t/c-test.ss"))
                   => '(("t/a-test.ss") ("t/b-test.ss") ("t/c-test.ss"))))
          (lambda ()
            (setenv "GERBIL_BUILD_CORES"
                    (or previous-build-cores ""))))))

    (test-case "process isolation keeps singleton batches in the parallel lane"
      (let* ((isolated-selector
              (testing-test-selector 'contains "registry-test"))
             (mapped
              (testing-interface-map-profile
               +asp-testing-interface+
               isolated-selector
               +testing-process-isolation-profile+))
             (previous-build-cores (getenv "GERBIL_BUILD_CORES" #f)))
        (dynamic-wind
          (lambda () (setenv "GERBIL_BUILD_CORES" "2"))
          (lambda ()
            (check (testing-interface-test-file-isolated?
                    mapped "t/registry-test.ss")
                   => #t)
            (check (testing-interface-test-file-serial?
                    mapped "t/registry-test.ss")
                   => #f)
            (check (testing-interface-test-file-batches
                    mapped
                    '("t/a-test.ss"
                      "t/registry-test.ss"
                      "t/b-test.ss"
                      "t/c-test.ss"))
                   => '(("t/a-test.ss" "t/b-test.ss")
                        ("t/c-test.ss")
                        ("t/registry-test.ss"))))
          (lambda ()
            (setenv "GERBIL_BUILD_CORES"
                    (or previous-build-cores ""))))))

    (test-case "the POO profile configures the current upstream runtime"
      (let (previous-max-heap (##get-max-heap))
        (check (testing-interface-apply-runtime-profile!
                +asp-testing-interface+
                "t/default-test.ss")
               => (* 1024 1024 1024))
        (check (##get-max-heap) => (* 1024 1024 1024))
        (##set-max-heap! previous-max-heap)))

    (test-case "removing memory removes its default and test bindings"
      (let* ((mapped
              (testing-interface-map-profile
               +asp-testing-interface+
               "t/small-test.ss"
               (.cc +testing-memory-profile+ maxHeapMiB: 256)))
             (without-memory
              (testing-interface-remove-profile mapped 'memory)))
        (check (testing-interface-max-heap-mib-for
                without-memory
                "t/small-test.ss")
               => #f)))

    (test-case "invalid POO memory specializations fail closed"
      (let (testing
            (testing-interface-map-profile
             +asp-testing-interface+
             "t/invalid-memory-test.ss"
             (.cc +testing-memory-profile+ maxHeapMiB: 0)))
        (check-exception
         (testing-interface-max-heap-mib-for
          testing
          "t/invalid-memory-test.ss")
         true)))

    (test-case "performance receipt slots do not self-reference"
      (let (receipt
            (testing-benchmark-body-phase
             'bounded-work
             '((status . pass)
               (elapsedNs . 1000000))))
        (check (object? receipt) => #t)
        (check (.ref receipt 'name) => 'bounded-work)
        (check (.ref receipt 'status) => 'ok)
        (check (assq 'name (.ref receipt 'details))
               => '(name . bounded-work))))))
