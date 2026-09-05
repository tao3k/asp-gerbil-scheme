;;; -*- Gerbil -*-
;;; Package build API behavior tests.

(import :gerbil/gambit
        :std/test
        (only-in :std/misc/path path-expand)
        (only-in :std/source gerbil-home)
        "../src/build-api/package-build")

(export package-build-test)

(def +package-build-test-root+
  (path-expand ".cache/agent-semantic-protocol/test/package-build"
               (current-directory)))

(def (with-gerbil-path value thunk)
  (let ((previous-path (getenv "GERBIL_PATH"))
        (previous-directory (current-directory)))
    (dynamic-wind
      (lambda ()
        (setenv "GERBIL_PATH" value))
      thunk
      (lambda ()
        (setenv "GERBIL_PATH" (or previous-path ""))
        (current-directory previous-directory)))))

(def package-build-test
  (test-suite "package build api"
    (test-case "uses caller GERBIL_PATH for dependency build artifacts"
      (let* ((package-root (path-expand "linked-package" +package-build-test-root+))
             (consumer-gerbil-path
              (path-expand "consumer/.gerbil" +package-build-test-root+))
             (expected (path-expand consumer-gerbil-path)))
        (with-gerbil-path
         consumer-gerbil-path
         (lambda ()
           (check (asp-gerbil-scheme-package-build-active-gerbil-path package-root)
                  => expected)
           (check (asp-gerbil-scheme-package-build-active-gerbil-lib-path package-root)
                  => (path-expand "lib" expected))))))
    (test-case "uses the Gerbil default path when caller path is absent"
      (let* ((package-root (path-expand "standalone-package"
                                        +package-build-test-root+))
             (expected (path-expand (gerbil-home))))
        (with-gerbil-path
         ""
         (lambda ()
           (check (asp-gerbil-scheme-package-build-active-gerbil-path package-root)
                  => expected)
           (check (asp-gerbil-scheme-package-build-active-gerbil-lib-path package-root)
                  => (path-expand "lib" expected))))))))
