;;; -*- Gerbil -*-
;;; Content-addressed expansion artifacts for expensive pure generators.
;;; This cache never decides whether a native target is current and never
;;; changes the build graph: every projected target still reaches std/make.

(import :gerbil/gambit
        (only-in "../object-family/syntax"
                 defpoo-object-family poo-family-ref)
        (only-in :std/crypto/digest sha256)
        (only-in :std/misc/path
                 path-directory path-expand path-maybe-normalize
                 path-simplify subpath?)
        (only-in :std/misc/ports read-all-as-u8vector)
        (only-in :std/srfi/13 string-prefix?)
        (only-in :std/sugar with-catch)
        (only-in :std/text/utf8 string->utf8)
        "./generated-module-projection")

(export asp-gerbil-scheme-generated-artifact-member-prototype
        asp-gerbil-scheme-generated-artifact-member
        asp-gerbil-scheme-generated-artifact-member-name
        asp-gerbil-scheme-generated-artifact-member-schema
        asp-gerbil-scheme-generated-artifact-member-validator
        asp-gerbil-scheme-generated-artifact-bundle-prototype
        asp-gerbil-scheme-generated-artifact-bundle
        asp-gerbil-scheme-generated-artifact-bundle-namespace
        asp-gerbil-scheme-generated-artifact-bundle-producer-identity
        asp-gerbil-scheme-generated-artifact-bundle-input-identity
        asp-gerbil-scheme-generated-artifact-bundle-members
        asp-gerbil-scheme-generated-artifact-bundle-artifact-roots
        asp-gerbil-scheme-generated-artifact-bundle-receipt-root
        asp-gerbil-scheme-generated-artifact-bundle-materializer
        asp-gerbil-scheme-generated-artifact-bundle-loader
        asp-gerbil-scheme-generated-artifact-bundle-artifact-paths
        asp-gerbil-scheme-generated-artifact-resolution-prototype
        asp-gerbil-scheme-generated-artifact-resolution-status
        asp-gerbil-scheme-generated-artifact-resolution-key
        asp-gerbil-scheme-generated-artifact-resolution-locators
        asp-gerbil-scheme-generated-artifact-resolution-receipt
        asp-gerbil-scheme-generated-artifact-receipt-schema
        asp-gerbil-scheme-generated-artifact-key
        asp-gerbil-scheme-generated-artifact-receipt-path
        asp-gerbil-scheme-resolve-generated-artifact-bundle!
        (import: "./generated-module-projection"))

