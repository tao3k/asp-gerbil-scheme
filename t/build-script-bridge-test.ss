(import :std/test
        (only-in :asp-gerbil-scheme/src/building/build-script
                 call-with-framework-build-cores
                 framework-build-core-count
                 framework-build-profile-options
                 framework-resolve-build-keys
                 framework-normalize-build-options
                 framework-merge-build-options
                 framework-build-reexec-required?
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
    (test-case "package profiles lower directly to std/make options"
      (check (framework-build-profile-options 'development)
             => [optimize: #f])
      (cond-expand
       (darwin
        (check (framework-build-profile-options 'production)
               => [optimize: #t]))
       (else
        (check (framework-build-profile-options 'production)
               => [optimize: #t build-release: #t])))
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
        (check (cdr (assoc 'defaultCoreSelection contract))
               => "host-cpu-count")
        (check (cdr (assoc 'compilerCoreCapture contract))
               => "pre-import-child-process")
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
