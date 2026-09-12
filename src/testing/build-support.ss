;;; -*- Gerbil -*-
;;; Explicit test targets use the native std/make dependency graph.

(import (rename-in :clan/building
                   (all-gerbil-modules upstream-all-gerbil-modules))
        (only-in :std/make make)
        (only-in :std/misc/path path-directory path-expand)
        (only-in :std/sort sort)
        (only-in :std/srfi/1 append-map delete-duplicates)
        (only-in :std/sugar filter)
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/framework
        :asp-gerbil-scheme/src/testing/build-paths)

(export #t)

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
            (string-append normalized-directory "/")))
         (root (testing-object-ref build 'root "."))
         (catalog-root (path-expand normalized-directory root))
         (files
          (if (file-exists? catalog-root)
            (parameterize ((current-directory catalog-root))
              (map (cut string-append directory-path <>)
                   (upstream-all-gerbil-modules)))
            [])))
    (sort
     (filter (lambda (file)
               (and (testing-build-support-source-file? file)
                    (equal? (path-directory file) directory-path)))
             files)
     string<?)))

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
  (when (pair? files)
    ;; The package directory owns gerbil.pkg and import resolution. Native make
    ;; owns ordering, transitive dependencies, output paths, and freshness.
    (parameterize ((current-directory
                    (path-expand (testing-object-ref build 'root "."))))
      (make (delete-duplicates files equal?) srcdir: (current-directory)))))

;; : (-> TestingBuild TestingSelection Unit)
(def (testing-build-compile-selection-support! build selection)
  (testing-build-compile-support-files!
   build
   (append
    (testing-build-support-files-for-suites
     build
     (map testing-suite-name (testing-selection-suites selection)))
    (if (testing-object-ref build 'compileSelectedTests #f)
      (testing-build-selected-gxtest-files selection)
      []))))
