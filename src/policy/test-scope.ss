;;; -*- Gerbil -*-
;;; Native source scope for policy tests.
;;;
;;; Production and test modules come from clan/building's std/make graph.
;;; ASP performs no filesystem discovery or import expansion.

(import :gerbil/gambit
        (rename-in :clan/building
                   (all-gerbil-modules std-make-gerbil-modules))
        (only-in :std/misc/path path-expand)
        (only-in :std/srfi/13 string-suffix?))

(export project-policy-source-files)

(def (project-policy-test-files)
  (let (test-root (path-expand "t" (current-directory)))
    (if (file-exists? test-root)
      (parameterize ((current-directory test-root))
        (map (cut string-append "t/" <>)
             (filter (cut string-suffix? "-test.ss" <>)
                     (std-make-gerbil-modules))))
      [])))

(def (project-policy-source-files)
  (append (std-make-gerbil-modules)
          (project-policy-test-files)))
