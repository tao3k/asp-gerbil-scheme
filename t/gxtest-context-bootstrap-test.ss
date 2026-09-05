(import
 :gerbil/gambit
 :std/test
 :asp-gerbil-scheme/src/testing/gxtest-context)

(def gxtest-context-bootstrap-test
  (test-suite "gxtest context bootstrap"
    (test-case "context bootstrap preserves the caller Gerbil path"
      (let ((caller-gerbil-path (getenv "GERBIL_PATH" #f))
            (sentinel "/tmp/asp-gerbil-scheme-context-path-sentinel"))
        (setenv "GERBIL_PATH" sentinel)
        (configure-build-root! (current-directory))
        (check (getenv "GERBIL_PATH" #f) => sentinel)
        (setenv "GERBIL_PATH" (or caller-gerbil-path ""))
        (configure-build-root! (current-directory))))
    (test-case "package output prefix initializes the package context"
      (check (package-output-prefix "scoped-policy")
             => "asp-gerbil-scheme/scoped-policy"))))

(run-tests! gxtest-context-bootstrap-test)
