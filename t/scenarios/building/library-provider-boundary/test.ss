(import :std/test
        :clan/poo/object
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/building/package-spec
        :asp-gerbil-scheme/src/building/project-package-spec)

(export library-provider-boundary-test)

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

(def library-provider-boundary-test
  (test-suite "library-default and explicit-provider build boundary"
    (test-case "default package spec contains no provider entry modules"
      (let (library-spec
            (asp-gerbil-scheme-package-native-spec
             asp-gerbil-scheme-library-package-spec))
        (check (.get asp-gerbil-scheme-library-package-spec role) => 'library)
        (for-each
         (lambda (module)
           (check (member module library-spec) => #f))
         +provider-entry-modules+)))))
