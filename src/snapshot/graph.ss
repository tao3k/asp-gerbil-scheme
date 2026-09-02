;;; -*- Gerbil -*-
;;; Stable provider evidence snapshot projections.

(import :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/snapshot/core)

(export extension-packet-snapshot)

;; : (-> ProjectIndex JsonPacket )
(def (extension-packet-snapshot index)
  (list 'extensionPacket
        (project-package-snapshot (project-index-package index))
        (list 'extensions
              (map extension-fact-snapshot (project-extension-facts index)))
        (list 'searchLines (project-extension-search-lines index))))
