;;; -*- Gerbil -*-
;;; Declarative Builder Profile shared by discovery and native build.

(import (only-in :clan/poo/object .def .get)
        (only-in "../object-family/syntax" defpoo-object-family poo-family-ref)
        (only-in "./build-environment-profile"
                 asp-gerbil-scheme-host-build-environment-profile
                 asp-gerbil-scheme-apply-build-environment-profile!)
        (only-in "./source-discovery"
                 +default-excluded-module-files+
                 all-gerbil-modules/roots/config)
        (only-in :std/srfi/13 string-prefix?))

(export asp-gerbil-scheme-builder-profile-prototype
        asp-gerbil-scheme-development-builder-profile
        asp-gerbil-scheme-production-builder-profile
        asp-gerbil-scheme-builder-profile-native-profile
        asp-gerbil-scheme-builder-profile-build-environment
        asp-gerbil-scheme-builder-profile-apply-build-environment!
        asp-gerbil-scheme-builder-profile-profiles
        asp-gerbil-scheme-builder-profile-exclude-directories
        asp-gerbil-scheme-builder-profile-test-roots
        asp-gerbil-scheme-builder-profile-gitignore?
        asp-gerbil-scheme-builder-profile-default-project-excludes?
        asp-gerbil-scheme-builder-profile-module-under-root?
        asp-gerbil-scheme-builder-profile-modules
        asp-gerbil-scheme-builder-profile-modules/root-roots
        asp-gerbil-scheme-builder-profile-modules/config)

(defpoo-object-family
  (prototype asp-gerbil-scheme-builder-profile-prototype
             (name 'builder)
             (native-profile 'development)
             (build-environment-profile
              asp-gerbil-scheme-host-build-environment-profile)
             (profiles ['asp-quality])
             ;; Scenario fixtures and generated snapshots are policy/test
             ;; inputs owned by their harnesses, not package modules.
             (exclude-directories ["scenarios" "snapshots"])
             ;; Gerbil projects conventionally use either t/ or test/; neither
             ;; directory is part of the native library projection by default.
             (test-roots ["t" "test"])
             (gitignore? #t)
             (default-project-excludes? #t))
  (accessors poo-family-ref
             (required
              (asp-gerbil-scheme-builder-profile-native-profile native-profile)
              (asp-gerbil-scheme-builder-profile-build-environment
               build-environment-profile)
              (asp-gerbil-scheme-builder-profile-profiles profiles)
              (asp-gerbil-scheme-builder-profile-exclude-directories
               exclude-directories)
              (asp-gerbil-scheme-builder-profile-test-roots test-roots)
              (asp-gerbil-scheme-builder-profile-gitignore? gitignore?)
              (asp-gerbil-scheme-builder-profile-default-project-excludes?
               default-project-excludes?))
             (optional)))

(.def (asp-gerbil-scheme-development-builder-profile
       @ asp-gerbil-scheme-builder-profile-prototype)
  (name 'development)
  (native-profile 'development))

(.def (asp-gerbil-scheme-production-builder-profile
       @ asp-gerbil-scheme-builder-profile-prototype)
  (name 'production)
  (native-profile 'production))

(def (asp-gerbil-scheme-builder-profile-apply-build-environment! profile)
  (asp-gerbil-scheme-apply-build-environment-profile!
   (asp-gerbil-scheme-builder-profile-build-environment profile)))

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
  (asp-gerbil-scheme-builder-profile-modules/config
   profile root roots exclude exclude-dirs))

;; : (-> BuilderProfile Path (List Path) (List Path))
(def (asp-gerbil-scheme-builder-profile-modules/root-roots profile root roots)
  (asp-gerbil-scheme-builder-profile-modules/config
   profile
   root
   roots
   +default-excluded-module-files+
   (asp-gerbil-scheme-builder-profile-exclude-directories profile)))

;;; AOT boundary:
;;; - Source coverage and package-spec owners call this positional entry.
;;; - Keyword defaults are resolved by the declarative API above, within the
;;;   module that owns its generated dispatcher.
;; : (-> BuilderProfile Path (List Path) (List Path) (List Path) (List Path))
(def (asp-gerbil-scheme-builder-profile-modules/config
      profile root roots exclude exclude-dirs)
  (all-gerbil-modules/roots/config
   root
   roots
   exclude
   exclude-dirs
   (asp-gerbil-scheme-builder-profile-default-project-excludes? profile)
   (asp-gerbil-scheme-builder-profile-gitignore? profile)))
