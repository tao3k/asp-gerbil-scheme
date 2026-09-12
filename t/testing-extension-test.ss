;;; -*- Gerbil -*-

(import :std/test
        (only-in :clan/poo/object .cc .ref object?)
        "../src/testing/extension"
        "../src/testing/performance")

(export testing-extension-test)

(def testing-extension-test
  (test-suite "POO extensions for upstream testing"
    (test-case "the object names the upstream executor without replacing it"
      (check (object? +asp-testing-interface+) => #t)
      (check (.ref +asp-testing-interface+ 'upstream) => ':clan/testing)
      (check (.ref +asp-testing-interface+ 'command) => 'gerbil-test))

    (test-case "scenario profiles are enabled by default"
      (check (testing-interface-profile-names +asp-testing-interface+)
             => '(memory performance debug-trace serial-resource discovery))
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
               => '(memory debug-trace serial-resource discovery))
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
