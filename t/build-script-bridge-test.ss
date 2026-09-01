(import :std/test
        (only-in :asp-gerbil-scheme/src/building/build-script
                 call-with-framework-build-cores
                 framework-build-core-count
                 framework-build-reexec-required?
                 framework-executable-build-spec
                 framework-build-contract))

(export build-script-bridge-test main)

(def build-script-bridge-test
  (test-suite "Building Build SS bridge"
    (test-case "package libraries follow and do not enter the executable closure"
      (check
       (framework-executable-build-spec
        "main" "provider" '("runtime") '("library") '())
       => '((gxc: "runtime" (static: #t))
            (exe: "main" bin: "provider")
            "library")))
    (test-case "native TLS flags remain declarative and platform resolved"
      (let* ((spec (framework-executable-build-spec
                    "main" "provider" '("runtime") '("library") '(tls)))
             (executable (cadr spec)))
        (check (and (member "-cc-options" executable) #t) => #t)
        (check (and (member "-ld-options" executable) #t) => #t)
        (check (member "-pkg-config" executable) => #f)))
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
        (check (cdr (assoc 'dependencyEnvironmentOwner contract))
               => "gxpkg-env")
        (check (cdr (assoc 'nativeLinkWorkingDirectory contract))
               => "declared-bindir")
        (check (cdr (assoc 'buildGraphProjection contract))
               => "declared-compiler-runtime-closure-to-std/make")
        (check (cdr (assoc 'libraryBuildProjection contract))
               => "post-executable-package-modules-to-std/make")
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
      (let (previous-cores (getenv "GERBIL_BUILD_CORES" #f))
        (dynamic-wind
          (lambda ()
            (setenv "GERBIL_BUILD_CORES" ""))
          (lambda ()
            (check (framework-build-reexec-required? []) => #t)
            (check (framework-build-reexec-required? ["compile"]) => #t)
            (check (framework-build-reexec-required? ["meta"]) => #f)
            (check (framework-build-reexec-required? ["spec"]) => #f)
            (check (framework-build-reexec-required? ["clean"]) => #f)
            (setenv "GERBIL_BUILD_CORES" "3")
            (check (framework-build-reexec-required? []) => #f)
            (check (framework-build-reexec-required? ["compile"]) => #f))
          (lambda ()
            (setenv "GERBIL_BUILD_CORES" (or previous-cores ""))))))))

(def (main . _args)
  (run-tests! build-script-bridge-test))
