;;; Package-spec declarations are the sole bridge from downstream build.ss
;;; syntax to POO-owned package objects and their source/native projections.
;;; Preserve caller roots and module ownership; policy may observe the catalog
;;; but must never make tests into production compilation units.
(export asp-gerbil-scheme-package-spec!
        asp-gerbil-scheme-library-package-prototype
        asp-gerbil-scheme-package-native-spec
        asp-gerbil-scheme-package-builder-profile
        asp-gerbil-scheme-package-build-profile
        asp-gerbil-scheme-package-generated-modules
        asp-gerbil-scheme-package-modules
        asp-gerbil-scheme-package-source-roots
        asp-gerbil-scheme-package-exclude-directories
        asp-gerbil-scheme-package-exclude-modules)

(import (only-in :clan/poo/object .cc .def .get)
        (only-in "../object-family/syntax" defpoo-object-family poo-family-ref)
        (only-in "./builder-profile"
                 asp-gerbil-scheme-development-builder-profile
                 asp-gerbil-scheme-builder-profile-apply-build-environment!
                 asp-gerbil-scheme-builder-profile-exclude-directories
                 asp-gerbil-scheme-builder-profile-module-under-root?
                 asp-gerbil-scheme-builder-profile-modules/config
                 asp-gerbil-scheme-builder-profile-native-profile
                 asp-gerbil-scheme-builder-profile-test-roots)
        (only-in "./source-discovery"
                 +default-excluded-module-files+)
        (only-in "./source-coverage"
                 asp-gerbil-scheme-source-coverage)
        (only-in "./generated-artifact"
                 asp-gerbil-scheme-project-generated-modules)
        (only-in "../building/build-script"
                 framework-apply-build-core-policy!)
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/srfi/13 string-suffix?))

;; asp-gerbil-scheme-package-spec!
;;   : (-> Syntax Syntax)
;;   | defaults roots to the standard Gerbil project root
;;   | rationale keeps policy admission and std/make on projections of one owner value
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
;;         (spec spec)
;;         (profile asp-gerbil-scheme-development-builder-profile))
;;       (spec)
;;       ;; => std/make BuildSpec
;;       ```
;;     %
(defsyntax (asp-gerbil-scheme-package-spec! stx)
  (syntax-case stx (spec)
  ((macro (name @ prototype) (spec spec-name) slot ...)
   (with-syntax
    ((+this-source-file+
      (datum->syntax
       #'macro
       (path-normalize
        (path-expand (source-location-path (stx-source stx)))))))
     #'(begin
        (.def (name @ prototype)
          slot ...)
        (set! name
              (asp-gerbil-scheme-resolve-package-modules
               name +this-source-file+))
        (asp-gerbil-scheme-apply-package-source-coverage!
         name +this-source-file+)
        (def (spec-name)
          (asp-gerbil-scheme-builder-profile-apply-build-environment!
           (asp-gerbil-scheme-package-builder-profile name))
          (framework-apply-build-core-policy!)
          (asp-gerbil-scheme-package-build-spec name)))))))

;; : (-> PackageSpec Path PackageSpec)
(def (asp-gerbil-scheme-resolve-package-modules package-spec source-file)
  (if (.get package-spec modules)
    package-spec
    (let* ((root (path-directory source-file))
           (profile (asp-gerbil-scheme-package-builder-profile package-spec))
           (modules
            (asp-gerbil-scheme-builder-profile-modules/config
             profile
             root
             (asp-gerbil-scheme-package-source-roots package-spec)
             +default-excluded-module-files+
             (asp-gerbil-scheme-package-exclude-directories package-spec)))
           (excluded
            (map asp-gerbil-scheme-module-source-stem
                 (asp-gerbil-scheme-package-exclude-modules package-spec))))
      (.cc package-spec 'modules
           (filter
            (lambda (module)
              (not (member (asp-gerbil-scheme-module-source-stem module)
                           excluded)))
            modules)))))

;; Discovery returns source paths while std/make declarations conventionally
;; use module stems.  Normalize once at the ownership boundary.
;; : (-> ModulePath ModulePath)
(def (asp-gerbil-scheme-module-source-stem module)
  (if (string-suffix? ".ss" module)
    (substring module 0 (- (string-length module) 3))
    module))

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
       (let (test-roots
             (asp-gerbil-scheme-builder-profile-test-roots
              (asp-gerbil-scheme-package-builder-profile package-spec)))
         (filter
          (lambda (module)
            (not
             (ormap
              (lambda (root)
                (asp-gerbil-scheme-builder-profile-module-under-root?
                 module root))
              test-roots)))
          (asp-gerbil-scheme-package-modules package-spec)))))
     generated-modules)))

;; The macro-generated spec procedure is the direct std/make boundary used by
;; clan/building. A PackageSpec remains the POO owner;
;; spec-projector selects its native or policy-admitted projection.
(def (asp-gerbil-scheme-package-build-spec package-spec)
  (let (projector (.get package-spec spec-projector))
    (unless (procedure? projector)
      (error "Package Spec spec-projector must be a procedure" projector))
    (projector package-spec)))

(def (asp-gerbil-scheme-package-build-profile package-spec)
  (asp-gerbil-scheme-builder-profile-native-profile
   (asp-gerbil-scheme-package-builder-profile package-spec)))

(def (asp-gerbil-scheme-package-exclude-directories package-spec)
  (or (.get package-spec exclude-directories)
      (asp-gerbil-scheme-builder-profile-exclude-directories
       (asp-gerbil-scheme-package-builder-profile package-spec))))

;; The macro calls this once while loading build.ss.  Keeping the projection
;; behind a named function leaves the public syntax purely declarative.
(def (asp-gerbil-scheme-apply-package-source-coverage! package-spec source-file)
  (when (.get package-spec source-catalog-authority)
    (asp-gerbil-scheme-source-coverage
     roots: (asp-gerbil-scheme-package-source-roots package-spec)
     exclude-directories:
     (asp-gerbil-scheme-package-exclude-directories package-spec)
     files: (asp-gerbil-scheme-package-modules package-spec)
     owner-root: (path-directory source-file))))

;; Import-safe semantic base for concrete project library and provider specs.
;; Script entrypoints remain in top-level build.ss files; this module owns only
;; reusable POO values and projections.
(defpoo-object-family
  (prototype asp-gerbil-scheme-library-package-prototype
             (role 'library)
             (profile asp-gerbil-scheme-development-builder-profile)
             (source-catalog-authority 'project)
             (modules #f)
             (roots ["."])
             (exclude-directories #f)
             (exclude-modules [])
             (generated-modules [])
             (spec-projector asp-gerbil-scheme-package-native-spec)
             (native-spec-projector #f)
             (native-spec #f))
  (accessors poo-family-ref
             (required
              (asp-gerbil-scheme-package-builder-profile profile)
              (asp-gerbil-scheme-package-modules modules)
              (asp-gerbil-scheme-package-source-roots roots)
              (asp-gerbil-scheme-package-generated-modules generated-modules)
              (asp-gerbil-scheme-package-exclude-modules exclude-modules))
             (optional)))
