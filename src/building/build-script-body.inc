;;; Single implementation shared by the root build.ss bootstrap and the public
;;; :asp-gerbil-scheme/src/building/build-script module.
(import :gerbil/gambit
        (only-in :gerbil/compiler/base __available-cores)
        :clan/poo/object
        :std/make
        (only-in "../build-api/source-coverage-query"
                 asp-gerbil-scheme-consume-source-coverage-query!)
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)
        (only-in :std/os/flock open-output-file/lock LOCK_EX)
        (only-in :std/source gerbil-home)
        (only-in :std/sort sort)
        (only-in :std/srfi/13
                 string-prefix?
                 string-suffix?
                 string-tokenize
                 string-trim-both)
        (only-in :std/text/json json-object->string write-json-sort-keys?)
        (only-in :gerbil/gambit getenv))

(include "memory-anomaly-guard-body.inc")

(def (framework-build-artifact-root)
  (getenv "ASP_PROVIDER_ARTIFACT_ROOT"
          (getenv "GERBIL_PATH" (gerbil-home))))

(def (framework-build-bindir)
  (path-expand "bin" (framework-build-artifact-root)))

(def (framework-modules-before-target build-spec target)
  (let loop ((rest build-spec) (modules []))
    (cond
     ((null? rest) (reverse modules))
     ((eq? (car rest) target) (reverse modules))
     ((string? (car rest)) (loop (cdr rest) (cons (car rest) modules)))
     (else (loop (cdr rest) modules)))))

