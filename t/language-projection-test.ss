;;; -*- Gerbil -*-
;;; Native parser projection contract tests.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/commands/projection
        :asp-gerbil-scheme/src/parser/language-projection
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/13 string-contains string-prefix?)
        (only-in :std/sugar hash-get hash-key?)
        :std/test)

(export language-projection-test)

(def +projection-fixture+ "t/fixtures/parser/projection-burst.ss")

(def language-projection-test
  (test-suite "native parser language projection"
    (test-case "projection publishes only query-free parser facts"
      (let ((projection (parse-owner-language-projection "." +projection-fixture+)))
        (check (hash-get projection 'schemaId)
               => "agent.semantic-protocols.semantic-language-projection")
        (check (hash-get projection 'languageId) => "gerbil-scheme")
        (check (hash-key? projection 'query) => #f)
        (check (hash-key? projection 'artifact) => #f)
        (check (hash-key? projection 'workspace) => #f)
        (check (hash-key? projection 'rank) => #f)))
    (test-case "projection preserves native structural selectors"
      (let* ((projection (parse-owner-language-projection "." +projection-fixture+))
             (items (hash-get projection 'items))
             (relations (hash-get projection 'relations))
             (first-item (car items)))
        (check (> (length items) 0) => #t)
        (check (string-prefix? "gerbil-scheme://" (hash-get first-item 'selector))
               => #t)
        (check (> (length relations) 1) => #t)))
    (test-case "projection command emits only the machine artifact"
      (let ((output
             (call-with-output-string
              (lambda (port)
                (parameterize ((current-output-port port))
                  (check (projection-main
                          [+projection-fixture+ "--workspace" "." "--json"])
                         => 0))))))
        (check (source-contains?
                output
                "agent.semantic-protocols.semantic-language-projection")
               => #t)
        (check (source-contains? output "\"query\"") => #f)
        (check (source-contains? output "\"rank\"") => #f)))
    (test-case "fmt does not import projection or ASP lifecycle state"
      (let ((source (call-with-input-file "src/commands/fmt.ss" read-all-as-string)))
        (check (source-contains? source "parser/language-projection") => #f)
        (check (source-contains? source "semantic-language-projection") => #f)
        (check (source-contains? source "source-index") => #f)
        (check (source-contains? source "turso") => #f)))))

(def (source-contains? source needle)
  (and (string-contains source needle) #t))
