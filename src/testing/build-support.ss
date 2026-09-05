;;; -*- Gerbil -*-
;;; Support module compilation and cache checks for downstream testing builds.

(import :gerbil/gambit
        (only-in :gerbil/gambit getenv)
        (only-in :std/misc/path path-directory)
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/1 append-map)
        (only-in :std/sugar filter)
        (only-in :asp-gerbil-scheme/src/build-api/builder-profile
                 asp-gerbil-scheme-development-builder-profile
                 asp-gerbil-scheme-builder-profile-modules/root-roots)
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/framework
        :asp-gerbil-scheme/src/testing/build-paths
        :asp-gerbil-scheme/src/testing/build-process)

(export #t)

;; : (List Path)
(def +testing-build-framework-dependency-stamps+
  '("asp-gerbil-scheme/src/benchmark/gate.ssi"
    "asp-gerbil-scheme/src/testing/model.ssi"
    "asp-gerbil-scheme/src/testing/scope.ssi"
    "asp-gerbil-scheme/src/testing/scenario.ssi"
    "asp-gerbil-scheme/src/testing/performance.ssi"
    "asp-gerbil-scheme/src/testing/selection.ssi"
    "asp-gerbil-scheme/src/testing/batch.ssi"
    "asp-gerbil-scheme/src/testing/framework.ssi"))

;; : (-> TestingBuild Path [String])
(def (testing-build-support-command build file)
  ["gxc" (testing-build-path build file)])

