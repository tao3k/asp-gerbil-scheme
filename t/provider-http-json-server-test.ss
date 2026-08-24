;;; -*- Gerbil -*-

(export provider-http-json-server-test)

(import :gerbil/gambit
        :gslph/src/commands/projection-batch
        :gslph/src/runtime/provider-http-json-server
        :gslph/src/runtime/provider-operation
        (only-in :std/format format)
        (only-in :std/misc/path path-expand)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)
        (only-in :std/sugar hash hash-key?)
        (only-in :std/text/base64 base64-encode)
        (only-in :std/text/json read-json write-json)
        (only-in :gslph/src/support/time
                 duration-micros
                 monotonic-micros)
        :std/test)

(def +artifact-digest+
  "blake3-256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
(def +registration-digest+
  "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
(def +contract-digest+
  "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc")

;; HTTP/live-corpus acceptance consumes an artifact already admitted by the
;; workspace build/install boundary. It must never make a test invocation
;; silently enter the native executable linker path.
(def (provider-test-artifact package-root)
  (let (artifact
        (or (getenv "ASP_PROVIDER_TEST_ARTIFACT" #f)
            (path-expand
             "build/workspace-provider/bin/asp-gerbil-scheme"
             package-root)))
    (unless (file-exists? artifact)
      (error
       "provider-http-json-server-test-artifact-required: materialize the workspace provider artifact first with ASP_PROVIDER_ARTIFACT_ROOT=<artifact-root> /usr/bin/env -u SDKROOT gxi build.ss"
       artifact))
    artifact))

(def (provider-environment package-root artifact include-contract?)
  (append
  (list "env"
         "-u"
         "ASP_PROVIDER_ARTIFACT_DIGEST"
         "-u"
         "ASP_PROVIDER_REGISTRATION_DIGEST"
         "-u"
         "ASP_PROVIDER_RUNTIME_CONTRACT_DIGEST"
         "ASP_CLIENT_SERVER_HOST=127.0.0.1:0"
         "ASP_PROVIDER_ID=asp-gerbil-scheme"
         "ASP_PROVIDER_LANGUAGE_ID=gerbil-scheme")
   (if include-contract?
       (list (string-append "ASP_PROVIDER_ARTIFACT_DIGEST=" +artifact-digest+)
             (string-append "ASP_PROVIDER_REGISTRATION_DIGEST=" +registration-digest+)
             (string-append "ASP_PROVIDER_RUNTIME_CONTRACT_DIGEST=" +contract-digest+))
       '())
   (list artifact "serve")))

(def (http-get-json url)
  (read-json
   (open-input-string
    (run-process
     (list "curl" "--fail-with-body" "--silent" "--show-error" url)
     coprocess: read-all-as-string
     stderr-redirection: #t))))

(def (http-post-json url body)
  (read-json
   (open-input-string
    (run-process
     (list "curl"
           "--fail-with-body"
           "--silent"
           "--show-error"
           "--header"
           "content-type: application/json"
           "--data"
           body
           url)
     coprocess: read-all-as-string
     stderr-redirection: #t))))

(def (json-string value)
  (call-with-output-string
   (lambda (port) (write-json value port))))

(def (read-bootstrap-json process)
  (let (line (read-line process))
    (unless (and (string? line)
                 (> (string-length line) 0)
                 (char=? (string-ref line 0) #\{))
      (error "provider bootstrap is not a JSON object line" line))
    (with-catch
     (lambda (exception)
       (error "provider bootstrap JSON decode failed" line exception))
     (lambda ()
       (read-json (open-input-string line))))))

(def (file-bytes path)
  (string->utf8
   (call-with-input-file path read-all-as-string)))

(def (owner-header path bytes)
  (hash ("ownerPath" path)
        ("sourceLeafDigest" (string-append "digest:" path))
        ("sourceText" (utf8->string bytes))))

(def (live-corpus-request package-root request-id
                          (generation-root "live-corpus-generation"))
  (let* ((path-a "t/fixtures/std-builder-topology/a.ss")
         (path-b "t/fixtures/std-builder-topology/b.ss")
         (source-a (file-bytes (path-expand path-a package-root)))
         (source-b (file-bytes (path-expand path-b package-root)))
         (header
          (hash ("schemaId" +request-schema-id+)
                ("schemaVersion" "1")
                ("languageId" +language-id+)
                ("providerId" +provider-id+)
                ("generationRootDigest" generation-root)
                ("parserIdentityDigest" "live-corpus-parser")
                ("queryPackDigest" "live-corpus-query-pack")
                ("owners" (vector (owner-header path-a source-a)
                                   (owner-header path-b source-b))))))
    (json-string
     (hash ("schemaId" "agent.semantic-protocols.provider-runtime-request-frame")
           ("schemaVersion" "1")
           ("requestId" request-id)
           ("operation" "projection-batch")
           ("payload" header)))))

(def (exact-query-request request-id projection-kind)
  (let* ((owner-path "src/sample.ss")
         (selector "gerbil-scheme://src/sample.ss#item/function/sample")
         (source "(def (sample value) (+ value 1))\n")
         (source-bytes (string->utf8 source)))
    (json-string
     (hash
      ("schemaId" "agent.semantic-protocols.provider-runtime-request-frame")
      ("schemaVersion" "1")
      ("requestId" request-id)
      ("operation" "query")
      ("payload"
       (hash
        ("schemaId" "agent.semantic-protocols.provider-native-exact-request")
        ("schemaVersion" "1")
        ("languageId" "gerbil-scheme")
        ("providerId" "asp-gerbil-scheme")
        ("projectionKind" projection-kind)
        ("structuralSelector" selector)
        ("ownerPath" owner-path)
        ("generationIdentityDigest" (make-string 64 #\a))
        ("parserIdentityDigest" (make-string 64 #\b))
        ("queryPackDigest" (make-string 64 #\c))
        ("sourceDigest" (make-string 64 #\d))
        ("sourceByteLength" (u8vector-length source-bytes))
        ("sourceEncoding" "base64")
        ("sourceBytesBase64" (base64-encode source-bytes))
        ("transport" "stdin-json")))))))

(def (read-nonempty-line port)
  (let (line (read-line port))
    (cond
     ((eof-object? line) (error "timed HTTP response omitted latency"))
     ((zero? (string-length line)) (read-nonempty-line port))
     (else line))))

(def (curl-transfer-arguments url body first?)
  (append
   (if first? '() '("--next"))
   (list "--http1.1"
         "--fail-with-body"
         "--silent"
         "--show-error"
         "--max-time"
         "2"
         "--header"
         "content-type: application/json"
         "--data"
         body
         "--write-out"
         "\n%{time_total}\n"
         url)))

(def (warm-live-corpus-samples endpoint body warm-count sample-count)
  (let* ((url (string-append endpoint "v1/provider-runtime"))
         (total (+ warm-count sample-count))
         (arguments
          (let build ((remaining total) (first? #t) (result '("curl")))
            (if (zero? remaining)
                result
                (build (- remaining 1)
                       #f
                       (append result
                               (curl-transfer-arguments url body first?))))))
         (output
          (run-process arguments
                       coprocess: read-all-as-string
                       stderr-redirection: #t))
         (port (open-input-string output)))
    (let parse ((index 0) (samples '()))
      (if (= index total)
          (reverse samples)
          (let* ((response (read-json port))
                 (elapsed-seconds
                  (string->number (read-nonempty-line port)))
                 (elapsed
                  (inexact->exact (round (* elapsed-seconds 1000000.0)))))
            (unless (string=? (hash-ref response "outcome") "ready")
              (error "live corpus provider request failed" response))
            (parse (+ index 1)
                   (if (< index warm-count)
                       samples
                       (cons elapsed samples))))))))

(def (direct-live-corpus-samples body warm-count sample-count)
  (let ((request-value (read-json (open-input-string body)))
        (total (+ warm-count sample-count)))
    (let loop ((index 0) (samples '()))
      (if (= index total)
          (reverse samples)
          (let* ((started (monotonic-micros))
                 (response (provider-runtime-request->response request-value))
                 (elapsed (duration-micros started (monotonic-micros))))
            (unless (string=? (hash-ref response "outcome") "ready")
              (error "direct live corpus provider request failed" response))
            (loop (+ index 1)
                  (if (< index warm-count)
                      samples
                      (cons elapsed samples))))))))

(def (insert-latency value sorted)
  (cond
   ((null? sorted) (list value))
   ((<= value (car sorted)) (cons value sorted))
   (else (cons (car sorted) (insert-latency value (cdr sorted))))))

(def (sort-latencies values)
  (let loop ((rest values) (sorted '()))
    (if (null? rest)
        sorted
        (loop (cdr rest) (insert-latency (car rest) sorted)))))

(def (latency-percentile sorted percentile)
  (list-ref sorted
            (quotient (* (- (length sorted) 1) percentile) 100)))

(def (concurrent-live-corpus-responses endpoint body count)
  (let spawn ((remaining count) (threads '()))
    (if (zero? remaining)
        (map thread-join! threads)
        (let (thread
              (make-thread
               (lambda ()
                 (http-post-json
                  (string-append endpoint "v1/provider-runtime")
                  body))))
          (thread-start! thread)
          (spawn (- remaining 1) (cons thread threads))))))

(def (all-ready? responses)
  (or (null? responses)
      (and (string=? (hash-ref (car responses) "outcome") "ready")
           (all-ready? (cdr responses)))))

(def provider-http-json-server-test
  (test-suite
   "provider HTTP JSON server"
   (test-case
   "bootstrap health runtime request and shutdown share one server lifecycle"
(let* ((package-root (current-directory))
       (artifact (provider-test-artifact package-root)))
      (run-process
       (provider-environment package-root artifact #t)
       directory: package-root
       coprocess:
       (lambda (process)
       (let* ((bootstrap (read-bootstrap-json process))
                (endpoint (hash-ref bootstrap "endpoint"))
                (health (http-get-json (string-append endpoint "health")))
                (invalid (http-post-json
                          (string-append endpoint "v1/provider-runtime")
                          "{}"))
                (shutdown (http-post-json
                           (string-append endpoint "shutdown")
                           "{}")))
           (check (hash-ref bootstrap "schemaVersion") => "1")
           (check (hash-ref bootstrap "state") => "ready")
           (check (hash-ref bootstrap "transport") => "http-json")
           (check (hash-ref health "artifactDigest") => +artifact-digest+)
           (check (hash-ref health "registrationDigest") => +registration-digest+)
           (check (hash-ref health "contractDigest") => +contract-digest+)
           (let ((operations (hash-ref health "operations")))
             (check (length operations) => 3)
             (check (hash-ref (car operations) "operation") => "projection-batch")
             (check (hash-ref (car operations) "requestSchemaId")
                    => "https://schemas.agent-semantic-protocols.dev/provider-language-projection-batch-request.schema.json")
             (check (hash-ref (car operations) "responseSchemaId")
                    => "https://schemas.agent-semantic-protocols.dev/provider-language-projection-batch-response.schema.json")
             (check (hash-ref (cadr operations) "operation") => "project-resolution")
             (check (hash-ref (cadr operations) "requestSchemaId")
                    => "https://schemas.agent-semantic-protocols.dev/provider-project-resolution-request.schema.json")
             (check (hash-ref (cadr operations) "responseSchemaId")
                    => "https://schemas.agent-semantic-protocols.dev/provider-project-resolution-response.schema.json")
             (check (hash-ref (caddr operations) "operation") => "query")
             (check (hash-ref (caddr operations) "requestSchemaId")
                    => "https://agent-semantic-protocols.dev/schemas/provider-native-exact-request.v1.schema.json")
             (check (hash-ref (caddr operations) "responseSchemaId")
                    => "https://agent-semantic-protocols.dev/schemas/provider-native-exact-response.v1.schema.json"))
           (check (hash-ref invalid "schemaVersion") => "1")
           (check (hash-ref invalid "outcome") => "error")
           (check (string? (hash-ref invalid "error" #f)) => #t)
           (check (> (string-length (hash-ref invalid "error" "")) 0) => #t)
           (check (hash-ref shutdown "state") => "draining")
           (read-all-as-string process))))))
   (test-case
    "exact source and callable skeleton query share the resident HTTP lifecycle"
    (let* ((package-root (current-directory))
           (artifact (provider-test-artifact package-root)))
      (run-process
       (provider-environment package-root artifact #t)
       directory: package-root
       coprocess:
       (lambda (process)
         (let* ((bootstrap (read-bootstrap-json process))
                (endpoint (hash-ref bootstrap "endpoint"))
                (source-response
                 (http-post-json
                  (string-append endpoint "v1/provider-runtime")
                  (exact-query-request "exact-source" "source")))
                (skeleton-response
                 (http-post-json
                  (string-append endpoint "v1/provider-runtime")
                  (exact-query-request "exact-skeleton" "callable-skeleton")))
                (shutdown
                 (http-post-json (string-append endpoint "shutdown") "{}")))
           (for-each
            (lambda (response)
              (check (hash-ref response "outcome") => "ready")
              (let* ((payload (hash-ref response "payload"))
                     (facts (hash-ref payload "normalizedParserFacts")))
                (check (hash-ref payload "ownerPath") => "src/sample.ss")
                (check (hash-ref payload "resolutionState") => "resolved")
                (check (hash-ref facts "itemName") => "sample")
                (check (hash-ref facts "ownerPath") => "src/sample.ss")))
            (list source-response skeleton-response))
           (check (hash-ref (hash-ref source-response "payload") "projectionText")
                  => "(def (sample value) (+ value 1))\n")
           (check (hash-table?
                   (hash-ref (hash-ref skeleton-response "payload")
                             "projectionPayload"))
                  => #t)
           (check (hash-ref shutdown "state") => "draining")
           (read-all-as-string process))))))
   (test-case
   "warm live corpus projection stays below one millisecond"
    (let* ((package-root (current-directory))
           (artifact (provider-test-artifact package-root))
           (body (live-corpus-request package-root "live-corpus-warm"))
           (direct-response
            (provider-runtime-request->response
             (read-json (open-input-string body))))
           (service-samples (direct-live-corpus-samples body 16 128))
           (service-sorted (sort-latencies service-samples))
           (service-maximum (apply max service-samples))
           (memo-stats
            (gslph/src/runtime/provider-operation#provider-runtime-projection-memo-stats)))
      (check (hash-ref direct-response "outcome") => "ready")
      (displayln
        (format "[provider-projection-memo-input] requestBytes=~a responsePayloadBytes=~a entries=~a hits=~a misses=~a"
                (string-length body)
                (string-length (json-string (hash-ref direct-response "payload")))
                (hash-ref memo-stats "entries")
               (hash-ref memo-stats "hits")
               (hash-ref memo-stats "misses")))
      (check (> (hash-ref memo-stats "hits") 0) => #t)
      (run-process
       (provider-environment package-root artifact #t)
       directory: package-root
       coprocess:
       (lambda (process)
       (let* ((bootstrap (read-bootstrap-json process))
                (endpoint (hash-ref bootstrap "endpoint")))
           (with-catch
            (lambda (error)
              (with-catch
               (lambda (_) #f)
               (lambda ()
                 (http-post-json (string-append endpoint "shutdown") "{}")))
              (raise error))
            (lambda ()
              (let* ((samples (warm-live-corpus-samples endpoint body 16 128))
                     (sorted (sort-latencies samples))
                     (p50 (latency-percentile sorted 50))
                     (p95 (latency-percentile sorted 95))
                     (p99 (latency-percentile sorted 99))
                     (maximum (apply max samples)))
                (displayln
                 (format
                  "[provider-live-corpus] schemaVersion=1 provider=asp-gerbil-scheme owners=2 samples=128 serviceP50Micros=~a serviceP95Micros=~a serviceP99Micros=~a serviceMaxMicros=~a loopbackP50Micros=~a loopbackP95Micros=~a loopbackP99Micros=~a loopbackMaxMicros=~a"
                  (latency-percentile service-sorted 50)
                  (latency-percentile service-sorted 95)
                  (latency-percentile service-sorted 99)
                  service-maximum
                  p50
                  p95
                  p99
                  maximum))
                (check (< service-maximum 1000) => #t))
              (let (responses
                    (concurrent-live-corpus-responses endpoint body 16))
                (check (length responses) => 16)
                (check (all-ready? responses) => #t))
              (http-post-json (string-append endpoint "shutdown") "{}")))
           (read-all-as-string process))))))
   (test-case
    "projection memo is bounded and evicts old content identities"
    (let* ((package-root (current-directory))
           (before
            (gslph/src/runtime/provider-operation#provider-runtime-projection-memo-stats))
           (first-body
            (live-corpus-request package-root "memo-0" "memo-generation-0")))
      (let populate ((index 0))
        (when (< index 6)
          (provider-runtime-request->response
           (read-json
            (open-input-string
             (live-corpus-request
              package-root
              (format "memo-~a" index)
              (format "memo-generation-~a" index)))))
          (populate (+ index 1))))
      (let (after
            (gslph/src/runtime/provider-operation#provider-runtime-projection-memo-stats))
        (check (hash-ref after "entries") => 4)
        (check (>= (- (hash-ref after "misses")
                      (hash-ref before "misses"))
                   6)
               => #t)
        (let (misses-before-replay (hash-ref after "misses"))
          (provider-runtime-request->response
           (read-json (open-input-string first-body)))
          (check
           (> (hash-ref
               (gslph/src/runtime/provider-operation#provider-runtime-projection-memo-stats)
               "misses")
              misses-before-replay)
           => #t))))
   (test-case
   "project-resolution uses the canonical provider identity"
    (let* ((package-root (current-directory))
           (artifact (provider-test-artifact package-root))
           (project-request
            (hash
             ("schemaId" "agent.semantic-protocols.provider-project-resolution-request")
             ("schemaVersion" "1")
             ("languageId" "gerbil-scheme")
             ("providerId" "asp-gerbil-scheme")
             ("candidateBase" ".")
             ("candidateGeneration"
              (hash ("algorithm" "blake3-path-set-v1")
                    ("digest" (string-append "blake3:" (make-string 64 #\a)))
                    ("authorities" ["asp-workspace-admission"])))
             ("collectionScope" (hash ("kind" "complete-generation")))
             ("candidatePaths" ["gerbil.pkg" "build.ss" "src/main.ss"])
             ("policyExclusions" []))))
      (run-process
       (provider-environment package-root artifact #t)
       directory: package-root
       coprocess:
       (lambda (process)
         (let* ((bootstrap (read-json process))
                (endpoint (hash-ref bootstrap "endpoint"))
                (frame
                 (json-string
                  (hash
                   ("schemaId" "agent.semantic-protocols.provider-runtime-request-frame")
                   ("schemaVersion" "1")
                   ("requestId" "project-resolution-canonical")
                   ("operation" "project-resolution")
                   ("payload" project-request))))
                (response
                 (http-post-json
                  (string-append endpoint "v1/provider-runtime")
                  frame))
                (not-applicable-frame
                 (json-string
                  (hash
                   ("schemaId" "agent.semantic-protocols.provider-runtime-request-frame")
                   ("schemaVersion" "1")
                   ("requestId" "project-resolution-not-applicable")
                   ("operation" "project-resolution")
                   ("payload"
                    (hash
                     ("schemaId" "agent.semantic-protocols.provider-project-resolution-request")
                     ("schemaVersion" "1")
                     ("languageId" "gerbil-scheme")
                     ("providerId" "asp-gerbil-scheme")
                     ("candidateBase" ".")
                     ("candidateGeneration"
                      (hash
                       ("algorithm" "blake3-path-set-v1")
                       ("digest" (string-append "blake3:" (make-string 64 #\d)))
                       ("authorities" ["asp-workspace-admission"])))
                     ("collectionScope" (hash ("kind" "complete-generation")))
                     ("candidatePaths" ["Cargo.toml" "src/lib.rs"])
                     ("policyExclusions" []))))))
                (not-applicable-response
                 (http-post-json
                  (string-append endpoint "v1/provider-runtime")
                  not-applicable-frame))
                (shutdown
                 (http-post-json (string-append endpoint "shutdown") "{}")))
           (unless (equal? (hash-ref response "outcome") "ready")
             (error (hash-ref response "error")))
           (check (hash-ref response "outcome") => "ready")
           (let (inner (hash-ref response "payload"))
             (check (hash-ref inner "schemaVersion") => "1")
             (check (hash-ref inner "providerId") => "asp-gerbil-scheme")
             (check (hash-ref inner "state") => "resolved"))
           (check (hash-ref not-applicable-response "outcome") => "ready")
           (let (inner (hash-ref not-applicable-response "payload"))
             (check (hash-ref inner "schemaVersion") => "1")
             (check (hash-ref inner "providerId") => "asp-gerbil-scheme")
             (check (hash-ref inner "state") => "not-applicable")
             (check (hash-key? inner "scope") => #f)
             (check (hash-key? inner "failure") => #f))
           (check (hash-ref shutdown "state") => "draining")
           (read-all-as-string process))))))
   (test-case
    "missing contract identity cannot publish a ready bootstrap"
    (check
     (with-catch
      (lambda (_) #t)
      (lambda ()
     (gslph/src/runtime/provider-http-json-server#validate-provider-http-json-environment!
      (lambda (_) #f))
        #f))
     => #t)))))
