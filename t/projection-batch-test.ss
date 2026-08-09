;;; -*- Gerbil -*-
;;; Bounded-memory contract tests for the hidden ASP projection transport.

(import :gerbil/gambit
        :gslph/src/commands/projection-batch
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/1 find)
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar hash)
        (only-in :std/text/json write-json)
        :std/test)

(export projection-batch-test)

(def +sample-owner-a+
  "(def +request-schema-id+ \"request-v1\")\n(def (sample x) (+ x 1))\n")
(def +sample-owner-b+
  "(def (second value)\n  (* value 2))\n")

(def (owner-header path byte-length)
  (hash
   ("ownerPath" path)
   ("sourceLeafDigest" (string-append "digest:" path))
   ("byteLength" byte-length)))

(def (request-header owners)
  (hash
   ("schemaId" +request-schema-id+)
   ("schemaVersion" "1")
   ("languageId" +language-id+)
   ("providerId" +provider-id+)
   ("transport" +transport+)
   ("generationRootDigest" "generation-root")
   ("parserIdentityDigest" "parser-identity")
   ("queryPackDigest" "query-pack")
   ("owners" (list->vector owners))))

(def (json-bytes value)
  (string->utf8
   (call-with-output-string
    (lambda (port) (write-json value port)))))

(def (u32-big-endian value)
  (let (bytes (make-u8vector 4 0))
    (u8vector-set! bytes 0 (bitwise-and (arithmetic-shift value -24) 255))
    (u8vector-set! bytes 1 (bitwise-and (arithmetic-shift value -16) 255))
    (u8vector-set! bytes 2 (bitwise-and (arithmetic-shift value -8) 255))
    (u8vector-set! bytes 3 (bitwise-and value 255))
    bytes))

(def (append-u8vectors chunks)
  (let* ((total (apply + (map u8vector-length chunks)))
         (result (make-u8vector total 0)))
    (let outer ((rest chunks) (offset 0))
      (if (null? rest)
        result
        (let* ((chunk (car rest))
               (length (u8vector-length chunk)))
          (let inner ((index 0))
            (when (< index length)
              (u8vector-set! result (+ offset index)
                             (u8vector-ref chunk index))
              (inner (+ index 1))))
          (outer (cdr rest) (+ offset length)))))))

(def (projection-frame owners sources (trailing #f))
  (let (header-bytes (json-bytes (request-header owners)))
    (append-u8vectors
     (append (list (u32-big-endian (u8vector-length header-bytes))
                   header-bytes)
             sources
             (if trailing (list trailing) '())))))

(def (projection-rejected? thunk)
  (with-catch (lambda (_exception) #t)
              (lambda () (thunk) #f)))

(def (response-items response owner-index)
  (hash-ref (vector-ref (hash-ref response "owners") owner-index) "items"))

(def projection-batch-test
  (test-suite
   "Gerbil provider projection batch"
   (test-case
    "streaming projection preserves multi-owner boundaries and selectors"
    (let* ((source-a (string->utf8 +sample-owner-a+))
           (source-b (string->utf8 +sample-owner-b+))
           (owners
            (list (owner-header "src/a.ss" (u8vector-length source-a))
                  (owner-header "src/b.ss" (u8vector-length source-b))))
           (frame (projection-frame owners (list source-a source-b)))
           (streamed
            (project-provider-projection-stream (open-input-u8vector frame)))
           (materialized (project-provider-projection-batch frame))
           (stream-items-a (response-items streamed 0))
           (materialized-items-b (response-items materialized 1))
           (plus-item
            (find (lambda (item)
                    (equal? (hash-ref item "name") "+request-schema-id+"))
                  (vector->list stream-items-a)))
           (sample-item
            (find (lambda (item)
                    (equal? (hash-ref item "name") "sample"))
                  (vector->list stream-items-a))))
      (check (vector-length (hash-ref streamed "owners")) => 2)
      (check (vector-length materialized-items-b) => 1)
      (check (not plus-item) => #f)
      (check
       (not (not (string-contains (hash-ref plus-item "selector")
                                  "%2Brequest-schema-id%2B")))
       => #t)
      (check (hash-ref plus-item "sourceByteStart") => 0)
      (check (> (hash-ref plus-item "sourceByteEnd")
                (hash-ref plus-item "sourceByteStart"))
             => #t)
      (check (hash-ref sample-item "kind") => "function")
      (check (hash-ref (hash-ref sample-item "identity") "kind")
             => "function")
      (check (not (not (string-contains (hash-ref sample-item "selector")
                                        "#item/function/sample")))
             => #t)))
   (test-case
    "declared owner size is rejected before reading or allocating it"
    (let* ((declared-size (+ (* 16 1024 1024) 1))
           (owners
            (list (owner-header "src/oversized.ss" declared-size)))
           (frame (projection-frame owners '())))
      (check
       (projection-rejected?
        (lambda ()
          (project-provider-projection-stream (open-input-u8vector frame))))
       => #t)
      (check
       (projection-rejected?
        (lambda () (project-provider-projection-batch frame)))
       => #t)))
   (test-case
    "truncated and trailing owner bytes fail closed"
    (let* ((source (string->utf8 +sample-owner-b+))
           (owners
            (list (owner-header "src/truncated.ss"
                                (+ (u8vector-length source) 1))))
           (truncated (projection-frame owners (list source)))
           (exact-owner
            (list (owner-header "src/trailing.ss"
                                (u8vector-length source))))
           (trailing
            (projection-frame exact-owner (list source) (make-u8vector 1 0))))
      (check
       (projection-rejected?
        (lambda ()
          (project-provider-projection-stream (open-input-u8vector truncated))))
       => #t)
      (check
       (projection-rejected?
        (lambda ()
          (project-provider-projection-stream (open-input-u8vector trailing))))
       => #t)))
   (test-case
    "runtime adapter never materializes stdin as a byte list"
    (let (source
          (call-with-input-file "src/commands/projection-batch.ss"
                                read-all-as-string))
      (check (not (string-contains source "read-all-u8vector")) => #t)
      (check
       (not (not (string-contains source
                                  "project-provider-projection-stream")))
       => #t)))))
