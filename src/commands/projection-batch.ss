;;; -*- Gerbil -*-
;;; Shared ASP projection-batch adapter backed by the native Gerbil parser.

(import :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/parser/exact-owner
                 parse-exact-owner-definitions)
        (only-in :asp-gerbil-scheme/src/parser/selectors item-structural-selector)
        (only-in :asp-gerbil-scheme/src/parser/model
                 definition-name
                 definition-kind
                 definition-start
                 definition-end)
        (only-in :asp-gerbil-scheme/src/parser/selectors definition-selector)
        (only-in :asp-gerbil-scheme/src/utilities/functional
                 u8vector-line-start-offsets)
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar hash))

(export project-provider-projection-batch
        +request-schema-id+
        +language-id+
        +provider-id+)

(def +request-schema-id+
  "agent.semantic-protocols.provider-language-projection-batch-request")
(def +response-schema-id+
  "agent.semantic-protocols.provider-language-projection-batch-response")
(def +identity-schema-id+ "agent.semantic-protocols.canonical-language-item-identity")
(def +language-id+ "gerbil-scheme")
(def +provider-id+ "asp-gerbil-scheme")

;; The structured Runtime operation is an untrusted ASP/provider boundary.
(def +max-owner-count+ 4096)
(def +max-owner-bytes+ (* 16 1024 1024))
(def +max-total-owner-bytes+ (* 64 1024 1024))
(def +max-owner-items+ 200000)
(def +max-total-items+ 250000)

(def (project-provider-projection-batch request)
  (validate-header request)
  (let (owner-headers (json-array->list (required-field request "owners")))
    (validate-owner-count owner-headers)
    (projection-response request (project-structured-owners owner-headers))))

(def (projection-response header owners)
  (hash
   ("schemaId" +response-schema-id+)
   ("schemaVersion" "1")
   ("languageId" +language-id+)
   ("providerId" +provider-id+)
   ("generationRootDigest"
    (required-string header "generationRootDigest"))
   ("owners" (list->vector owners))))

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
  (required-string header "parserIdentityDigest")
  (required-string header "queryPackDigest"))

(def (project-structured-owners headers)
  (let loop ((rest headers) (source-total 0) (item-total 0) (out '()))
    (if (null? rest)
      (reverse out)
      (let* ((owner (car rest))
             (path (required-string owner "ownerPath"))
             (digest (required-string owner "sourceLeafDigest"))
             (source-text (required-string owner "sourceText"))
             (source-bytes (string->utf8 source-text))
             (byte-length (u8vector-length source-bytes))
             (next-source-total (+ source-total byte-length)))
        (validate-owner-byte-length path byte-length next-source-total)
        (let* ((projected
                (project-owner path digest source-text source-bytes))
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

(def (project-owner path digest source-text source-bytes)
  (let (parsed
        (with-catch
         (lambda (failure) (vector 'syntax-unavailable failure))
         (lambda ()
           (with-parsed-definitions
            source-text path
            (lambda (definitions) (vector 'ready definitions))))))
    (if (eq? (vector-ref parsed 0) 'syntax-unavailable)
      (syntax-unavailable-owner path digest (vector-ref parsed 1))
      (project-parsed-owner
       path digest source-bytes (vector-ref parsed 1)))))

(def (syntax-unavailable-owner path digest failure)
  (hash
   ("ownerPath" path)
   ("sourceLeafDigest" digest)
   ("projectionState" "syntax-unavailable")
   ("diagnostic"
    (hash
     ("schemaId" "agent.semantic-protocols.provider-language-projection-diagnostic")
     ("schemaVersion" "1")
     ("reasonKind" "source-syntax-unavailable")
     ("message" (bounded-diagnostic-message failure))))
   ("items" (vector))
   ("relations" (vector))))

(def (bounded-diagnostic-message failure)
  (let (message (projection-string failure))
    (if (> (string-length message) 4096)
      (substring message 0 4096)
      message)))

(def (project-parsed-owner path digest source-bytes definitions)
  (let* ((starts (u8vector-line-start-offsets source-bytes))
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
     ("projectionState" "ready")
     ("diagnostic" #!void)
     ("items" (list->vector items))
     ("relations" []))))

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
    (let (item-name
          (substring parser-selector
                     (+ item-position
                        (string-length parser-item-prefix))
                     (string-length parser-selector)))
      (if (string-contains item-name "%")
        (string-append +language-id+ "://" path "#item/" canonical-kind "/"
                       item-name)
        (item-structural-selector path canonical-kind item-name)))))

(def (canonical-definition-kind kind)
  (cond
   ((member kind '("def" "function")) "function")
   ((member kind '("defmethod" "method")) "method")
   ((member kind '("defsyntax" "macro")) "macro")
   (else kind)))

(def (with-parsed-definitions source-text owner-path proc)
  (let* ((name (string-append "asp-gerbil-scheme-projection-"
                              (symbol->string (gensym)) ".ss"))
         (path (string-append "/tmp/" name)))
    (with-catch
     (lambda (exception)
       (when (file-exists? path) (delete-file path))
       (raise exception))
     (lambda ()
       (call-with-output-file (list path: path char-encoding: 'UTF-8)
         (lambda (port) (display source-text port)))
       (let (result
             (proc (parse-exact-owner-definitions path owner-path)))
         (delete-file path)
         result)))))

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

(def (json-array->list value)
  (cond
   ((vector? value) (vector->list value))
   ((list? value) value)
   (else (error "projection batch owners must be an array"))))

(def (assert-equal label actual expected)
  (unless (equal? actual expected)
    (error "projection batch request identity mismatch"
           label actual expected)))
