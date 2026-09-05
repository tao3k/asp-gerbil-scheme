;;; Public project build operations delegate to the native-build owner without
;;; duplicating scheduling, caching, platform detection, or std/make policy.
;;; This module is a stable library facade, not an alternate build engine.
(export
 project-clean-target
 project-compile-target
 project-compile-spec
 configure-project-build-root!
 project-install-target)

(import (only-in :asp-gerbil-scheme/src/build-api/native-build
                 clean-target
                 compile-target
                 install-target)
        (only-in :asp-gerbil-scheme/src/build-api/native-build-spec
                 compile-spec
                 configure-build-root!))

;; : (-> Void)
(def (project-clean-target)
  (clean-target))

;; : (-> Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean Void)
(def (project-compile-target verbose debug no-optimize optimized release full binary
                             force?: (force? #f))
  (compile-target verbose debug no-optimize optimized release full binary force?))

;; : (-> Boolean Boolean Boolean BuildSpec)
(def (project-compile-spec full? release? binary?)
  (compile-spec full? release? binary?))

;; : (-> Root Void)
(def (configure-project-build-root! root)
  (configure-build-root! root))

;; : (-> Boolean Boolean Boolean Boolean Boolean Boolean (Maybe Symbol) Void)
(def (project-install-target verbose debug no-optimize optimized release full (flag #f))
  (install-target verbose debug no-optimize optimized release full flag))
