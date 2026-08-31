;;; -*- Gerbil -*-

(import :std/test
        :asp-gerbil-scheme/src/testing/project-build)

(def testing-project-build-interface-test
  (test-suite "testing project-build public interface"
    (test-case "exports project test execution procedures"
      (check (procedure? configure-project-testing-root!) => #t)
      (check (procedure? project-test-target) => #t)
      (check (procedure? project-test-file-target) => #t)
      (check (procedure? project-test-full-target) => #t))))

(run-tests! testing-project-build-interface-test)
