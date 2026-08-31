(import
 :std/test
 :asp-gerbil-scheme/src/testing/gxtest-context)

(def gxtest-context-bootstrap-test
  (test-suite "gxtest context bootstrap"
    (test-case "package output prefix initializes the package context"
      (check (package-output-prefix "scoped-policy")
             => "asp-gerbil-scheme/scoped-policy"))))

(run-tests! gxtest-context-bootstrap-test)
