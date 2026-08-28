;;; -*- Gerbil -*-
;;; Parser selector and project aggregation helpers.

(import :gerbil/gambit
        :gslph/src/parser/model
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :std/sugar hash-get hash-key? hash-put!))

(export project-definitions
        project-calls
        project-macro-family-facts
        project-predicate-family-facts
        project-field-access-pattern-facts
        project-projection-burst-facts
        project-boolean-condition-facts
        project-loop-driver-facts
        project-dependency-adapter-quality-facts
        project-function-quality-profiles
        project-typed-contract-facts
        project-comment-quality-facts
        find-owner
        definition-selector
        selector-owner-path-encode
        call-fact-selector
        module-import-fact-selector
        module-export-fact-selector
        macro-fact-selector
        macro-family-fact-selector
        binding-fact-selector
        poo-form-fact-selector
        higher-order-fact-selector
        control-flow-fact-selector
        predicate-family-fact-selector
        field-access-pattern-fact-selector
        projection-burst-fact-selector
        boolean-condition-fact-selector
        loop-driver-fact-selector
        dependency-adapter-quality-fact-selector
        function-quality-profile-selector
        typed-contract-fact-selector
        comment-quality-fact-selector
        top-form-selector
        item-structural-selector
        selector-component-canonicalize
        relative-path
        source-full-path
        normalize-owner)

