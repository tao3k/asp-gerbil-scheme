;;; Package-spec declarations are the sole bridge from downstream build.ss
;;; syntax to POO-owned package objects and their source/native projections.
;;; Preserve native module ownership; policy may observe the catalog but must
;;; never make tests into production compilation units.
(export asp-gerbil-scheme-package-spec!
        asp-gerbil-scheme-library-package-prototype
        asp-gerbil-scheme-package-native-spec
        asp-gerbil-scheme-package-generated-modules
        asp-gerbil-scheme-package-product-entry-modules
        asp-gerbil-scheme-package-modules)

(import (only-in :clan/poo/object .cc .def .get)
        (only-in "../object-family/syntax" defpoo-object-family poo-family-ref)
        (rename-in :clan/building
                   (all-gerbil-modules upstream-all-gerbil-modules)
                   (default-exclude-dirs upstream-default-exclude-dirs))
        (only-in :clan/building remove-build-file)
        (only-in "./generated-artifact"
                 asp-gerbil-scheme-project-generated-modules)
        (only-in "./core-capacity"
                 initialize-native-build-core-capacity!)
        (only-in :std/srfi/1 fold)
        (only-in :std/srfi/13 string-prefix?))

;; asp-gerbil-scheme-package-spec!
;;   : (-> Syntax Syntax)
;;   | defaults modules to clan/building's native package catalog
;;   | doc m%
;;       Declare a downstream Gerbil package without importing ASP product
;;       entrypoints.  The native-spec slot remains an ordinary std/make value;
;;       source coverage is a second projection of the same POO object.
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

;; : (-> NativeBuildItem Boolean)
(def (native-library-module? item)
  (let (path
        (match item
          ((? string?) item)
          ([gxc: (? string?) . _] (cadr item))
          (else #f)))
    (and path
         (or (string-prefix? "src/" path)
             (member path '("build-api.ss" "version.ss"))))))

;; : (-> PackageSpec (List NativeBuildItem))
(def (asp-gerbil-scheme-package-modules package-spec)
  (let (declared
        (asp-gerbil-scheme-package-declared-modules package-spec))
    (or (and (procedure? declared) (declared))
        declared
      ;; Exactly match clan/building: gxpkg invokes build.ss in the package
      ;; directory, and the native catalog reads that current directory. The
      ;; library projection is internally bounded to public top-level modules
      ;; and src/; tests and generated build trees are never user options.
        (filter native-library-module?
                (upstream-all-gerbil-modules
                 exclude-dirs:
                 (asp-gerbil-scheme-package-exclude-dirs package-spec))))))

;; : (-> PackageSpec (List NativeBuildItem))
(def (asp-gerbil-scheme-package-default-native-spec package-spec)
  (fold (lambda (module current)
          (remove-build-file current module))
        (asp-gerbil-scheme-package-modules package-spec)
        (asp-gerbil-scheme-package-product-entry-modules package-spec)))

(def (asp-gerbil-scheme-package-native-spec package-spec)
  (let ((projector (.get package-spec native-spec-projector))
        (native-spec (.get package-spec native-spec))
        (generated-modules
         (asp-gerbil-scheme-package-generated-modules package-spec)))
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
     generated-modules)))

;; The macro-generated spec procedure is the direct std/make boundary used by
;; clan/building. A PackageSpec remains the POO owner;
;; spec-projector selects its native or policy-admitted projection.
(def (asp-gerbil-scheme-package-build-spec package-spec)
  (initialize-native-build-core-capacity!)
  (let (projector (.get package-spec spec-projector))
    (unless (procedure? projector)
      (error "Package Spec spec-projector must be a procedure" projector))
    (projector package-spec)))

;; Import-safe semantic base for concrete project library and provider specs.
;; Script entrypoints remain in top-level build.ss files; this module owns only
;; reusable POO values and projections.
(defpoo-object-family
  (prototype asp-gerbil-scheme-library-package-prototype
             (role 'library)
             (modules #f)
             (exclude-dirs upstream-default-exclude-dirs)
             (product-entry-modules [])
             (generated-modules [])
             (spec-projector asp-gerbil-scheme-package-native-spec)
             (native-spec-projector #f)
             (native-spec #f))
  (accessors poo-family-ref
             (required
              (asp-gerbil-scheme-package-declared-modules modules)
              (asp-gerbil-scheme-package-exclude-dirs exclude-dirs)
              (asp-gerbil-scheme-package-product-entry-modules
               product-entry-modules)
              (asp-gerbil-scheme-package-generated-modules generated-modules))
             (optional)))
