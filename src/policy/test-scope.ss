;;; -*- Gerbil -*-
;;; Native source scope for policy tests.
;;;
;;; Production and test modules use the same lightweight source catalog as
;;; PackageSpec. std/make remains the sole build graph executor.

(import :gerbil/gambit
        (rename-in "../build-api/native-spec-support"
                   (all-gerbil-modules native-gerbil-modules))
        (only-in :std/misc/path path-expand)
        (only-in :std/srfi/13 string-suffix?))

(export project-policy-source-files)

(def (project-policy-test-files)
  (let (test-root (path-expand "t" (current-directory)))
    (if (file-exists? test-root)
      (parameterize ((current-directory test-root))
        (map (cut string-append "t/" <>)
             (filter (cut string-suffix? "-test.ss" <>)
                     (native-gerbil-modules))))
      [])))

(def (project-policy-source-files)
  (append (native-gerbil-modules)
          (project-policy-test-files)))
