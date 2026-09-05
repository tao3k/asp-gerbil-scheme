;;; -*- Gerbil -*-
;;; The source bootstrap facade must expose every API used by build.ss before
;;; the installed public facade exists.

(import :std/test
        (only-in "../build-api"
                 asp-gerbil-scheme-package-profiled-build-spec
                 asp-gerbil-scheme-development-builder-profile
                 asp-gerbil-scheme-production-builder-profile
                 asp-gerbil-scheme-builder-profile-native-profile))

(export build-api-source-bootstrap-test)

(def build-api-source-bootstrap-test
  (test-suite "build API source bootstrap facade"
    (test-case "exports the Builder Profile native-spec projection"
      (check (procedure? asp-gerbil-scheme-package-profiled-build-spec)
             => #t))
    (test-case "exports the declarative Builder Profile values"
      (check (asp-gerbil-scheme-builder-profile-native-profile
              asp-gerbil-scheme-development-builder-profile)
             => 'development)
      (check (asp-gerbil-scheme-builder-profile-native-profile
              asp-gerbil-scheme-production-builder-profile)
             => 'production))))
