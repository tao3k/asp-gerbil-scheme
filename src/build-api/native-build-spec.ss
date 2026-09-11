;;; -*- Gerbil -*-
;;; Pure root and target-spec projections for the native build owner.
;;; This module does not acquire leases, inspect receipts, or execute std/make.

(import (only-in :std/misc/path path-expand path-normalize)
        (only-in :std/srfi/13 string-prefix?)
        (only-in "./package-build"
                 asp-gerbil-scheme-package-configure-build-root!
                 asp-gerbil-scheme-package-build-active-gerbil-path
                 asp-gerbil-scheme-package-build-package-name)
        (only-in "./source-coverage"
                 asp-gerbil-scheme-source-coverage-files
                 asp-gerbil-scheme-source-coverage-roots
                 asp-gerbil-scheme-source-coverage-exclude-directories)
        (only-in "./package-native-plan"
                 asp-gerbil-scheme-package-api-spec))

(export package-root
        source-root
        configure-build-root!
        ensure-build-root!
        source-output-prefix
        test-output-prefix
        package-api-output-root
        package-build-spec
        library-spec
        compile-spec)

;; : (Maybe Path)
(def package-root #f)

;; : (Maybe Path)
(def source-root #f)

;; : (Maybe Datum)
(def current-package-gerbil-modules-key #f)

;; : (Maybe (List ModulePath))
(def current-package-gerbil-modules #f)

;; : (Maybe String)
(def package-name #f)

;; : (-> String Void)
(def (configure-build-root! root)
  (set! package-root (path-normalize root))
  (asp-gerbil-scheme-package-configure-build-root! package-root)
  (set! source-root (path-expand "src" package-root))
  (set! current-package-gerbil-modules-key #f)
  (set! current-package-gerbil-modules #f)
  (set! package-name
        (asp-gerbil-scheme-package-build-package-name package-root)))

;; : (-> Void)
(def (ensure-build-root!)
  (unless package-root
    (configure-build-root! (current-directory))))

;; : (-> String String)
(def (package-output-prefix root-name)
  (ensure-build-root!)
  (unless package-name
    (error "gerbil.pkg must declare package: for build output prefix"))
  (string-append package-name "/" root-name))

;; : (-> String)
(def (source-output-prefix)
  (package-output-prefix "src"))

;; : (-> String)
(def (test-output-prefix)
  (package-output-prefix "t"))

;; : (List ModulePath)
(def excluded-library-files
  '("provider-server.ss"
    "commands/provider-runtime.ss"))

;; : (List String)
(def +library-excluded-dirs+
  '("testing"))

;; : (List String)
(def +default-excluded-dirs+
  '("run" "t" ".git" "_darcs" ".gerbil"))

;; : (-> ModulePath Boolean)
(def (runtime-library-module? module)
  (and (not (member module excluded-library-files))
       (not (library-excluded-dir-module? module))))

;; : (-> ModulePath Boolean)
(def (library-excluded-dir-module? module)
  (let loop ((dirs +library-excluded-dirs+))
    (and (pair? dirs)
         (or (string-prefix? (string-append (car dirs) "/") module)
             (loop (cdr dirs))))))

;; : (-> (List BuildSpec))
(def (library-spec)
  (filter runtime-library-module? (all-package-gerbil-modules)))

;; : (-> [Path (List Path) (List String)])
(def (package-gerbil-modules-cache-key)
  (list package-root
        (asp-gerbil-scheme-source-coverage-roots)
        (coverage-excluded-directories)))

;; : (-> (List ModulePath))
(def (all-package-gerbil-modules)
  (let (key (package-gerbil-modules-cache-key))
    (if (and current-package-gerbil-modules-key
             (equal? current-package-gerbil-modules-key key))
      current-package-gerbil-modules
      (let (modules (source-runtime-modules))
        (set! current-package-gerbil-modules-key key)
        (set! current-package-gerbil-modules modules)
        modules))))

;; : (-> Path (Maybe ModulePath))
(def (source-runtime-module-path path)
  (let (prefix "src/")
    (and (string-prefix? prefix path)
         (substring path (string-length prefix) (string-length path)))))

;; : (-> (List ModulePath))
(def (source-runtime-modules)
  (filter (lambda (module) module)
          (map source-runtime-module-path
               (asp-gerbil-scheme-source-coverage-files package-root))))

;; : (-> (List String))
(def (coverage-excluded-directories)
  (append +default-excluded-dirs+
          +library-excluded-dirs+
          (asp-gerbil-scheme-source-coverage-exclude-directories)))

;; : (-> (List BuildSpec))
(def (package-build-spec)
  (ensure-build-root!)
  (asp-gerbil-scheme-package-api-spec))

;; : (-> PackageLibOutputRoot)
(def (package-api-output-root)
  (path-expand (source-output-prefix)
               (path-expand "lib"
                            (asp-gerbil-scheme-package-build-active-gerbil-path
                             package-root))))

;; : (-> Boolean (List BuildSpec))
(def (compile-spec full?)
  (ensure-build-root!)
  (if full?
    (library-spec)
    (asp-gerbil-scheme-package-api-spec)))
