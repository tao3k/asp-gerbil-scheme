;;; Single implementation shared by the root build.ss bootstrap and the public
;;; :asp-gerbil-scheme/src/building/build-script module.
(import :gerbil/gambit
        :std/make
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/misc/process run-process/batch)
        (only-in :std/os/flock open-output-file/lock LOCK_EX)
        (only-in :std/source gerbil-home)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :gerbil/gambit getenv))

(def (framework-build-artifact-root)
  (getenv "ASP_PROVIDER_ARTIFACT_ROOT"
          (getenv "GERBIL_PATH" (gerbil-home))))

(def (framework-build-bindir)
  (path-expand "bin" (framework-build-artifact-root)))

(def (framework-file-modification-seconds path)
  (time->seconds (file-info-last-modification-time (file-info path))))

(def (framework-runtime-source-path source-directory module)
  (path-expand (string-append module ".ss") source-directory))

(def (framework-runtime-source-newer-than-executable? source-directory module
                                                       executable)
  (let (source (framework-runtime-source-path source-directory module))
    (and (file-exists? source)
         (> (framework-file-modification-seconds source)
            (framework-file-modification-seconds executable)))))

;; std/make owns compilation and linking, but its executable target does not
;; model the explicitly embedded runtime-module closure as dependencies. Make
;; that missing edge visible by invalidating only a stale generated executable;
;; the same std/make invocation remains the sole builder and linker.
(def (framework-invalidate-stale-executables! build-spec source-directory bindir)
  (for-each
   (lambda (spec)
     (match spec
       ([exe: module bin: binary]
        (let ((executable (path-expand binary bindir))
              (sources
               (cons module
                     (framework-modules-before-target build-spec spec))))
          (when (and (file-exists? executable)
                     (ormap
                      (lambda (source)
                        (framework-runtime-source-newer-than-executable?
                         source-directory source executable))
                      sources))
            (delete-file executable))))
       (else (void))))
   build-spec))

(def (framework-modules-before-target build-spec target)
  (let loop ((rest build-spec) (modules []))
    (cond
     ((null? rest) (reverse modules))
     ((eq? (car rest) target) (reverse modules))
     ((string? (car rest)) (loop (cdr rest) (cons (car rest) modules)))
     (else (loop (cdr rest) modules)))))

(def (framework-native-link-options native-capabilities)
  (apply append
         (map
          (lambda (capability)
            (case capability
              ((tls)
               (cond-expand
                      (darwin
                       '("-cc-options" "-include openssl/kdf.h"
                         "-ld-options" "-lssl -lcrypto"))
                 (linux
                  '("-ld-options" "-lssl -lcrypto"))
                 (else
                  (error "unsupported native TLS linker platform"))))
              (else
               (error "unsupported native build capability" capability))))
          native-capabilities)))

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

