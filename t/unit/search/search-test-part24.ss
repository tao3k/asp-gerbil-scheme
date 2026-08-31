(import :std/test
        :std/srfi/13
        :asp-gerbil-scheme/src/commands/search)

(export search-test-part-24)

(def (search-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (search-main args)))))))
    (check status => 0)
    output))

(def (contains? text part)
  (and (string-contains text part) #t))

(def search-test-part-24
  (test-suite "gerbil scheme harness prime seeds JSON"
    (test-case "prime seeds JSON remains package-only"
      (let (output
            (search-output
             ["prime" "--view" "seeds" "--json" "--workspace" "."]))
        (check (contains? output "\"projectPackage\"") => #t)
        (check (contains? output "\"extensions\"") => #t)
        (check (contains? output "\"packageManager\":\"gxpkg\"") => #t)
        (check (contains? output "\"name\":\"poo\"") => #t)
        (check (contains? output "\"owners\":[]") => #t)))))
