;;; -*- Gerbil -*-
;;; Parser-owned package metadata facts.

(import :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/parser/support datum-list-items safe-cadr)
        (only-in :std/misc/list unique)
        (only-in :std/sugar filter-map))

(export read-project-package
        project-package-path
        project-package-name
        project-package-dependencies
        project-package-manager
        project-package-source-scope
        project-package-with-source-scope
        source-scope-roots
        source-scope-runtime-roots
        source-scope-exclude-directories
        source-scope-explanation
        read-package-forms
        package-form?
        package-dependencies)
;; Source scope is an executed Build API projection, never package metadata.
(defstruct source-scope (roots runtime-roots exclude-directories explanation))
(defstruct project-package (path name dependencies manager source-scope))

;;; The runtime build collector supplies this scope explicitly. No policy DSL
;;; or external configuration file is interpreted by the package reader.
;; : (-> ProjectPackage (List Path) (List Path) (List Path) String ProjectPackage)
(def (project-package-with-source-scope package roots runtime-roots exclude-directories explanation)
  (make-project-package
   (project-package-path package)
   (project-package-name package)
   (project-package-dependencies package)
   (project-package-manager package)
   (make-source-scope roots runtime-roots exclude-directories explanation)))
;;; Boundary:
;;; - read-project-package coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> String ParsedData )
(def (read-project-package root)
  (let (package-form (read-package-form root))
    (and package-form
         (make-project-package
          "gerbil.pkg"
          (datum->string (safe-cadr package-form))
          (package-dependencies package-form)
          "gxpkg"
          #f))))
;;; Boundary:
;;; - read-package-form composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> String ParsedData )
(def (read-package-form root)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((path (path-expand "gerbil.pkg" root))
            (forms (read-package-forms path)))
       (find package-form? forms)))))
;; read-package-forms
;;   : (-> Path (List Datum))
;;   | doc m%
;;       `read-package-forms path` reads every form from a package or build
;;       source file, preserving source order.
;;
;;       # Examples
;;
;;       ```scheme
;;       (read-package-forms "gerbil.pkg")
;;       ;; => package-forms
;;       ```
;;     %
(def (read-package-forms path)
  (call-with-input-file path
    (lambda (port)
      (let lp ((out '()))
        (let (next (read port))
          (if (eof-object? next)
            (reverse out)
            (lp (cons next out))))))))
;; : (-> Datum Boolean )
(def (package-form? datum)
  (and (pair? datum) (eq? (car datum) 'package:)))
;;; Boundary:
;;; - package-dependencies is a field lookup plus dependency string projection.
;;; - Reuse package-field-value so package metadata traversal has one owner.
;; : (-> Datum Integer )
(def (package-dependencies datum)
  (let (deps (package-field-value datum 'depend:))
    (if deps
      (unique (filter-map datum->string (datum-list-items deps)))
      '())))
;; package-field-value
;;   : (-> Datum Symbol (U #f Datum))
;;   | doc m%
;;       `package-field-value datum field` returns the datum immediately after a
;;       package field marker, or `#f` when the field is absent.
;;
;;       # Examples
;;
;;       ```scheme
;;       (package-field-value '(package: name "demo") 'name)
;;       ;; => "demo"
;;       ```
;;     %
(def (package-field-value datum field)
  (let (tail (member field (datum-list-items datum)))
    (and tail
         (pair? (cdr tail))
         (cadr tail))))
;; datum->string
;;   : (-> Obj (U #f String))
;;   | doc m%
;;       `datum->string obj` converts package datums into comparable string
;;       values, preserving `#f` for absent data.
;;
;;       # Examples
;;
;;       ```scheme
;;       (datum->string 'allow)
;;       ;; => "allow"
;;       ```
;;     %
(def (datum->string obj)
  (cond
   ((not obj) #f)
   ((string? obj) obj)
   ((symbol? obj) (symbol->string obj))
   (else (call-with-output-string "" (cut display obj <>)))))