;; : (-> TestingBuild MaybePath)
(def (testing-build-default-support-output-root build)
  (let ((gerbil-path (getenv "GERBIL_PATH" #f))
        (package-name (testing-object-ref build 'packageName #f)))
    (and gerbil-path
         package-name
         (path-expand package-name
                      (path-expand "lib" gerbil-path)))))

;; : (-> TestingBuild Path MaybePath)
(def (testing-build-support-output-directory build file)
  (let (root (or (testing-object-ref build 'supportOutputRoot #f)
                 (testing-build-default-support-output-root build)))
    (and root
         (path-directory
          (testing-build-path build
                              (path-expand file root))))))

;; : (-> TestingBuild Path MaybePath)
(def (testing-build-support-output-file build file)
  (let (root (or (testing-object-ref build 'supportOutputRoot #f)
                 (testing-build-default-support-output-root build)))
    (and root
         (testing-build-replace-suffix
          (testing-build-path build (path-expand file root))
          ".ss"
          ".ssi"))))

;; : (-> Path Number)
(def (testing-build-file-seconds path)
  (time->seconds (file-info-last-modification-time (file-info path))))

;; : (-> Path Boolean)
(def (testing-build-absolute-path? path)
  (and (string? path)
       (> (string-length path) 0)
       (char=? (string-ref path 0) #\/)))

;; : (-> MaybePath)
(def (testing-build-gerbil-lib-root)
  (let (gerbil-path (getenv "GERBIL_PATH" #f))
    (and gerbil-path
         (path-expand "lib" gerbil-path))))

;; : (-> Path MaybePath)
(def (testing-build-framework-dependency-stamp-path stamp)
  (let (lib-root (testing-build-gerbil-lib-root))
    (and lib-root
         (path-expand stamp lib-root))))

;; : (-> TestingBuild Path MaybePath)
(def (testing-build-configured-dependency-stamp-path build stamp)
  (cond
   ((testing-build-absolute-path? stamp) stamp)
   ((string? stamp) (testing-build-path build stamp))
   (else #f)))

;; : (-> TestingBuild (List Path))
(def (testing-build-compile-dependency-stamp-paths build)
  (filter
   values
   (append
    (map testing-build-framework-dependency-stamp-path
         +testing-build-framework-dependency-stamps+)
    (map (lambda (stamp)
           (testing-build-configured-dependency-stamp-path build stamp))
         (testing-object-ref build 'compileDependencyStamps [])))))

;; : (-> Path Path Boolean)
(def (testing-build-file-current? output source)
  (and (file-exists? output)
       (> (testing-build-file-seconds output)
          (testing-build-file-seconds source))))

;; : (-> TestingBuild Path Boolean)
(def (testing-build-compile-dependencies-current? build output)
  (let loop ((stamps (testing-build-compile-dependency-stamp-paths build)))
    (cond
     ((null? stamps) #t)
     ((not (file-exists? (car stamps))) (loop (cdr stamps)))
     ((testing-build-file-current? output (car stamps)) (loop (cdr stamps)))
     (else #f))))

;; : (-> TestingBuild Path Boolean)
(def (testing-build-gxtest-compiled-current? build file)
  (let ((output (testing-build-support-output-file build file))
        (source (testing-build-path build file)))
    (and output
         (file-exists? source)
         (testing-build-file-current? output source)
         (testing-build-compile-dependencies-current? build output))))

;; : (-> TestingBuild Path Boolean)
(def (testing-build-support-current? build file)
  (let ((output (testing-build-support-output-file build file))
        (source (testing-build-path build file)))
    (and output
         (file-exists? source)
         (testing-build-file-current? output source))))

;; : (-> TestingBuild Path Unit)
(def (testing-build-ensure-support-output-directory! build file)
  (let (directory (testing-build-support-output-directory build file))
    (when directory
      (run-process ["mkdir" "-p" directory]
                   stdin-redirection: #f
                   stdout-redirection: #f
                   stderr-redirection: #f))))

;; : (-> TestingBuild Path Integer)
(def (testing-build-compile-support-file build file)
  (if (testing-build-support-current? build file)
    0
    (begin
      (testing-build-ensure-support-output-directory! build file)
      (testing-build-run-process/status
       (testing-build-support-command build file)))))

;; : (-> Path Boolean)
(def (testing-build-support-source-file? file)
  (and (string? file)
       (testing-string-suffix? ".ss" file)))

;; : (-> TestingBuild Path [Path])
(def (testing-build-support-catalog-files build directory)
  (let* ((normalized-directory (testing-normalize-path directory))
         (directory-path
          (if (testing-string-suffix? "/" normalized-directory)
            normalized-directory
            (string-append normalized-directory "/"))))
    (filter (lambda (file)
              (and (testing-build-support-source-file? file)
                   (equal? (path-directory file) directory-path)))
            (asp-gerbil-scheme-builder-profile-modules/root-roots
             asp-gerbil-scheme-development-builder-profile
             (testing-object-ref build 'root ".")
             [normalized-directory]))))

;; : (-> TestingBuild [Path])
(def (testing-build-support-files build)
  (append (testing-object-ref build 'supportFiles [])
          (append-map (lambda (directory)
                        (testing-build-support-catalog-files build directory))
                      (testing-object-ref build 'supportDirectories []))))

;; : (-> TestingBuild String [Path])
(def (testing-build-suite-support-files build suite-name)
  (let (entry (assoc suite-name (testing-object-ref build 'suiteSupportFiles [])))
    (if entry (cdr entry) [])))

;; : (-> TestingBuild String [Path])
(def (testing-build-suite-support-directories build suite-name)
  (let (entry (assoc suite-name
                     (testing-object-ref build 'suiteSupportDirectories [])))
    (if entry (cdr entry) [])))

;; : (-> TestingBuild [Path] [Path])
(def (testing-build-support-files-from-directories build directories)
  (append-map (lambda (directory)
                (testing-build-support-catalog-files build directory))
              directories))

;; : (-> TestingBuild [String] [Path])
(def (testing-build-support-files-for-suites build suite-names)
  (append (testing-build-support-files build)
          (append-map (lambda (suite-name)
                        (testing-build-suite-support-files build suite-name))
                      suite-names)
          (testing-build-support-files-from-directories
           build
           (append-map (lambda (suite-name)
                         (testing-build-suite-support-directories
                          build
                          suite-name))
                       suite-names))))

;; : (-> TestingSelection [Path])
(def (testing-build-selected-gxtest-files selection)
  (append-map (lambda (suite)
                (if (eq? (testing-object-kind suite) 'gxtest-suite)
                  (testing-expand-suite-args
                   suite
                   (testing-selection-args selection))
                  []))
              (testing-selection-suites selection)))

;; : (-> TestingBuild [Path] Unit)
(def (testing-build-compile-support-files! build files)
  (for-each
   (lambda (file)
     (let (status (testing-build-compile-support-file build file))
       (unless (= status 0)
         (error "testing support compile failed" file status))))
   files))

;; : (-> TestingBuild TestingSelection Unit)
(def (testing-build-compile-selection-support! build selection)
  (let (support-files
        (testing-build-support-files-for-suites
         build
         (map testing-suite-name (testing-selection-suites selection))))
    (testing-build-compile-support-files! build support-files)
    (when (testing-object-ref build 'compileSelectedTests #f)
      (testing-build-compile-support-files!
       build
       (testing-build-selected-gxtest-files selection)))))
