;;; -*- Gerbil -*-
;;; Provider-owned extension fact model.

(import :gerbil/runtime/gambit
        (only-in :std/string/misc string-join)
        )

(export extension-fact
        make-extension-fact
        extension-fact?
        extension-fact-name
        extension-fact-activation
        extension-fact-dependency-mode
        extension-fact-package-manager
        extension-fact-package
        extension-fact-dependencies
        extension-fact-capabilities
        extension-fact-json
        extension-fact-search-line)
;; ExtensionFactStruct
(defstruct extension-fact (name activation dependency-mode package-manager package dependencies capabilities))
;; : (-> Fact Json )
(def (extension-fact-json fact)
  (hash (name (extension-fact-name fact))
        (activation (extension-fact-activation fact))
        (dependencyMode (extension-fact-dependency-mode fact))
        (packageManager (extension-fact-package-manager fact))
        (package (extension-fact-package fact))
        (dependencies (extension-fact-dependencies fact))
        (capabilities (extension-fact-capabilities fact))))
;; : (-> ExtensionFact String )
(def (extension-fact-search-line fact)
  (string-append
   "|extension name="
   (extension-fact-name fact)
   " activation="
   (extension-fact-activation fact)
   " packageManager="
   (extension-fact-package-manager fact)
   " dependencyMode="
   (extension-fact-dependency-mode fact)
   " package="
   (extension-fact-package fact)
   " dependencies="
   (string-join (extension-fact-dependencies fact) ",")
   " capabilities="
   (string-join (extension-fact-capabilities fact) ",")))
