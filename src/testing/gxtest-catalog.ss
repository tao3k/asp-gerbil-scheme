;;; -*- Gerbil -*-
;;; Build API projection of the project test graph.

(import (rename-in :clan/building
                   (all-gerbil-modules upstream-all-gerbil-modules))
        (only-in :std/misc/path path-directory path-expand)
        (only-in :std/srfi/1 append-map fold)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in "./gxtest-context"
                 ensure-build-root!
                 gxtest-test-module-path
                 package-root)
        (only-in "./gxtest-smoke"
                 asp-gerbil-scheme-default-gxtest-smoke-files)
        :gerbil/gambit)

(export gxtest-test-files
        default-gxtest-test-files
        gxtest-test-spec
        gxtest-project-policy-files)

;; : (-> Path Boolean)
(def (explicit-project-policy-test-file? entry)
  (string=? entry "project-policy-test.ss"))

;; : (-> Path Boolean)
(def (test-file-entry? entry)
  (and (string-suffix? "-test.ss" entry)
       (not (member entry '("." "..")))
       (not (explicit-project-policy-test-file? entry))))

;; : (-> Path Boolean)
(def (top-level-test-file? path)
  (and (equal? (path-directory path) "t/")
       (test-file-entry?
        (substring path 2 (string-length path)))))

;; : (-> Path Boolean)
(def (policy-agent-poo-test-file? entry)
  (string-prefix? "agent-poo-" entry))

;; : (-> Path Boolean)
(def (policy-subdir-test-file? path)
  (and (equal? (path-directory path) "t/policy/")
       (let (entry (substring path 9 (string-length path)))
         (and (test-file-entry? entry)
              (policy-agent-poo-test-file? entry)))))

;; The aggregate t/policy-test.ss imports these suites as native test modules.
;; They are policy evidence even when they are not independent runner entries.
(def (project-policy-subdir-test-file? path)
  (and (equal? (path-directory path) "t/policy/")
       (test-file-entry?
        (substring path 9 (string-length path)))))

;; : (-> Path (List (List Path)) (List (List Path)))
(def (gxtest-catalog-test-file-step path buckets)
  (cond
   ((top-level-test-file? path)
    (list (cons path (car buckets)) (cadr buckets)))
   ((policy-subdir-test-file? path)
    (list (car buckets) (cons path (cadr buckets))))
   (else buckets)))

(def +native-test-roots+ ["t" "test"])

;; : (-> (List Path))
(def (native-test-catalog-files)
  (append-map
   (lambda (root)
     (let (directory (path-expand root package-root))
       (if (file-exists? directory)
         (parameterize ((current-directory directory))
           (map (cut string-append root "/" <>)
                (upstream-all-gerbil-modules)))
         [])))
   +native-test-roots+))

;; Test discovery applies clan/building's native catalog independently under
;; each conventional test directory. This is Testing data, not a package
;; BuildSpec or a source-root option on PackageSpec.
;; : (-> (List Path))
(def (gxtest-test-files)
  (ensure-build-root!)
  (let (buckets
        (fold gxtest-catalog-test-file-step
              (list [] [])
              (native-test-catalog-files)))
    (append (reverse (car buckets))
            (reverse (cadr buckets)))))

;; : (-> (List Path))
(def (default-gxtest-test-files)
  (asp-gerbil-scheme-default-gxtest-smoke-files))

;; : (-> (List ModulePath))
(def (gxtest-test-spec)
  (map gxtest-test-module-path (gxtest-test-files)))

;; Project policy consumes clan/building's native package module catalog, the
;; same upstream catalog used by PackageSpec to project the std/make graph, plus
;; the native test-module catalog selected by Testing conventions. The parser
;; receives this list unchanged and never discovers roots or expands imports.
;; : (-> (List Path))
(def (gxtest-project-policy-files)
  (append (upstream-all-gerbil-modules)
          (filter (lambda (path)
                    (or (top-level-test-file? path)
                        (project-policy-subdir-test-file? path)))
                  (native-test-catalog-files))))
