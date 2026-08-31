;;; -*- Gerbil -*-
;;; Receipt helpers for native asp-gerbil-scheme launcher binaries.

(import (only-in :std/misc/path path-directory path-expand)
        (only-in :std/srfi/13 string-suffix?)
        (only-in "./package-receipt"
                 asp-gerbil-scheme-package-build-receipt-status
                 asp-gerbil-scheme-package-build-receipt-status-ref
                 asp-gerbil-scheme-package-build-receipt-write)
        :gerbil/gambit)
(export asp-gerbil-scheme-build-module-source-file
        asp-gerbil-scheme-build-module-output-file
        asp-gerbil-scheme-build-module-artifact-files
        asp-gerbil-scheme-build-module-artifact-file
        asp-gerbil-scheme-cli-launcher-build-current?
        asp-gerbil-scheme-cli-launcher-build-receipt-status
        asp-gerbil-scheme-ensure-cli-launcher-inputs!
        asp-gerbil-scheme-ensure-install-launcher-inputs!
        asp-gerbil-scheme-install-launcher-build-current?
        asp-gerbil-scheme-install-launcher-build-receipt-status
        asp-gerbil-scheme-write-cli-launcher-build-receipt!
        asp-gerbil-scheme-write-install-launcher-build-receipt!)

(def +cli-launcher-build-receipt-version+
  'asp-gerbil-scheme-cli-launcher-build.v1)

(def +cli-launcher-inputs-version+
  'asp-gerbil-scheme-cli-launcher-inputs.v1)

(def +install-launcher-build-receipt-version+
  'asp-gerbil-scheme-install-launcher-build.v1)

(def +install-launcher-inputs-version+
  'asp-gerbil-scheme-install-launcher-inputs.v1)

;; : (-> Path ModulePath Path)
(def (asp-gerbil-scheme-build-module-source-file source-root module)
  (path-expand module source-root))

;; : (-> ModulePath String)
(def (asp-gerbil-scheme-module-path-stem module)
  (if (string-suffix? ".ss" module)
    (substring module 0 (- (string-length module) 3))
    module))

;; : (-> Path ModulePath Path)
(def (asp-gerbil-scheme-build-module-output-file output-root module)
  (path-expand
   (string-append (asp-gerbil-scheme-module-path-stem module) ".scm")
   output-root))

;; : (-> Path ModulePath [Path])
(def (asp-gerbil-scheme-build-module-artifact-files output-root module)
  (let (scm-file (asp-gerbil-scheme-build-module-output-file output-root module))
    (let (stem (substring scm-file 0 (- (string-length scm-file) 4)))
      [(string-append stem ".ssi")
       (string-append stem "~0.scm")
       scm-file])))

;;; asp-gerbil-scheme-build-module-artifact-file
;; : (-> Path ModulePath Path)
;;; | doc m%
;;; Selects the first existing compiled artifact for a module while preserving
;;; the canonical output path as the deterministic fallback.
;;; # Examples
;;; ```scheme
;;; (asp-gerbil-scheme-build-module-artifact-file output-root "parser/core.ss")
;;; ;; => an existing artifact path or the canonical module output path
;;; ```
(def (asp-gerbil-scheme-build-module-artifact-file output-root module)
  (let loop ((candidates (asp-gerbil-scheme-build-module-artifact-files output-root module)))
    (cond
     ((null? candidates)
      (asp-gerbil-scheme-build-module-output-file output-root module))
     ((file-exists? (car candidates))
      (car candidates))
     (else
      (loop (cdr candidates))))))

;; : (-> Path Void)
(def (ensure-directory! path)
  (unless (file-exists? path)
    (let (parent (path-directory path))
      (when (and parent
                 (not (string=? parent ""))
                 (not (string=? parent path)))
        (ensure-directory! parent))
      (create-directory path))))

;; : (-> Path Datum Boolean)
(def (datum-file-current? path datum)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (and (file-exists? path)
          (equal? (call-with-input-file path read) datum)))))

;; : (-> Path Datum Void)
(def (write-datum-file-if-changed! path datum)
  (unless (datum-file-current? path datum)
    (ensure-directory! (path-directory path))
    (call-with-output-file path
      (lambda (port)
        (write datum port)
        (newline port)))))

;; : (-> Boolean String)
(def (cli-launcher-kind release?)
  (if release? "release" "dev"))

;; : (-> Path Boolean Path)
(def (cli-launcher-build-receipt-path package-root release?)
  (path-expand
   (string-append ".gerbil/build/cli-launcher-"
                  (cli-launcher-kind release?)
                  ".receipt")
   package-root))

;; : (-> Path Boolean Path)
(def (cli-launcher-inputs-path package-root release?)
  (path-expand
   (string-append ".gerbil/build/cli-launcher-"
                  (cli-launcher-kind release?)
                  ".inputs")
   package-root))

;; : (-> Path)
(def (install-launcher-build-receipt-path package-root)
  (path-expand ".gerbil/build/install-launcher.receipt" package-root))

;; : (-> Path)
(def (install-launcher-inputs-path package-root)
  (path-expand ".gerbil/build/install-launcher.inputs" package-root))

;; : (-> Boolean Boolean Boolean Boolean Datum Datum Datum)
(def (cli-launcher-inputs release?
                          build-optimize?
                          effective-release?
                          effective-optimized?
                          gsc-options-key
                          gsc-options)
  [+cli-launcher-inputs-version+
   release?
   build-optimize?
   effective-release?
   effective-optimized?
   gsc-options-key
   gsc-options])

;; : (-> Boolean Boolean Boolean Datum Datum Datum)
(def (install-launcher-inputs build-optimize?
                              effective-release?
                              effective-optimized?
                              gsc-options-key
                              gsc-options)
  [+install-launcher-inputs-version+
   build-optimize?
   effective-release?
   effective-optimized?
   gsc-options-key
   gsc-options])

;; : (-> Path Boolean Boolean Boolean Boolean Datum Datum Path)
(def (asp-gerbil-scheme-ensure-cli-launcher-inputs!
      package-root
      release?
      build-optimize?
      effective-release?
      effective-optimized?
      gsc-options-key
      gsc-options)
  (let ((path (cli-launcher-inputs-path package-root release?))
        (datum (cli-launcher-inputs
                release?
                build-optimize?
                effective-release?
                effective-optimized?
                gsc-options-key
                gsc-options)))
    (write-datum-file-if-changed! path datum)
    path))

;; : (-> Path Boolean Boolean Boolean Datum Datum Path)
(def (asp-gerbil-scheme-ensure-install-launcher-inputs!
      package-root
      build-optimize?
      effective-release?
      effective-optimized?
      gsc-options-key
      gsc-options)
  (let ((path (install-launcher-inputs-path package-root))
        (datum (install-launcher-inputs
                build-optimize?
                effective-release?
                effective-optimized?
                gsc-options-key
                gsc-options)))
    (write-datum-file-if-changed! path datum)
    path))

;; : (-> Path Path [ModulePath] [Path])
(def (launcher-build-source-files source-root inputs-path source-modules)
  (cons inputs-path
        (map (lambda (module)
               (asp-gerbil-scheme-build-module-source-file source-root module))
             source-modules)))

;; : (-> Path Path [ModulePath] [Path])
(def (launcher-build-output-files output-root binpath output-modules)
  (cons binpath
        (map (lambda (module)
               (asp-gerbil-scheme-build-module-artifact-file output-root module))
             output-modules)))

;; : (-> Path Path Path Path Path [ModulePath] [ModulePath] BuildReceiptStatus)
(def (asp-gerbil-scheme-install-launcher-build-receipt-status
      package-root
      source-root
      output-root
      binpath
      inputs-path
      output-modules
      source-modules)
  (asp-gerbil-scheme-package-build-receipt-status
   (install-launcher-build-receipt-path package-root)
   version: +install-launcher-build-receipt-version+
   expected-sources: (launcher-build-source-files
                      source-root inputs-path source-modules)
   expected-outputs: (launcher-build-output-files
                      output-root binpath output-modules)))

;; : (-> Path Path Path Path Path [ModulePath] [ModulePath] Void)
(def (asp-gerbil-scheme-write-install-launcher-build-receipt!
      package-root
      source-root
      output-root
      binpath
      inputs-path
      output-modules
      source-modules)
  (let (stamp (install-launcher-build-receipt-path package-root))
    (ensure-directory! (path-directory stamp))
    (asp-gerbil-scheme-package-build-receipt-write
     stamp
     (launcher-build-source-files source-root inputs-path source-modules)
     (launcher-build-output-files output-root binpath output-modules)
     version: +install-launcher-build-receipt-version+)))

;; : (-> Path Path Path Boolean Path Path [ModulePath] [ModulePath] BuildReceiptStatus)
(def (asp-gerbil-scheme-cli-launcher-build-receipt-status
      package-root
      source-root
      output-root
      release?
      binpath
      inputs-path
      output-modules
      source-modules)
  (asp-gerbil-scheme-package-build-receipt-status
   (cli-launcher-build-receipt-path package-root release?)
   version: +cli-launcher-build-receipt-version+
   expected-sources: (launcher-build-source-files
                      source-root inputs-path source-modules)
   expected-outputs: (launcher-build-output-files
                      output-root binpath output-modules)))

;; : (-> Path Path Path Boolean Path Path [ModulePath] [ModulePath] Void)
(def (asp-gerbil-scheme-write-cli-launcher-build-receipt!
      package-root
      source-root
      output-root
      release?
      binpath
      inputs-path
      output-modules
      source-modules)
  (let (stamp (cli-launcher-build-receipt-path package-root release?))
    (ensure-directory! (path-directory stamp))
    (asp-gerbil-scheme-package-build-receipt-write
     stamp
     (launcher-build-source-files source-root inputs-path source-modules)
     (launcher-build-output-files output-root binpath output-modules)
     version: +cli-launcher-build-receipt-version+)))

;; : (-> BuildReceiptStatus Boolean)
(def (asp-gerbil-scheme-cli-launcher-build-current? status)
  (eq? (asp-gerbil-scheme-package-build-receipt-status-ref status 'status 'unknown)
       'current))

;; : (-> BuildReceiptStatus Boolean)
(def (asp-gerbil-scheme-install-launcher-build-current? status)
  (eq? (asp-gerbil-scheme-package-build-receipt-status-ref status 'status 'unknown)
       'current))
