;;; -*- Gerbil -*-
;;; Package-local Gerbil environment support.

(import (only-in :std/misc/path path-expand path-normalize)
         (only-in :std/srfi/13 string-prefix?)
         (only-in :std/source gerbil-home)
        :gerbil/gambit)
(export asp-gerbil-scheme-package-configure-build-root!
         asp-gerbil-scheme-package-build-package-name
         asp-gerbil-scheme-package-build-active-gerbil-path
         asp-gerbil-scheme-package-build-active-gerbil-lib-path)

;; package-root
;;   : (Maybe Path)
;;   | doc m%
;;       Holds the configured package root for lock and artifact operations;
;;       callers set it only through the package-build configuration boundary.
;; # Examples
;; ```scheme
;; package-root
;; => #f before package-build configuration
;; ```
;;     %
(def package-root #f)

;; : (-> Path Path)
;; : (-> MaybeString Boolean)
(def (package-build-non-empty-string? value)
  (and (string? value)
       (> (string-length value) 0)))

;; : (-> Path (Maybe String))
;; asp-gerbil-scheme-package-build-package-name
;;   : (-> Path (Maybe String))
;;   | doc m%
;;       Reads the package name declared by the package-local `gerbil.pkg` file.
;;
;;       # Examples
;;       ```scheme
;;       (asp-gerbil-scheme-package-build-package-name ".")
;;       ;; => "asp-gerbil-scheme"
;;       ```
;;     %
(def (asp-gerbil-scheme-package-build-package-name root)
  (let* ((package-file (path-expand "gerbil.pkg" root))
         (plist (with-catch
                 (lambda (_) #f)
                 (lambda () (call-with-input-file package-file read)))))
    (let loop ((rest plist))
      (if (and (pair? rest) (pair? (cdr rest)))
        (if (eq? (car rest) 'package:)
          (let (name (cadr rest))
            (cond
             ((symbol? name) (symbol->string name))
             ((string? name) name)
             (else #f)))
          (loop (cdr rest)))
        #f))))

;; : (-> Path Path)
(def (asp-gerbil-scheme-package-build-active-gerbil-path root)
  (path-expand
   (let (path (getenv "GERBIL_PATH" #f))
     (if (package-build-non-empty-string? path)
       path
       (gerbil-home)))))

;; : (-> Path Path)
(def (asp-gerbil-scheme-package-build-active-gerbil-lib-path root)
  (path-expand "lib" (asp-gerbil-scheme-package-build-active-gerbil-path root)))

;; : (-> Path Void)
(def (asp-gerbil-scheme-package-configure-build-root! root)
  (let (active-gerbil-path (asp-gerbil-scheme-package-build-active-gerbil-path root))
    (set! package-root (path-normalize root))
    (current-directory package-root)
    (add-load-path! (path-expand "lib" active-gerbil-path))))

;; : (-> Void)
;; ensure-package-build-root!
;;   : (-> Unit)
;;   | doc m%
;;       Configures the package-local build root when no package context is active.
;;
;;       # Examples
;;       ```scheme
;;       (ensure-package-build-root!)
;;       => (void)
;;       ```
;;     %
(def (ensure-package-build-root!)
  (unless package-root
    (asp-gerbil-scheme-package-configure-build-root! (current-directory))))

;; : (-> Path MaybeString)
