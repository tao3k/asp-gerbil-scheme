;;; -*- Gerbil -*-
;;; Provider-core exact source and callable-skeleton projection.

(import :gerbil/expander
        :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/parser/control-flow
                 control-flow-facts-from-form)
        (only-in :asp-gerbil-scheme/src/parser/exact-owner
                 parse-exact-owner-definitions
                 read-exact-owner-forms)
        (only-in :asp-gerbil-scheme/src/utilities/functional
                 u8vector-line-start-offsets)
        (only-in :asp-gerbil-scheme/src/parser/model
                 binding-fact-end
                 binding-fact-kind
                 binding-fact-name
                 binding-fact-scope
                 binding-fact-start
                 call-fact-callee
                 call-fact-caller
                 call-fact-end
                 call-fact-start
                 control-flow-fact-caller
                 control-flow-fact-end
                 control-flow-fact-kind
                 control-flow-fact-role
                 control-flow-fact-start
                 definition-end
                 definition-formals
                 definition-kind
                 definition-name
                 definition-start)
        (only-in :asp-gerbil-scheme/src/parser/syntax
                 binding-facts-from-form
                 calls-from-form)
        (only-in :std/srfi/1 find foldl)
        (only-in :std/srfi/13 string-contains string-index string-prefix? string-split)
        (only-in :std/text/base64 base64-decode))

(export project-provider-native-exact-request)

(def +request-schema-id+
  "agent.semantic-protocols.provider-native-exact-request")
(def +response-schema-id+
  "agent.semantic-protocols.provider-native-exact-projection")
(def +exact-selector-schema-id+
  "agent.semantic-protocols.exact-selector")
(def +canonical-selector-schema-id+
  "asp.canonical-item-selector.v1")
(def +language-id+ "gerbil-scheme")
(def +provider-id+ "asp-gerbil-scheme")
(def +selector-prefix+ "gerbil-scheme://")

