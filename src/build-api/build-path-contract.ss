;;; -*- Gerbil -*-
;;; Minimal path contracts for build/install tests.

(import (only-in :std/misc/path path-directory path-expand path-normalize path-strip-directory)
        :gerbil/gambit)
(export clean-target
        configure-build-root!
        configure-build-path-root!
        dev-launcher-binpath
        install-launcher-binpath)

(def package-root #f)

;; : (-> String Void)
(def (configure-build-root! root)
  (set! package-root (path-normalize root))
  (current-directory package-root)
  (setenv "GERBIL_PATH" (path-expand ".gerbil" package-root)))

;; : (-> Path Void)
;; Configure only the shared path contract for a native build owner.
(def (configure-build-path-root! root)
  (configure-build-root! root))

;; : (-> Void)
(def (ensure-build-root!)
  (unless package-root
    (configure-build-root! (current-directory))))

;; : (-> Path)
(def (dev-launcher-binpath)
  (path-expand ".bin/asp-gerbil-scheme" package-root))

;; : (-> Path)
(def (asp-state-home-directory)
  (or (getenv "ASP_STATE_HOME" #f)
      (path-expand ".agent-semantic-protocols" (user-home-directory))))

(def (asp-install-launcher-directory)
  (or (getenv "SEMANTIC_AGENT_BIN_DIR" #f)
      (path-expand "runtime/bin" (asp-state-home-directory))))

(def (install-launcher-binpath (flag #f))
  (case flag
    ((#f)
     (path-expand ".local/bin/asp-gerbil-scheme" (user-home-directory)))
    ((asp)
     (path-expand "asp-gerbil-scheme" (asp-install-launcher-directory)))
    (else
     (error "unsupported gerbil-scheme install flag" flag))))

;; : (-> Path)
(def (user-home-directory)
  (or (getenv "HOME" #f)
      (error "HOME is required when ASP_STATE_HOME is unset")))

;; : (-> Path Void)
(def (delete-file* path)
  (with-catch
   (lambda (_) #!void)
   (lambda ()
     (when (file-exists? path)
       (delete-file path)))))

;; : (-> Path Void)
(def (cleanup-compile-exe-artifacts! binpath)
  (let* ((bindir (path-directory binpath))
         (name (path-strip-directory binpath))
         (prefix (string-append name "__exe")))
    (for-each
     (lambda (suffix)
       (delete-file* (path-expand (string-append prefix suffix) bindir)))
     '(".c" "_.c" ".scm" ".o" "_.o"))))

;; : (-> Void)
(def (clean-target)
  (ensure-build-root!)
  (current-directory package-root)
  (let (binpath (dev-launcher-binpath))
    (delete-file* binpath)
    (cleanup-compile-exe-artifacts! binpath))
  #!void)
