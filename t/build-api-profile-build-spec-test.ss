;;; -*- Gerbil -*-
;;; Builder Profiles projection contract.

(import :clan/poo/object
        (only-in :gerbil/gambit getenv setenv)
        (only-in :std/test
                 test-suite test-case check check-exception run-tests!)
        (only-in :std/sugar hash)
        (only-in "../build-api"
                 asp-gerbil-scheme-build-environment-profile-prototype
                 asp-gerbil-scheme-development-builder-profile
                 asp-gerbil-scheme-builder-profile-profiles
                 asp-gerbil-scheme-library-package-prototype
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-package-modules
                 asp-gerbil-scheme-package-profile-admit-report!
                 asp-gerbil-scheme-package-profiled-build-spec))

(export build-api-profile-build-spec-test)

(.def (macro-witness-build-environment-profile
       @ asp-gerbil-scheme-build-environment-profile-prototype)
  (name 'macro-witness)
  (bindings '(("SDKROOT" . #f))))

(.def (native-only-builder-profile
       @ asp-gerbil-scheme-development-builder-profile)
  (name 'native-only-test)
  (build-environment-profile macro-witness-build-environment-profile)
  (profiles []))

(.def (native-only-package-spec
       @ asp-gerbil-scheme-library-package-prototype)
  (profile native-only-builder-profile)
  (native-spec ["src/main"]))

(asp-gerbil-scheme-package-spec!
 (macro-witness-package-spec
  @ asp-gerbil-scheme-library-package-prototype)
 (spec macro-witness-native-spec)
 (profile native-only-builder-profile)
 (modules ["src/main.ss"])
 (native-spec ["src/main"]))

(def build-api-profile-build-spec-test
  (test-suite "Build API Builder Profiles"
    (test-case "official Builder Profile selects ASP quality"
      (check (asp-gerbil-scheme-builder-profile-profiles
              asp-gerbil-scheme-development-builder-profile)
             => ['asp-quality]))
    (test-case "downstream POO profile declaratively controls projection"
      (check (asp-gerbil-scheme-package-profiled-build-spec
              native-only-package-spec)
              => ["src/main"]))
    (test-case "package declaration macro projects modules and native spec"
      (let (previous
            (getenv "SDKROOT" #f))
        (unwind-protect
          (begin
            (setenv "SDKROOT" "/foreign/sdk")
            (check (asp-gerbil-scheme-package-modules
                    macro-witness-package-spec)
                   => ["src/main.ss"])
            (check (macro-witness-native-spec) => ["src/main"])
            (check (getenv "SDKROOT" #f) => #f))
          (if previous
            (setenv "SDKROOT" previous)
            (setenv "SDKROOT")))))
    (test-case "passing profile report is admitted"
      (let (report (hash (status "pass") (findings [])))
        (check (asp-gerbil-scheme-package-profile-admit-report! report)
               => report)))
    (test-case "failing profile report rejects the build spec"
      (check-exception
       (asp-gerbil-scheme-package-profile-admit-report!
        (hash (status "fail") (findings [(hash (ruleId "TEST"))])))
       true))))

(def (main . _args)
  (run-tests! build-api-profile-build-spec-test))
