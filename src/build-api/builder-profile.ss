;;; -*- Gerbil -*-
;;; Declarative Builder Profile shared by discovery and native build.

(import (only-in :clan/poo/object .def .get)
        "./source-discovery"
        (only-in :std/srfi/13 string-prefix?))

(export asp-gerbil-scheme-builder-profile-prototype
        asp-gerbil-scheme-development-builder-profile
        asp-gerbil-scheme-production-builder-profile
        asp-gerbil-scheme-builder-profile-native-profile
        asp-gerbil-scheme-builder-profile-profiles
        asp-gerbil-scheme-builder-profile-exclude-directories
        asp-gerbil-scheme-builder-profile-test-roots
        asp-gerbil-scheme-builder-profile-gitignore?
        asp-gerbil-scheme-builder-profile-default-project-excludes?
        asp-gerbil-scheme-builder-profile-module-under-root?
        asp-gerbil-scheme-builder-profile-modules)

(.def asp-gerbil-scheme-builder-profile-prototype
  (name 'builder)
  (native-profile 'development)
  (profiles ['asp-quality])
  ;; Scenario fixtures and generated snapshots are policy/test inputs owned by
  ;; their harnesses, not package modules discovered by std/make.
  (exclude-directories ["scenarios" "snapshots"])
  ;; Gerbil projects conventionally use either t/ or test/; neither directory
  ;; is part of the package's native library projection by default.
  (test-roots ["t" "test"])
  (gitignore? #t)
  (default-project-excludes? #t))

(.def (asp-gerbil-scheme-development-builder-profile
       @ asp-gerbil-scheme-builder-profile-prototype)
  (name 'development)
  (native-profile 'development))

(.def (asp-gerbil-scheme-production-builder-profile
       @ asp-gerbil-scheme-builder-profile-prototype)
  (name 'production)
  (native-profile 'production))

(def (asp-gerbil-scheme-builder-profile-native-profile profile)
  (.get profile native-profile))

(def (asp-gerbil-scheme-builder-profile-profiles profile)
  (.get profile profiles))

;; : (-> BuilderProfile (List Path))
(def (asp-gerbil-scheme-builder-profile-exclude-directories profile)
  (.get profile exclude-directories))

;; Test roots are a build-profile convention, not a second source catalog.
;; Downstream packages still declare one explicit project root set.
;; : (-> BuilderProfile (List Path))
(def (asp-gerbil-scheme-builder-profile-test-roots profile)
  (.get profile test-roots))

(def (asp-gerbil-scheme-builder-profile-gitignore? profile)
  (.get profile gitignore?))

(def (asp-gerbil-scheme-builder-profile-default-project-excludes? profile)
  (.get profile default-project-excludes?))

;; : (-> Path Path Boolean)
(def (asp-gerbil-scheme-builder-profile-module-under-root? module root)
  (or (string=? root "")
      (string=? root ".")
      (string=? module root)
      (string-prefix? (string-append root "/") module)))

(def (asp-gerbil-scheme-builder-profile-modules
      profile root: (root ".")
      roots: (roots ["."])
      exclude: (exclude +default-excluded-module-files+)
      exclude-dirs:
      (exclude-dirs
       (asp-gerbil-scheme-builder-profile-exclude-directories profile)))
  (filter
   (lambda (module)
     (ormap (lambda (source-root)
              (asp-gerbil-scheme-builder-profile-module-under-root?
               module source-root))
            roots))
   (all-gerbil-modules
    root: root
    exclude: exclude
    exclude-dirs: exclude-dirs
    default-project-excludes?:
    (asp-gerbil-scheme-builder-profile-default-project-excludes? profile)
    respect-gitignore?:
    (asp-gerbil-scheme-builder-profile-gitignore? profile))))
