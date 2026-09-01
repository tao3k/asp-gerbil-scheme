(export asp-gerbil-scheme-package-spec!
        asp-gerbil-scheme-package-native-spec)

(import :clan/poo/object)

;; Keep Gerbil's native build spec as the only downstream data model.  The
;; macro contributes a stable POO declaration boundary without wrapping
;; std/make forms in a second option language.

(defrules asp-gerbil-scheme-package-spec! ()
  ((_ declaration slot ...)
   (.def declaration slot ...)))

(def (asp-gerbil-scheme-package-native-spec package-spec)
  (.get package-spec native-spec))
