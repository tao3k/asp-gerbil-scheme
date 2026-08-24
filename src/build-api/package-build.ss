;;; -*- Gerbil -*-
;;; Package-local Gerbil environment support.

(import (only-in :std/misc/path path-expand path-normalize)
         (only-in :std/srfi/13 string-prefix?)
         (only-in :gerbil/tools/env setup-local-pkg-env!)
        :gerbil/gambit)
(export gslph-package-configure-build-root!
         gslph-package-build-package-name
         gslph-package-build-active-gerbil-path
         gslph-package-build-active-gerbil-lib-path)

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
(def (package-local-gerbil-path root)
  (path-expand ".gerbil" root))

;; : (-> MaybeString Boolean)
(def (package-build-non-empty-string? value)
  (and (string? value)
       (> (string-length value) 0)))

;; : (-> Path (Maybe String))
;; gslph-package-build-package-name
;;   : (-> Path (Maybe String))
;;   | doc m%
;;       Reads the package name declared by the package-local `gerbil.pkg` file.
;;
;;       # Examples
;;       ```scheme
;;       (gslph-package-build-package-name ".")
;;       ;; => "gslph"
;;       ```
;;     %
(def (gslph-package-build-package-name root)
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
(def (gslph-package-build-active-gerbil-path root)
  (path-expand
   (let (path (getenv "GERBIL_PATH" #f))
     (if (package-build-non-empty-string? path)
       path
       (package-local-gerbil-path root)))))

;; : (-> Path Path)
(def (gslph-package-build-active-gerbil-lib-path root)
  (path-expand "lib" (gslph-package-build-active-gerbil-path root)))

;; : (-> Path Void)
(def (gslph-package-configure-build-root! root)
  (let (active-gerbil-path (gslph-package-build-active-gerbil-path root))
    (set! package-root (path-normalize root))
    (current-directory package-root)
     (setup-local-pkg-env! #t)
     (setenv "GERBIL_PATH" active-gerbil-path)
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
    (gslph-package-configure-build-root! (current-directory))))

;; : (-> Path MaybeString)
