;;; -*- Gerbil -*-
;;; Builder Profile projection from a package object to its native build spec.

(import (only-in :gerbil/expander import-module)
        (only-in :std/sugar hash-get)
        (only-in "./builder-profile"
                 asp-gerbil-scheme-builder-profile-profiles)
        (only-in "./package-spec"
                 asp-gerbil-scheme-package-builder-profile
                 asp-gerbil-scheme-package-native-spec)
        (only-in "../building/memory-anomaly-guard"
                 call-with-framework-memory-anomaly-guard)
        (only-in "./source-coverage"
                 asp-gerbil-scheme-source-coverage-owner-root))

(export asp-gerbil-scheme-package-profile-admit-report!
        asp-gerbil-scheme-package-profiled-build-spec)

;; : (-> PolicyReport PolicyReport)
(def (asp-gerbil-scheme-package-profile-admit-report! report)
  (if (equal? (hash-get report 'status) "pass")
    report
    (error "ASP Gerbil Scheme Builder Profile rejected build spec")))

;; : (-> Root PolicyReport)
(def (asp-gerbil-scheme-project-profile-report root)
  (import-module ':asp-gerbil-scheme/src/policy/gxtest-report #f #t)
  ((eval 'asp-gerbil-scheme/src/policy/gxtest-report#project-policy-report)
   root))

;; : (-> PolicyReport Void)
(def (asp-gerbil-scheme-display-project-profile-report report)
  ((eval
    'asp-gerbil-scheme/src/policy/gxtest-report#display-project-policy-report)
   report))

;; Policy admission runs inside the same gxi process that loads build.ss. Its
;; full source parse needs the Scheme-owned rapid-growth guard before std/make;
;; otherwise an abnormal admission heap trajectory is invisible to the native
;; build guard.
;; : (-> Integer)
(def (asp-gerbil-scheme-profile-worker-count)
  (let* ((raw (getenv "GERBIL_BUILD_CORES" #f))
         (configured (and raw (string->number raw))))
    (if (and (integer? configured) (> configured 0))
      configured
      (max 1 (##cpu-count)))))

;; : (-> PackageSpec (Maybe Root) BuildSpec)
(def (asp-gerbil-scheme-package-profiled-build-spec package-spec (root #f))
  (let (profiles
        (asp-gerbil-scheme-builder-profile-profiles
         (asp-gerbil-scheme-package-builder-profile package-spec)))
    (when (member 'asp-quality profiles)
      (displayln "[asp-gerbil-scheme-build] phase=profile-admission profile=asp-quality")
      (force-output)
      (let (report
            (call-with-framework-memory-anomaly-guard
             "asp-quality profile admission"
             (asp-gerbil-scheme-profile-worker-count)
             (lambda ()
               (asp-gerbil-scheme-project-profile-report
                (or root
                    (asp-gerbil-scheme-source-coverage-owner-root)
                    ".")))
             #t
             'profile-admission-start))
        (unless (equal? (hash-get report 'status) "pass")
          (asp-gerbil-scheme-display-project-profile-report report))
        (asp-gerbil-scheme-package-profile-admit-report! report))))
  (asp-gerbil-scheme-package-native-spec package-spec))
