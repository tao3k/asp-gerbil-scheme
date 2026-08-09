(export
 project-clean-target
 project-compile-target
 project-compile-spec
 configure-project-build-root!
 project-install-target)

(import :gslph/src/build-api/native-build)

(def (project-clean-target)
  (clean-target))

(def (project-compile-target verbose debug no-optimize optimized release full binary
                             force?: (force? #f))
  (compile-target verbose debug no-optimize optimized release full binary force?))

(def (project-compile-spec full? release? binary?)
  (compile-spec full? release? binary?))

(def (configure-project-build-root! root)
  (configure-build-root! root))

(def (project-install-target verbose debug no-optimize optimized release full (flag #f))
  (install-target verbose debug no-optimize optimized release full flag))
