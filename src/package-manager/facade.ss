;;; -*- Gerbil -*-
;;; Stable facade for Gerbil package-manager facts.

(import :asp-gerbil-scheme/src/package-manager/core)

(export +gerbil-package-manager-id+
        +gerbil-local-package-root-hint+
        project-package-managed-by-gerbil?
        project-package-depends-on?
        project-package-activates?
        gerbil-local-source-candidate
        git-repository-candidate
        package-source-index-hint)