;;; Projection cache boundary:
;;; - ProjectIndex is immutable for a policy/check pass, but policy rules ask
;;;   for the same flattened fact families many times.
;;; - Cache projections by ProjectIndex object identity without changing the
;;;   public ProjectIndex struct shape used by downstream code.
;; Weak keys are required: a projection cache must not become the owner of an
;; otherwise unreachable full-project index across repeated queries.
;; : HashTable
(def +project-projection-cache+ (make-table weak-keys: #t))

;; : (-> ProjectIndex HashTable)
(def (project-projection-cache index)
  (if (hash-key? +project-projection-cache+ index)
    (hash-get +project-projection-cache+ index)
    (let (cache (make-hash-table))
      (hash-put! +project-projection-cache+ index cache)
      cache)))

;; : (-> ProjectIndex Symbol (-> SourceFile List) List)
(def (project-fact-projection index key accessor)
  (let (cache (project-projection-cache index))
    (if (hash-key? cache key)
      (hash-get cache key)
      (let (facts (apply append (map accessor (project-index-files index))))
        (hash-put! cache key facts)
        facts))))

;;; Aggregation boundary:
;;; - Keep project-level fact projections outside the source reader.
;;; - Preserve source-file-owned ordering for policy and search packets.
;; : (-> ProjectIndex (List Definition) )
(def (project-definitions index)
  (project-fact-projection index 'definitions source-file-definitions))

;;; Call aggregation preserves source-file order so selector and search packet
;;; output stay deterministic across project collection runs.
;; : (-> ProjectIndex (List CallFact) )
(def (project-calls index)
  (project-fact-projection index 'calls source-file-calls))

;;; Macro-family facts are source-owned cross-macro evidence.
;;; The project projection only flattens files for policy and search consumers.
;; : (-> ProjectIndex (List MacroFamilyFact) )
(def (project-macro-family-facts index)
  (project-fact-projection index 'macro-family-facts
                           source-file-macro-family-facts))

;;; Predicate-family facts are already source-owned by the native parser.
;;; The project projection only flattens file buckets for policy and search.
;; : (-> ProjectIndex (List PredicateFamilyFact) )
(def (project-predicate-family-facts index)
  (project-fact-projection index 'predicate-family-facts
                           source-file-predicate-family-facts))

;;; Field-access facts must remain separate from predicate-family thresholds so
;;; agent repair can explain selector-helper evidence independently.
;; : (-> ProjectIndex (List FieldAccessPatternFact) )
(def (project-field-access-pattern-facts index)
  (project-fact-projection index 'field-access-pattern-facts
                           source-file-field-access-pattern-facts))

;;; Projection-burst facts are caller-scoped native evidence for output/projection walls.
;;; Policy consumers decide thresholds through detection profiles.
;; : (-> ProjectIndex (List ProjectionBurstFact) )
(def (project-projection-burst-facts index)
  (project-fact-projection index 'projection-burst-facts
                           source-file-projection-burst-facts))

;;; Boolean-condition facts keep individual predicate helpers queryable even
;;; when a family-level policy finding owns the repair decision.
;; : (-> ProjectIndex (List BooleanConditionFact) )
(def (project-boolean-condition-facts index)
  (project-fact-projection index 'boolean-condition-facts
                           source-file-boolean-condition-facts))

;;; Loop-driver facts distinguish pure transform drift from IO/runtime driver
;;; boundaries before policy decides whether a named let should remain.
;; : (-> ProjectIndex (List LoopDriverFact) )
(def (project-loop-driver-facts index)
  (project-fact-projection index 'loop-driver-facts
                           source-file-loop-driver-facts))

;;; Dependency adapter facts expose define-type/protocol wrappers over imported
;;; dependency primitives before policy decides whether the boundary is strong.
;; : (-> ProjectIndex (List DependencyAdapterQualityFact) )
(def (project-dependency-adapter-quality-facts index)
  (project-fact-projection index 'dependency-adapter-quality-facts
                           source-file-dependency-adapter-quality-facts))

;;; Function-quality profiles are the function-level join across parser fact families.
;;; Keep this projection first-class so repair planning can group by function.
;; : (-> ProjectIndex (List FunctionQualityProfile) )
(def (project-function-quality-profiles index)
  (project-fact-projection index 'function-quality-profiles
                           source-file-function-quality-profiles))

;;; Typed-contract facts are flattened after parsing so R013 can stay a policy
;;; consumer of native evidence rather than re-reading comment text.
;; : (-> ProjectIndex (List TypedContractFact) )
(def (project-typed-contract-facts index)
  (project-fact-projection index 'typed-contract-facts
                           source-file-typed-contract-facts))

;;; Comment-quality facts carry parser evidence for R015 repair prompts.
;;; Keeping this as a projection helper lets check, info, and search share the
;;; same native evidence list.
;; : (-> ProjectIndex (List CommentQualityFact) )
(def (project-comment-quality-facts index)
  (project-fact-projection index 'comment-quality-facts
                           source-file-comment-quality-facts))

;;; Owner lookup boundary:
;;; - Normalize user-facing owner paths before comparing parser-owned paths.
;;; - Keep parse-source-file independent from query selector policy.
;; : (-> ProjectIndex String SourceFile )
(def (find-owner index owner)
  (find (lambda (file) (equal? (source-file-path file) (normalize-owner owner)))
        (project-index-files index)))

;; : (-> Definition Selector )
(def (definition-selector defn)
  (item-structural-selector (definition-path defn)
                            (definition-kind defn)
                            (definition-name defn)))

;; : (-> CallFact Selector )
(def (call-fact-selector call)
  (selector-from call-fact-path call-fact-start call-fact-end call))

;; : (-> Fact Selector )
(def (module-import-fact-selector fact)
  (selector-from module-import-fact-path
                 module-import-fact-start
                 module-import-fact-end
                 fact))

;; : (-> Fact Selector )
(def (module-export-fact-selector fact)
  (selector-from module-export-fact-path
                 module-export-fact-start
                 module-export-fact-end
                 fact))

;; : (-> Fact Selector )
(def (macro-fact-selector fact)
  (selector-from macro-fact-path macro-fact-start macro-fact-end fact))

;; : (-> Fact Selector )
(def (macro-family-fact-selector fact)
  (selector-from macro-family-fact-path
                 macro-family-fact-start
                 macro-family-fact-end
                 fact))

;; : (-> Fact Selector )
(def (binding-fact-selector fact)
  (selector-from binding-fact-path binding-fact-start binding-fact-end fact))

;; : (-> Fact Selector )
(def (poo-form-fact-selector fact)
  (selector-from poo-form-fact-path poo-form-fact-start poo-form-fact-end fact))

;; : (-> Fact Selector )
(def (higher-order-fact-selector fact)
  (selector-from higher-order-fact-path
                 higher-order-fact-start
                 higher-order-fact-end
                 fact))

;; : (-> ControlFlowFact Selector )
(def (control-flow-fact-selector fact)
  (selector-from control-flow-fact-path
                 control-flow-fact-start
                 control-flow-fact-end
                 fact))

;; : (-> PredicateFamilyFact Selector )
(def (predicate-family-fact-selector fact)
  (selector-from predicate-family-fact-path
                 predicate-family-fact-start
                 predicate-family-fact-end
                 fact))

;; : (-> FieldAccessPatternFact Selector )
(def (field-access-pattern-fact-selector fact)
  (selector-from field-access-pattern-fact-path
                 field-access-pattern-fact-start
                 field-access-pattern-fact-end
                 fact))

;; : (-> ProjectionBurstFact Selector )
(def (projection-burst-fact-selector fact)
  (selector-from projection-burst-fact-path
                 projection-burst-fact-start
                 projection-burst-fact-end
                 fact))

;; : (-> BooleanConditionFact Selector )
(def (boolean-condition-fact-selector fact)
  (selector-from boolean-condition-fact-path
                 boolean-condition-fact-start
                 boolean-condition-fact-end
                 fact))

;; : (-> LoopDriverFact Selector )
(def (loop-driver-fact-selector fact)
  (selector-from loop-driver-fact-path
                 loop-driver-fact-start
                 loop-driver-fact-end
                 fact))

;; : (-> DependencyAdapterQualityFact Selector )
(def (dependency-adapter-quality-fact-selector fact)
  (selector-from dependency-adapter-quality-fact-path
                 dependency-adapter-quality-fact-start
                 dependency-adapter-quality-fact-end
                 fact))

;; : (-> FunctionQualityProfile Selector )
(def (function-quality-profile-selector fact)
  (selector-from function-quality-profile-path
                 function-quality-profile-start
                 function-quality-profile-end
                 fact))

;; : (-> TypedContractFact Selector )
(def (typed-contract-fact-selector fact)
  (selector-from typed-contract-fact-path
                 typed-contract-fact-comment-start
                 typed-contract-fact-comment-end
                 fact))

;; : (-> CommentQualityFact Selector )
(def (comment-quality-fact-selector fact)
  (selector-from comment-quality-fact-path
                 comment-quality-fact-comment-start
                 comment-quality-fact-comment-end
                 fact))

;; : (-> Form Selector )
(def (top-form-selector form)
  (selector-from top-form-path top-form-start top-form-end form))

;;; Selector projection boundary:
;;; - Fact-specific selector functions keep their public names.
;;; - Accessor-based projection keeps the `path:start-end` encoding in one place.
;; : (-> (-> Fact Path) (-> Fact Line) (-> Fact Line) Fact Selector)
(def (selector-from path-accessor start-accessor end-accessor fact)
  (source-range-selector (path-accessor fact)
                         (start-accessor fact)
                         (end-accessor fact)))

;;; Structural item selector encoding is parser-owned so owner-items and query
;;; share one stable item identity instead of treating symbols as file paths.
;; : (-> Path Kind Name Selector)
(def (item-structural-selector path kind name)
  (string-append "gerbil-scheme://"
                 (selector-owner-path-encode path)
                 "#item/"
                 (selector-component-encode kind)
                 "/"
                 (selector-component-encode name)))

;; Canonical selector components use the shared RFC 3986 unreserved set and
;; uppercase percent escapes, matching the language-neutral ASP contract.
(def (selector-component-encode component)
  (selector-encode component selector-component-unreserved-byte?))

(def (selector-owner-path-encode path)
  (selector-encode
   path
   (lambda (byte)
     (or (= byte 47) (selector-component-unreserved-byte? byte)))))

(def (selector-encode component byte-allowed?)
  (let ((bytes (string->utf8 component))
        (output (open-output-string)))
    (let loop ((index 0))
      (when (< index (u8vector-length bytes))
        (let (byte (u8vector-ref bytes index))
          (if (byte-allowed? byte)
            (write-char (integer->char byte) output)
            (begin
              (write-char #\% output)
              (write-char (selector-hex-digit (quotient byte 16)) output)
              (write-char (selector-hex-digit (modulo byte 16)) output)))
          (loop (+ index 1)))))
    (get-output-string output)))

(def (selector-component-canonicalize component)
  (let ((bytes (string->utf8 component))
        (output (open-output-string)))
    (let loop ((index 0))
      (when (< index (u8vector-length bytes))
        (let* ((byte (u8vector-ref bytes index))
               (first-hex
                (and (= byte 37)
                     (< (+ index 2) (u8vector-length bytes))
                     (selector-hex-byte-value
                      (u8vector-ref bytes (+ index 1)))))
               (second-hex
                (and first-hex
                     (selector-hex-byte-value
                      (u8vector-ref bytes (+ index 2))))))
          (cond
           ((and first-hex second-hex)
            (write-char #\% output)
            (write-char (selector-hex-digit first-hex) output)
            (write-char (selector-hex-digit second-hex) output)
            (loop (+ index 3)))
           ((selector-component-unreserved-byte? byte)
            (write-char (integer->char byte) output)
            (loop (+ index 1)))
           (else
            (write-char #\% output)
            (write-char (selector-hex-digit (quotient byte 16)) output)
            (write-char (selector-hex-digit (modulo byte 16)) output)
            (loop (+ index 1)))))))
    (get-output-string output)))

;;; Boundary:
;;; - Byte classification stays composable so percent encoding does not grow a branch ladder.
;; : (-> Integer Boolean)
(def (selector-component-unreserved-byte? byte)
  (ormap (lambda (predicate) (predicate byte))
         (list selector-digit-byte?
               selector-uppercase-byte?
               selector-lowercase-byte?
               selector-unreserved-punctuation-byte?)))

;; : (-> Integer Boolean)
(def (selector-digit-byte? byte)
  (and (>= byte 48) (<= byte 57)))

;; : (-> Integer Boolean)
(def (selector-uppercase-byte? byte)
  (and (>= byte 65) (<= byte 90)))

;; : (-> Integer Boolean)
(def (selector-lowercase-byte? byte)
  (and (>= byte 97) (<= byte 122)))

;; : (-> Integer Boolean)
(def (selector-unreserved-punctuation-byte? byte)
  ;; Structural selector components use RFC 3986 unreserved bytes only;
  ;; query delimiters such as `?` must be percent-encoded.
  (member byte '(45 46 95 126)))

(def (selector-hex-byte-value byte)
  (cond
   ((selector-digit-byte? byte) (- byte 48))
   ((and (>= byte 65) (<= byte 70)) (+ 10 (- byte 65)))
   ((and (>= byte 97) (<= byte 102)) (+ 10 (- byte 97)))
   (else #f)))

(def (selector-hex-digit value)
  (integer->char (+ value (if (< value 10) 48 55))))

;;; Range selector encoding is shared by parser, search, snapshots, and CLI query.
;;; Keep the string shape centralized so colon/dash compatibility cannot drift.
;; : (-> Path Line Line Selector)
(def (source-range-selector path start end)
  (string-append path ":"
                 (number->string start)
                 "-"
                 (number->string end)))

;;; Path normalization boundary:
;;; - Project paths are stored relative to the collected root.
;;; - Absolute selectors stay stable for CLI callers before becoming relpaths.
;; : (-> String String String )
(def (relative-path root path)
  (let* ((root* (canonical-root-path root))
         (path* (path-normalize (path-expand path root*)))
         (prefix (if (string-suffix? "/" root*) root* (string-append root* "/"))))
    (if (string-prefix? prefix path*)
      (substring path* (string-length prefix) (string-length path*))
      path*)))

;; : (-> String String )
(def (canonical-root-path root)
  (let (path (path-normalize (path-expand "" root)))
    (if (and (> (string-length path) 1)
             (string-suffix? "/" path))
      (substring path 0 (- (string-length path) 1))
      path)))

;; : (-> String String String )
(def (source-full-path root path)
  (if (string-prefix? "/" path)
    (path-normalize path)
    (path-normalize (path-expand path (canonical-root-path root)))))

;; : (-> String NormalizeOwner )
(def (normalize-owner owner)
  (if (string-prefix? "./" owner)
    (substring owner 2 (string-length owner))
    owner))
