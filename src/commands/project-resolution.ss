;;; -*- Gerbil -*-
;;; Typed Gerbil package scope from ASP-admitted candidates.

(import :gerbil/gambit
        (only-in :gslph/src/constants +language-id+ +provider-id+)
        (only-in :gslph/src/parser/package
                 project-package-dependencies
                 project-package-name
                 project-package-source-scope-policy
                 read-project-package
                 source-scope-policy-roots
                 source-scope-policy-runtime-roots)
        :std/crypto/digest
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/1 filter-map find)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :std/sugar hash))

(export project-resolution-request->response)

(def +request-schema-id+
  "agent.semantic-protocols.provider-project-resolution-request")
(def +response-schema-id+
  "agent.semantic-protocols.provider-project-resolution-response")
(def +scope-schema-id+
  "agent.semantic-protocols.project-resolution")
(def +package-graph-schema-id+
  "agent.semantic-protocols.language-package-graph")
(def +parser-id+ "gerbil.package-spec")
(def +source-extensions+ '(".ss" ".ssi" ".scm" ".sld"))
(def +hex-digits+ "0123456789abcdef")

(defstruct project-resolution-not-applicable ())

(def (project-resolution-request->response request)
  (validate-project-resolution-request request)
  (let* ((workspace-root (path-normalize (current-directory)))
         (candidates
          (json-array->list (required-field request "candidatePaths")))
         (candidate-manifests
          (filter (lambda (path) (string-suffix? "/gerbil.pkg"
                                                 (string-append "/" path)))
                  candidates))
         (manifests
          (if (member "gerbil.pkg" candidate-manifests)
            ["gerbil.pkg"]
            [])))
    (when (null? candidate-manifests)
      (raise (make-project-resolution-not-applicable)))
    (when (null? manifests)
      (error "provider project entry is required: tracked gerbil.pkg"))
    (let* ((packages
            (filter-map
             (lambda (manifest)
               (gerbil-package-scope workspace-root manifest candidates))
             manifests))
           (entry-manifest (car manifests)))
      (when (null? packages)
        (error "candidate gerbil.pkg files declare no package metadata"))
      (let* ((generation
              (required-string
               (required-hash request "candidateGeneration")
               "digest"))
             (unresolved
              (filter-map package-unresolved packages))
             (scopes
              (filter-map package-source-scope packages))
             (internal-edges
              (package-internal-dependencies packages))
             (external-dependencies
              (package-external-dependencies packages)))
        (hash
         ("schemaId" +response-schema-id+)
         ("schemaVersion" "1")
         ("languageId" +language-id+)
         ("providerId" +provider-id+)
         ("state" "resolved")
         ("scope"
          (hash
           ("schemaId" +scope-schema-id+)
           ("schemaVersion" "1")
           ("state" "resolved")
           ("completeness" (if (null? unresolved) "exact" "partial"))
           ("languageId" +language-id+)
           ("providerId" +provider-id+)
           ("parserId" +parser-id+)
           ("candidateGenerationDigest" generation)
           ("projectEntry" entry-manifest)
           ("packageGraph"
            (hash
             ("schemaId" +package-graph-schema-id+)
             ("schemaVersion" "1")
             ("languageId" +language-id+)
             ("providerId" +provider-id+)
             ("projectEntry" entry-manifest)
             ("parserId" +parser-id+)
             ("manifests"
              (map (lambda (path)
                     (project-file workspace-root path "gerbil-package"))
                   manifests))
             ("lockfiles" [])
             ("packages" (map package-document packages))
             ("internalDependencyEdges" internal-edges)
             ("externalDependencies" external-dependencies)
             ("unresolved" unresolved)))
           ("sourceScopes" scopes)
           ("conflicts" [])
           ("metrics"
            (hash
             ("parsedManifestCount" (length manifests))
             ("parsedLockfileCount" 0)
             ("affectedPackageCount" (length packages))
             ("fullWorkspaceReads" 0)
             ("fullManifestReparses" 0)
             ("dbOpens" 0)
             ("elapsedMicros" 0))))))))))

(def (validate-project-resolution-request request)
  (unless (hash-table? request)
    (error "project-resolution request must be a JSON object"))
  (unless (equal? (required-string request "schemaId") +request-schema-id+)
    (error "project-resolution request schema must be v1"))
  (unless (equal? (required-string request "schemaVersion") "1")
    (error "project-resolution request schema must be v1"))
  (let ((received-language-id (required-string request "languageId"))
        (received-provider-id (required-string request "providerId")))
    (unless (equal? received-language-id +language-id+)
      (error
       (string-append
        "project-resolution language identity mismatch expected="
        +language-id+
        " received="
        received-language-id)))
    (unless (equal? received-provider-id +provider-id+)
      (error
       (string-append
        "project-resolution provider identity mismatch expected="
        +provider-id+
        " received="
        received-provider-id))))
  (unless (equal? (required-string request "candidateBase") ".")
    (error "project-resolution candidateBase must be ."))
  (required-string (required-hash request "candidateGeneration") "digest")
  (validate-project-resolution-collection-scope
   (required-hash request "collectionScope"))
  (for-each
   (lambda (path)
     (unless (and (string? path) (> (string-length path) 0))
       (error "project-resolution candidate path must be a string")))
   (json-array->list (required-field request "candidatePaths")))
  (required-field request "policyExclusions"))

(def (validate-project-resolution-collection-scope scope)
  (let (kind (required-string scope "kind"))
    (cond
     ((equal? kind "complete-generation")
      (when (hash-key? scope "ownerPaths")
        (error "complete-generation collectionScope must not include ownerPaths")))
     ((equal? kind "explicit-owners")
      (let (owner-paths
            (json-array->list (required-field scope "ownerPaths")))
        (when (null? owner-paths)
          (error "explicit-owners collectionScope requires ownerPaths"))
        (for-each
         (lambda (path)
           (unless (and (string? path)
                        (> (string-length path) 0)
                        (not (equal? path "."))
                        (not (string-prefix? "/" path))
                        (equal? path (path-normalize path)))
             (error "explicit owner path must be normalized and workspace-relative" path)))
         owner-paths)))
     (else
      (error "project-resolution collectionScope is invalid" kind)))))

(def (gerbil-package-scope workspace-root manifest candidates)
  (let* ((manifest-directory (path-directory manifest))
         (relative-root
          (if (or (equal? manifest-directory "")
                  (equal? manifest-directory "."))
            "."
            manifest-directory))
         (package-root
          (path-normalize
           (path-expand relative-root workspace-root)))
         (package (read-project-package package-root)))
    (and package
         (let* ((policy (project-package-source-scope-policy package))
                (declared-roots
                 (if policy
                   (unique
                    (append (source-scope-policy-roots policy)
                            (source-scope-policy-runtime-roots policy)))
                   '()))
                (roots
                 (map (lambda (root)
                        (relative-package-path relative-root root))
                      declared-roots))
                (admitted-roots
                 (filter (lambda (root)
                           (ormap (lambda (candidate)
                                    (and (source-candidate? candidate)
                                         (path-within? candidate root)))
                                  candidates))
                         roots))
                (name (or (project-package-name package)
                          (path-normalize relative-root)))
                (package-id
                 (string-append
                  "gerbil-package-"
                  (short-digest (string-append manifest ":" name))))
                (target-id
                 (string-append
                  "gerbil-target-"
                  (short-digest (string-append package-id ":library")))))
           (hash
            ("packageId" package-id)
            ("name" name)
            ("manifestPath" manifest)
            ("root" (if (equal? relative-root ".") "." relative-root))
            ("workspaceMember" #t)
            ("targetId" target-id)
            ("sourceRoots" admitted-roots)
            ("dependencies" (project-package-dependencies package)))))))

(def (package-document package)
  (hash
   ("packageId" (hash-ref package "packageId"))
   ("name" (hash-ref package "name"))
   ("manifestPath" (hash-ref package "manifestPath"))
   ("root" (hash-ref package "root"))
   ("workspaceMember" #t)
   ("targets"
    (if (null? (hash-ref package "sourceRoots"))
      []
      [(hash
        ("targetId" (hash-ref package "targetId"))
        ("kind" "library")
        ("name" (hash-ref package "name"))
        ("explicit" #t)
        ("sourceRoots" (hash-ref package "sourceRoots"))
        ("entrypoints" [])
        ("generatedRoots" []))]))))

(def (package-source-scope package)
  (let (roots (hash-ref package "sourceRoots"))
    (and (pair? roots)
         (hash
          ("scopeId"
           (string-append
            "gerbil-source-scope-"
            (short-digest
             (string-append
              (hash-ref package "packageId")
              ":"
              (hash-ref package "targetId")))))
          ("packageId" (hash-ref package "packageId"))
          ("targetId" (hash-ref package "targetId"))
          ("roots" roots)
          ("explicitPaths" roots)
          ("extensions" +source-extensions+)
          ("includeAuthority" "manifest-explicit")
          ("exclusions" [])
          ("classifications" ["production"])))))

(def (package-unresolved package)
  (and (null? (hash-ref package "sourceRoots"))
       (hash
        ("state" "target-source-missing")
        ("path" (hash-ref package "manifestPath"))
        ("reasonKind" "package-source-scope-missing"))))

(def (package-internal-dependencies packages)
  (apply append
         (map
          (lambda (package)
            (filter-map
             (lambda (dependency)
               (let (target
                     (find (lambda (candidate)
                             (equal? dependency (hash-ref candidate "name")))
                           packages))
                 (and target
                      (hash
                       ("fromPackageId" (hash-ref package "packageId"))
                       ("toPackageId" (hash-ref target "packageId"))
                       ("kind" "normal")))))
             (hash-ref package "dependencies")))
          packages)))

(def (package-external-dependencies packages)
  (apply append
         (map
          (lambda (package)
            (filter-map
             (lambda (dependency)
               (and (not (find (lambda (candidate)
                                 (equal? dependency (hash-ref candidate "name")))
                               packages))
                    (hash
                     ("dependencyId"
                      (string-append
                       "gerbil-dependency-"
                       (short-digest
                        (string-append
                         (hash-ref package "packageId")
                         ":"
                         dependency))))
                     ("name" dependency)
                     ("kind" "normal"))))
             (hash-ref package "dependencies")))
          packages)))

(def (project-file workspace-root path kind)
  (hash
   ("path" path)
   ("kind" kind)
   ("digest"
    (sha256-text
     (call-with-input-file
      (path-expand path workspace-root)
      read-all-as-string)))))

(def (relative-package-path package-root path)
  (cond
   ((equal? path ".") package-root)
   ((or (equal? package-root "")
        (equal? package-root "."))
    path)
   (else (string-append package-root "/" path))))

(def (path-within? candidate root)
  (or (equal? root ".")
      (equal? candidate root)
      (string-prefix? (string-append root "/") candidate)))

(def (source-candidate? path)
  (ormap (lambda (extension) (string-suffix? extension path))
         +source-extensions+))

(def (unique values)
  (let loop ((remaining values) (seen '()) (result '()))
    (if (null? remaining)
      (reverse result)
      (let (value (car remaining))
        (if (member value seen)
          (loop (cdr remaining) seen result)
          (loop (cdr remaining)
                (cons value seen)
                (cons value result)))))))

(def (required-field object key)
  (let (value (hash-ref object key #f))
    (unless value
      (error "project-resolution request omitted field" key))
    value))

(def (required-hash object key)
  (let (value (required-field object key))
    (unless (hash-table? value)
      (error "project-resolution request field must be an object" key))
    value))

(def (required-string object key)
  (let (value (required-field object key))
    (unless (and (string? value) (> (string-length value) 0))
      (error "project-resolution request field must be a string" key))
    value))

(def (json-array->list value)
  (cond
   ((vector? value) (vector->list value))
   ((list? value) value)
   (else (error "project-resolution request field must be an array"))))

(def (project-resolution-not-applicable-response)
  (hash
   ("schemaId" +response-schema-id+)
   ("schemaVersion" "1")
   ("languageId" +language-id+)
   ("providerId" +provider-id+)
   ("state" "not-applicable")))

(def (project-resolution-failure reason message next-action)
  (hash
   ("schemaId" +response-schema-id+)
   ("schemaVersion" "1")
   ("languageId" +language-id+)
   ("providerId" +provider-id+)
   ("state" "failed")
   ("failure"
    (hash
     ("reasonKind" reason)
     ("message" message)
     ("nextAction" next-action)))))

(def (sha256-text text)
  (string-append
   "sha256:"
   (apply string-append
          (map byte->hex (u8vector->list (sha256 text))))))

(def (short-digest text)
  (substring (sha256-text text) 7 23))

(def (byte->hex byte)
  (string
   (string-ref +hex-digits+ (quotient byte 16))
   (string-ref +hex-digits+ (modulo byte 16))))
