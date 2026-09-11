;;; Public project build operations delegate to the native-build owner without
;;; duplicating scheduling, caching, platform detection, or std/make policy.
;;; This module is a stable library facade, not an alternate build engine.
(export
 project-clean-target
 project-compile-target
 project-compile-spec
 configure-project-build-root!)

(import (only-in :asp-gerbil-scheme/src/build-api/native-build
                 clean-target
                 compile-target)
        (only-in :asp-gerbil-scheme/src/build-api/native-build-spec
                 compile-spec
                 configure-build-root!))

;; : (-> Void)
(def (project-clean-target)
  (clean-target))

;; : (-> Boolean Boolean Boolean Void)
(def (project-compile-target verbose full force?)
  (compile-target verbose full force?))

;; : (-> Boolean BuildSpec)
(def (project-compile-spec full?)
  (compile-spec full?))

;; : (-> Root Void)
(def (configure-project-build-root! root)
  (configure-build-root! root))
