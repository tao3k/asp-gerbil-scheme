;;; Package-spec declarations are the sole bridge from downstream build.ss
;;; syntax to POO-owned package objects and their source/native projections.
;;; Preserve native module ownership; tests and policy receive explicit inputs
;;; and never infer a second production graph from this projection.
(export asp-gerbil-scheme-package-spec!
        all-gerbil-modules
        default-exclude-dirs
        asp-gerbil-scheme-library-package-prototype
        asp-gerbil-scheme-package-native-spec
        asp-gerbil-scheme-package-generated-modules
        asp-gerbil-scheme-package-product-entry-modules
        asp-gerbil-scheme-package-native-prelude-spec
        asp-gerbil-scheme-package-native-profile
        asp-gerbil-scheme-package-native-capabilities
        asp-gerbil-scheme-package-pkg-config-libs
        asp-gerbil-scheme-package-nix-deps
        asp-gerbil-scheme-package-native-options-resolver
        asp-gerbil-scheme-package-public-entry-modules
        asp-gerbil-scheme-package-modules)

(import (only-in :clan/poo/object .cc .def .get)
        (only-in :gerbil/gambit
                 make-thread thread-start! thread-sleep! thread-terminate!
                 write-substring)
        (only-in "../object-family/syntax" defpoo-object-family poo-family-ref)
        (rename-in "./native-spec-support"
                   (all-gerbil-modules upstream-all-gerbil-modules)
                   (default-exclude-dirs upstream-default-exclude-dirs))
        (only-in "./native-spec-support"
                 all-gerbil-modules
                 default-exclude-dirs
                 remove-build-files
                 normalize-spec)
        (only-in "./generated-module-projection"
                 asp-gerbil-scheme-project-generated-modules)
        (only-in "./native-import-closure"
                 asp-gerbil-scheme-native-import-closure)
        (only-in "./core-capacity"
                 initialize-native-build-core-capacity!)
        (only-in "./native-profile"
                 asp-gerbil-scheme-default-native-profile
                 asp-gerbil-scheme-native-profile-projection-heartbeat-seconds
                 asp-gerbil-scheme-native-profile-executable-gsc-options
                 asp-gerbil-scheme-native-profile-prepare!))

;; asp-gerbil-scheme-package-spec!
;;   : (-> Syntax Syntax)
;;   | defaults modules to the local lightweight native source catalog
;;   | doc m%
;;       Declare a downstream Gerbil package without importing ASP product
;;       entrypoints.  The native-spec slot remains an ordinary std/make value.
;;
;;       # Examples
;;
;;       ```scheme
;;       (asp-gerbil-scheme-package-spec!
;;         (example-package @ asp-gerbil-scheme-library-package-prototype)
;;         (spec spec))
;;       (spec)
;;       ;; => std/make BuildSpec
;;       ```
;;     %
(defrules asp-gerbil-scheme-package-spec! ()
  ((_ (name @ prototype) (spec spec-name) slot ...)
   (begin
     (.def (name @ prototype)
       slot ...)
     (def (spec-name)
       (asp-gerbil-scheme-package-build-spec name)))))

;; : (-> PackageSpec (List NativeBuildItem))
(def (asp-gerbil-scheme-package-modules package-spec)
  (let (declared
        (asp-gerbil-scheme-package-declared-modules package-spec))
    (or (and (procedure? declared) (declared))
        declared
        (alet (entries
               (asp-gerbil-scheme-package-public-entry-modules package-spec))
          (and (pair? entries)
               (asp-gerbil-scheme-native-import-closure
                (current-directory) entries)))
      ;; Without declared public entries, gxpkg invokes build.ss in the package
      ;; directory and the native catalog reads that current directory. Tests
      ;; and generated build trees stay excluded.
        (upstream-all-gerbil-modules
         exclude-dirs:
         (asp-gerbil-scheme-package-exclude-dirs package-spec)))))

;; : (-> PackageSpec (List NativeBuildItem))
(def (asp-gerbil-scheme-package-default-native-spec package-spec)
  (append
   (asp-gerbil-scheme-package-native-prelude-spec package-spec)
   (remove-build-files
    (asp-gerbil-scheme-package-modules package-spec)
    (append
     (.get package-spec exclude-modules)
     (asp-gerbil-scheme-package-product-entry-modules package-spec)))
   (.get package-spec extra-spec)))