(def (framework-option resolver package fallback)
  (or (try
        (resolver package #f)
        (catch _ #f))
      fallback))

(def (framework-homebrew-prefix packages)
  (let loop ((rest packages))
    (and (pair? rest)
         (or (try
              (string-trim-both
               (run-process ["brew" "--prefix" (car rest)]
                            coprocess: read-all-as-string
                            stderr-redirection: #t))
              (catch _ #f))
             (loop (cdr rest))))))

(def (framework-tls-cc-options)
  (let (native (framework-option cppflags "openssl" #f))
    (string-append
     (or native
         (cond-expand
           (darwin
            (let (prefix (framework-homebrew-prefix '("openssl@3" "openssl")))
              (if prefix (string-append "-I" prefix "/include") "")))
           (else "")))
     " -include openssl/kdf.h")))

(def (framework-tls-ld-options)
  (framework-option
   ldflags
   "openssl"
   (cond-expand
     (darwin
      (let (prefix (framework-homebrew-prefix '("openssl@3" "openssl")))
        (if prefix
          (string-append "-L" prefix "/lib -lssl -lcrypto")
          "-lssl -lcrypto")))
     (else "-lssl -lcrypto"))))

(def (framework-native-link-options native-capabilities)
  (apply append
         (map
          (lambda (capability)
            (case capability
              ((tls)
               (list "-cc-options" (framework-tls-cc-options)
                     "-ld-options" (framework-tls-ld-options)))
              (else
               (error "unsupported native build capability" capability))))
          native-capabilities)))

(def (framework-duplicate-module-owners modules)
  (let loop ((remaining modules) (seen []) (duplicates []))
    (if (null? remaining)
      (reverse duplicates)
      (let (module (car remaining))
        (cond
         ((and (member module seen) (not (member module duplicates)))
          (loop (cdr remaining) seen (cons module duplicates)))
         (else
          (loop (cdr remaining) (cons module seen) duplicates)))))))

(def (framework-static-runtime-build-spec runtime-modules)
  (map (lambda (module) `(gxc: ,module (static: #t))) runtime-modules))

(def (framework-executable-build-spec module binary runtime-modules
                                          library-modules native-capabilities)
  (append (framework-static-runtime-build-spec runtime-modules)
               `((exe: ,module bin: ,binary
                       ,@(framework-native-link-options native-capabilities)))
               library-modules))

(def (framework-validate-runtime-closure! build-spec)
  (def (module-name id)
    (if (symbol? id) (symbol->string id) id))
  (for-each
   (lambda (spec)
     (match spec
       ([exe: module bin: binary]
        (let* ((declared (framework-modules-before-target build-spec spec))
               (stub-path
                  (string-append
                   (path-expand binary (framework-build-bindir))
                   "__exe.scm"))
                 (form (call-with-input-file stub-path read))
                 (builtin-modules (cadr (caddr form)))
                 (module-suffix (string-append "/" module))
                 (target-id
                  (find (lambda (id)
                          (string-suffix? module-suffix
                                          (module-name id)))
                        builtin-modules)))
            (unless target-id
              (error "provider executable stub omits target module"
                     module stub-path))
            (let* ((target-name (module-name target-id))
                   (prefix-length (- (string-length target-name)
                                     (string-length module)))
                   (package-prefix (substring target-name 0 prefix-length))
                   (actual
                    (sort
                     (filter-map
                      (lambda (id)
                        (let (name (module-name id))
                          (and (string-prefix? package-prefix name)
                               (substring name prefix-length
                                          (string-length name)))))
                      builtin-modules)
                     string<?))
                   (expected (sort (cons module declared) string<?)))
              (unless (equal? actual expected)
                (error "provider runtime closure drift"
                       expected actual stub-path)))))
       (else (void))))
   build-spec))

(def (framework-build-cache-root)
  (getenv "GERBIL_PATH" (gerbil-home)))

(def (framework-static-directory)
  (path-expand "lib/static" (framework-build-cache-root)))

(def (framework-positive-core-count value)
  (let (parsed (and value (string->number value)))
    (and (integer? parsed) (> parsed 0) parsed)))

(def (framework-environment-value? value)
  (and (string? value) (> (string-length value) 0)))

(def (framework-build-core-count)
  (or (framework-positive-core-count
       (getenv "GERBIL_BUILD_CORES" #f))
      (max 1 (##cpu-count))))

;; Gerbil 0.18.2 reads GERBIL_BUILD_CORES in std/make and captures it in
;; compiler/base. Apply one value to both owners before std/make receives the
;; package spec. An explicit override wins; otherwise use the logical CPU count.
(def (framework-apply-build-core-policy!)
  (let (selected (framework-build-core-count))
    (setenv "GERBIL_BUILD_CORES" (number->string selected))
    (set! __available-cores selected)
    selected))

(def (framework-recover-object-locks!)
  (def (recover-directory directory)
    (if (file-exists? directory)
      (filter-map
       (lambda (entry)
         (and (string-suffix? ".o.lock" entry)
              (let (path (path-expand entry directory))
                (delete-file path)
                path)))
       (directory-files directory))
      []))
  ;; Both directories are owned by the same per-GERBIL_PATH build lease.
  ;; Gerbil places module object locks in static/ and executable stub locks in
  ;; bindir; leaving either surface out reintroduces its unbounded poll loop.
  (append (recover-directory (framework-static-directory))
          (recover-directory (framework-build-bindir))))

(def +framework-darwin-native-environment-exclusions+
  '("SDKROOT" "DEVELOPER_DIR"))

(def (call-with-framework-native-toolchain-environment thunk)
  (cond-expand
   (darwin
    (let (previous
          (map (lambda (name) (cons name (getenv name #f)))
               +framework-darwin-native-environment-exclusions+))
      (dynamic-wind
        (lambda ()
          (for-each (lambda (entry) (setenv (car entry))) previous))
        thunk
        (lambda ()
          (for-each
           (lambda (entry)
             (if (cdr entry)
               (setenv (car entry) (cdr entry))
               (setenv (car entry))))
           previous)))))
   (else (thunk))))

(def (call-with-framework-build-lease thunk)
  (let* ((cache-root (framework-build-cache-root))
         (lease-path (path-expand ".asp-gerbil-scheme-build.lease" cache-root)))
    (create-directory* cache-root)
    (let (lease (open-output-file/lock lease-path op: LOCK_EX))
      (unwind-protect
        (call-with-framework-native-toolchain-environment
         (lambda ()
           (framework-recover-object-locks!)
           (thunk)))
        (close-port lease)))))

(def (framework-build-profile-options profile)
  (case profile
    ((development)
     [optimize: #f])
    ((production)
     (cond-expand
      ;; Gerbil's build-optimized path emits one SINGLE_HOST executable C
      ;; translation unit.  GCC 16 needs more than ten minutes and about
      ;; 1.55 GiB RSS for the provider unit on Darwin, while the preceding
      ;; module graph finishes in about one minute.  Keep Scheme optimization
      ;; enabled but retain std/make's multi-unit executable topology there.
      (darwin [optimize: #t])
      (else [optimize: #t build-release: #t])))
    (else
     (error "unsupported Scheme build profile" profile))))

(def (framework-profile-controlled-option? option)
  (memq option '(optimize: build-release: build-optimized:)))

(def (framework-resolve-build-keys keys)
  (let loop ((rest keys) (profile #f) (native-options []))
    (match rest
      ([]
       (unless profile
         (error "defbuild-script requires profile: development or production"))
       (append (framework-build-profile-options profile)
               (reverse native-options)))
      ([profile: value . tail]
       (when profile
         (error "defbuild-script declares more than one build profile"))
       (loop tail value native-options))
      ([option value . tail]
       (when (framework-profile-controlled-option? option)
         (error "build profile owns std/make optimization options" option))
       (loop tail profile (cons value (cons option native-options))))
      (else
       (error "malformed defbuild-script options" keys)))))

(def (framework-build-option-keys options)
  (let loop ((rest options) (keys []))
    (match rest
      ([] keys)
      ([key _value . tail]
       (loop tail (cons key keys)))
      (else
       (error "malformed std/make options" options)))))

(def (framework-remove-build-options options removed-keys)
  (let loop ((rest options) (kept []))
    (match rest
      ([] (reverse kept))
      ([key value . tail]
       (if (memq key removed-keys)
         (loop tail kept)
         (loop tail (cons value (cons key kept)))))
      (else
       (error "malformed std/make options" options)))))

(def (framework-normalize-build-options options)
  (match options
    ([] [])
    ([key value . tail]
     (cons* key
            value
            (framework-normalize-build-options
             (framework-remove-build-options tail [key]))))
    (else
     (error "malformed std/make options" options))))

(def (framework-merge-build-options base overrides)
  (let (normalized-overrides
        (framework-normalize-build-options overrides))
    (append normalized-overrides
            (framework-remove-build-options
             (framework-normalize-build-options base)
             (framework-build-option-keys normalized-overrides)))))

(def (framework-parse-build-options options)
  (def (present? keyword parsed)
    (and (memq keyword parsed) #t))
  (let loop ((rest options) (parsed []))
    (match rest
      ([] parsed)
      ([(or "-v" "--verbose") . rest]
       (loop rest (cons* verbose: #t parsed)))
      (["--release" . rest]
         ;; Gerbil implements build-release: by forwarding -static to the
         ;; final native linker. Darwin has no static C runtime startup object
         ;; (crt0.o), so a release build there is optimized but dynamically
         ;; linked. Keep this policy in the Building Framework so every
         ;; executable target has the same platform-correct meaning.
         (cond-expand
          (darwin
           (loop rest
                 (if (present? build-optimized: parsed)
                     parsed
                     (cons* optimize: #t build-optimized: #t parsed))))
          (else
           (loop rest (cons* optimize: #t build-release: #t parsed)))))
      (["--optimized" . rest]
       (loop rest
             (if (present? build-optimized: parsed)
               parsed
               (cons* optimize: #t build-optimized: #t parsed))))
      (["--debug" . rest]
       (loop rest (cons* debug: #t parsed)))
      (else
       (error "Unexpected " rest)))))

(def (framework-build-main arguments build-spec keys source-file)
  (def source-directory
    (path-normalize (path-directory source-file)))
  (def (build options)
    (let ((bindir (framework-build-bindir))
          (build-keys (framework-resolve-build-keys keys)))
      (create-directory* bindir)
      (call-with-framework-build-lease
       (lambda ()
         ;; std/make receives the complete declared spec and remains the only
         ;; dependency, freshness, scheduling, compiler, and linker authority.
         ;; ASP observes this one native session without pre-cleaning or
         ;; filtering its module graph.
         (call-with-framework-memory-anomaly-guard
          "std/make package build"
          (framework-build-core-count)
          (lambda ()
            (parameterize ((current-directory bindir))
              (apply make
                     build-spec
                     srcdir: source-directory
                     (framework-merge-build-options build-keys options)))))
         (framework-validate-runtime-closure! build-spec)))))
  (def (clean)
    (apply make-clean
           build-spec
           srcdir: source-directory
           (framework-resolve-build-keys keys)))
  (match arguments
    (["meta"] (write '("spec" "compile" "clean")) (newline))
    (["spec"] (pretty-print build-spec))
    (["compile" . options]
     (build (framework-parse-build-options options)))
    (["clean"] (clean))
    ([] (build []))))

;;; Script lifecycle boundary: declaration queries execute the package-spec
;;; projection but never enter re-exec, locking, compilation, or cleaning.
;;; Keeping this decision inside the Building Framework prevents an internal
;;; query binding from leaking into downstream macro expansions.
;; : (-> (List String) BuildSpec (List BuildOption) Path Void)
(def (framework-build-dispatch arguments build-spec keys source-file)
  (unless (asp-gerbil-scheme-consume-source-coverage-query! source-file)
    (framework-apply-build-core-policy!)
    (parameterize
     ((current-directory
       (path-normalize (path-directory source-file))))
     (framework-build-main arguments build-spec keys source-file))))

(defsyntax (defbuild-script stx)
  (syntax-case stx ()
    ((macro build-spec keys ...)
     (with-syntax* ((@this-script (stx-identifier #'macro 'this-source-file))
                    (+this-source-file+ (syntax/loc stx (@this-script)))
                    (@main (stx-identifier #'macro 'main)))
       #'(def (@main . arguments)
           (framework-build-dispatch
            arguments build-spec [keys ...] +this-source-file+))))))

(def (framework-build-contract)
  '((schemaId . "asp-gerbil-scheme.build-script-contract")
    (schemaVersion . "1")
    (commandSurfaceOwner . "Building-Framework")
    (executor . "std/make")
    (dependencyGraphOwner . "std/make")
    (buildProfileOwner . "POO-package-spec")
    (buildProfileProjection . "native-std/make-options")
    (developmentProfile . "gcc-optimize-disabled")
    (productionProfile . "gcc-platform-release-policy")
    (buildDepsOwner . "std/make-srcdir-default")
    (parallelismOwner . "GERBIL_BUILD_CORES")
    (verbosityOwner . "build-script-cli-to-std-make")
    (defaultCoreSelection . "host-cpu-count")
    (compilerCoreCapture . "environment-and-compiler-counter")
    (dependencyEnvironmentOwner . "gxpkg-env")
    (nativeLinkWorkingDirectory . "declared-bindir")
    (darwinNativeEnvironmentOwner . "Building-Framework")
    (darwinNativeEnvironmentExclusions . "SDKROOT-and-DEVELOPER_DIR")
    (releaseLinkageOwner . "Building-Framework-platform-policy")
    (darwinReleaseLinkage . "optimized-dynamic")
    (darwinExecutableTopology . "optimized-multi-unit")
    (buildGraphProjection . "declared-compiler-runtime-closure-to-std/make")
    (buildGraphAdmission . "none-full-declared-spec-to-std/make")
    (affectedOutputInvalidation . "none")
    (upstreamBuildSessionCount . "one-native-std/make-session")
    (libraryBuildProjection . "post-executable-package-modules-to-std/make")
    (runtimeClosureDriftOracle . "gerbil-executable-stub")
    (executableFreshnessOwner . "declared-runtime-closure-to-std-make")
    (cacheConcurrencyOwner . "kernel-flock-per-GERBIL_PATH")
    (objectLockRecovery . "static-and-binary-under-exclusive-build-lease")
    (artifactRootEnvironment . "ASP_PROVIDER_ARTIFACT_ROOT")))
