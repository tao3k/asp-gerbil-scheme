;;; -*- Gerbil -*-

(export provider-http-json-server-test)

(import :gerbil/runtime/gambit
        :asp-gerbil-scheme/src/commands/projection-batch
        :asp-gerbil-scheme/src/runtime/provider-http-json-server
        :asp-gerbil-scheme/src/runtime/provider-operation
        :asp-gerbil-scheme/src/runtime/provider/interface
        (only-in :std/string/path path-expand)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)
        (only-in :std/io/bio/api
                 open-input-port-buffered-reader
                 BufferedReader-read-line-utf8)
        (only-in :std/list/list iota)
        (only-in :asp-gerbil-scheme/src/support/list append-map)
        (only-in :std/encoding/base64 base64-encode)
        (only-in :std/encoding/json JSONReadOptions read-json write-json)
        (only-in "support/provider-http-benchmark"
                 parallel-live-corpus-samples)
        :std/test)

(def +artifact-digest+
  "blake3-256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
(def +registration-digest+
  "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
(def +contract-digest+
  "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc")

(def (read-wire-json reader)
  (read-json reader (JSONReadOptions object-as-hash: #t)))

;; HTTP/live-corpus acceptance consumes an artifact already admitted by the
;; workspace build/install boundary. It must never make a test invocation
;; silently enter the native executable linker path.
(def (provider-test-artifact package-root)
  (let (artifact
        (or (getenv "ASP_PROVIDER_TEST_ARTIFACT" #f)
            (path-expand
             ".gerbil/bin/asp-gerbil-scheme"
             package-root)))
    (unless (file-exists? artifact)
      (error
       "provider-http-json-server-test-artifact-required: materialize the workspace provider artifact first with gxpkg env gxi ./build-provider.ss compile"
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
  (read-wire-json
   (open-input-string
    (run-process
     (list "curl" "--fail-with-body" "--silent" "--show-error" url)
     coprocess: read-all-as-string
     stderr-redirection: #t))))

(def (http-post-json url body)
  (read-wire-json
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
   (lambda (port) (write-json port value))))

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
       (read-wire-json (open-input-string line))))))

(def (file-bytes path)
  (string->utf8
   (call-with-input-file path read-all-as-string)))

(def (owner-header path bytes)
  (hash ("ownerPath" path)
        ("sourceLeafDigest" (string-append "digest:" path))
        ("sourceEncoding" "utf8")
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

(def (read-nonempty-buffered-line reader)
  (let (line (BufferedReader-read-line-utf8 reader))
    (cond
     ((eof-object? line) (error "timed HTTP response omitted latency"))
     ((zero? (string-length line)) (read-nonempty-buffered-line reader))
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
          (cons "curl"
                (append-map
                 (lambda (index)
                   (curl-transfer-arguments url body (zero? index)))
                 (iota total)))))
    ;; V19 JSON and latency lines must share one BufferedReader. Mixing its
    ;; byte buffer with Gambit's character read-line corrupts the port state.
    (run-process
     arguments
     stderr-redirection: #t
     coprocess:
     (lambda (port)
       (let ((reader (open-input-port-buffered-reader port))
             (options (JSONReadOptions object-as-hash: #t)))
         (let parse ((index 0) (samples '()))
           (if (= index total)
               (reverse samples)
               (let* ((response (read-json reader options))
                      (elapsed-seconds
                       (string->number (read-nonempty-buffered-line reader)))
                      (elapsed
                       (inexact->exact (round (* elapsed-seconds 1000000.0)))))
                 (unless (string=? (hash-ref response "outcome") "ready")
                   (error "live corpus provider request failed" response))
                 (parse (+ index 1)
                        (if (< index warm-count)
                            samples
                            (cons elapsed samples)))))))))))

(def (direct-live-corpus-samples body warm-count sample-count)
  (let ((request-value (read-wire-json (open-input-string body)))
        (total (+ warm-count sample-count)))
    (let loop ((index 0) (samples '()))
      (if (= index total)
          (reverse samples)
          (let* ((started (##process-statistics))
                 (response (provider-runtime-request->response request-value))
                 (finished (##process-statistics))
                 (elapsed
                  (inexact->exact
                   (round
                    (* 1000000.0
                       (+ (- (f64vector-ref finished 0)
                             (f64vector-ref started 0))
                          (- (f64vector-ref finished 1)
                             (f64vector-ref started 1))))))))
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
    "runtime operations exchange validated POO payload and result objects"
    (let* ((schema (provider-schema-reference "test.schema" "1"))
           (descriptor
            (provider-operation-descriptor
             "test-operation" schema schema #f
             (lambda (payload)
               (provider-operation-result
                "test-operation"
                (hash ("echo"
                       (hash-ref
                        (provider-operation-payload->json payload)
                        "value")))))))
           (wire-payload (hash ("value" 42)))
           (payload (provider-operation-payload
                     "test-operation" wire-payload))
           (request (provider-runtime-request "poo-boundary" descriptor payload))
           (result (provider-operation-execute descriptor payload))
           (response (provider-runtime-ready-response
                      (provider-runtime-request-id request)
                      result))
           (wire-response (provider-runtime-response->json response)))
      (check (provider-runtime-request? request) => #t)
      (check (provider-operation-payload?
              (provider-runtime-request-payload request)) => #t)
      (check (hash-table? (provider-runtime-request-payload request)) => #f)
      (check (provider-operation-result? result) => #t)
      (check (hash-ref (hash-ref wire-response "payload") "echo") => 42)
      (check-exception
       (provider-runtime-request
        "poo-mismatch"
        descriptor
        (provider-operation-payload "other-operation" wire-payload))
       true)))
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
           (let (concurrency (hash-ref bootstrap "concurrency"))
             (check (hash-ref concurrency "model")
                    => "green-thread-per-connection")
             (check (hash-ref concurrency "requestScheduling")
                    => "serial-within-connection")
             (check (> (hash-ref concurrency "hostProcessors") 0) => #t)
             (check (> (hash-ref concurrency "vmProcessors") 0) => #t)
             (check (boolean? (hash-ref concurrency "smpRuntime")) => #t))
           (check (hash-ref health "artifactDigest") => +artifact-digest+)
           (check (hash-ref health "registrationDigest") => +registration-digest+)
           (check (hash-ref health "contractDigest") => +contract-digest+)
           (let ((operations (hash-ref health "operations")))
             ;; The runtime contract catalog contains only structural
             ;; projection, resolution, and exact-query operations.
             (check (length operations) => 3)
             (check (hash-ref (car operations) "operation") => "projection-batch")
             (check (hash-ref (hash-ref (car operations) "requestSchema") "schemaId")
                    => "agent.semantic-protocols.provider-language-projection-batch-request")
             (check (hash-ref (hash-ref (car operations) "responseSchema") "schemaId")
                    => "agent.semantic-protocols.provider-language-projection-batch-response")
             (check (hash-ref (cadr operations) "operation") => "project-resolution")
             (check (hash-ref (hash-ref (cadr operations) "requestSchema") "schemaVersion")
                    => "1")
             (check (hash-ref (hash-ref (cadr operations) "responseSchema") "schemaVersion")
                    => "1")
             (check (hash-ref (caddr operations) "operation") => "query")
             (check (hash-ref (hash-ref (caddr operations) "requestSchema") "schemaId")
                    => "agent.semantic-protocols.provider-native-exact-request")
             (check (hash-ref (hash-ref (caddr operations) "responseSchema") "schemaId")
                    => "agent.semantic-protocols.provider-native-exact-projection"))
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
             (read-wire-json (open-input-string body))))
           (service-samples (direct-live-corpus-samples body 16 128))
           (service-sorted (sort-latencies service-samples))
           (service-maximum (apply max service-samples))
           (memo-stats
            (asp-gerbil-scheme/src/runtime/provider-operation#provider-runtime-projection-memo-stats)))
      (check (hash-ref direct-response "outcome") => "ready")
      (displayln
        (string-append
         "[provider-projection-memo-input] requestBytes="
         (number->string (string-length body))
         " responsePayloadBytes="
         (number->string
          (string-length (json-string (hash-ref direct-response "payload"))))
         " entries=" (number->string (hash-ref memo-stats "entries"))
         " hits=" (number->string (hash-ref memo-stats "hits"))
         " misses=" (number->string (hash-ref memo-stats "misses"))))
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
                 (string-append
                  "[provider-live-corpus] schemaVersion=1 provider=asp-gerbil-scheme owners=2 samples=128"
                  " serviceP50Micros=" (number->string (latency-percentile service-sorted 50))
                  " serviceP95Micros=" (number->string (latency-percentile service-sorted 95))
                  " serviceP99Micros=" (number->string (latency-percentile service-sorted 99))
                  " serviceMaxMicros=" (number->string service-maximum)
                  " loopbackP50Micros=" (number->string p50)
                  " loopbackP95Micros=" (number->string p95)
                  " loopbackP99Micros=" (number->string p99)
                  " loopbackMaxMicros=" (number->string maximum)))
                (check (< (latency-percentile service-sorted 99) 1000) => #t))
              (let (responses
                    (concurrent-live-corpus-responses endpoint body 16))
                (check (length responses) => 16)
                (check (all-ready? responses) => #t))
              (let* ((parallel-samples
                      (parallel-live-corpus-samples endpoint body 16))
                     (parallel-sorted (sort-latencies parallel-samples)))
                (displayln
                 (string-append
                  "[provider-live-corpus-concurrent] schemaVersion=1 connections=16 samples=16"
                  " p50Micros=" (number->string (latency-percentile parallel-sorted 50))
                  " p95Micros=" (number->string (latency-percentile parallel-sorted 95))
                  " p99Micros=" (number->string (latency-percentile parallel-sorted 99))
                  " maxMicros=" (number->string (apply max parallel-samples))))
                (check (length parallel-samples) => 16))
              (http-post-json (string-append endpoint "shutdown") "{}")))
           (read-all-as-string process))))))
   (test-case
    "projection memo uses bounded least-recently-used eviction"
    (let* ((package-root (current-directory))
           (body (lambda (index)
                   (live-corpus-request
                    package-root
                    (string-append "memo-" (number->string index))
                    (string-append "memo-generation-" (number->string index)))))
           (execute (lambda (index)
                      (provider-runtime-request->response
                       (read-wire-json (open-input-string (body index)))))))
      (for-each execute (iota 4))
      (execute 0)
      (execute 4)
      (let* ((after (provider-runtime-projection-memo-stats))
             (hits-before (hash-ref after "hits")))
        (check (hash-ref after "entries") => 4)
        (execute 0)
        (check (> (hash-ref (provider-runtime-projection-memo-stats) "hits")
                  hits-before)
               => #t))
      (let (misses-before
            (hash-ref (provider-runtime-projection-memo-stats) "misses"))
        (execute 1)
        (check (> (hash-ref (provider-runtime-projection-memo-stats) "misses")
                  misses-before)
               => #t))))
   (test-case
    "projection memo rejects forged bytes under the same declared identity"
    (let* ((package-root (current-directory))
           (body (live-corpus-request
                  package-root "memo-source" "memo-source-generation"))
           (original (read-wire-json (open-input-string body)))
           (forged (read-wire-json (open-input-string body)))
           (forged-owner
            (car (hash-ref (hash-ref forged "payload") "owners"))))
      (provider-runtime-request->response original)
      (hash-put! forged-owner "sourceText" "(def forged-cache-witness 1)\n")
      (let* ((misses-before
              (hash-ref (provider-runtime-projection-memo-stats) "misses"))
             (response (provider-runtime-request->response forged))
             (owner (vector-ref
                     (hash-ref (hash-ref response "payload") "owners") 0))
             (item (vector-ref (hash-ref owner "items") 0)))
        (check (hash-ref item "name") => "forged-cache-witness")
        (check (> (hash-ref (provider-runtime-projection-memo-stats) "misses")
                  misses-before)
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
         (let* ((bootstrap (read-wire-json process))
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
     (asp-gerbil-scheme/src/runtime/provider-http-json-server#validate-provider-http-json-environment!
      (lambda (_) #f))
        #f))
     => #t))))
