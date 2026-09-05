;;; -*- Gerbil -*-
;;; Shared gxtest build-root context and module path helpers.

(import (only-in :std/misc/path path-expand path-normalize)
         (only-in :std/srfi/13 string-prefix? string-suffix?)
         (only-in "../build-api/package-build"
                  asp-gerbil-scheme-package-configure-build-root!
                  asp-gerbil-scheme-package-build-package-name)
         :gerbil/gambit)

(export package-root
        source-root
        test-root
        package-name
        configure-build-root!
        ensure-build-root!
        read-build-package-name
        package-output-prefix
        source-output-prefix
        test-output-prefix
        module-path-stem
        gxtest-test-module-path
        gxtest-source-module-path
        gxtest-file-module-symbol
        gxtest-normalize-module-path)

(def package-root (current-directory))
(def source-root (path-expand "src" package-root))
(def test-root (path-expand "t" package-root))
(def package-name #f)

;; : (-> String Void)
(def (configure-build-root! root)
  (set! package-root (path-normalize root))
  (asp-gerbil-scheme-package-configure-build-root! package-root)
  (set! source-root (path-expand "src" package-root))
  (set! test-root (path-expand "t" package-root))
  (set! package-name (read-build-package-name package-root)))

;; : (-> Void)
(def (ensure-build-root!)
  (unless (and package-root package-name)
    (configure-build-root! (current-directory))))

;; : (-> Path MaybeString)
(def (read-build-package-name root)
  (asp-gerbil-scheme-package-build-package-name root))

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

;; : (-> String)
(def (module-path-stem module)
  (if (string-suffix? ".ss" module)
    (substring module 0 (- (string-length module) 3))
    module))

;; : (-> Path ModulePath)
(def (gxtest-test-module-path path)
  (if (string-prefix? "t/" path)
    (substring path 2 (string-length path))
    path))

;; : (-> Path ModulePath)
(def (gxtest-source-module-path path)
  (if (string-prefix? "src/" path)
    (substring path 4 (string-length path))
    path))

;; : (-> Path Path)
(def (gxtest-trim-leading-dot-slash path)
  (if (string-prefix? "./" path)
    (substring path 2 (string-length path))
    path))

;; : (-> Path Symbol)
(def (gxtest-file-module-symbol file)
  (ensure-build-root!)
  (string->symbol
   (string-append ":"
                  package-name
                  "/"
                  (module-path-stem
                   (gxtest-trim-leading-dot-slash file)))))

;; : (-> ModulePath ModulePath)
(def (gxtest-normalize-module-path module-path)
  (if (and package-name
           (string-prefix? (string-append package-name "/") module-path))
    (substring module-path
               (+ (string-length package-name) 1)
               (string-length module-path))
    module-path))