(def (required-string request key)
  (let (value (hash-ref request key #f))
    (unless (and (string? value) (not (equal? value "")))
      (error "provider-native exact request is missing a string field" key))
    value))

(def (required-integer request key)
  (let (value (hash-ref request key #f))
    (unless (and (integer? value) (>= value 0))
      (error "provider-native exact request is missing an integer field" key))
    value))

(def (assert-equal label actual expected)
  (unless (equal? actual expected)
    (error "provider-native exact request identity mismatch"
           label actual expected)))

;; A parsed selector is:
;; [requested root owner kind symbol segment-kind segment-identity].
(def (parse-exact-selector selector)
  (unless (string-prefix? +selector-prefix+ selector)
    (error "provider-native exact selector has the wrong language prefix"
           selector))
  (let (item-position (string-contains selector "#item/"))
    (unless item-position
      (error "provider-native exact selector is missing #item/" selector))
    (let* ((owner-start (string-length +selector-prefix+))
           (owner (substring selector owner-start item-position))
           (tail-start (+ item-position (string-length "#item/")))
           (tail (substring selector tail-start (string-length selector)))
           (segment-position (string-contains tail "/segment/"))
           (root-tail
            (if segment-position
              (substring tail 0 segment-position)
              tail))
           (kind-separator (string-index root-tail #\/)))
      (unless kind-separator
        (error "provider-native exact selector is missing item kind" selector))
      (let* ((kind (substring root-tail 0 kind-separator))
             (symbol
              (substring root-tail
                         (+ kind-separator 1)
                         (string-length root-tail)))
             (root-end
              (if segment-position
                (+ tail-start segment-position)
                (string-length selector)))
             (root (substring selector 0 root-end)))
        (if segment-position
          (let* ((segment-start
                  (+ segment-position (string-length "/segment/")))
                 (segment-tail
                  (substring tail segment-start (string-length tail)))
                 (parts (string-split segment-tail #\/)))
            (unless (= (length parts) 2)
              (error "provider-native exact descendant selector is malformed"
                     selector))
            (vector selector root owner kind symbol
                    (car parts) (cadr parts)))
          (vector selector root owner kind symbol #f #f))))))

(def (selector-requested selector) (vector-ref selector 0))
(def (selector-root selector) (vector-ref selector 1))
(def (selector-owner selector) (vector-ref selector 2))
(def (selector-kind selector) (vector-ref selector 3))
(def (selector-symbol selector) (vector-ref selector 4))
(def (selector-segment-kind selector) (vector-ref selector 5))
(def (selector-segment-identity selector) (vector-ref selector 6))

(def +definition-kind-aliases+
  '(("function" "def" "function")
    ("method" "defmethod" "method")
    ("macro" "defsyntax" "macro")))

;; : (-> String String Boolean)
(def (definition-kind-matches? selector-kind definition-kind)
  (let (aliases (assoc selector-kind +definition-kind-aliases+ equal?))
    (if aliases
      (member definition-kind (cdr aliases))
      (equal? selector-kind definition-kind))))

(def (temporary-source-name)
  (string-append "asp-gerbil-scheme-exact-" (symbol->string (gensym)) ".ss"))

(def (with-parsed-source source-text proc)
  (let* ((name (temporary-source-name))
         (path (string-append "/tmp/" name)))
    (with-catch
     (lambda (exception)
       (when (file-exists? path)
         (delete-file path))
       (raise exception))
     (lambda ()
       (call-with-output-file path
         (lambda (port)
           (display source-text port)))
       (let (result
             (proc (vector
                    (parse-exact-owner-definitions path name)
                    (read-exact-owner-forms path))))
         (delete-file path)
         result)))))

;; Parser line ranges are one-based and inclusive. Returned byte ranges are
;; zero-based and end-exclusive.
(def (line-range->byte-range starts byte-length start-line end-line)
  (let* ((start-index (- start-line 1))
         (start
          (if (< start-index (vector-length starts))
            (vector-ref starts start-index)
            byte-length))
         (end
          (if (< end-line (vector-length starts))
            (vector-ref starts end-line)
            byte-length)))
    (vector start end)))

;; A segment is [kind label start-line end-line ordinal].
(def (make-segment kind label start-line end-line)
  (vector kind label start-line end-line 0))
(def (segment-kind segment) (vector-ref segment 0))
(def (segment-label segment) (vector-ref segment 1))
(def (segment-start-line segment) (vector-ref segment 2))
(def (segment-end-line segment) (vector-ref segment 3))
(def (segment-ordinal segment) (vector-ref segment 4))

(def (segment-before? left right)
  (or (< (segment-start-line left) (segment-start-line right))
      (and (= (segment-start-line left) (segment-start-line right))
           (< (segment-end-line left) (segment-end-line right)))))

(def (insert-segment segment segments)
  (cond
   ((null? segments) [segment])
   ((segment-before? segment (car segments))
    (cons segment segments))
   (else
    (cons (car segments)
          (insert-segment segment (cdr segments))))))

(def (sort-segments segments)
  (foldl insert-segment '() segments))

(def (exit-callee? callee)
  (member callee '("abort" "error" "errorf" "exit" "raise")))

(def (facts-from-forms extractor owner-path forms)
  (apply append
         (map (lambda (form)
                (extractor owner-path form (syntax->datum form)))
              forms)))

(def (collect-callable-segments owner-path forms definition)
  (let* ((name (definition-name definition))
         (bindings
          (map (lambda (fact)
                 (make-segment "binding"
                               (binding-fact-name fact)
                               (binding-fact-start fact)
                               (binding-fact-end fact)))
               (filter (lambda (fact)
                         (and (equal? (binding-fact-scope fact) name)
                              (not (equal? (binding-fact-kind fact)
                                           "formal"))))
                       (facts-from-forms binding-facts-from-form
                                         owner-path forms))))
         (control-flow
          (filter (lambda (fact)
                    (equal? (control-flow-fact-caller fact) name))
                  (facts-from-forms control-flow-facts-from-form
                                    owner-path forms)))
         (branches
          (map (lambda (fact)
                 (make-segment "branch"
                               (control-flow-fact-kind fact)
                               (control-flow-fact-start fact)
                               (control-flow-fact-end fact)))
               (filter (lambda (fact)
                         (not (equal? (control-flow-fact-role fact)
                                      "manual-loop")))
                       control-flow)))
         (loops
          (map (lambda (fact)
                 (make-segment "loop"
                               (control-flow-fact-kind fact)
                               (control-flow-fact-start fact)
                               (control-flow-fact-end fact)))
               (filter (lambda (fact)
                         (equal? (control-flow-fact-role fact)
                                 "manual-loop"))
                       control-flow)))
         (exits
          (map (lambda (fact)
                 (make-segment "exit"
                               (call-fact-callee fact)
                               (call-fact-start fact)
                               (call-fact-end fact)))
               (filter (lambda (fact)
                         (and (equal? (call-fact-caller fact) name)
                              (exit-callee? (call-fact-callee fact))))
                       (facts-from-forms calls-from-form owner-path forms))))
         (ordered (sort-segments (append bindings branches loops exits))))
    (let loop ((rest ordered) (ordinal 1) (out '()))
      (if (null? rest)
        (reverse out)
        (let (segment (car rest))
          (vector-set! segment 4 ordinal)
          (loop (cdr rest) (+ ordinal 1) (cons segment out)))))))

(def (exact-selector-json request selector segment)
  (let* ((segment?
          (and segment #t))
         (identity
          (and segment
               (string-append "ordinal-"
                              (number->string
                               (segment-ordinal segment)))))
         (structural-selector
          (if segment
            (string-append (selector-root selector)
                           "/segment/"
                           (segment-kind segment)
                           "/"
                           identity)
            (selector-root selector)))
         (segments
          (if segment
            [(hash (relation "contains")
                   (kind (segment-kind segment))
                   (identity identity)
                   (label (segment-label segment)))]
            [])))
    (hash
     (schemaId +exact-selector-schema-id+)
     (schemaVersion "1")
     (languageId +language-id+)
     (ownerPath (selector-owner selector))
     (selector structural-selector)
     (generationIdentityDigest
      (required-string request "generationIdentityDigest"))
     (parserIdentityDigest
      (required-string request "parserIdentityDigest"))
     (queryPackDigest
      (required-string request "queryPackDigest"))
     (rootItemSelector
      (hash
       (schemaId +canonical-selector-schema-id+)
       (schemaVersion "1")
       (languageId +language-id+)
       (kind (selector-kind selector))
       (symbol (selector-symbol selector))
       (scopes [])
       (structuralSelector (selector-root selector))))
     (segments segments))))

(def (segment-byte-range segment starts byte-length)
  (line-range->byte-range starts
                          byte-length
                          (segment-start-line segment)
                          (segment-end-line segment)))

(def (segment-node request selector segment starts byte-length)
  (let* ((range (segment-byte-range segment starts byte-length))
         (node-id
          (string-append (segment-kind segment)
                         ":"
                         (number->string (segment-ordinal segment)))))
    (hash
     (nodeId node-id)
     (kind (segment-kind segment))
     (label (segment-label segment))
     (order (segment-ordinal segment))
     (queryable #t)
     (exactSelector (exact-selector-json request selector segment))
     (sourceLocatorHint
      (hash (sourceByteStart (vector-ref range 0))
            (sourceByteEnd (vector-ref range 1)))))))

(def (callable-skeleton-json request selector definition segments
                             starts byte-length root-range)
  (let* ((root-exact (exact-selector-json request selector #f))
         (root-node
          (hash
           (nodeId "callable:root")
           (kind "callable")
           (label (definition-name definition))
           (order 0)
           (queryable #t)
           (exactSelector root-exact)
           (languageFacts
            (hash (formalCount (length (definition-formals definition)))
                  (definitionKind (definition-kind definition))))))
         (child-nodes
          (map (lambda (segment)
                 (segment-node request selector segment starts byte-length))
               segments))
         (relations
          (map (lambda (segment)
                 (hash
                  (fromNodeId "callable:root")
                  (toNodeId
                   (string-append
                    (segment-kind segment)
                    ":"
                    (number->string (segment-ordinal segment))))
                  (kind "contains")))
               segments))
         (source-bytes (- (vector-ref root-range 1)
                          (vector-ref root-range 0)))
         (projected-bytes
          (min source-bytes
               (+ (string-length (definition-name definition))
                  (foldl (lambda (segment total)
                           (+ total
                              (string-length (segment-label segment))))
                         0
                         segments)))))
    (hash
     (rootSelector root-exact)
     (rootNodeId "callable:root")
     (callable
      (hash (kind (selector-kind selector))
            (displayName (definition-name definition))
            (signature (definition-name definition))))
     (nodes (list->vector (cons root-node child-nodes)))
     (relations (list->vector relations))
     (cost
      (hash (sourceBytes source-bytes)
            (projectedBytes projected-bytes)
            (omittedBytes (- source-bytes projected-bytes))))
     (languageFacts
      (hash (parser "gerbil-native-reader")
            (syntax "gerbil-scheme"))))))

(def (projection-response request selector projection-kind byte-range
                          projection-text projection-payload)
  (let (packet
        (hash
         (schemaId +response-schema-id+)
         (schemaVersion "1")
         (languageId +language-id+)
         (providerId +provider-id+)
         (ownerPath (selector-owner selector))
         (projectionMode projection-kind)
         (requestedStructuralSelector (selector-requested selector))
         (structuralSelector (selector-requested selector))
         (resolutionState "resolved")
         (normalizedParserFacts
          (hash
           (itemKind (selector-kind selector))
           (itemName (selector-symbol selector))
           (ownerPath (selector-owner selector))
           (resolvedSelector (selector-requested selector))
           (resolutionState "resolved")))
         (sourceContentDigest (required-string request "sourceDigest"))
         (sourceByteStart (vector-ref byte-range 0))
         (sourceByteEnd (- (vector-ref byte-range 1) 1))))
    (when projection-text
      (hash-put! packet 'projectionText projection-text))
    (when projection-payload
      (hash-put! packet 'projectionPayload projection-payload))
    packet))

(def (resolve-descendant segments selector)
  (let ((kind (selector-segment-kind selector))
        (identity (selector-segment-identity selector)))
    (and kind
         (find (lambda (segment)
                 (and (equal? (segment-kind segment) kind)
                      (equal?
                       (string-append
                        "ordinal-"
                        (number->string (segment-ordinal segment)))
                       identity)))
               segments))))

;;; Exact projection resolves the callable once, computes byte ranges from the
;;; shared line-offset index, and then selects source or skeleton rendering.
;;; Descendant selection is valid only for source projections; all failures
;;; retain the original requested selector so callers receive deterministic
;;; evidence instead of a widened owner-level fallback.
(def (project-parsed-request request selector source-bytes parsed)
  (let* ((definitions (vector-ref parsed 0))
         (forms (vector-ref parsed 1))
         (definition
          (find (lambda (candidate)
                  (and (equal? (definition-name candidate)
                               (selector-symbol selector))
                       (definition-kind-matches?
                        (selector-kind selector)
                        (definition-kind candidate))))
                definitions))
         (byte-length (u8vector-length source-bytes))
         (starts (u8vector-line-start-offsets source-bytes)))
    (unless definition
      (error "provider-native exact selector does not resolve"
             (selector-root selector)))
    (let* ((root-range
            (line-range->byte-range starts
                                    byte-length
                                    (definition-start definition)
                                    (definition-end definition)))
           (segments (collect-callable-segments
                      (selector-owner selector) forms definition))
           (projection-kind (required-string request "projectionKind")))
      (cond
       ((equal? projection-kind "source")
        (let* ((selected
                (if (selector-segment-kind selector)
                  (or (resolve-descendant segments selector)
                      (error "provider-native exact descendant does not resolve"
                             (selector-requested selector)))
                  #f))
               (range
                (if selected
                  (segment-byte-range selected starts byte-length)
                  root-range))
               (text
                (utf8->string
                 (subu8vector source-bytes
                              (vector-ref range 0)
                              (vector-ref range 1)))))
          (projection-response request selector "source" range text #f)))
       ((equal? projection-kind "callable-skeleton")
        (when (selector-segment-kind selector)
          (error "callable-skeleton requires a root callable selector"))
        (projection-response
         request
         selector
         "callable-skeleton"
         root-range
         #f
         (callable-skeleton-json request
                                 selector
                                 definition
                                 segments
                                 starts
                                 byte-length
                                 root-range)))
       (else
        (error "unsupported provider-native exact projection kind"
               projection-kind))))))

(def (validate-request request provider-id parser-identity-digest
                       query-pack-digest)
  (assert-equal "schemaId"
                (required-string request "schemaId")
                +request-schema-id+)
  (assert-equal "schemaVersion"
                (required-string request "schemaVersion")
                "1")
  (assert-equal "transport"
                (required-string request "transport")
                "stdin-json")
  (assert-equal "sourceEncoding"
                (required-string request "sourceEncoding")
                "base64")
  (assert-equal "languageId"
                (required-string request "languageId")
                +language-id+)
  (assert-equal "providerId"
                (required-string request "providerId")
                provider-id)
  (assert-equal "parserIdentityDigest"
                (required-string request "parserIdentityDigest")
                parser-identity-digest)
  (assert-equal "queryPackDigest"
                (required-string request "queryPackDigest")
                query-pack-digest)
  (required-string request "generationIdentityDigest")
  (required-string request "sourceDigest")
  (required-string request "ownerPath")
  (required-string request "structuralSelector")
  (required-integer request "sourceByteLength"))

(def (project-provider-native-exact-request request
                                            provider-id
                                            parser-identity-digest
                                            query-pack-digest)
  (validate-request request
                    provider-id
                    parser-identity-digest
                    query-pack-digest)
  (let* ((selector
          (parse-exact-selector
           (required-string request "structuralSelector")))
         (source-bytes
          (base64-decode
           (required-string request "sourceBytesBase64")))
         (source-length
          (required-integer request "sourceByteLength")))
    (assert-equal "ownerPath"
                  (selector-owner selector)
                  (required-string request "ownerPath"))
    (assert-equal "sourceByteLength"
                  (u8vector-length source-bytes)
                  source-length)
    (let (source-text (utf8->string source-bytes))
      (with-parsed-source
       source-text
       (lambda (file)
         (project-parsed-request request selector source-bytes file))))))
