;;; -*- Gerbil -*-
;;; The sole top-level facade must work at its stable package address both
;;; during source bootstrap and after installation.

(import :gerbil/gambit
        :std/test
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-profiled-build-spec
                 asp-gerbil-scheme-build-environment-profile-name
                 asp-gerbil-scheme-build-environment-profile-bindings
                 asp-gerbil-scheme-host-build-environment-profile
                 asp-gerbil-scheme-development-builder-profile
                 asp-gerbil-scheme-production-builder-profile
                 asp-gerbil-scheme-builder-profile-native-profile
                 framework-executable-build-spec
                 testing-build
                 testing-build-main
                 make-project-policy-test
                 run-modularity-policy
                 benchmark-run/result))

(export build-api-source-bootstrap-test)

(def build-api-source-bootstrap-test
  (test-suite "stable package-level Build API facade"
    (test-case "owns the only downstream module address"
      (check (file-exists? "build-api.ss") => #t)
      (check (file-exists? "src/package-build-api.ss") => #f))
    (test-case "exports the Builder Profile native-spec projection"
      (check (procedure? asp-gerbil-scheme-package-profiled-build-spec)
             => #t))
    (test-case "projects downstream Building, Testing, policy, and benchmark APIs"
      (check (procedure? framework-executable-build-spec) => #t)
      (check (procedure? testing-build) => #t)
      (check (procedure? testing-build-main) => #t)
      (check (procedure? make-project-policy-test) => #t)
      (check (procedure? run-modularity-policy) => #t)
      (check (procedure? benchmark-run/result) => #t))
    (test-case "exports the declarative Builder Profile values"
      (check (asp-gerbil-scheme-build-environment-profile-name
              asp-gerbil-scheme-host-build-environment-profile)
             => (cond-expand
                 (darwin 'macos-native)
                 (else 'portable)))
      (check (asp-gerbil-scheme-build-environment-profile-bindings
              asp-gerbil-scheme-host-build-environment-profile)
             => (cond-expand
                 (darwin '(("SDKROOT" . #f)
                           ("DEVELOPER_DIR" . #f)))
                 (else [])))
      (check (asp-gerbil-scheme-builder-profile-native-profile
              asp-gerbil-scheme-development-builder-profile)
             => 'development)
      (check (asp-gerbil-scheme-builder-profile-native-profile
              asp-gerbil-scheme-production-builder-profile)
             => 'production))))
