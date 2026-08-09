;;; -*- Gerbil -*-
;;; Shared ASP projection-batch adapter backed by the native Gerbil parser.

(import :gerbil/gambit
        (only-in :gslph/src/parser/exact-owner
                 parse-exact-owner-definitions)
        (only-in :gslph/src/parser/model
                 definition-name
                 definition-kind
                 definition-start
                 definition-end)
        (only-in :gslph/src/parser/selectors definition-selector)
        (only-in :gslph/src/protocol/json-output write-json-line)
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar hash)
        (only-in :std/text/json read-json))

(export projection-batch-main
        project-provider-projection-batch
        project-provider-projection-stream
        +request-schema-id+
        +transport+
        +language-id+
        +provider-id+)

(def +request-schema-id+
  "asp.provider-language-projection-batch-request.v1")
(def +response-schema-id+
  "asp.provider-language-projection-batch-response.v1")
(def +identity-schema-id+ "asp.canonical-language-item-identity.v1")
(def +transport+ "framed-stdin-v1")
(def +language-id+ "gerbil-scheme")
(def +provider-id+ "gerbil-scheme-harness")

;; The transport is an untrusted ASP/provider boundary.  Keep these limits
;; here, before any allocation based on request-controlled lengths.
(def +max-header-bytes+ (* 1024 1024))
(def +max-owner-count+ 4096)
(def +max-owner-bytes+ (* 16 1024 1024))
(def +max-total-owner-bytes+ (* 64 1024 1024))
(def +max-owner-items+ 200000)
(def +max-total-items+ 250000)

(def (projection-batch-main args)
  (unless (null? args)
    (error "projection-batch-stdin accepts only a framed stdin request"))
  (write-json-line
   (project-provider-projection-stream (current-input-port)))
  0)

(def (project-provider-projection-stream port)
  (let* ((length-bytes
          (read-exact-u8vector port 4
                               "projection batch frame is missing its header length"))
         (header-length (frame-header-length length-bytes)))
    (validate-header-length header-length)
    (let* ((header-bytes
            (read-exact-u8vector port header-length
                                 "projection batch header is truncated"))
           (header (decode-header header-bytes))
           (owner-headers
            (json-array->list (required-field header "owners"))))
      (validate-header header)
      (validate-owner-count owner-headers)
      (let (owners (read-and-project-owners port owner-headers))
        (unless (eof-object? (read-u8 port))
          (error "projection batch frame has trailing bytes"))
        (projection-response header owners)))))

(def (read-exact-u8vector port byte-length truncated-message)
  (let (bytes (make-u8vector byte-length 0))
    (let loop ((index 0))
      (if (= index byte-length)
        bytes
        (let (byte (read-u8 port))
          (when (eof-object? byte)
            (error truncated-message))
          (u8vector-set! bytes index byte)
          (loop (+ index 1)))))))

(def (project-provider-projection-batch frame)
  (let* ((header-length (frame-header-length frame))
         (header-end (+ 4 header-length)))
    (validate-header-length header-length)
    (when (> header-end (u8vector-length frame))
      (error "projection batch header exceeds the input frame"))
    (let* ((header (decode-header (subu8vector frame 4 header-end)))
           (owner-headers (json-array->list (required-field header "owners"))))
      (validate-header header)
      (validate-owner-count owner-headers)
      (let (owners (decode-and-project-owners frame header-end owner-headers))
        (projection-response header owners)))))

(def (decode-header bytes)
  (read-json (open-input-string (utf8->string bytes))))

(def (projection-response header owners)
  (hash
   ("schemaId" +response-schema-id+)
   ("schemaVersion" "1")
   ("languageId" +language-id+)
   ("providerId" +provider-id+)
   ("generationRootDigest"
    (required-string header "generationRootDigest"))
   ("owners" (list->vector owners))))

(def (frame-header-length frame)
  (when (< (u8vector-length frame) 4)
    (error "projection batch frame is missing its header length"))
  (+ (* (u8vector-ref frame 0) 16777216)
     (* (u8vector-ref frame 1) 65536)
     (* (u8vector-ref frame 2) 256)
     (u8vector-ref frame 3)))

