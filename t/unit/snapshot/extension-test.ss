;;; -*- Gerbil -*-
;;; Provider extensions publish facts only; ASP owns search composition.

(import :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/snapshot/facade
        :std/test)

(export check-extension-snapshot-schema-fields)

;; Snapshot
(def (check-extension-snapshot-schema-fields)
  (let (fact
        (make-extension-fact
         "poo"
         "gerbil.pkg"
         "required"
         "gxpkg"
         "sample/app"
         ["git.cons.io/mighty-gerbils/gerbil-poo"]
         ["object-system" "metaobject-protocol" "protocols"]))
    (check (extension-fact-snapshot fact)
           => '(providerExtension
                (name "poo")
                (activation "gerbil.pkg")
                (dependencyMode "required")
                (packageManager "gxpkg")
                (package "sample/app")
                (dependencies ("git.cons.io/mighty-gerbils/gerbil-poo"))
                (capabilities ("object-system" "metaobject-protocol" "protocols"))))))
