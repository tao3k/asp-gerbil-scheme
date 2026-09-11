;;; -*- Gerbil -*-
;;; Build API projection of the project test graph.

(import (only-in :std/misc/path path-directory)
        (only-in :std/srfi/1 fold)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in "../build-api/builder-profile"
                 asp-gerbil-scheme-development-builder-profile
                 asp-gerbil-scheme-builder-profile-test-roots
                 asp-gerbil-scheme-builder-profile-modules/root-roots)
        (only-in "./gxtest-context"
                 ensure-build-root!
                 gxtest-test-module-path
                 package-root)
        (only-in "./gxtest-smoke"
                 asp-gerbil-scheme-default-gxtest-smoke-files)
        :gerbil/gambit)

(export gxtest-test-files
        default-gxtest-test-files
        gxtest-test-spec)

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

;; : (-> Path (List (List Path)) (List (List Path)))
(def (gxtest-catalog-test-file-step path buckets)
  (cond
   ((top-level-test-file? path)
    (list (cons path (car buckets)) (cadr buckets)))
   ((policy-subdir-test-file? path)
    (list (car buckets) (cons path (cadr buckets))))
   (else buckets)))

;; The Builder Profile owns roots and exclusions.  This projection only selects
;; runnable test entries from that already-declared module catalog.
;; : (-> (List Path))
(def (gxtest-test-files)
  (ensure-build-root!)
  (let (buckets
        (fold gxtest-catalog-test-file-step
              (list [] [])
              (asp-gerbil-scheme-builder-profile-modules/root-roots
               asp-gerbil-scheme-development-builder-profile
               package-root
               (asp-gerbil-scheme-builder-profile-test-roots
                asp-gerbil-scheme-development-builder-profile))))
    (append (reverse (car buckets))
            (reverse (cadr buckets)))))

;; : (-> (List Path))
(def (default-gxtest-test-files)
  (asp-gerbil-scheme-default-gxtest-smoke-files))

;; : (-> (List ModulePath))
(def (gxtest-test-spec)
  (map gxtest-test-module-path (gxtest-test-files)))
