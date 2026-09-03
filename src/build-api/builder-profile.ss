;;; -*- Gerbil -*-
;;; Declarative Builder Profile shared by discovery and native build.

(import :clan/poo/object
        (only-in "./source-discovery"
                 +default-excluded-module-files+
                 all-gerbil-modules))

(export asp-gerbil-scheme-builder-profile-prototype
        asp-gerbil-scheme-development-builder-profile
        asp-gerbil-scheme-production-builder-profile
        asp-gerbil-scheme-builder-profile-native-profile
        asp-gerbil-scheme-builder-profile-profiles
        asp-gerbil-scheme-builder-profile-gitignore?
        asp-gerbil-scheme-builder-profile-default-project-excludes?
        asp-gerbil-scheme-builder-profile-modules)

(.def asp-gerbil-scheme-builder-profile-prototype
  (name 'builder)
  (native-profile 'development)
  (profiles ['asp-quality])
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

(def (asp-gerbil-scheme-builder-profile-gitignore? profile)
  (.get profile gitignore?))

(def (asp-gerbil-scheme-builder-profile-default-project-excludes? profile)
  (.get profile default-project-excludes?))

(def (asp-gerbil-scheme-builder-profile-modules
      profile root: (root ".")
      exclude: (exclude +default-excluded-module-files+)
      exclude-dirs: (exclude-dirs '()))
  (all-gerbil-modules
   root: root
   exclude: exclude
   exclude-dirs: exclude-dirs
   default-project-excludes?:
   (asp-gerbil-scheme-builder-profile-default-project-excludes? profile)
   respect-gitignore?:
   (asp-gerbil-scheme-builder-profile-gitignore? profile)))