;; Gerbil 0.18.2 captures GERBIL_BUILD_CORES while compiler/base is imported.
;; A build script therefore has to enter a child process with the variable set;
;; setting it around std/make after module loading cannot change worker count.
(def (framework-build-reexec-required? arguments)
  (and (or (null? arguments)
           (and (pair? arguments)
                (string=? (car arguments) "compile")))
       (not (framework-positive-core-count
             (getenv "GERBIL_BUILD_CORES" #f)))))

(def (framework-reexec-build-script source-file arguments)
  (let ((absolute-source-file (path-expand source-file))
        (previous-cores (getenv "GERBIL_BUILD_CORES" #f))
        (selected (number->string (max 1 (##cpu-count)))))
    (dynamic-wind
      (lambda ()
        (unless (framework-positive-core-count previous-cores)
          (setenv "GERBIL_BUILD_CORES" selected)))
      (lambda ()
        (run-process/batch
         (append ["gxpkg" "env" "gxi" absolute-source-file] arguments)))
      (lambda ()
        (setenv "GERBIL_BUILD_CORES" (or previous-cores ""))))))

(def (call-with-framework-build-cores thunk)
  (let ((previous (getenv "GERBIL_BUILD_CORES" #f))
        (selected (number->string (framework-build-core-count))))
    (dynamic-wind
      (lambda () (setenv "GERBIL_BUILD_CORES" selected))
      thunk
      (lambda () (setenv "GERBIL_BUILD_CORES" (or previous ""))))))

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

(def (call-with-framework-build-lease thunk)
  (let* ((cache-root (framework-build-cache-root))
         (lease-path (path-expand ".asp-gerbil-scheme-build.lease" cache-root)))
    (create-directory* cache-root)
    (let (lease (open-output-file/lock lease-path op: LOCK_EX))
      (unwind-protect
        (call-with-framework-build-cores
         (lambda ()
           (framework-recover-object-locks!)
           (thunk)))
        (close-port lease)))))

(def (framework-build-main arguments build-spec keys source-file)
  (def (parse-options options)
    (let loop ((rest options) (parsed []))
      (match rest
        ([] parsed)
        (["--release" . rest]
         ;; Gerbil implements build-release: by forwarding -static to the
         ;; final native linker. Darwin has no static C runtime startup object
         ;; (crt0.o), so a release build there is optimized but dynamically
         ;; linked. Keep this policy in the Building Framework so every
         ;; executable target has the same platform-correct meaning.
         (cond-expand
          (darwin
           (loop rest (cons* build-optimized: #t parsed)))
          (else
           (loop rest (cons* build-release: #t parsed)))))
        (["--optimized" . rest]
         (loop rest (cons* build-optimized: #t parsed)))
        (["--debug" . rest]
         (loop rest (cons* debug: #t parsed)))
        (else
         (error "Unexpected " rest)))))
  (def source-directory
    (path-normalize (path-directory source-file)))
  (def (build options)
    (let (bindir (framework-build-bindir))
      (create-directory* bindir)
      (call-with-framework-build-lease
       (lambda ()
         (framework-invalidate-stale-executables!
          build-spec source-directory bindir)
         ;; std/make compiles sources under its absolute srcdir, then drains
         ;; Gambit native jobs in the caller cwd.  Gerbil 0.18.2's macOS
         ;; executable linker emits __exe.c relative to that cwd, so the
         ;; caller must be the declared bindir for generation and consumption
         ;; to share one path.
         (parameterize ((current-directory bindir))
           (apply make
                  build-spec
                  srcdir: source-directory
                  (append options keys))
           (framework-validate-runtime-closure! build-spec))))))
  (def (clean)
    (apply make-clean build-spec srcdir: source-directory keys))
  (match arguments
    (["meta"] (write '("spec" "compile" "clean")) (newline))
    (["spec"] (pretty-print build-spec))
    (["compile" . options] (build (parse-options options)))
    (["clean"] (clean))
    ([] (build []))))

(defsyntax (defbuild-script stx)
  (syntax-case stx ()
    ((macro build-spec keys ...)
     (with-syntax* ((@this-script (stx-identifier #'macro 'this-source-file))
                    (+this-source-file+ (syntax/loc stx (@this-script)))
                    (@main (stx-identifier #'macro 'main)))
       #'(def (@main . arguments)
           (let (source-file +this-source-file+)
             (if (framework-build-reexec-required? arguments)
               (framework-reexec-build-script source-file arguments)
               (parameterize
                ((current-directory
                  (path-normalize (path-directory source-file))))
                (framework-build-main
                 arguments build-spec [keys ...] source-file)))))))))

(def (framework-build-contract)
  '((schemaId . "asp-gerbil-scheme.build-script-contract")
    (schemaVersion . "1")
    (commandSurfaceOwner . "Building-Framework")
    (executor . "std/make")
    (dependencyGraphOwner . "std/make")
    (parallelismOwner . "GERBIL_BUILD_CORES")
    (defaultCoreSelection . "host-cpu-count")
    (compilerCoreCapture . "pre-import-child-process")
    (dependencyEnvironmentOwner . "gxpkg-env")
    (nativeLinkWorkingDirectory . "declared-bindir")
    (releaseLinkageOwner . "Building-Framework-platform-policy")
    (darwinReleaseLinkage . "optimized-dynamic")
    (buildGraphProjection . "declared-compiler-runtime-closure-to-std/make")
    (libraryBuildProjection . "post-executable-package-modules-to-std/make")
    (runtimeClosureDriftOracle . "gerbil-executable-stub")
    (executableFreshnessOwner . "declared-runtime-closure-to-std-make")
    (cacheConcurrencyOwner . "kernel-flock-per-GERBIL_PATH")
    (objectLockRecovery . "static-and-binary-under-exclusive-build-lease")
    (artifactRootEnvironment . "ASP_PROVIDER_ARTIFACT_ROOT")))
