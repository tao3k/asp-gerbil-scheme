;;; -*- Gerbil -*-
;;; The sole top-level facade must work at its stable package address both
;;; during source bootstrap and after installation.

(import :gerbil/gambit
        :std/test
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-native-spec
                 testing-interface-command-for
                 testing-interface-run-test!
                 testing-benchmark-run/result
                 make-project-policy-test
                 run-modularity-policy
                 benchmark-run/result
                 make-micro-kernel-fixture
                 micro-kernel-run/result))

(export build-api-source-bootstrap-test)

(def build-api-source-bootstrap-test
  (test-suite "stable package-level Build API facade"
    (test-case "owns the only downstream module address"
      (check (file-exists? "build-api.ss") => #t)
      (check (file-exists? "src/package-build-api.ss") => #f))
    (test-case "exports the compile-mode-neutral native-spec projection"
      (check (procedure? asp-gerbil-scheme-package-native-spec)
             => #t))
    (test-case "projects native build, testing extensions, policy, and benchmark APIs"
      (check (procedure? testing-interface-command-for) => #t)
      (check (procedure? testing-interface-run-test!) => #t)
      (check (procedure? testing-benchmark-run/result) => #t)
      (check (procedure? make-project-policy-test) => #t)
      (check (procedure? run-modularity-policy) => #t)
      (check (procedure? benchmark-run/result) => #t)
      (check (procedure? make-micro-kernel-fixture) => #t)
      (check (procedure? micro-kernel-run/result) => #t))))
