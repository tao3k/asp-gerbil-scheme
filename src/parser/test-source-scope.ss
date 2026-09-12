;;; -*- Gerbil -*-
;;; Explicit changed-file and package-only parser projections.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/package
        :asp-gerbil-scheme/src/parser/parse-workers
        :asp-gerbil-scheme/src/parser/source-scope
        (only-in :std/sort sort))

(export collect-source-scope
        collect-project-package-only)

;; collect-source-scope
;;   : (-> String (List String) ProjectIndex)
;;   | doc m%
;;       `collect-source-scope root paths` is a changed-file convenience API.
;;       It filters missing and non-source paths, but never expands imports or
;;       claims to reconstruct the package build graph.
;;     %
(def (collect-source-scope root paths)
  (let* ((root (path-normalize root))
         (package (read-project-package root))
         (files (sort (changed-source-files root package paths) string<?)))
    (make-project-index root
                        (parse-source-files root files)
                        package)))

;; collect-project-package-only
;;   : (-> String ProjectIndex)
;;   | doc m%
;;       `collect-project-package-only root` returns package metadata without
;;       parsing source owners, which keeps package-policy checks lightweight.
;;     %
(def (collect-project-package-only root)
  (let* ((root (path-normalize root))
         (package (read-project-package root)))
    (make-project-index root '() package)))