(def (validate-header-length header-length)
  (when (> header-length +max-header-bytes+)
    (error "projection batch header exceeds the byte limit"
           header-length +max-header-bytes+)))

(def (validate-owner-count owner-headers)
  (when (> (length owner-headers) +max-owner-count+)
    (error "projection batch exceeds the owner count limit"
           (length owner-headers) +max-owner-count+)))

(def (validate-header header)
  (assert-equal "schemaId" (required-string header "schemaId")
                +request-schema-id+)
  (assert-equal "schemaVersion" (required-string header "schemaVersion") "1")
  (assert-equal "languageId" (required-string header "languageId")
                +language-id+)
  (assert-equal "providerId" (required-string header "providerId")
                +provider-id+)
  (assert-equal "transport" (required-string header "transport") +transport+)
  (required-string header "parserIdentityDigest")
  (required-string header "queryPackDigest"))

(def (decode-and-project-owners frame cursor headers)
  (let loop ((rest headers) (offset cursor) (source-total 0)
             (item-total 0) (out '()))
    (if (null? rest)
      (begin
        (unless (= offset (u8vector-length frame))
          (error "projection batch frame has trailing bytes"))
        (reverse out))
      (let* ((owner (car rest))
             (path (required-string owner "ownerPath"))
             (digest (required-string owner "sourceLeafDigest"))
             (byte-length (required-integer owner "byteLength"))
             (end (+ offset byte-length))
             (next-source-total (+ source-total byte-length)))
        (validate-owner-byte-length path byte-length next-source-total)
        (when (> end (u8vector-length frame))
          (error "projection batch owner bytes are truncated" path))
        (let* ((projected
                (project-owner path digest (subu8vector frame offset end)))
               (next-item-total
                (validated-next-item-total projected item-total path)))
          (loop (cdr rest) end next-source-total next-item-total
                (cons projected out)))))))

(def (read-and-project-owners port headers)
  (let loop ((rest headers) (source-total 0) (item-total 0) (out '()))
    (if (null? rest)
      (reverse out)
      (let* ((owner (car rest))
             (path (required-string owner "ownerPath"))
             (digest (required-string owner "sourceLeafDigest"))
             (byte-length (required-integer owner "byteLength"))
             (next-source-total (+ source-total byte-length)))
        (validate-owner-byte-length path byte-length next-source-total)
        (let* ((source-bytes
                (read-exact-u8vector
                 port byte-length
                 "projection batch owner bytes are truncated"))
               (projected (project-owner path digest source-bytes))
               (next-item-total
                (validated-next-item-total projected item-total path)))
          (loop (cdr rest) next-source-total next-item-total
                (cons projected out)))))))

(def (validate-owner-byte-length path byte-length next-source-total)
  (when (> byte-length +max-owner-bytes+)
    (error "projection batch owner exceeds the byte limit"
           path byte-length +max-owner-bytes+))
  (when (> next-source-total +max-total-owner-bytes+)
    (error "projection batch exceeds the total owner byte limit"
           next-source-total +max-total-owner-bytes+)))

(def (validated-next-item-total projected item-total path)
  (let* ((owner-item-count (vector-length (hash-ref projected "items")))
         (next-item-total (+ item-total owner-item-count)))
    (when (> owner-item-count +max-owner-items+)
      (error "projection batch owner exceeds the item limit"
             path owner-item-count +max-owner-items+))
    (when (> next-item-total +max-total-items+)
      (error "projection batch exceeds the total item limit"
             next-item-total +max-total-items+))
    next-item-total))

(def (project-owner path digest source-bytes)
  (with-parsed-definitions
   source-bytes path
   (lambda (definitions)
     (let* ((starts (line-start-offsets source-bytes))
            (byte-length (u8vector-length source-bytes))
            (_ (when (> (length definitions) +max-owner-items+)
                 (error "projection batch owner exceeds the item limit"
                        path (length definitions) +max-owner-items+)))
            (items
             (map (lambda (definition)
                    (project-definition path definition starts byte-length))
                  definitions)))
       (hash
        ("ownerPath" path)
        ("sourceLeafDigest" digest)
        ("items" (list->vector items))
        ("relations" []))))))

(def (project-definition path definition starts byte-length)
  (let* ((name (projection-string (definition-name definition)))
         (parser-kind (projection-string (definition-kind definition)))
         (kind (canonical-definition-kind parser-kind))
         (selector (owner-definition-selector
                    path definition parser-kind kind))
         (range (line-range->byte-range
                 starts byte-length
                 (definition-start definition)
                 (definition-end definition))))
    (hash
     ("itemId" (string-append "item:" selector))
     ("ownerId" (string-append "owner:" path))
     ("kind" kind)
     ("name" name)
     ("selector" selector)
     ("sourceByteStart" (vector-ref range 0))
     ("sourceByteEnd" (vector-ref range 1))
     ("identity"
      (hash
       ("schemaId" +identity-schema-id+)
       ("schemaVersion" "1")
       ("languageId" +language-id+)
       ("kind" kind)
       ("symbol" name)
       ("scopes" [])))
     ("projections" []))))

(def (owner-definition-selector path definition parser-kind canonical-kind)
  (let* ((parser-selector (definition-selector definition))
         (parser-item-prefix (string-append "#item/" parser-kind "/"))
         (item-position (string-contains parser-selector parser-item-prefix)))
    (unless item-position
      (error "parser definition selector is not canonical" parser-selector))
    (string-append +language-id+ "://" path "#item/" canonical-kind "/"
                   (substring parser-selector
                              (+ item-position
                                 (string-length parser-item-prefix))
                              (string-length parser-selector)))))

(def (canonical-definition-kind kind)
  (cond
   ((member kind '("def" "function")) "function")
   ((member kind '("defmethod" "method")) "method")
   ((member kind '("defsyntax" "macro")) "macro")
   (else kind)))

(def (with-parsed-definitions source-bytes owner-path proc)
  (let* ((name (string-append "gslph-projection-"
                              (symbol->string (gensym)) ".ss"))
         (path (string-append "/tmp/" name)))
    (with-catch
     (lambda (exception)
       (when (file-exists? path) (delete-file path))
       (raise exception))
     (lambda ()
       (call-with-output-file path
         (lambda (port) (write-subu8vector source-bytes 0
                                            (u8vector-length source-bytes)
                                            port)))
       (let (result
             (proc (parse-exact-owner-definitions path owner-path)))
         (delete-file path)
         result)))))

(def (line-start-offsets bytes)
  (let loop ((index 0) (starts '(0)))
    (cond
     ((= index (u8vector-length bytes))
      (list->vector (reverse starts)))
     ((= (u8vector-ref bytes index) 10)
      (loop (+ index 1) (cons (+ index 1) starts)))
     (else (loop (+ index 1) starts)))))

(def (line-range->byte-range starts byte-length start-line end-line)
  (let* ((start-index (- start-line 1))
         (start (if (< start-index (vector-length starts))
                  (vector-ref starts start-index)
                  byte-length))
         (end (if (< end-line (vector-length starts))
                (vector-ref starts end-line)
                byte-length)))
    (vector start end)))

(def (projection-string value)
  (cond
   ((string? value) value)
   ((symbol? value) (symbol->string value))
   (else (call-with-output-string (lambda (port) (display value port))))))

(def (required-field object key)
  (let (value (hash-ref object key #f))
    (unless value (error "projection batch request omitted field" key))
    value))

(def (required-string object key)
  (let (value (required-field object key))
    (unless (and (string? value) (> (string-length value) 0))
      (error "projection batch field must be a string" key))
    value))

(def (required-integer object key)
  (let (value (required-field object key))
    (unless (and (integer? value) (>= value 0))
      (error "projection batch field must be a non-negative integer" key))
    value))

(def (json-array->list value)
  (cond
   ((vector? value) (vector->list value))
   ((list? value) value)
   (else (error "projection batch owners must be an array"))))

(def (assert-equal label actual expected)
  (unless (equal? actual expected)
    (error "projection batch request identity mismatch"
           label actual expected)))
