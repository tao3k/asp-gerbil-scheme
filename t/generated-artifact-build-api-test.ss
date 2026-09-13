;;; -*- Gerbil -*-
;;; Verified expansion-artifact and native BuildSpec projection contracts.

(import :gerbil/gambit
        (only-in :std/test test-suite test-case check check-exception)
        (only-in :std/misc/path path-directory path-expand)
        "../src/build-api/generated-artifact"
        (only-in "../src/build-api/package-spec"
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(export generated-artifact-build-api-test)

(def +generated-artifact-test-root+
  (path-expand
   (string-append
    ".cache/agent-semantic-protocol/test/generated-artifact/"
    (number->string (current-jiffy)) "-"
    (number->string (random-integer 1073741824)))
   (current-directory)))

(def (generated-artifact-test-ensure-directory! path)
  (unless (file-exists? path)
    (create-directory* path)))

(def (generated-artifact-test-write-datum! path value)
  (generated-artifact-test-ensure-directory! (path-directory path))
  (call-with-output-file
   path
   (lambda (output)
     (write value output)
     (newline output)
     (force-output output))))

(def (generated-artifact-test-read-datum path)
  (call-with-input-file path read))

(def (generated-artifact-test-receipt-ref receipt key)
  (cdr (assq key receipt)))

(def (generated-artifact-test-artifact-root case-name)
  (path-expand (string-append case-name "/artifacts")
               +generated-artifact-test-root+))

(def (generated-artifact-test-bundle case-name input-identity locator
                                     (validator pair?))
  (let (artifact-root
        (generated-artifact-test-artifact-root case-name))
    (asp-gerbil-scheme-generated-artifact-bundle
     namespace: case-name
     producer-identity: '((module . "test-generator")
                          (version . "v1"))
     input-identity: input-identity
     members:
     [(asp-gerbil-scheme-generated-artifact-member
       name: 'grammar
       schema: "test.generated-grammar.v1"
       validator: validator)]
     artifact-roots: [artifact-root]
     receipt-root: +generated-artifact-test-root+
     materializer:
     (lambda (_member value roots)
       (generated-artifact-test-write-datum!
        (path-expand locator (car roots))
        value)
       locator)
     loader:
     (lambda (_member member-locator roots)
       (generated-artifact-test-read-datum
        (path-expand member-locator (car roots))))
     artifact-paths:
     (lambda (_member member-locator)
       [member-locator]))))

(asp-gerbil-scheme-package-spec!
 (generated-artifact-package-spec
  @ asp-gerbil-scheme-library-package-prototype)
 (spec generated-artifact-package-build-spec)
 (modules ["plain.ss" "generated.ss"])
 (generated-modules
  [(asp-gerbil-scheme-verified-generated-module
    module: "generated.ss"
    extra-inputs: ["cache/grammar.gir.z"])]))

(def generated-artifact-build-api-test
  (test-suite "verified generated artifact build api"
    (test-case "materializes once and reuses only verified bytes"
      (let* ((bundle
              (generated-artifact-test-bundle
               "reuse" '((grammarDigest . "input-a")) "grammar-a.ss"))
             (producer-count 0)
             (producer
              (lambda ()
                (set! producer-count (+ producer-count 1))
                ['(artifact input-a)])))
        (let* ((generated
                (asp-gerbil-scheme-resolve-generated-artifact-bundle!
                 bundle producer))
               (receipt
                (asp-gerbil-scheme-generated-artifact-resolution-receipt
                 generated)))
          (check
           (asp-gerbil-scheme-generated-artifact-resolution-status generated)
           => 'generated)
          (check (generated-artifact-test-receipt-ref receipt 'schema)
                 => asp-gerbil-scheme-generated-artifact-receipt-schema)
          (check (generated-artifact-test-receipt-ref receipt 'key)
                 => (asp-gerbil-scheme-generated-artifact-resolution-key
                     generated))
          (check (length
                  (generated-artifact-test-receipt-ref receipt 'artifacts))
                 => 1))
        (check producer-count => 1)
        (check
         (asp-gerbil-scheme-generated-artifact-resolution-status
          (asp-gerbil-scheme-resolve-generated-artifact-bundle!
           bundle producer))
         => 'reused)
        (check producer-count => 1)))
    (test-case "canonical input identity participates in the cache key"
      (let ((first
             (generated-artifact-test-bundle
              "input-key" '((grammarDigest . "input-a")) "a.ss"))
            (second
             (generated-artifact-test-bundle
              "input-key" '((grammarDigest . "input-b")) "b.ss")))
        (check
         (equal? (asp-gerbil-scheme-generated-artifact-key first)
                 (asp-gerbil-scheme-generated-artifact-key second))
         => #f)))
    (test-case "tampered bytes cannot be reused without the producer"
      (let* ((locator "grammar.ss")
             (bundle
              (generated-artifact-test-bundle
               "tamper" '((grammarDigest . "tamper")) locator
               (lambda (value)
                 (equal? value '(artifact original)))))
             (artifact-path
              (path-expand locator
                           (generated-artifact-test-artifact-root "tamper"))))
        (asp-gerbil-scheme-resolve-generated-artifact-bundle!
         bundle (lambda () ['(artifact original)]))
        (generated-artifact-test-write-datum! artifact-path '(artifact forged))
        (check-exception
         (asp-gerbil-scheme-resolve-generated-artifact-bundle!
          bundle (lambda () (error "producer unavailable")))
         true)
        (check
         (asp-gerbil-scheme-generated-artifact-resolution-status
          (asp-gerbil-scheme-resolve-generated-artifact-bundle!
           bundle (lambda () ['(artifact original)])))
         => 'generated)))
    (test-case "post-materialization validation fails closed"
      (let (bundle
            (generated-artifact-test-bundle
             "invalid" '((grammarDigest . "invalid")) "grammar.ss"
             (lambda (value)
               (equal? value '(artifact admitted)))))
        (check-exception
         (asp-gerbil-scheme-resolve-generated-artifact-bundle!
         bundle (lambda () ['(artifact rejected)]))
         true)))
    (test-case "one cache key cannot publish two valid byte identities"
      (let* ((locator "grammar.ss")
             (bundle
              (generated-artifact-test-bundle
               "conflict" '((grammarDigest . "conflict")) locator))
             (artifact-path
              (path-expand
               locator
               (generated-artifact-test-artifact-root "conflict"))))
        (asp-gerbil-scheme-resolve-generated-artifact-bundle!
         bundle (lambda () ['(artifact first)]))
        (generated-artifact-test-write-datum! artifact-path '(artifact second))
        (check-exception
         (asp-gerbil-scheme-resolve-generated-artifact-bundle!
          bundle (lambda () ['(artifact second)]))
         true)))
    (test-case "artifact locators cannot escape an owned root"
      (let (bundle
            (generated-artifact-test-bundle
             "escape" '((grammarDigest . "escape")) "../escape.ss"))
        (check-exception
         (asp-gerbil-scheme-resolve-generated-artifact-bundle!
          bundle (lambda () ['(artifact escape)]))
         true)))
    (test-case "projection preserves every native target and option"
      (let* ((declaration
              (asp-gerbil-scheme-verified-generated-module
               module: "generated"
               extra-inputs: ["cache/grammar.gir.z" "existing.input"]))
             (spec
              ["plain"
               [gxc: "generated"
                     [extra-inputs: ["existing.input"] optimize: #f]
                     verbose: #t]
               [gxc: "tail" [debug: #t]]])
             (projected
              (asp-gerbil-scheme-project-generated-modules
               spec [declaration])))
        (check (length projected) => (length spec))
        (check (car projected) => (car spec))
        (check (caddr projected) => (caddr spec))
        (check
         (cadr projected)
         => [gxc: "generated"
                  [extra-inputs:
                   ["existing.input" "cache/grammar.gir.z"]
                   optimize: #f]
                  verbose: #t])))
    (test-case "PackageSpec projects declarations without graph admission"
      (let (spec (generated-artifact-package-build-spec))
        (check (length spec) => 2)
        (check (car spec) => "plain.ss")
        (check (cadr spec)
               => [gxc: "generated.ss"
                        [extra-inputs: ["cache/grammar.gir.z"]]])))
    (test-case "projection rejects ambiguous target ownership"
      (let (declaration
            (asp-gerbil-scheme-verified-generated-module
             module: "generated"
             extra-inputs: ["cache/grammar.gir.z"]))
        (check-exception
         (asp-gerbil-scheme-project-generated-modules
          ["plain"] [declaration])
         true)
        (check-exception
         (asp-gerbil-scheme-project-generated-modules
          ["generated" [gxc: "generated"]] [declaration])
         true)))))
