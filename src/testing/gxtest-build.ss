;;; -*- Gerbil -*-
;;; Gxtest package build lifecycle helpers.

(import (only-in :std/misc/path path-directory path-expand path-strip-directory)
        (rename-in "../build-api/native-build"
                   (configure-build-root! configure-native-build-root!)
                   (compile-package-api-if-stale
                    native-compile-package-api-if-stale))
        (only-in "../build-api/native-build"
                 compile-selected-gxtest-target)
        (only-in "../build-api/package-receipt"
                 asp-gerbil-scheme-package-build-receipt-status
                 asp-gerbil-scheme-package-build-receipt-status-ref
                 asp-gerbil-scheme-package-build-receipt-write)
        (only-in "../build-api/package-spec"
                 asp-gerbil-scheme-package-api-spec)
        (only-in "./gxtest-context"
                 package-root
                 ensure-build-root!)
        (only-in "./gxtest-discovery"
                 gxtest-selected-source-module-files
                 gxtest-selected-test-files)
        (only-in "./gxtest-receipts"
                  display-package-api-build-receipt-status
                  ensure-directory!
                  selected-gxtest-build-current?
                  selected-gxtest-build-receipt-status
                  write-selected-gxtest-build-receipt!)
        :gerbil/gambit)

(export clean-target
        compile-package-api-if-stale
        compile-scoped-policy-engine-if-stale
        compile-selected-gxtest-if-stale
        compile-spec
        dev-launcher-binpath
         install-launcher-binpath)

;; : (-> (List String))
(def cli-bootstrap-modules
  '("constants.ss"
    "commands/search-prime-light-list.ss"
    "commands/search-prime-light.ss"
    "commands/search.ss"
    "commands/query.ss"
    "commands/check-cache.ss"
    "commands/check.ss"
    "commands/evidence.ss"
    "commands/agent.ss"
    "commands/guide.ss"
    "commands/info.ss"
    "search-light-launcher.ss"
    "build-api/source-coverage.ss"
    "build-api/package-receipt.ss"
    "policy/gxtest-report.ss"
    "policy/gxtest.ss"
    "support/time.ss"
    "benchmark/gate.ss"
    "commands/bench-light.ss"))

;; : (-> Boolean Boolean Boolean (List BuildSpec))
(def (compile-spec full? release? binary?)
  (cond
   ((or full? release?)
    (error "full and release compile specs are owned by native-build"))
   (binary? cli-bootstrap-modules)
   (else (asp-gerbil-scheme-package-api-spec))))

;; : (-> BuildReceiptStatus)
(def (compile-package-api-if-stale)
  (configure-native-build-root! package-root)
  (native-compile-package-api-if-stale))

;; : (-> (List Path) Alist)
(def (compile-selected-gxtest! files)
  (configure-native-build-root! package-root)
  (compile-selected-gxtest-target
   (gxtest-selected-source-module-files files)
   (gxtest-selected-test-files files)))

;; : (-> (List Path) BuildReceiptStatus)
(def (compile-selected-gxtest-if-stale files)
  (let (status (selected-gxtest-build-receipt-status files))
    (display-package-api-build-receipt-status status)
    (if (selected-gxtest-build-current? status)
      status
      ;; The selected source closure is already dependency ordered and is the
      ;; complete build input for this target.  Prebuilding the package API
      ;; here turns a one-file gxtest into a whole-package (currently hundreds
      ;; of modules) build and defeats the lightweight provider boundary.
      (let (metadata (compile-selected-gxtest! files))
        (write-selected-gxtest-build-receipt! files metadata)
        (selected-gxtest-build-receipt-status files)))))

(def +scoped-policy-engine-build-receipt-version+
  'asp-gerbil-scheme-scoped-policy-engine-build.v1)

(def (write-scoped-policy-engine-build-receipt! receipt-path source-files output-files)
  (ensure-directory! (path-directory receipt-path))
  (asp-gerbil-scheme-package-build-receipt-write
   receipt-path
   source-files
   output-files
   version: +scoped-policy-engine-build-receipt-version+))

(def (scoped-policy-engine-build-receipt-status receipt-path source-files output-files)
  (asp-gerbil-scheme-package-build-receipt-status
   receipt-path
   version: +scoped-policy-engine-build-receipt-version+
   expected-sources: source-files
   expected-outputs: output-files))

(def (compile-scoped-policy-engine-if-stale source-files output-files receipt-path)
  (let (status (scoped-policy-engine-build-receipt-status
                receipt-path
                source-files
                output-files))
    (display-package-api-build-receipt-status status)
    (if (eq? (asp-gerbil-scheme-package-build-receipt-status-ref status 'status #f) 'current)
      status
      (begin
        (compile-package-api-if-stale)
        (write-scoped-policy-engine-build-receipt! receipt-path source-files output-files)
        (scoped-policy-engine-build-receipt-status
         receipt-path
         source-files
         output-files)))))

;; : (-> Path)
(def (dev-launcher-binpath)
  (path-expand ".bin/asp-gerbil-scheme" package-root))

;; : (-> Path)
(def (install-launcher-binpath)
  (path-expand "asp-gerbil-scheme" (asp-install-launcher-directory)))

;; : (-> Path)
(def (asp-state-home-directory)
  (or (getenv "ASP_STATE_HOME" #f)
      (path-expand ".agent-semantic-protocols" (user-home-directory))))

(def (asp-install-launcher-directory)
  (or (getenv "SEMANTIC_AGENT_BIN_DIR" #f)
      (path-expand "runtime/bin" (asp-state-home-directory))))

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
