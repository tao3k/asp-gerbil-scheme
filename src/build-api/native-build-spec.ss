;;; -*- Gerbil -*-
;;; Pure root and target-spec projections for the native build owner.
;;; This module does not acquire leases, inspect receipts, or execute std/make.

(import (only-in :std/misc/path path-expand path-normalize)
        (only-in :std/srfi/13 string-prefix?)
        (only-in "./package-build"
                 asp-gerbil-scheme-package-configure-build-root!
                 asp-gerbil-scheme-package-build-active-gerbil-path
                 asp-gerbil-scheme-package-build-package-name)
        (only-in "./cli-gsc-options"
                 asp-gerbil-scheme-cli-gsc-options)
        (only-in "./source-coverage"
                 asp-gerbil-scheme-source-coverage-files
                 asp-gerbil-scheme-source-coverage-roots
                 asp-gerbil-scheme-source-coverage-exclude-directories)
        (only-in "./source-closure"
                 asp-gerbil-scheme-source-dependency-order)
        (only-in "./build-path-contract" configure-build-path-root!)
        (only-in "./package-native-plan"
                 asp-gerbil-scheme-package-api-spec)
        (only-in "./release-modules" cli-release-modules))

(export package-root
        source-root
        configure-build-root!
        ensure-build-root!
        source-output-prefix
        test-output-prefix
        package-api-output-root
        package-build-spec
        cli-binary-module-spec
        cli-binary-exe-spec
        cli-install-module-spec
        cli-install-spec
        provider-server-workspace-install-spec
        workspace-runtime-library-spec
        install-launcher-source-modules
        cli-launcher-source-modules
        compile-spec
        cli-binary-build-spec)

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
  (configure-build-path-root! package-root)
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
  '("cli.ss"
    "cli-dev-linker.ss"
    "cli-install-linker.ss"
    "cli-launcher.ss"
    "cli-release-linker.ss"))

;; : (List ModulePath)
(def cli-bootstrap-modules
  '("constants.ss"
    "support/time.ss"))

;; : (List String)
(def +library-excluded-dirs+
  '("testing"))

;; : (List String)
(def +default-excluded-dirs+
  '("run" "t" ".git" "_darcs" ".gerbil"))

;; : (-> Boolean String (List BuildSpec))
(def (cli-exe-spec optimized? root)
  [(append (if optimized?
             [optimized-exe: root bin: "asp-gerbil-scheme"]
             [exe: root bin: "asp-gerbil-scheme"])
           (asp-gerbil-scheme-cli-gsc-options package-root))])

;; : (-> Boolean (List BuildSpec))
(def (cli-dev-spec optimized?)
  (cli-exe-spec optimized? "cli-dev-linker"))

;; : (-> Boolean (List BuildSpec))
(def (cli-release-spec optimized?)
  (cli-exe-spec optimized? "cli-release-linker"))

;; : (-> Boolean (List BuildSpec))
(def (cli-install-spec optimized?)
  (cli-exe-spec optimized? "cli-release-linker"))

;; : (-> (List BuildSpec))
(def (provider-server-workspace-install-spec)
  [(append [exe: "provider-server" bin: "asp-gerbil-scheme"]
           (asp-gerbil-scheme-cli-gsc-options package-root))])

;; : (-> (List ModulePath))
(def (cli-install-module-spec)
  (cli-launcher-source-modules #t))

;; : (-> Boolean (List ModulePath))
(def (cli-binary-module-spec release?)
  (if release? cli-release-modules cli-bootstrap-modules))

;; : (-> Boolean (List BuildSpec))
(def (cli-binary-exe-spec release? optimized?)
  (if release?
    (cli-release-spec optimized?)
    (cli-dev-spec optimized?)))

;; : (-> Boolean (List BuildSpec))
(def (cli-binary-spec release? optimized?)
  (append (cli-binary-module-spec release?)
          (cli-binary-exe-spec release? optimized?)))

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

(def (runtime-library-source-files)
  (filter (lambda (path)
            (let (module (source-runtime-module-path path))
              (and module (runtime-library-module? module))))
          (asp-gerbil-scheme-source-coverage-files package-root)))

(def (workspace-runtime-library-spec)
  (let* ((ordered-source-files
          (asp-gerbil-scheme-source-dependency-order
           package-root
           (runtime-library-source-files)))
         (ordered-runtime-spec
          (map source-runtime-module-path ordered-source-files)))
    ;; The workspace installer generates this module; source coverage does not.
    (if (member "cli-launcher.ss" ordered-runtime-spec)
      ordered-runtime-spec
      (cons "cli-launcher.ss" ordered-runtime-spec))))

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

;; : (-> (List ModulePath))
(def (install-launcher-source-modules)
  (cli-launcher-source-modules #t))

;; : (-> Boolean (List ModulePath))
(def (cli-launcher-source-modules release?)
  (append (cli-binary-module-spec release?)
          (list (if release?
                  "cli-release-linker.ss"
                  "cli-dev-linker.ss"))))

;; : (-> Boolean Boolean Boolean (List BuildSpec))
(def (compile-spec full? release? binary?)
  (ensure-build-root!)
  (cond
   (full? (library-spec))
   (release? (cli-binary-spec #t #t))
   (binary? (cli-binary-spec #f #f))
   (else (asp-gerbil-scheme-package-api-spec))))

;; : (-> Boolean (List BuildSpec))
(def (cli-binary-build-spec release?)
  (cli-binary-spec release? #t))
