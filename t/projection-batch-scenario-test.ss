;;; -*- Gerbil -*-
;;; Scenario-owned performance gate for the lightweight projection adapter.

(import :gerbil/gambit
        :gslph/src/benchmark/framework
        :gslph/src/commands/projection-batch
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/1 iota)
        (only-in :std/sugar hash)
        (only-in :std/text/json write-json)
        :std/test)

(export projection-batch-scenario-test)

(def +scenario-root+
  "t/scenarios/provider/exact-owner-projection")
(def +scenario-owner-count+ 64)

(def (scenario-owner-source)
  (call-with-input-file
   (path-expand "input/owner.ss" +scenario-root+)
   read-all-as-string))

(def (scenario-owner-header index byte-length)
  (let (path (string-append "src/scenario-owner-"
                            (number->string index)
                            ".ss"))
    (hash
     ("ownerPath" path)
     ("sourceLeafDigest" (string-append "digest:" path))
     ("byteLength" byte-length))))

(def (scenario-request-header owner-headers)
  (hash
   ("schemaId" +request-schema-id+)
   ("schemaVersion" "1")
   ("languageId" +language-id+)
   ("providerId" +provider-id+)
   ("transport" +transport+)
   ("generationRootDigest" "scenario-generation-root")
   ("parserIdentityDigest" "scenario-parser-identity")
   ("queryPackDigest" "scenario-query-pack")
   ("owners" (list->vector owner-headers))))

(def (scenario-json-bytes value)
  (string->utf8
   (call-with-output-string
    (lambda (port) (write-json value port)))))

(def (scenario-u32-big-endian value)
  (let (bytes (make-u8vector 4 0))
    (u8vector-set! bytes 0 (bitwise-and (arithmetic-shift value -24) 255))
    (u8vector-set! bytes 1 (bitwise-and (arithmetic-shift value -16) 255))
    (u8vector-set! bytes 2 (bitwise-and (arithmetic-shift value -8) 255))
    (u8vector-set! bytes 3 (bitwise-and value 255))
    bytes))

(def (scenario-append-u8vectors chunks)
  (let* ((total (apply + (map u8vector-length chunks)))
         (result (make-u8vector total 0)))
    (let loop ((rest chunks) (offset 0))
      (if (null? rest)
        result
        (let* ((chunk (car rest))
               (length (u8vector-length chunk)))
          (subu8vector-move! chunk 0 length result offset)
          (loop (cdr rest) (+ offset length)))))))

(def (scenario-frame)
  (let* ((source (string->utf8 (scenario-owner-source)))
         (indexes (iota +scenario-owner-count+))
         (owner-headers
          (map (lambda (index)
                 (scenario-owner-header index (u8vector-length source)))
               indexes))
         (header (scenario-json-bytes
                  (scenario-request-header owner-headers))))
    (scenario-append-u8vectors
     (append (list (scenario-u32-big-endian (u8vector-length header)) header)
             (map (lambda (_) source) indexes)))))

(def (scenario-project frame)
  (project-provider-projection-stream (open-input-u8vector frame)))

(def projection-batch-scenario-test
  (test-suite
   "Gerbil exact-owner projection scenario"
   (test-case
    "scenario contract owns the lightweight provider performance budget"
    (check (benchmark-contract-input-expected-pass?
            (path-expand "benchmark.ss" +scenario-root+))
           => #t)
    (check (benchmark-contract-valid/root? +scenario-root+) => #t)
    (let* ((frame (scenario-frame))
           (receipt
            (benchmark-contract-run/root
             +scenario-root+
             (lambda () (scenario-project frame)))))
      (check receipt ? benchmark-contract-receipt-pass?)))
   (test-case
    "scenario returns every framed owner without workspace discovery"
    (let* ((response (scenario-project (scenario-frame)))
           (owners (hash-ref response "owners")))
      (check (vector-length owners) => +scenario-owner-count+)
      (check (vector-length (hash-ref (vector-ref owners 0) "items")) => 3)))))
