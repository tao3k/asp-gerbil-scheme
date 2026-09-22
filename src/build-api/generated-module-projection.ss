;;; -*- Gerbil -*-
;;; Lightweight PackageSpec projection for verified generated modules.
;;; Artifact hashing, persistence, and validation remain in generated-artifact;
;;; ordinary build scripts must not load that implementation when declarations
;;; are empty.

(import :gerbil/runtime/gambit
        (only-in "../object-family/syntax"
                 defpoo-object-family poo-family-ref)
        (only-in :std/list/list delete-duplicates/hash)
        (only-in :std/list/plist pgetq psetq)
        )

(export asp-gerbil-scheme-verified-generated-module-prototype
        asp-gerbil-scheme-verified-generated-module
        asp-gerbil-scheme-verified-generated-module-name
        asp-gerbil-scheme-verified-generated-module-extra-inputs
        asp-gerbil-scheme-project-generated-modules)

;; A package-level declaration projects only to std/make's native
;; extra-inputs: plist. It does not remove, split, or mark a target current.
(defpoo-object-family
  (prototype asp-gerbil-scheme-verified-generated-module-prototype
             (module #f)
             (extra-inputs []))
  (constructor
   (asp-gerbil-scheme-verified-generated-module
    module: (module-name #f)
    extra-inputs: (module-extra-inputs []))
   (module module-name)
   (extra-inputs module-extra-inputs))
  (accessors poo-family-ref
             (required
              (asp-gerbil-scheme-verified-generated-module-name module)
              (asp-gerbil-scheme-verified-generated-module-extra-inputs
               extra-inputs))
             (optional)))

;; generated-module-spec-module
;;   : (-> BuildSpec (Maybe Path))
(def (generated-module-spec-module spec)
  (match spec
    ((? string? module) module)
    ([gxc: module . _] (and (string? module) module))
    (else #f)))

;; : (-> BuildSpec (List Path) BuildSpec)
(def (generated-module-project-extra-inputs spec extra-inputs)
  (match spec
    ((? string? module)
     [gxc: module [extra-inputs: extra-inputs]])
    ([gxc: module [plist ...] . options]
     [gxc: module
           (psetq plist extra-inputs:
                  (delete-duplicates/hash
                   (append (pgetq extra-inputs: plist []) extra-inputs)
                   from-end?: #t))
           . options])
    ([gxc: module . options]
     [gxc: module [extra-inputs: extra-inputs] . options])
    (else
     (error "verified generated module must project to a gxc target" spec))))

;;; Declaration validation and duplicate detection share one index construction.
;; : (-> (List VerifiedGeneratedModule) HashTable)
(def (generated-module-declaration-index declarations)
  (let (index (make-hash-table))
    (for-each
     (lambda (declaration)
       (let ((module
              (asp-gerbil-scheme-verified-generated-module-name declaration))
             (extra-inputs
              (asp-gerbil-scheme-verified-generated-module-extra-inputs
               declaration)))
         (unless (and (string? module)
                      (> (string-length module) 0)
                      (list? extra-inputs)
                      (andmap string? extra-inputs)
                      (not (hash-key? index module)))
           (error "invalid or duplicate verified generated module declaration"
                  module))
         (hash-put! index module declaration)))
     declarations)
    index))

;; : (-> (List BuildSpec) (List VerifiedGeneratedModule) (List BuildSpec))
(def (asp-gerbil-scheme-project-generated-modules build-spec declarations)
  (unless (and (list? build-spec)
               (list? declarations))
    (error "generated module projection requires list contracts"
           build-spec declarations))
  (let* ((declarations-by-module
          (generated-module-declaration-index declarations))
         (target-counts (make-hash-table))
         (projected
          (map
           (lambda (spec)
             (let* ((module (generated-module-spec-module spec))
                    (declaration
                     (and module
                          (hash-get declarations-by-module module))))
               (if declaration
                 (begin
                   (hash-put! target-counts module
                              (+ 1 (or (hash-get target-counts module) 0)))
                   (generated-module-project-extra-inputs
                    spec
                    (asp-gerbil-scheme-verified-generated-module-extra-inputs
                     declaration)))
                 spec)))
           build-spec)))
    (for-each
     (lambda (declaration)
       (let (module
             (asp-gerbil-scheme-verified-generated-module-name declaration))
         (unless (= (or (hash-get target-counts module) 0) 1)
           (error "verified generated module must own exactly one native target"
                  module))))
     declarations)
    projected))
