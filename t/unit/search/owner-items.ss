;;; -*- Gerbil -*-
;;; Owner-items fast-path unit checks.
;;; These tests guard launcher shape and parser-owned owner item limits.

(import :gerbil/gambit
        :gslph/src/commands/guide-sections
        :gslph/src/commands/search-owner-items
        :gslph/src/parser/owner-items
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/1 find)
        (only-in :std/srfi/13 string-contains string-index string-prefix?)
        :std/test)

(export check-owner-items-limit-budget
        check-owner-items-limit-zero-skips-call-collection
        check-owner-items-query-ignores-selected-owner-path
        check-owner-items-limited-parser-skips-recursive-call-projection
        check-owner-items-gerbil-package-facts
        check-owner-items-fast-entrypoint-stays-light
        check-cli-launcher-search-fast-path-stays-canonical
        check-search-fast-path-build-boundary
        check-search-light-uses-bounded-preview
        check-owner-items-omits-empty-role-field
        check-owner-items-definition-next-command-uses-structural-selector
        check-guide-sections-static-data-loads
        check-search-guide-fast-entrypoint-stays-light)

;; FixturePath
(def +owner-items-fixture+ "t/fixtures/parser/complex-syntax.ss")

;; : (-> Unit )
(def (check-owner-items-limit-budget)
  (let* ((file (parse-owner-items-source-file "."
                                              (path-expand +owner-items-fixture+ ".")))
         (all (matching-owner-syntax-facts file '()))
         (limited (matching-owner-syntax-facts file '() 3)))
    (check (> (length all) 3) => #t)
    (check (length limited) => 3)
    (check (owner-item-query-terms "projection|chain receipt")
           => ["projection" "chain" "receipt"])
    (check (owner-item-query-terms "one|two|three|four|five|six|seven")
           => ["one" "two" "three" "four" "five" "six"])))

;; : (-> Unit )
(def (check-owner-items-limit-zero-skips-call-collection)
  (let* ((file (parse-owner-items-source-file "."
                                              (path-expand +owner-items-fixture+ ".")
                                              0
                                              ["call"]))
         (facts (matching-owner-syntax-facts file ["call"] 0)))
    (check (length (source-file-calls file)) => 0)
    (check facts => [])))

;; : (-> Unit )
(def (check-owner-items-query-ignores-selected-owner-path)
  (let* ((file (parse-owner-items-source-file "."
                                              (path-expand +owner-items-fixture+ ".")))
         (facts (matching-owner-syntax-facts file ["complex-syntax"] 20)))
    (check facts => [])))

;; : (-> Unit )
(def (check-owner-items-limited-parser-skips-recursive-call-projection)
  (let* ((file (parse-owner-items-source-file
                "."
                (path-expand "src/parser/selectors.ss" ".")
                4
                ["selector-from"]))
         (definition
          (find (lambda (defn)
                  (equal? (definition-name defn) "selector-from"))
                (source-file-definitions file))))
    (check (source-file-calls file) => [])
    (check (not (not definition)) => #t)))

;;; Regression: gerbil.pkg is a package owner, not an empty config blob.
;;; Owner-items should expose package metadata through parser-owned facts so
;;; agents can query dependencies and policy without raw file reads.
;; : (-> Unit )
(def (check-owner-items-gerbil-package-facts)
  (let* ((file (parse-owner-items-source-file "." "gerbil.pkg"))
         (facts (matching-owner-syntax-facts file ["gerbil.pkg"] 10 "."))
         (package-fact
          (find (lambda (fact)
                  (equal? (hash-get fact 'kind) "package"))
                facts)))
    (check (not (not package-fact)) => #t)
    (check (hash-get package-fact 'name)
           => "gerbil-scheme-language-project-harness")
    (check (not (not (member "git.cons.io/mighty-gerbils/gerbil-poo"
                              (hash-get package-fact 'queryKeys))))
           => #t)
    (check (not (not (member "source-scope"
                              (hash-get package-fact 'queryKeys))))
           => #t)))

;; : (-> Unit )
(def (check-owner-items-fast-entrypoint-stays-light)
  (let (source
        (call-with-input-file
            "src/search-fast/gerbil-scheme-search-owner-items.ss"
          read-all-as-string))
    (check (source-contains? source ":gslph/src/commands/search-owner-items") => #t)
    (check (source-contains? source ":gslph/src/parser/owner-items") => #f)
    (check (source-contains? source ":gslph/src/parser/facade") => #f)
    (check (source-contains? source ":gslph/src/commands/search\n") => #f)
    (check (source-contains? source ":gslph/src/commands/search ") => #f)
    (check (source-contains? source ":gslph/src/commands/search)") => #f)
    (check (source-contains? source ":gslph/src/cli") => #f)))

;; : (-> Unit )
(def (check-cli-launcher-search-fast-path-stays-canonical)
  (let (source
        (call-with-input-file "src/cli-launcher.ss" read-all-as-string))
    (check (source-contains? source ":gslph/src/search-light-launcher") => #t)
    (check (source-contains? source "(only-in :gslph/src/cli") => #f)
    (check (source-contains? source "try-search-light-main") => #t)
    (check (source-contains? source "(def (command-line-args argv)") => #t)
    (check (source-contains? source "\"search\"") => #t)
    (check (source-contains? source "dispatch-native-command") => #t)
    (check (source-contains? source "emit-missing-command-binary") => #t)
    (check (source-contains? source "try-sibling-command-binary") => #t)
    (check (source-contains? source ":gslph/src/commands/search-owner-items") => #f)
    (check (source-contains? source "native-search-owner-items-argv?") => #f)
    (check (source-contains? source "gslph search requires sibling binary") => #f)
    (check (source-contains? source "src/cli.ss") => #f)
    (check (source-contains? source "gerbil-scheme-harness") => #f)))

;; : (-> Unit )
(def (check-search-fast-path-build-boundary)
  (let (source
        (call-with-input-file "build.ss" read-all-as-string))
    (check (source-contains? source ":std/make") => #t)
    (check (source-contains? source "(def cli-spec\n  '((exe: \"cli-launcher\" bin: \"gslph\")))") => #t)
    (check (source-contains? source "(def cli-bootstrap-modules") => #t)
    (check (source-contains? source "\"search-light-launcher.ss\"") => #t)
    (check (source-contains? source "\"cli-launcher.ss\"") => #t)
    (check (source-contains? source "(def excluded-library-files") => #t)
    (check (source-contains? source "\"cli.ss\"") => #t)
    (check (source-contains? source "(def (package-build-spec)\n  (append (runtime-library-spec) cli-spec))") => #t)
    (check (source-contains? source "(def (compile-spec full? release? binary?)") => #t)
    (check (source-contains? source "(binary? cli-spec)") => #t)
    (check (source-contains? source "build-release: effective-release?") => #t)
    (check (source-contains? source "build-optimized: effective-optimized?") => #t)
    (check (source-contains? source "parallelize: worker-count") => #t)
    (check (source-contains? source "sync-build-worker-count!") => #t)
    (check (source-contains? source "__available-cores") => #t)
    (check (source-contains? source "run-build-impl") => #f)
    (check (source-contains? source "build-impl.ss") => #f)
    (check (source-contains? source "(def (static-cli-launcher-spec)") => #f)
    (check (source-contains? source "(static-cli-launcher-spec)") => #f)
    (check (source-contains? source "(def search-launcher-spec") => #f)
    (check (source-contains? source "(def (search-acceleration-spec release?)") => #f)
    (check (source-contains? source "(def launcher-spec") => #f)
    (check (source-contains? source "(def (static-launcher-spec)") => #f)))

;; : (-> Unit )
(def (check-search-light-uses-bounded-preview)
  (let (source
        (call-with-input-file "src/commands/search-prime-light.ss" read-all-as-string))
    (check (source-contains? source "collect-source-files-preview") => #t)
    (check (source-contains? source "filePreview=") => #t)
    (check (source-contains? source ":gslph/src/parser/package") => #f)
    (check (source-contains? source ":gslph/src/parser/source-scope") => #f)
    (check (source-contains? source ":gslph/src/parser/source-class") => #f)
    (check (source-contains? source ":gslph/src/support/args") => #f)
    (check (source-contains? source ":std/sugar") => #f)
    (check (source-contains? source "(hash") => #f)))

;; : (-> Unit )
(def (check-owner-items-omits-empty-role-field)
  (let* ((file (parse-owner-items-source-file
                (path-expand +owner-items-fixture+)))
         (facts (matching-owner-syntax-facts file ["call"] 4))
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (emit-owner-items file [] facts 4))))))
        (check (> (length facts) 0) => #t)
        (check (source-contains? output " languageKind=call") => #t)
        (check (source-contains? output " evidenceSelector=gerbil-scheme://") => #t)
        (check (source-contains? output " graphOnly=true") => #t)
        (check (source-contains? output " selector=gerbil-scheme://") => #f)
        (check (source-contains? output " enclosingReadSelector=") => #f)
        (check (source-contains? output " nextCommand=\"asp gerbil-scheme query --selector ") => #f)
        (check (source-contains? output " role=") => #f)))

;; : (-> Unit )
(def (check-owner-items-definition-next-command-uses-structural-selector)
  (let* ((file (parse-owner-items-source-file "."
                                              (path-expand "src/parser/selectors.ss" ".")
                                              4
                                              ["selector-from"]))
         (definitions [(find (lambda (defn)
                               (equal? (definition-name defn) "selector-from"))
                             (source-file-definitions file))])
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (emit-owner-items file definitions [] 4))))))
    (check (source-contains?
            output
            "readSelector=gerbil-scheme://src/parser/selectors.ss#item/def/selector-from")
           => #t)
    (check (source-contains?
            output
            "nextCommand=\"asp gerbil-scheme query --selector gerbil-scheme://src/parser/selectors.ss#item/def/selector-from --workspace . --projection source\"")
           => #t)
    (check (source-contains? output "selector=selector-from") => #f)))

;; : (-> Unit )
(def (check-search-guide-fast-entrypoint-stays-light)
  (let (source
        (call-with-input-file
            "src/search-fast/gerbil-scheme-search-guide.ss"
          read-all-as-string))
    (check (source-contains? source ":gslph/src/commands/guide-sections") => #t)
    (check (source-contains? source ":gslph/src/commands/search\n") => #f)
    (check (source-contains? source ":gslph/src/commands/search ") => #f)
    (check (source-contains? source ":gslph/src/commands/search)") => #f)
    (check (source-contains? source ":gslph/src/cli") => #f)))

;; : (-> Unit )
(def (check-guide-sections-static-data-loads)
  (let (lines (guide-section-lines-for ["--poo"]))
    (check (car lines) => "gerbil-scheme-harness guide")
    (check (not (not (member "|cmd pattern-poo=gerbil-scheme-harness search pattern poo [term ...] --view seeds"
                              lines)))
           => #t)
    (check (not (not (member "|policy poo-structural-facts=search structural --owner <path> --json exposes parser-owned POO forms as custom/generic/method owner facts with role,supers,slots,options,specializers,specializerTypes,dispatchArity; query owner facts before editing POO object/type/method forms"
                              lines)))
           => #t)))

;; : (-> SourceText Needle Boolean )
(def (source-contains? source needle)
  (and (string-contains source needle) #t))
