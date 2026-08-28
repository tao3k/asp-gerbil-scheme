;;; -*- Gerbil -*-
;;; Shared ASP projection-batch adapter backed by the native Gerbil parser.

(import :gerbil/gambit
        (only-in :gslph/src/parser/exact-owner
                 parse-exact-owner-definitions)
        (only-in :gslph/src/parser/selectors
                 item-structural-selector
                 selector-owner-path-encode)
        (only-in :gslph/src/parser/model
                 definition-name
                 definition-kind
                 definition-start
                 definition-end)
        (only-in :gslph/src/parser/selectors definition-selector)
        (only-in :std/text/base64 base64-decode)
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar hash hash-key? hash-put!))

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
  (let* ((owner-headers
          (json-array->list (required-field request "owners")))
         (auxiliary-headers
          (if (hash-key? request "auxiliaryOwners")
            (json-array->list (hash-ref request "auxiliaryOwners"))
            '()))
         (materialized-headers (append owner-headers auxiliary-headers)))
    (validate-materialized-owner-headers materialized-headers)
    (with-materialized-owner-batch
     materialized-headers
     (lambda (source-root)
       (projection-response
        request
        (project-structured-owners owner-headers source-root))))))

(def (projection-response header owners)
  (hash
   ("schemaId" +response-schema-id+)
   ("schemaVersion" "1")
   ("languageId" +language-id+)
   ("providerId" +provider-id+)
   ("generationRootDigest"
    (required-nonempty-string header "generationRootDigest"))
   ("owners" (list->vector owners))))

(def (validate-owner-count owner-headers)
  (when (> (length owner-headers) +max-owner-count+)
    (error "projection batch exceeds the owner count limit"
           (length owner-headers) +max-owner-count+)))

(def (validate-materialized-owner-headers owner-headers)
  (validate-owner-count owner-headers)
  (let ((seen (make-hash-table)))
   (let loop ((rest owner-headers) (source-total 0))
    (unless (null? rest)
      (let* ((owner (car rest))
             (path (required-nonempty-string owner "ownerPath"))
             (source-bytes (required-source-bytes owner))
             (byte-length (u8vector-length source-bytes))
             (next-source-total (+ source-total byte-length)))
        (when (hash-key? seen path)
          (error "projection batch ownerPath is duplicated" path))
        (hash-put! seen path #t)
        (validate-owner-byte-length path byte-length next-source-total)
        (loop (cdr rest) next-source-total))))))

(def (validate-header header)
  (assert-equal "schemaId" (required-nonempty-string header "schemaId")
                +request-schema-id+)
  (assert-equal "schemaVersion" (required-nonempty-string header "schemaVersion") "1")
  (assert-equal "languageId" (required-nonempty-string header "languageId")
                +language-id+)
  (assert-equal "providerId" (required-nonempty-string header "providerId")
                +provider-id+)
  (required-nonempty-string header "parserIdentityDigest")
  (required-nonempty-string header "queryPackDigest"))

(def (project-structured-owners headers source-root)
  (let loop ((rest headers) (source-total 0) (item-total 0) (out '()))
    (if (null? rest)
      (reverse out)
      (let* ((owner (car rest))
             (path (required-nonempty-string owner "ownerPath"))
             (digest (required-nonempty-string owner "sourceLeafDigest"))
             (source-bytes (required-source-bytes owner))
             (byte-length (u8vector-length source-bytes))
             (next-source-total (+ source-total byte-length)))
        (validate-owner-byte-length path byte-length next-source-total)
        (let* ((projected
                (with-catch
                 (lambda (failure)
                   (error (string-append
                           "projection batch owner failed: ownerPath=" path
                           " cause=" (projection-failure-message failure))))
                 (lambda ()
                   (project-owner path digest source-bytes source-root))))
               (next-item-total
                (validated-next-item-total projected item-total path)))
          (loop (cdr rest) next-source-total next-item-total
                (cons projected out)))))))

(def (projection-failure-message failure)
  (call-with-output-string
   (lambda (port)
     (display-exception failure port))))

(def (with-materialized-owner-batch headers proc)
  (let* ((root (##create-temporary-directory))
         (source-root root)
         (previous-load-path (load-path)))
    (def (cleanup!)
      (set-load-path! previous-load-path)
      (when (file-exists? root)
        (delete-file-or-directory root #t)))
    (with-catch
     (lambda (failure)
       (cleanup!)
       (raise failure))
     (lambda ()
       (for-each
        (lambda (owner)
          (let* ((owner-path
                  (required-nonempty-string owner "ownerPath"))
                 (source-path (batch-owner-source-path source-root owner-path))
                 (source-bytes
                  (parser-safe-source-bytes (required-source-bytes owner))))
            (ensure-directory-tree! (path-directory source-path))
            (call-with-output-file source-path
              (lambda (port)
                (write-subu8vector source-bytes 0
                                   (u8vector-length source-bytes) port)))))
        headers)
       (add-load-path! source-root)
       (let (package-root (string-append source-root "/src"))
         (when (file-exists? package-root)
           (add-load-path! package-root)))
       (let (result (proc source-root))
         (cleanup!)
         result)))))

(def (batch-owner-source-path source-root owner-path)
  (let (segments (string-split owner-path #\/))
    (unless (and (not (string-empty? owner-path))
                 (not (eq? (string-ref owner-path 0) #\/))
                 (andmap (lambda (segment)
                           (and (not (string-empty? segment))
                                (not (member segment '("." "..")))))
                         segments))
      (error "projection batch ownerPath is not a canonical relative path"
             owner-path))
    (string-append source-root "/" owner-path)))

(def (ensure-directory-tree! directory)
  (let (directory (strip-trailing-directory-separators directory))
    (unless (file-exists? directory)
      (let (parent
            (strip-trailing-directory-separators (path-directory directory)))
        (unless (or (equal? parent directory) (file-exists? parent))
          (ensure-directory-tree! parent)))
      (create-directory directory))))

(def (strip-trailing-directory-separators path)
  (let loop ((end (string-length path)))
    (if (and (> end 1) (eq? (string-ref path (- end 1)) #\/))
      (loop (- end 1))
      (substring path 0 end))))

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

(def (project-owner path digest source-bytes source-root)
  (with-parsed-definitions
   (batch-owner-source-path source-root path) path
   (lambda (definitions)
     (let* ((starts (line-start-offsets source-bytes))
            (byte-length (u8vector-length source-bytes))
            (_ (when (> (length definitions) +max-owner-items+)
                 (error "projection batch owner exceeds the item limit"
                        path (length definitions) +max-owner-items+)))
            (items
             (deduplicate-projected-items
              (project-definitions path definitions starts byte-length))))
       (hash
        ("ownerPath" path)
        ("sourceLeafDigest" digest)
        ("items" (list->vector items))
        ("relations" []))))))

(def (project-definitions path definitions starts byte-length)
  (let loop ((rest definitions) (out '()))
    (if (null? rest)
      (reverse out)
      (let* ((definition (car rest))
             (recovery-end
              (next-native-definition-start
               (cdr rest) (definition-start definition)
               starts byte-length)))
        (loop (cdr rest)
              (cons (project-definition
                     path definition starts byte-length recovery-end)
                    out))))))

(def (next-native-definition-start definitions current-line starts byte-length)
  (let loop ((rest definitions))
    (if (null? rest)
      byte-length
      (let (next-line (definition-start (car rest)))
        (if (> next-line current-line)
          (line-start->byte-offset starts byte-length next-line)
          (loop (cdr rest)))))))

(def (line-start->byte-offset starts byte-length line)
  (let (index (- line 1))
    (if (and (>= index 0) (< index (vector-length starts)))
      (vector-ref starts index)
      byte-length)))

(def (deduplicate-projected-items items)
  (let (seen (make-hash-table))
    (let loop ((rest (reverse items)) (out '()))
      (if (null? rest)
        out
        (let* ((item (car rest))
               (selector (hash-ref item "selector")))
          (if (hash-key? seen selector)
            (loop (cdr rest) out)
            (begin
              (hash-put! seen selector #t)
              (loop (cdr rest) (cons item out)))))))))

(def (project-definition path definition starts byte-length recovery-end)
  (let* ((name (projection-string (definition-name definition)))
         (parser-kind (projection-string (definition-kind definition)))
         (kind (canonical-definition-kind parser-kind))
         (selector (owner-definition-selector
                    path definition kind))
         (native-range
          (line-range->byte-range
           starts byte-length
           (definition-start definition)
           (definition-end definition)))
         (range
          (if (> (vector-ref native-range 1) (vector-ref native-range 0))
            native-range
            (vector (vector-ref native-range 0) recovery-end))))
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

(def (owner-definition-selector path definition canonical-kind)
  (let* ((parser-selector (definition-selector definition))
         (parser-item-prefix "#item/")
         (item-position (string-contains parser-selector parser-item-prefix)))
    (unless item-position
      (error "parser definition selector is not canonical" parser-selector))
    (let* ((selector-tail
            (substring parser-selector
                       (+ item-position (string-length parser-item-prefix))
                       (string-length parser-selector)))
           (kind-separator (string-contains selector-tail "/")))
      (unless kind-separator
        (error "parser definition selector has no item-name segment"
               parser-selector))
      (let (item-name
            (substring selector-tail (+ kind-separator 1)
                       (string-length selector-tail)))
      (if (string-contains item-name "%")
        (string-append +language-id+ "://" (selector-owner-path-encode path)
                       "#item/" canonical-kind "/"
                       item-name)
        (item-structural-selector path canonical-kind item-name))))))

(def (canonical-definition-kind kind)
  (cond
   ((member kind '("def" "def*" "define" "define-values" "defn" "function"))
    "function")
   ((member kind '("defmethod" ".defmethod" "defcompile-method" "method"))
    "method")
   ((member kind '("define-syntax" "defsyntax" "defsyntax-for-match"
                   "defrules" "defrule" "defsyntax-parameter"
                   "defsyntax-parameter*" "defsyntax-for-import"
                   "defsyntax-for-export" "defsyntax-for-import-export"
                   "def-stx" "defsyntax-stx" "defsyntax-stx/form" "macro"))
    "macro")
   ((equal? kind "defstruct") "struct")
   ((member kind '("defclass" ".defclass")) "class")
   ((equal? kind "define-type") "type")
   ((member kind '("defgeneric" ".defgeneric")) "generic")
   ((member kind '("defprotocol" ".defprotocol")) "protocol")
   ((equal? kind "defalias") "alias")
   (else "definition")))

(def (with-parsed-definitions source-path owner-path proc)
  (proc (parse-exact-owner-definitions source-path owner-path)))

;;; Native reader boundary:
;;; - Projection digests and byte ranges remain tied to the original bytes.
;;; - A few upstream corpora deliberately embed invalid UTF-8 sequences inside
;;;   string literals. Replace only invalid bytes in the temporary parse view.
;;; - Every replacement is one ASCII byte, so length and newline offsets remain
;;;   identical; valid UTF-8 identifiers and comments are preserved verbatim.
(def (parser-safe-source-bytes source-bytes)
  (let ((parser-bytes (u8vector-copy source-bytes))
        (length (u8vector-length source-bytes)))
    (let loop ((index 0))
      (when (< index length)
        (let (sequence-length
              (valid-utf8-sequence-length source-bytes index length))
          (if (number? sequence-length)
            (loop (+ index sequence-length))
            (begin
              (u8vector-set! parser-bytes index 63)
              (loop (+ index 1)))))))
    (normalize-r4rs-named-character-literals! parser-bytes length)
    parser-bytes))

;;; R4RS/Gambit source treats named character literals case-insensitively, while
;;; the Gerbil reader accepts the canonical lowercase spelling. Case-fold only
;;; multi-letter ASCII names in the temporary parser view. A one-letter literal
;;; such as #\A remains the character A. This transform is byte-length preserving.
(def (normalize-r4rs-named-character-literals! bytes length)
  (let loop ((index 0))
    (when (< index length)
      (if (and (< (+ index 2) length)
               (= (u8vector-ref bytes index) 35)
               (= (u8vector-ref bytes (+ index 1)) 92)
               (ascii-letter-byte? (u8vector-ref bytes (+ index 2))))
        (let (end (ascii-letter-run-end bytes (+ index 2) length))
          (when (> (- end (+ index 2)) 1)
            (ascii-lowercase-range! bytes (+ index 2) end))
          (loop end))
        (loop (+ index 1))))))

(def (ascii-letter-run-end bytes start length)
  (let loop ((index start))
    (if (and (< index length)
             (ascii-letter-byte? (u8vector-ref bytes index)))
      (loop (+ index 1))
      index)))

(def (ascii-letter-byte? byte)
  (or (<= 65 byte 90) (<= 97 byte 122)))

(def (ascii-lowercase-range! bytes start end)
  (let loop ((index start))
    (when (< index end)
      (let (byte (u8vector-ref bytes index))
        (when (<= 65 byte 90)
          (u8vector-set! bytes index (+ byte 32))))
      (loop (+ index 1)))))

(def (valid-utf8-sequence-length bytes index length)
  (let (first (u8vector-ref bytes index))
    (cond
     ((<= first #x7f) 1)
     ((and (<= #xc2 first #xdf)
           (utf8-continuation-at? bytes (+ index 1) length))
      2)
     ((and (= first #xe0)
           (utf8-byte-in-range-at? bytes (+ index 1) length #xa0 #xbf)
           (utf8-continuation-at? bytes (+ index 2) length))
      3)
     ((and (or (<= #xe1 first #xec) (<= #xee first #xef))
           (utf8-continuation-at? bytes (+ index 1) length)
           (utf8-continuation-at? bytes (+ index 2) length))
      3)
     ((and (= first #xed)
           (utf8-byte-in-range-at? bytes (+ index 1) length #x80 #x9f)
           (utf8-continuation-at? bytes (+ index 2) length))
      3)
     ((and (= first #xf0)
           (utf8-byte-in-range-at? bytes (+ index 1) length #x90 #xbf)
           (utf8-continuation-at? bytes (+ index 2) length)
           (utf8-continuation-at? bytes (+ index 3) length))
      4)
     ((and (<= #xf1 first #xf3)
           (utf8-continuation-at? bytes (+ index 1) length)
           (utf8-continuation-at? bytes (+ index 2) length)
           (utf8-continuation-at? bytes (+ index 3) length))
      4)
     ((and (= first #xf4)
           (utf8-byte-in-range-at? bytes (+ index 1) length #x80 #x8f)
           (utf8-continuation-at? bytes (+ index 2) length)
           (utf8-continuation-at? bytes (+ index 3) length))
      4)
     (else #f))))

(def (utf8-continuation-at? bytes index length)
  (utf8-byte-in-range-at? bytes index length #x80 #xbf))

(def (utf8-byte-in-range-at? bytes index length lower upper)
  (and (< index length)
       (<= lower (u8vector-ref bytes index) upper)))

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
    (unless (string? value)
      (error "projection batch field must be a string" key))
    value))

(def (required-nonempty-string object key)
  (let (value (required-string object key))
    (when (zero? (string-length value))
      (error "projection batch field must be a non-empty string" key))
    value))

(def (required-source-bytes owner)
  (let (encoding (required-nonempty-string owner "sourceEncoding"))
    (cond
     ((string=? encoding "utf8")
      (when (hash-ref owner "sourceBytesBase64" #f)
        (error "projection batch UTF-8 owner has a base64 payload"))
      (string->utf8 (required-string owner "sourceText")))
     ((string=? encoding "base64")
      (when (hash-ref owner "sourceText" #f)
        (error "projection batch base64 owner has a text payload"))
      (base64-decode (required-string owner "sourceBytesBase64")))
     (else
      (error "projection batch source encoding is not supported" encoding)))))

(def (json-array->list value)
  (cond
   ((vector? value) (vector->list value))
   ((list? value) value)
   (else (error "projection batch owners must be an array"))))

(def (assert-equal label actual expected)
  (unless (equal? actual expected)
    (error "projection batch request identity mismatch"
           label actual expected)))
