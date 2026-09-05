;;; -*- Gerbil -*-
;;; Builder Profiles projection contract.

(import :clan/poo/object
        (only-in :std/test
                 test-suite test-case check check-exception run-tests!)
        (only-in :std/sugar hash)
        (only-in ../src/build-api/builder-profile
                 asp-gerbil-scheme-development-builder-profile
                 asp-gerbil-scheme-builder-profile-profiles)
(only-in ../src/build-api/package-spec
                 asp-gerbil-scheme-library-package-prototype
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-package-modules)
        (only-in ../src/build-api/profile-build-spec
                 asp-gerbil-scheme-package-profile-admit-report!
                 asp-gerbil-scheme-package-profiled-build-spec))

(export build-api-profile-build-spec-test)

(.def (native-only-builder-profile
       @ asp-gerbil-scheme-development-builder-profile)
  (name 'native-only-test)
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
      (check (asp-gerbil-scheme-package-modules macro-witness-package-spec)
             => ["src/main.ss"])
      (check (macro-witness-native-spec) => ["src/main"]))
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