(def asp-gerbil-scheme-generated-artifact-receipt-schema
  'asp-gerbil-scheme.generated-artifact-receipt.v1)

;; One bundle member names a domain value, its stable schema, and the
;; independent validator applied after every load, including immediately after
;; materialization.
(defpoo-object-family
  (prototype asp-gerbil-scheme-generated-artifact-member-prototype
             (name #f)
             (schema #f)
             (validator #f))
  (constructor
   (asp-gerbil-scheme-generated-artifact-member
    name: (member-name #f)
    schema: (member-schema #f)
    validator: (member-validator #f))
   (name member-name)
   (schema member-schema)
   (validator member-validator))
  (accessors poo-family-ref
             (required
              (asp-gerbil-scheme-generated-artifact-member-name name)
              (asp-gerbil-scheme-generated-artifact-member-schema schema)
              (asp-gerbil-scheme-generated-artifact-member-validator validator))
             (optional)))

;; Materializer : (-> Member Value (List Root) Locator)
;; Loader       : (-> Member Locator (List Root) Value)
;; ArtifactPaths: (-> Member Locator (List RelativePath))
(defpoo-object-family
  (prototype asp-gerbil-scheme-generated-artifact-bundle-prototype
             (namespace #f)
             (producer-identity #f)
             (input-identity #f)
             (members [])
             (artifact-roots [])
             (receipt-root #f)
             (materializer #f)
             (loader #f)
             (artifact-paths #f))
  (constructor
   (asp-gerbil-scheme-generated-artifact-bundle
    namespace: (bundle-namespace #f)
    producer-identity: (bundle-producer-identity #f)
    input-identity: (bundle-input-identity #f)
    members: (bundle-members [])
    artifact-roots: (bundle-artifact-roots [])
    receipt-root: (bundle-receipt-root #f)
    materializer: (bundle-materializer #f)
    loader: (bundle-loader #f)
    artifact-paths: (bundle-artifact-paths #f))
   (namespace bundle-namespace)
   (producer-identity bundle-producer-identity)
   (input-identity bundle-input-identity)
   (members bundle-members)
   (artifact-roots bundle-artifact-roots)
   (receipt-root bundle-receipt-root)
   (materializer bundle-materializer)
   (loader bundle-loader)
   (artifact-paths bundle-artifact-paths))
  (accessors poo-family-ref
             (required
              (asp-gerbil-scheme-generated-artifact-bundle-namespace namespace)
              (asp-gerbil-scheme-generated-artifact-bundle-producer-identity
               producer-identity)
              (asp-gerbil-scheme-generated-artifact-bundle-input-identity
               input-identity)
              (asp-gerbil-scheme-generated-artifact-bundle-members members)
              (asp-gerbil-scheme-generated-artifact-bundle-artifact-roots
               artifact-roots)
              (asp-gerbil-scheme-generated-artifact-bundle-receipt-root
               receipt-root)
              (asp-gerbil-scheme-generated-artifact-bundle-materializer
               materializer)
              (asp-gerbil-scheme-generated-artifact-bundle-loader loader)
              (asp-gerbil-scheme-generated-artifact-bundle-artifact-paths
               artifact-paths))
             (optional)))

(defpoo-object-family
  (prototype asp-gerbil-scheme-generated-artifact-resolution-prototype
             (status #f)
             (key #f)
             (locators [])
             (receipt #f))
  (constructor
   (asp-gerbil-scheme-generated-artifact-resolution
    status: (resolution-status #f)
    key: (resolution-key #f)
    locators: (resolution-locators [])
    receipt: (resolution-receipt #f))
   (status resolution-status)
   (key resolution-key)
   (locators resolution-locators)
   (receipt resolution-receipt))
  (accessors poo-family-ref
             (required
              (asp-gerbil-scheme-generated-artifact-resolution-status status)
              (asp-gerbil-scheme-generated-artifact-resolution-key key)
              (asp-gerbil-scheme-generated-artifact-resolution-locators locators)
              (asp-gerbil-scheme-generated-artifact-resolution-receipt receipt))
             (optional)))

;; : (forall (k v) (-> [(Pair k v)] k v v))
;; generated-artifact-alist-ref
;; : (-> Alist Symbol Datum Datum)
(def (generated-artifact-alist-ref value key (default #f))
  (let (entry (and (list? value) (assq key value)))
    (if entry (cdr entry) default)))

;; : (forall (n) (-> n String))
;; generated-artifact-byte->hex
;; : (-> Byte String)
(def (generated-artifact-byte->hex byte)
  (let (digits "0123456789abcdef")
    (string (string-ref digits (quotient byte 16))
            (string-ref digits (modulo byte 16)))))

;; : (forall (b) (-> b String))
;; generated-artifact-sha256
;; : (-> U8Vector Digest)
(def (generated-artifact-sha256 bytes)
  (string-append
   "sha256:"
   (apply string-append
          (map generated-artifact-byte->hex
               (u8vector->list (sha256 bytes))))))

;; : (forall (a) (-> a String))
;; generated-artifact-datum-digest
;; : (-> Datum Digest)
(def (generated-artifact-datum-digest value)
  (generated-artifact-sha256
   (string->utf8 (object->string value))))

;; : (forall (p) (-> p String))
;; generated-artifact-file-digest
;; : (-> Path Digest)
(def (generated-artifact-file-digest path)
  (call-with-input-file
   path
   (lambda (input)
     (generated-artifact-sha256 (read-all-as-u8vector input)))))

;; : (forall (p) (-> p Boolean))
;; generated-artifact-valid-relative-path?
;; : (-> Path Boolean)
(def (generated-artifact-valid-relative-path? path)
  (and (string? path)
       (> (string-length path) 0)
       (not (string-prefix? "/" path))))

;; : (forall (a) (-> a Boolean))
;; generated-artifact-canonical-datum?
;; : (-> Datum Boolean)
(def (generated-artifact-canonical-datum? value)
  (cond
   ((or (null? value)
        (boolean? value)
        (number? value)
        (char? value)
        (string? value)
        (symbol? value))
    #t)
   ((pair? value)
    (and (generated-artifact-canonical-datum? (car value))
         (generated-artifact-canonical-datum? (cdr value))))
   ((vector? value)
    (andmap generated-artifact-canonical-datum? (vector->list value)))
   (else #f)))

;; : (forall (p) (-> p p))
;; generated-artifact-normalized-root
;; : (-> Path Path)
(def (generated-artifact-normalized-root root)
  (unless (and (string? root) (> (string-length root) 0))
    (error "generated artifact root must be a non-empty path" root))
  (path-maybe-normalize (path-expand root (current-directory))))

;; : (forall (p r) (-> p r p))
;; generated-artifact-resolve-owned-path
;; : (-> Path RelativePath Path)
(def (generated-artifact-resolve-owned-path root relative)
  (unless (generated-artifact-valid-relative-path? relative)
    (error "generated artifact path must be root-relative" relative))
  (let* ((normalized-root (generated-artifact-normalized-root root))
         (simplified (path-simplify (path-expand relative normalized-root)))
         (resolved (if (file-exists? simplified)
                     (path-maybe-normalize simplified)
                     simplified)))
    (unless (subpath? resolved normalized-root)
      (error "generated artifact path escapes its root" relative root))
    resolved))

;; : (forall (p) (-> p Void))
;; generated-artifact-ensure-directory!
;; : (-> Path Void)
(def (generated-artifact-ensure-directory! path)
  (unless (file-exists? path)
    (create-directory* path)))

;; : (forall (m) (-> m Alist))
;; generated-artifact-member-signature
;; : (-> GeneratedArtifactMember Alist)
(def (generated-artifact-member-signature member)
  `((name . ,(asp-gerbil-scheme-generated-artifact-member-name member))
    (schema . ,(asp-gerbil-scheme-generated-artifact-member-schema member))))

;; : (forall (b) (-> b Alist))
;; generated-artifact-contract-identity
;; : (-> GeneratedArtifactBundle Alist)
(def (generated-artifact-contract-identity bundle)
  `((namespace
     . ,(asp-gerbil-scheme-generated-artifact-bundle-namespace bundle))
    (producerIdentity
     . ,(asp-gerbil-scheme-generated-artifact-bundle-producer-identity bundle))
    (inputDigest
     . ,(generated-artifact-datum-digest
         (asp-gerbil-scheme-generated-artifact-bundle-input-identity bundle)))
    (members
     . ,(map generated-artifact-member-signature
             (asp-gerbil-scheme-generated-artifact-bundle-members bundle)))))

;; : (forall (b) (-> b String))
;; asp-gerbil-scheme-generated-artifact-key
;; : (-> GeneratedArtifactBundle Digest)
(def (asp-gerbil-scheme-generated-artifact-key bundle)
  (generated-artifact-datum-digest
   (generated-artifact-contract-identity bundle)))

;; : (forall (b) (-> b Void))
;; generated-artifact-validate-bundle!
;; : (-> GeneratedArtifactBundle Void)
(def (generated-artifact-validate-bundle! bundle)
  (let ((namespace
         (asp-gerbil-scheme-generated-artifact-bundle-namespace bundle))
        (members
         (asp-gerbil-scheme-generated-artifact-bundle-members bundle))
        (roots
         (asp-gerbil-scheme-generated-artifact-bundle-artifact-roots bundle))
        (receipt-root
         (asp-gerbil-scheme-generated-artifact-bundle-receipt-root bundle)))
    (unless (and (generated-artifact-valid-relative-path? namespace)
                 (list? members)
                 (pair? members)
                 (list? roots)
                 (pair? roots)
                 (andmap (lambda (root)
                           (and (string? root)
                                (> (string-length root) 0)))
                         roots)
                 (string? receipt-root)
                 (> (string-length receipt-root) 0)
                 (generated-artifact-canonical-datum?
                  (asp-gerbil-scheme-generated-artifact-bundle-producer-identity
                   bundle))
                 (generated-artifact-canonical-datum?
                  (asp-gerbil-scheme-generated-artifact-bundle-input-identity
                   bundle))
                 (procedure?
                  (asp-gerbil-scheme-generated-artifact-bundle-materializer
                   bundle))
                 (procedure?
                  (asp-gerbil-scheme-generated-artifact-bundle-loader bundle))
                 (procedure?
                  (asp-gerbil-scheme-generated-artifact-bundle-artifact-paths
                   bundle)))
      (error "invalid generated artifact bundle contract" namespace))
    (generated-artifact-resolve-owned-path receipt-root namespace)
    (let loop ((remaining members) (names []))
      (when (pair? remaining)
        (let* ((artifact-member (car remaining))
               (name
                (asp-gerbil-scheme-generated-artifact-member-name
                 artifact-member))
               (schema
                (asp-gerbil-scheme-generated-artifact-member-schema
                 artifact-member))
               (validator
                (asp-gerbil-scheme-generated-artifact-member-validator
                 artifact-member)))
          (unless (and (or (symbol? name) (string? name))
                       (string? schema)
                       (procedure? validator)
                       (not (member name names)))
            (error "invalid generated artifact member contract" name))
          (loop (cdr remaining) (cons name names)))))))

;; : (forall (b) (-> b String))
;; asp-gerbil-scheme-generated-artifact-receipt-path
;; : (-> GeneratedArtifactBundle Path)
(def (asp-gerbil-scheme-generated-artifact-receipt-path bundle)
  (generated-artifact-resolve-owned-path
   (asp-gerbil-scheme-generated-artifact-bundle-receipt-root bundle)
   (string-append
    (asp-gerbil-scheme-generated-artifact-bundle-namespace bundle)
    "/receipts/"
    (asp-gerbil-scheme-generated-artifact-key bundle)
    ".ss")))

;; : (forall (b r) (-> b (Maybe r)))
;; generated-artifact-receipt-read
;; : (-> GeneratedArtifactBundle (Maybe Alist))
(def (generated-artifact-receipt-read bundle)
  (let (path (asp-gerbil-scheme-generated-artifact-receipt-path bundle))
    (and (file-exists? path)
         (with-catch
          (lambda (_) #f)
          (lambda ()
            (call-with-input-file
             path
             (lambda (input)
               (let ((receipt (read input))
                     (trailing (read input)))
                 (and (eof-object? trailing)
                      (eq? (generated-artifact-alist-ref receipt 'schema)
                           asp-gerbil-scheme-generated-artifact-receipt-schema)
                      receipt)))))))))

;; : (forall (b r p) (-> b r (List p)))
;; generated-artifact-existing-paths
;; : (-> GeneratedArtifactBundle RelativePath (List Path))
(def (generated-artifact-existing-paths bundle relative)
  (filter file-exists?
          (map (lambda (root)
                 (generated-artifact-resolve-owned-path root relative))
               (asp-gerbil-scheme-generated-artifact-bundle-artifact-roots
                bundle))))

;; : (forall (b r a) (-> b r a))
;; generated-artifact-current-file-record
;; : (-> GeneratedArtifactBundle RelativePath Alist)
(def (generated-artifact-current-file-record bundle relative)
  (let (paths (generated-artifact-existing-paths bundle relative))
    (and (pair? paths)
         (let* ((digest (generated-artifact-file-digest (car paths)))
                (matching?
                 (andmap
                  (lambda (path)
                    (string=? digest (generated-artifact-file-digest path)))
                  (cdr paths))))
           (and matching?
                `((path . ,relative) (digest . ,digest)))))))

;; : (forall (b m l a) (-> b m l (List a)))
;; generated-artifact-current-file-records
;; : (-> GeneratedArtifactBundle GeneratedArtifactMember Locator (List Alist))
(def (generated-artifact-current-file-records bundle member locator)
  (let (relative-paths
        ((asp-gerbil-scheme-generated-artifact-bundle-artifact-paths bundle)
         member locator))
    (and (list? relative-paths)
         (pair? relative-paths)
         (let (records
               (map (lambda (relative)
                      (generated-artifact-current-file-record bundle relative))
                    relative-paths))
           (and (andmap pair? records) records)))))

(def (generated-artifact-load-valid? bundle member locator)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let (value
           ((asp-gerbil-scheme-generated-artifact-bundle-loader bundle)
            member locator
            (asp-gerbil-scheme-generated-artifact-bundle-artifact-roots
             bundle)))
       (and
        ((asp-gerbil-scheme-generated-artifact-member-validator member) value)
        #t)))))

(def (generated-artifact-current-member-record bundle member locator)
  (alet (artifacts
         (generated-artifact-current-file-records bundle member locator))
    (and (generated-artifact-load-valid? bundle member locator)
         `((name
            . ,(asp-gerbil-scheme-generated-artifact-member-name member))
           (schema
            . ,(asp-gerbil-scheme-generated-artifact-member-schema member))
           (locator . ,locator)
           (artifacts . ,artifacts)))))

(def (generated-artifact-current-member-records bundle locators)
  (let (members
        (asp-gerbil-scheme-generated-artifact-bundle-members bundle))
    (and (= (length members) (length locators))
         (let (records
               (map (lambda (member locator)
                      (generated-artifact-current-member-record
                       bundle member locator))
                    members
                    locators))
           (and (andmap pair? records) records)))))

(def (generated-artifact-receipt-locators receipt)
  (map (lambda (member-record)
         (generated-artifact-alist-ref member-record 'locator))
       (generated-artifact-alist-ref receipt 'artifacts [])))

(def (generated-artifact-reuse bundle)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (alet* ((receipt (generated-artifact-receipt-read bundle))
             (key (asp-gerbil-scheme-generated-artifact-key bundle))
             (_ (equal? (generated-artifact-alist-ref receipt 'key) key))
             (_ (equal? (generated-artifact-alist-ref receipt 'contract)
                        (generated-artifact-contract-identity bundle)))
             (locators (generated-artifact-receipt-locators receipt))
             (current
              (generated-artifact-current-member-records bundle locators))
             (_ (equal? current
                        (generated-artifact-alist-ref receipt 'artifacts))))
       (asp-gerbil-scheme-generated-artifact-resolution
        status: 'reused
        key: key
        locators: locators
        receipt: receipt)))))

(def (generated-artifact-receipt bundle records)
  `((schema . ,asp-gerbil-scheme-generated-artifact-receipt-schema)
    (key . ,(asp-gerbil-scheme-generated-artifact-key bundle))
    (contract . ,(generated-artifact-contract-identity bundle))
    (artifacts . ,records)))

(def (generated-artifact-publish-receipt! bundle receipt)
  (let* ((receipt-root
          (asp-gerbil-scheme-generated-artifact-bundle-receipt-root bundle))
         (directory-relative
          (string-append
           (asp-gerbil-scheme-generated-artifact-bundle-namespace bundle)
           "/receipts"))
         (directory
          (generated-artifact-resolve-owned-path
           receipt-root directory-relative)))
    (generated-artifact-ensure-directory! directory)
    (let* ((directory
            (generated-artifact-resolve-owned-path
             receipt-root directory-relative))
           (path
            (path-expand
             (string-append
              (asp-gerbil-scheme-generated-artifact-key bundle) ".ss")
             directory)))
    (cond
     ((file-exists? path)
      (unless (equal? (generated-artifact-receipt-read bundle) receipt)
        (error "generated artifact receipt conflicts with immutable cache key"
               path)))
     (else
      (let create-temporary ()
        (let (temporary
              (string-append path ".tmp."
                             (number->string
                              (random-integer 1073741824))))
          (if (file-exists? temporary)
            (create-temporary)
            (with-exception-catcher
             (lambda (exception)
               (when (file-exists? temporary) (delete-file temporary))
               (if (equal? (generated-artifact-receipt-read bundle) receipt)
                 (void)
                 (raise exception)))
             (lambda ()
               (call-with-output-file
                temporary
                (lambda (output)
                  (write receipt output)
                  (newline output)
                  (force-output output)))
               (rename-file temporary path #f)))))))))))

(def (generated-artifact-materialize bundle values)
  (let ((members
         (asp-gerbil-scheme-generated-artifact-bundle-members bundle))
        (materialize
         (asp-gerbil-scheme-generated-artifact-bundle-materializer bundle))
        (roots
         (asp-gerbil-scheme-generated-artifact-bundle-artifact-roots bundle)))
    (unless (= (length members) (length values))
      (error "generated artifact producer returned the wrong member count"
             (length members) (length values)))
    (map (lambda (member value)
           (materialize member value roots))
         members values)))

(def (asp-gerbil-scheme-resolve-generated-artifact-bundle! bundle producer)
  (generated-artifact-validate-bundle! bundle)
  (or (generated-artifact-reuse bundle)
      (let* ((values (producer))
             (locators (generated-artifact-materialize bundle values))
             (records
              (generated-artifact-current-member-records bundle locators)))
        (unless records
          (error "generated artifact bundle failed post-materialization validation"
                 (asp-gerbil-scheme-generated-artifact-bundle-namespace bundle)))
        (let (receipt (generated-artifact-receipt bundle records))
          (generated-artifact-publish-receipt! bundle receipt)
          (asp-gerbil-scheme-generated-artifact-resolution
           status: 'generated
           key: (asp-gerbil-scheme-generated-artifact-key bundle)
           locators: locators
           receipt: receipt)))))
