(import :std/test
        (only-in :asp-gerbil-scheme/src/building/build-script
                 framework-build-core-count
                 framework-build-trace-receipt
                 framework-apply-build-core-policy!
                 framework-build-profile-options
                 framework-build-spec-import-source
                 framework-build-module-schedule-line
                 framework-parse-build-options
                 framework-resolve-build-keys
                 framework-normalize-build-options
                 framework-merge-build-options
                 framework-std-make-options
                 framework-executable-build-spec
                 call-with-framework-native-toolchain-environment
                 framework-build-contract))

(export build-script-bridge-test main)

(def build-script-bridge-test
  (test-suite "Building Build SS bridge"
    (test-case "package libraries follow and do not enter the executable closure"
      (check
       (framework-executable-build-spec
        "main" "provider" '("runtime") '("library") '())
       => '((gxc: "runtime" (optimize: #t))
            (exe: "main" bin: "provider" runtime-linkage: separate-aot)
            "library")))
    (test-case "native TLS flags remain declarative and platform resolved"
      (let* ((spec (framework-executable-build-spec
                    "main" "provider" '("runtime") '("library") '(tls)))
             (executable (cadr spec)))
        (check (and (member "-cc-options" executable) #t) => #t)
        (check (and (member "-ld-options" executable) #t) => #t)
        (check (member "-pkg-config" executable) => #f)))
    (test-case "package profiles lower directly to std/make options"
      (check (framework-build-profile-options 'development)
             => [optimize: #f])
      (check (framework-build-profile-options 'production)
             => [optimize: #f])
      (check (framework-resolve-build-keys
              [profile: 'development bindir: "/tmp/profile-bin"])
             => [optimize: #f bindir: "/tmp/profile-bin"])
      (check (framework-merge-build-options
              [optimize: #f bindir: "/tmp/profile-bin"]
              [optimize: #t debug: #t])
             => [optimize: #t debug: #t bindir: "/tmp/profile-bin"])
      (check (framework-normalize-build-options
              [optimize: #t
               build-optimized: #t
               optimize: #t
               build-release: #t])
             => [optimize: #t
                 build-optimized: #t
                 build-release: #t]))
    (test-case "build verbosity lowers to the native std/make option"
      ;; gxi reserves -v for version output and gxc owns -V. The package
      ;; bridge exposes one unambiguous long option and lowers it to the
      ;; native std/make keyword rather than inventing verbosity levels.
      (check-exception (framework-parse-build-options '("-v")) true)
      (check (framework-parse-build-options '("--verbose" "--debug"))
             => [debug: #t verbose: #t])
      (check (framework-std-make-options [debug: #t verbose: #t])
             => [debug: #t verbose: 9]))
    (test-case "module scheduling resolves native build item sources"
      (check (framework-build-spec-import-source
              "src/runtime/parser" "/workspace")
             => "/workspace/src/runtime/parser.ss")
      (check (framework-build-spec-import-source
              [exe: "src/main" bin: "gparse"] "/workspace")
             => "/workspace/src/main.ss")
      (check (framework-build-spec-import-source
              [ssi: "src/native"] "/workspace")
             => "/workspace/src/native.ssi")
      (check (framework-build-spec-import-source
              [static-include: "src/native.c"] "/workspace")
             => #f)
      (check (framework-build-module-schedule-line "/workspace/src/main.ss")
             => (string-append
                 "[asp-gerbil-scheme-build] phase=module-scheduled source="
                 "/workspace/src/main.ss")))
    (test-case "verbose builds expose a typed live phase trace"
      (let (receipt
            (framework-build-trace-receipt
             "std/make package build" 'active 12 4096 87.5 0))
        (check (hash-get receipt "schema")
               => "asp-gerbil-scheme.build-trace.v1")
        (check (hash-get receipt "phase") => "active")
        (check (hash-get receipt "activityKind")
               => "scheme-expansion-or-dependency-analysis")
        (check (hash-get receipt "elapsedMs") => 12000)
        (check (hash-get receipt "activeCompilerJobs") => 0)))
    (test-case "publishes one explicit ownership contract"
      (let (contract (framework-build-contract))
        (check (cdr (assoc 'executor contract)) => "std/make")
        (check (cdr (assoc 'dependencyGraphOwner contract)) => "std/make")
        (check (cdr (assoc 'buildProfileOwner contract))
               => "POO-package-spec")
        (check (cdr (assoc 'buildProfileProjection contract))
               => "native-std/make-options")
        (check (cdr (assoc 'buildDepsOwner contract))
               => "std/make-srcdir-default")
        (check (cdr (assoc 'parallelismOwner contract))
               => "GERBIL_BUILD_CORES")
        (check (cdr (assoc 'verbosityOwner contract))
               => "build-script-cli-to-std-make")
        (check (cdr (assoc 'nativeVerboseLevel contract)) => 9)
        (check (cdr (assoc 'defaultCoreSelection contract))
               => "host-cpu-count")
        (check (cdr (assoc 'compilerCoreCapture contract))
               => "environment-and-compiler-counter")
        (check (cdr (assoc 'dependencyEnvironmentOwner contract))
               => "gxpkg-env")
        (check (cdr (assoc 'nativeLinkWorkingDirectory contract))
               => "declared-bindir")
        (check (cdr (assoc 'darwinNativeEnvironmentOwner contract))
               => "Building-Framework")
        (check (cdr (assoc 'darwinNativeEnvironmentExclusions contract))
               => "SDKROOT-and-DEVELOPER_DIR")
        (check (cdr (assoc 'darwinExecutableTopology contract))
               => "optimized-multi-unit")
        (check (cdr (assoc 'linuxReleaseLinkage contract))
               => "optimized-dynamic")
        (check (cdr (assoc 'buildGraphProjection contract))
               => "declared-compiler-runtime-closure-to-std/make")
        (check (cdr (assoc 'buildGraphAdmission contract))
               => "none-full-declared-spec-to-std/make")
        (check (cdr (assoc 'affectedOutputInvalidation contract))
               => "none")
        (check (cdr (assoc 'upstreamBuildSessionCount contract))
               => "one-native-std/make-session")
        (check (cdr (assoc 'libraryBuildProjection contract))
               => "post-executable-package-modules-to-std/make")
        (check (cdr (assoc 'runtimeClosureDriftOracle contract))
               => "entry-stub-and-separate-aot-modules")
        (check (cdr (assoc 'runtimeLinkage contract))
               => "separate-aot")
        (check (cdr (assoc 'executableFreshnessOwner contract))
               => "declared-runtime-closure-to-std-make")
        (check (cdr (assoc 'cacheConcurrencyOwner contract))
               => "kernel-flock-per-GERBIL_PATH")
        (check (cdr (assoc 'objectLockRecovery contract))
               => "static-and-binary-under-exclusive-build-lease")))
    (test-case "resolves host cores while preserving an explicit override"
      (let (previous (getenv "GERBIL_BUILD_CORES" #f))
        (dynamic-wind
          (lambda () (setenv "GERBIL_BUILD_CORES" ""))
          (lambda ()
            (check (framework-build-core-count) => (max 1 (##cpu-count)))
            (setenv "GERBIL_BUILD_CORES" "3")
            (check (framework-build-core-count) => 3))
          (lambda ()
            (setenv "GERBIL_BUILD_CORES" (or previous ""))))))
    (test-case "isolates Homebrew GCC from Nix Darwin SDK selection"
      (cond-expand
       (darwin
        (let ((previous-sdk (getenv "SDKROOT" #f))
              (previous-developer (getenv "DEVELOPER_DIR" #f)))
          (dynamic-wind
            (lambda ()
              (setenv "SDKROOT" "/nix/test-sdk")
              (setenv "DEVELOPER_DIR" "/nix/test-developer"))
            (lambda ()
              (check
               (call-with-framework-native-toolchain-environment
                (lambda ()
                  (list (getenv "SDKROOT" #f)
                        (getenv "DEVELOPER_DIR" #f))))
               => '(#f #f))
              (check (getenv "SDKROOT" #f) => "/nix/test-sdk")
              (check (getenv "DEVELOPER_DIR" #f)
                     => "/nix/test-developer"))
            (lambda ()
              (if previous-sdk
                (setenv "SDKROOT" previous-sdk)
                (setenv "SDKROOT"))
              (if previous-developer
                (setenv "DEVELOPER_DIR" previous-developer)
                (setenv "DEVELOPER_DIR"))))))
       (else
        (check
         (call-with-framework-native-toolchain-environment
          (lambda () 'unchanged))
         => 'unchanged))))
    (test-case "applies one adaptive core value to the native build"
      (let (previous-cores (getenv "GERBIL_BUILD_CORES" #f))
        (dynamic-wind
          (lambda ()
            (setenv "GERBIL_BUILD_CORES" ""))
          (lambda ()
            (check (framework-apply-build-core-policy!)
                   => (max 1 (##cpu-count)))
            (check (getenv "GERBIL_BUILD_CORES")
                   => (number->string (max 1 (##cpu-count))))
            (setenv "GERBIL_BUILD_CORES" "3")
            (check (framework-apply-build-core-policy!) => 3)
            (check (getenv "GERBIL_BUILD_CORES") => "3"))
          (lambda ()
            (setenv "GERBIL_BUILD_CORES" (or previous-cores ""))))))))

(def (main . _args)
  (run-tests! build-script-bridge-test))
