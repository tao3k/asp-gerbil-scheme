(export asp-gerbil-scheme-library-package-spec)

(import :clan/building
        (only-in :std/srfi/1 fold)
        (only-in :std/srfi/13 string-prefix?)
        (only-in "./package-spec" asp-gerbil-scheme-package-spec!))

;; These are package-role entry modules, not a hand-maintained dependency
;; closure.  The executable compiler continues to derive their transitive
;; imports from Gerbil source.
(def +provider-entry-modules+
  '("src/provider-server"
    "src/cli"
    "src/cli-dev-linker"
    "src/cli-install-linker"
    "src/cli-query"
    "src/cli-release-linker"
    "src/runtime/provider-operation"
    "src/runtime/provider-http-json-server"
    "src/commands/provider-runtime"
    "src/search-light-launcher"
    "src/cli-launcher"
    "src/building/provider-package-spec"))

(def (asp-gerbil-scheme-source-modules)
  (filter (cut string-prefix? "src/" <>) (all-gerbil-modules)))

(asp-gerbil-scheme-package-spec! asp-gerbil-scheme-library-package-spec
  (role 'library)
  (native-spec
   (fold (lambda (module spec)
           (remove-build-file spec module))
         (asp-gerbil-scheme-source-modules)
         +provider-entry-modules+)))
