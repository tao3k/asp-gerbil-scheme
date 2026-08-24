(import :std/misc/process
        :std/srfi/13
        :std/test
        (only-in ../src/building/build-script
                 call-with-framework-build-cores
                 framework-build-core-count
                 framework-build-reexec-required?
                 framework-build-contract))

(export build-script-bridge-test main)

(def +fixture-build-script+
  "t/fixtures/build-script-bridge/build.ss")

(def (run-fixture . arguments)
  (run-process
   (append ["gxi" +fixture-build-script+] arguments)))

(def build-script-bridge-test
  (test-suite "Building Build SS bridge"
    (test-case "re-exports the upstream command surface"
      (check (run-fixture "meta")
             => "(\"spec\" \"compile\" \"clean\")\n"))
    (test-case "downstream target declaration remains upstream-owned"
      (let (spec (run-fixture "spec"))
        (check (string-contains spec "exe:") ? true)
        (check (string-contains spec "support.ss") ? true)
        (check (string-contains spec "downstream-build-script-probe") ? true)))
    (test-case "publishes one explicit ownership contract"
      (let (contract (framework-build-contract))
        (check (cdr (assoc 'executor contract)) => "std/make")
        (check (cdr (assoc 'dependencyGraphOwner contract)) => "std/make")
        (check (cdr (assoc 'parallelismOwner contract))
               => "GERBIL_BUILD_CORES")
        (check (cdr (assoc 'defaultCoreSelection contract))
               => "host-cpu-count")
        (check (cdr (assoc 'compilerCoreCapture contract))
               => "pre-import-child-process")
        (check (cdr (assoc 'dependencyCacheIsolation contract))
               => "GERBIL_BUILD_PREFIX")
        (check (cdr (assoc 'nativeLinkWorkingDirectory contract))
               => "declared-bindir")
        (check (cdr (assoc 'buildGraphProjection contract))
               => "declared-compiler-runtime-closure-to-std/make")
        (check (cdr (assoc 'runtimeClosureDriftOracle contract))
               => "gerbil-executable-stub")
        (check (cdr (assoc 'executableFreshnessOwner contract))
               => "declared-runtime-closure-to-std-make")
        (check (cdr (assoc 'cacheConcurrencyOwner contract))
               => "kernel-flock-per-GERBIL_PATH")
        (check (cdr (assoc 'objectLockRecovery contract))
               => "static-and-binary-under-exclusive-build-lease")))
    (test-case "injects host cores while preserving an explicit override"
      (let (previous (getenv "GERBIL_BUILD_CORES" #f))
        (dynamic-wind
          (lambda () (setenv "GERBIL_BUILD_CORES" ""))
          (lambda ()
            (check (framework-build-core-count) => (max 1 (##cpu-count)))
            (check (call-with-framework-build-cores
                    (lambda ()
                      (string->number (getenv "GERBIL_BUILD_CORES"))))
                   => (max 1 (##cpu-count)))
            (setenv "GERBIL_BUILD_CORES" "3")
            (check (framework-build-core-count) => 3)
            (check (call-with-framework-build-cores
                    (lambda () (getenv "GERBIL_BUILD_CORES")))
                   => "3"))
          (lambda ()
            (setenv "GERBIL_BUILD_CORES" (or previous ""))))))
    (test-case "re-enters compile before compiler modules capture core count"
      (let ((previous-cores (getenv "GERBIL_BUILD_CORES" #f))
            (previous-prefix (getenv "GERBIL_BUILD_PREFIX" #f)))
        (dynamic-wind
          (lambda ()
            (setenv "GERBIL_BUILD_CORES" "")
            (setenv "GERBIL_BUILD_PREFIX" ""))
          (lambda ()
            (check (framework-build-reexec-required? []) => #t)
            (check (framework-build-reexec-required? ["compile"]) => #t)
            (check (framework-build-reexec-required? ["meta"]) => #f)
            (check (framework-build-reexec-required? ["spec"]) => #f)
            (check (framework-build-reexec-required? ["clean"]) => #f)
            (setenv "GERBIL_BUILD_CORES" "3")
            (check (framework-build-reexec-required? []) => #t)
            (setenv "GERBIL_BUILD_PREFIX" "1")
            (check (framework-build-reexec-required? []) => #f)
            (check (framework-build-reexec-required? ["compile"]) => #f))
          (lambda ()
            (setenv "GERBIL_BUILD_CORES" (or previous-cores ""))
            (setenv "GERBIL_BUILD_PREFIX" (or previous-prefix ""))))))))

(def (main . _args)
  (run-tests! build-script-bridge-test))