;; : (-> PackageSpec (List NativeBuildItem))
(def (asp-gerbil-scheme-package-native-spec package-spec)
  (let* ((native-profile
          (asp-gerbil-scheme-package-native-profile package-spec))
         (_prepared
          ((asp-gerbil-scheme-native-profile-prepare! native-profile)
           (asp-gerbil-scheme-package-pkg-config-libs package-spec)))
         (native-options-resolver
          (asp-gerbil-scheme-package-native-options-resolver package-spec))
        (native-options
         (if native-options-resolver
           (native-options-resolver)
           []))
        (projector (.get package-spec native-spec-projector))
        (native-spec (.get package-spec native-spec))
        (generated-modules
         (asp-gerbil-scheme-package-generated-modules package-spec)))
    (map (lambda (item)
           (match item
             ([(? (cut member <> '(exe: static-exe:))) . _]
              (normalize-spec
               item
               (append
                (asp-gerbil-scheme-native-profile-executable-gsc-options
                 native-profile)
                native-options)))
             ((or (? string?) [(? (cut member <> '(gxc: gsc:))) . _])
              (if (null? native-options) item
                (normalize-spec item native-options)))
             (else item)))
         (asp-gerbil-scheme-project-generated-modules
          (cond
           ((procedure? projector)
            (projector package-spec))
           (projector
            (error "Package Spec native-spec-projector must be a procedure"
                   projector))
           (native-spec
            native-spec)
           (else
            (asp-gerbil-scheme-package-default-native-spec package-spec)))
         generated-modules))))

(def (native-build-observability-enabled?)
  (cond
   ((getenv "GERBIL_BUILD_VERBOSE" #f)
    => (lambda (value)
         (let (level (string->number value))
           (and (real? level) (> level 0)))))
   (else #f)))

(def (native-build-elapsed-milliseconds started-jiffy)
  (quotient (* (- (current-jiffy) started-jiffy) 1000)
            (jiffies-per-second)))

(def (write-native-build-observation! phase started-jiffy . fields)
  (let* ((port (current-output-port))
         (record
          (call-with-output-string
           (lambda (buffer)
             (display "[asp-build] phase=" buffer)
             (display phase buffer)
             (for-each
              (lambda (field) (display " " buffer) (display field buffer))
              fields)
             (display " elapsedMs=" buffer)
             (display (native-build-elapsed-milliseconds started-jiffy)
                      buffer)
             (newline buffer)))))
    (write-substring record 0 (string-length record) port)
    (force-output port)))

;; Keep the native PackageSpec projection observable without changing its
;; ownership or caching its result.  The heartbeat interval is declared by the
;; PackageSpec's native POO profile; std/make retains planning and execution.
(def (call-with-native-build-projection-observation package-spec thunk)
  (if (not (native-build-observability-enabled?))
    (thunk)
    (let* ((started-jiffy (current-jiffy))
           (profile (asp-gerbil-scheme-package-native-profile package-spec))
           (interval
            (asp-gerbil-scheme-native-profile-projection-heartbeat-seconds
             profile))
           (port (current-output-port))
           (heartbeat #f))
      (unless (and (real? interval) (> interval 0))
        (error "native profile projection heartbeat must be positive" interval))
      (write-native-build-observation!
       'spec-project-start started-jiffy
       "owner=asp-build-api/native-import-closure"
       "executor=std/make")
      (dynamic-wind
        (lambda ()
          (set! heartbeat
                (make-thread
                 (lambda ()
                   (let loop ()
                     (thread-sleep! interval)
                     (parameterize ((current-output-port port))
                       (write-native-build-observation!
                        'spec-project-active started-jiffy
                        "owner=asp-build-api/native-import-closure"
                        "executor=std/make"))
                     (loop)))))
          (thread-start! heartbeat))
        (lambda ()
          (let (result (thunk))
            (write-native-build-observation!
             'spec-project-complete started-jiffy
             (string-append "targetCount="
                            (number->string (length result)))
             "owner=asp-build-api/native-import-closure"
             "executor=std/make")
            result))
        (lambda ()
          (when heartbeat
            (thread-terminate! heartbeat)))))))

;; The macro-generated spec procedure is the direct std/make boundary. A
;; PackageSpec remains the POO owner;
;; spec-projector selects its native or policy-admitted projection.
;; : (-> PackageSpec (List NativeBuildItem))
(def (asp-gerbil-scheme-package-build-spec package-spec)
  (initialize-native-build-core-capacity!)
  (let (projector (.get package-spec spec-projector))
    (unless (procedure? projector)
      (error "Package Spec spec-projector must be a procedure" projector))
    ;; GERBIL_BUILD_VERBOSE activates a native PackageSpec projection receipt;
    ;; std/make still owns planning, currentness, compilation, and its output.
    (call-with-native-build-projection-observation
     package-spec (lambda () (projector package-spec)))))

;; Import-safe semantic base for concrete project library and provider specs.
;; Script entrypoints remain in top-level build.ss files; this module owns only
;; reusable POO values and projections.
(defpoo-object-family
  (prototype asp-gerbil-scheme-library-package-prototype
             (role 'library)
             (modules #f)
             (public-entry-modules [])
             (exclude-dirs upstream-default-exclude-dirs)
             (exclude-modules [])
             (native-prelude-spec [])
             (extra-spec [])
             (product-entry-modules [])
             (generated-modules [])
             (native-profile asp-gerbil-scheme-default-native-profile)
             (native-capabilities [])
             (pkg-config-libs #f)
             (nix-deps #f)
             (native-options-resolver #f)
             (spec-projector asp-gerbil-scheme-package-native-spec)
             (native-spec-projector #f)
             (native-spec #f))
  (accessors poo-family-ref
             (required
              (asp-gerbil-scheme-package-declared-modules modules)
              (asp-gerbil-scheme-package-public-entry-modules
               public-entry-modules)
              (asp-gerbil-scheme-package-exclude-dirs exclude-dirs)
              (asp-gerbil-scheme-package-product-entry-modules
               product-entry-modules)
              (asp-gerbil-scheme-package-native-prelude-spec
               native-prelude-spec)
              (asp-gerbil-scheme-package-generated-modules generated-modules)
              (asp-gerbil-scheme-package-native-profile native-profile)
              (asp-gerbil-scheme-package-native-capabilities
               native-capabilities)
              (asp-gerbil-scheme-package-pkg-config-libs pkg-config-libs)
              (asp-gerbil-scheme-package-nix-deps nix-deps)
              (asp-gerbil-scheme-package-native-options-resolver
               native-options-resolver))
             (optional)))
