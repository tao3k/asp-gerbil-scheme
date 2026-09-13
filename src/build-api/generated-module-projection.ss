;;; -*- Gerbil -*-
;;; Lightweight PackageSpec projection for verified generated modules.
;;; Artifact hashing, persistence, and validation remain in generated-artifact;
;;; ordinary build scripts must not load that implementation when declarations
;;; are empty.

(import :gerbil/gambit
        (only-in "../object-family/syntax"
                 defpoo-object-family poo-family-ref)
        (only-in :std/misc/plist pgetq psetq))

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

(def (generated-module-ordered-unique values)
  (reverse
   (foldl (lambda (value result)
            (if (member value result)
              result
              (cons value result)))
          []
          values)))

(def (generated-module-spec-module spec)
  (cond
   ((string? spec) spec)
   ((and (pair? spec)
         (eq? (car spec) gxc:)
         (pair? (cdr spec))
         (string? (cadr spec)))
    (cadr spec))
   (else #f)))

(def (generated-module-project-extra-inputs spec extra-inputs)
  (match spec
    ((? string? module)
     [gxc: module [extra-inputs: extra-inputs]])
    ([gxc: module [plist ...] . options]
     [gxc: module
           (psetq plist extra-inputs:
                  (generated-module-ordered-unique
                   (append (pgetq extra-inputs: plist []) extra-inputs)))
           . options])
    ([gxc: module . options]
     [gxc: module [extra-inputs: extra-inputs] . options])
    (else
     (error "verified generated module must project to a gxc target" spec))))

(def (generated-module-project declaration build-spec)
  (let* ((module
          (asp-gerbil-scheme-verified-generated-module-name declaration))
         (matches
          (filter (lambda (spec)
                    (equal? (generated-module-spec-module spec) module))
                  build-spec)))
    (unless (= (length matches) 1)
      (error "verified generated module must own exactly one native target"
             module))
    (map (lambda (spec)
           (if (equal? (generated-module-spec-module spec) module)
             (generated-module-project-extra-inputs
              spec
              (asp-gerbil-scheme-verified-generated-module-extra-inputs
               declaration))
             spec))
         build-spec)))

;; : (-> (List BuildSpec) (List VerifiedGeneratedModule) (List BuildSpec))
(def (asp-gerbil-scheme-project-generated-modules build-spec declarations)
  (unless (and (list? build-spec)
               (list? declarations))
    (error "generated module projection requires list contracts"
           build-spec declarations))
  (let (modules
        (map asp-gerbil-scheme-verified-generated-module-name declarations))
    (unless
     (and
      (andmap
       (lambda (declaration)
         (let ((module
                (asp-gerbil-scheme-verified-generated-module-name declaration))
               (extra-inputs
                (asp-gerbil-scheme-verified-generated-module-extra-inputs
                 declaration)))
           (and (string? module)
                (> (string-length module) 0)
                (list? extra-inputs)
                (andmap string? extra-inputs))))
       declarations)
      (= (length modules)
         (length (generated-module-ordered-unique modules))))
     (error "invalid or duplicate verified generated module declaration"
            modules)))
  (foldl generated-module-project build-spec declarations))
