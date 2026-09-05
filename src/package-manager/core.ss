;;; -*- Gerbil -*-
;;; Gerbil package-manager facts derived from gerbil.pkg.

(import :asp-gerbil-scheme/src/parser/facade)

(export +gerbil-package-manager-id+
        +gerbil-local-package-root-hint+
        project-package-managed-by-gerbil?
        project-package-depends-on?
        project-package-activates?
        gerbil-local-source-candidate
        git-repository-candidate
        package-source-index-hint)
;; String
(def +gerbil-package-manager-id+ "gxpkg")
;; String
(def +gerbil-local-package-root-hint+ "~/.gerbil")
;; : (-> Package Boolean )
(def (project-package-managed-by-gerbil? package)
  (and package
       (equal? (project-package-manager package) +gerbil-package-manager-id+)))
;;; Boundary:
;;; - project-package-activates? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Package TokenMatches Boolean )
(def (project-package-activates? package token-matches?)
  (and (project-package-managed-by-gerbil? package)
       (not
        (not
         (or (token-matches? (project-package-name package))
             (ormap token-matches? (project-package-dependencies package)))))))
;;; Boundary:
;;; - project-package-depends-on? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Package TokenMatches Boolean )
(def (project-package-depends-on? package token-matches?)
  (and (project-package-managed-by-gerbil? package)
       (not
        (not
         (ormap token-matches? (project-package-dependencies package))))))
;; : (-> PackageName Json )
(def (gerbil-local-source-candidate package-name)
  (hash (kind "gerbil-package-source")
        (manager +gerbil-package-manager-id+)
        (rootHint +gerbil-local-package-root-hint+)
        (package package-name)
        (status "probe-first")
        (missingAction "install-package-before-repository-fallback")
        (globalStoreRoot +gerbil-local-package-root-hint+)
        (localStateWarning
         "do not create repository-local .gerbil state; gxpkg state belongs under ~/.gerbil")
        (installHint
         (string-append +gerbil-package-manager-id+ " install " package-name))
        (globalBuildHint "run gxpkg build from the package checkout when developing locally")
        (gxtestImportHint "(import :asp-gerbil-scheme/src/policy/gxtest)")
        (testEntrypointHint "(make-project-policy-test \".\")")
        (owner "asp-server")))
;; : (-> Repository Json )
(def (git-repository-candidate repository)
  (hash (kind "git-repository")
        (vcs "git")
        (repository repository)
        (url (string-append "https://" repository))
        (status "fallback")
        (owner "asp-server")))
;; Json
(def (package-source-index-hint)
  (hash (owner "asp-server")
        (backend "rust-sql")
        (mode "local-source-before-git")
        (packageManager +gerbil-package-manager-id+)
        (globalStoreRoot +gerbil-local-package-root-hint+)
        (missingLocalAction "install-package-before-repository-fallback")
        (localStateWarning
         "do not create repository-local .gerbil state; gxpkg state belongs under ~/.gerbil")
        (gxtestImportHint "(import :asp-gerbil-scheme/src/policy/gxtest)")
        (testEntrypointHint "(make-project-policy-test \".\")")
        (fallbackPolicy "repository-source-after-install-check")))
