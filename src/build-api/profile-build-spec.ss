;;; -*- Gerbil -*-
;;; Builder Profile projection from a package object to its native build spec.

(import (only-in :gerbil/expander import-module)
        (only-in :std/sugar hash-get)
        (only-in "./builder-profile"
                 asp-gerbil-scheme-builder-profile-profiles)
        (only-in "./package-spec"
                 asp-gerbil-scheme-package-builder-profile
                 asp-gerbil-scheme-package-native-spec))

(export asp-gerbil-scheme-package-profile-admit-report!
        asp-gerbil-scheme-package-profiled-build-spec)

(def (asp-gerbil-scheme-package-profile-admit-report! report)
  (if (equal? (hash-get report 'status) "pass")
    report
    (error "ASP Gerbil Scheme Builder Profile rejected build spec")))

(def (asp-gerbil-scheme-project-profile-report root)
  (import-module ':asp-gerbil-scheme/src/policy/gxtest-report #f #t)
  ((eval 'asp-gerbil-scheme/src/policy/gxtest-report#project-policy-report)
   root))

(def (asp-gerbil-scheme-display-project-profile-report report)
  ((eval
    'asp-gerbil-scheme/src/policy/gxtest-report#display-project-policy-report)
   report))

(def (asp-gerbil-scheme-package-profiled-build-spec package-spec (root "."))
  (let (profiles
        (asp-gerbil-scheme-builder-profile-profiles
         (asp-gerbil-scheme-package-builder-profile package-spec)))
    (when (member 'asp-quality profiles)
      (displayln "[asp-gerbil-scheme-build] phase=profile-admission profile=asp-quality")
      (force-output)
      (let (report (asp-gerbil-scheme-project-profile-report root))
        (unless (equal? (hash-get report 'status) "pass")
          (asp-gerbil-scheme-display-project-profile-report report))
        (asp-gerbil-scheme-package-profile-admit-report! report))))
  (asp-gerbil-scheme-package-native-spec package-spec))
