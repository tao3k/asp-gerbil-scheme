;;; -*- Gerbil -*-
;;; Gerbil contract projection metadata extraction.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/runtime-contract
        :asp-gerbil-scheme/src/parser/typed-contract-scheme
        (only-in :std/srfi/13
                 string-contains
                 string-join
                 string-prefix?
                 string-trim)
        (only-in :std/misc/list unique)
        (only-in :std/srfi/1 drop-right iota last take-while)
        (only-in :std/sugar filter filter-map find foldl hash ormap))

(export typed-comment-empty-metadata
        typed-comment-metadata
        typed-comment-metadata/groups
        typed-comment-metadata/groups/signature-type
        typed-comment-signature-comment-start
        typed-comment-section-groups
        typed-comment-section-facets
        typed-comment-section-facets/groups
        typed-comment-section-start?
        typed-comment-strip-signature-marker
        join-nonblank-with-space)

;;; Leading-name blockers encode full-form typed doc grammar. Prefix blockers
;;; identify metadata lines, while fragment blockers keep prose and signatures
;;; from being misread as a definition name.
;; (List String)
(def +typed-comment-leading-name-blocked-prefixes+ '(":" "|"))
;; (List String)
(def +typed-comment-leading-name-blocked-fragments+ '(" " "\t" "("))

;; typed-comment-empty-metadata
;;   : (-> BlockStyle SignatureContract TypedCommentMetadata)
;;   | doc m%
;;       `typed-comment-empty-metadata block-style signature` returns the
;;       canonical metadata envelope for a typed contract block.
;;     %
(def (typed-comment-empty-metadata block-style signature)
  (hash (kind "typed-comment")
        (syntax "scheme-native-block")
        (blockStyle block-style)
        (fullForm #f)
        (leadingName #f)
         (leadingNameMatchesDefinition #f)
         (signature signature)
         (signatureType #f)
         (signatureTypes [])
         (polymorphicSignatures [])
         (localTypes [])
        (runtimeContracts [])
        (runtimeContractsDetailed [])
        (requires [])
        (requiresDetailed [])
        (warnings [])
        (rationales [])
        (docs [])
        (refinements [])
        (sections [])))

;;; Boundary:
;;; - Metadata keeps typed comments parser-owned instead of policy-owned.
;;; - Contract-related fields remain stable until a versioned schema replaces them.
;; typed-comment-metadata
;;   : (-> (List TypedCommentLine) TypedCommentLine SignatureContract (List TypedCommentLine) TypedCommentMetadata)
;;   | doc m%
;;       `typed-comment-metadata block signature-start signature section-entries`
;;       extracts full-form name, local type, runtime witness, and doc metadata.
;;     %
(def (typed-comment-metadata block signature-start signature section-entries)
  (typed-comment-metadata/groups block
                                 signature-start
                                 signature
                                 (typed-comment-section-groups section-entries)))

;; : (-> (List TypedCommentLine) TypedCommentLine SignatureContract (List TypedCommentSection) TypedCommentMetadata)
(def (typed-comment-metadata/groups block signature-start signature sections)
  (typed-comment-metadata/groups/signature-type
   block
   signature-start
   signature
   sections
   (scheme-type-signature-json signature)))

;; : (-> (List TypedCommentLine) TypedCommentLine SignatureContract (List TypedCommentSection) Json TypedCommentMetadata)
(def (typed-comment-metadata/groups/signature-type block signature-start signature sections signature-type)
  (let (leading-entry (typed-comment-leading-name-entry block signature-start))
    (hash (kind "typed-comment")
          (syntax "gerbil-contract-projection")
          (blockStyle "gerbil-contract-block")
          (fullForm (if leading-entry #t #f))
          (leadingName (and leading-entry (string-trim (cadr leading-entry))))
           (leadingNameMatchesDefinition #f)
           (signature signature)
           (signatureType signature-type)
           (signatureTypes
            (typed-comment-signature-types block))
           (polymorphicSignatures
            (typed-comment-polymorphic-signature-types block))
           (localTypes
            (filter-map typed-comment-type-section-json sections))
          (runtimeContracts
           (typed-comment-section-values sections "contract"))
          (runtimeContractsDetailed
           (map scheme-runtime-contract-json
                (typed-comment-section-values sections "contract")))
          (requires
           (typed-comment-section-values sections "requires"))
          (requiresDetailed
           (map scheme-predicate-expression-json
                (typed-comment-section-values sections "requires")))
          (warnings
           (typed-comment-section-values sections "warning"))
          (rationales
           (typed-comment-section-values sections "rationale"))
          (docs
           (filter-map typed-comment-doc-section-json sections))
          (refinements
           (typed-comment-refinement-values sections))
          (sections
           (map typed-comment-section-json sections)))))

;; typed-comment-signature-comment-start
;;   : (-> (List TypedCommentLine) TypedCommentLine LineNumber)
;;   | doc m%
;;       `typed-comment-signature-comment-start block signature-start` returns
;;       the leading-name line when full form is present, otherwise the signature line.
;;     %
(def (typed-comment-signature-comment-start block signature-start)
  (let (leading-entry (typed-comment-leading-name-entry block signature-start))
    (if leading-entry
      (car leading-entry)
      (car signature-start))))

;; typed-comment-section-facets
;;   : (-> (List TypedCommentLine) (List QualityFacet))
;;   | doc m%
;;       `typed-comment-section-facets entries` projects typed-comment section
;;       metadata into compact quality facets for existing policy consumers.
;;     %
(def (typed-comment-section-facets entries)
  (typed-comment-section-facets/groups
   (typed-comment-section-groups entries)))

;; : (-> (List TypedCommentSection) (List QualityFacet))
(def (typed-comment-section-facets/groups sections)
  (unique
   (apply append
          (map typed-comment-section-group-facets sections))))

;; typed-comment-section-start?
;;   : (-> TypedCommentLine Boolean)
;;   | doc m%
;;       `typed-comment-section-start? entry` detects `|` metadata section lines
;;       after the caller has already normalized semicolon comment text.
;;     %
(def (typed-comment-section-start? entry)
  (string-prefix? "|" (string-trim (cadr entry))))

;;; Signature type projection:
;;; - Layered comments may carry a polymorphic generic signature and a readable
;;;   domain summary.
;;; - The definition-facing final signature may span continuation lines, while
;;;   earlier layered signatures remain independent.
;; : (-> (List TypedCommentLine) (List Json))
(def (typed-comment-signature-types block)
  (typed-comment-signature-types/starts
   block
   (filter typed-comment-signature-start? block)))

;; : (-> (List TypedCommentLine) (List Json))
(def (typed-comment-polymorphic-signature-types block)
  (typed-comment-signature-types/starts
   block
   (filter typed-comment-polymorphic-signature-start? block)))

;; : (-> (List TypedCommentLine) (List TypedCommentLine) (List Json))
(def (typed-comment-signature-types/starts block signature-starts)
  (if (null? signature-starts)
    []
    (let (final-signature-start
          (last (filter typed-comment-signature-start? block)))
      (map (lambda (entry)
             (typed-comment-signature-line-type
              block final-signature-start entry))
           signature-starts))))

;; : (-> (List TypedCommentLine) TypedCommentLine TypedCommentLine Json)
(def (typed-comment-signature-line-type block final-signature-start entry)
  (scheme-type-signature-json
   (if (equal? entry final-signature-start)
     (typed-comment-final-signature-text block entry)
     (typed-comment-strip-signature-marker
      (string-trim (cadr entry))))))

;; : (-> (List TypedCommentLine) TypedCommentLine SignatureContract)
(def (typed-comment-final-signature-text block signature-start)
  (let* ((remaining (cdr (member signature-start block)))
         (continuation
          (take-while (lambda (entry)
                        (not (typed-comment-section-start? entry)))
                      remaining)))
    (string-join
     (cons (typed-comment-strip-signature-marker
            (string-trim (cadr signature-start)))
           (map (lambda (entry)
                  (string-trim (cadr entry)))
                continuation))
     " ")))

;; : (-> TypedCommentLine Boolean)
(def (typed-comment-polymorphic-signature-start? entry)
  (and (typed-comment-signature-start? entry)
       (string-prefix? "(forall"
                       (typed-comment-strip-signature-marker
                        (string-trim (cadr entry))))))

;; : (-> TypedCommentLine Boolean)
(def (typed-comment-signature-start? entry)
  (string-prefix? ":" (string-trim (cadr entry))))

;; typed-comment-strip-signature-marker
;;   : (-> TypedCommentText SignatureContract)
;;   | doc m%
;;       `typed-comment-strip-signature-marker text` removes the leading `:`
;;       marker from a Gerbil contract projection signature line.
;;     %
(def (typed-comment-strip-signature-marker text)
  (string-trim
   (substring text 1 (string-length text))))

;;; Joining ignores blank contract fragments after the parser has normalized
;;; each line.  `string-join` keeps spacing policy local.
;; join-nonblank-with-space
;;   : (-> (List String) String)
;;   | doc m%
;;       `join-nonblank-with-space parts` joins non-empty normalized fragments
;;       into one signature or section value without preserving layout noise.
;;     %
(def (join-nonblank-with-space parts)
  (string-join (filter (lambda (part)
                         (not (equal? part "")))
                       parts)
               " "))

;;; Boundary:
;;; - Only the immediately preceding compact symbol line can be a full-form name.
;;; - Prose comments above the signature must not become parser metadata.
;; : (-> (List TypedCommentLine) TypedCommentLine (Maybe TypedCommentLine))
(def (typed-comment-leading-name-entry block signature-start)
  (let (before-signature
        (take-while (lambda (entry)
                      (not (equal? entry signature-start)))
                    block))
    (and (pair? before-signature)
         (let (candidate (last before-signature))
           (and (typed-comment-leading-name? (cadr candidate))
                candidate)))))

;; : (-> TypedCommentText Boolean)
(def (typed-comment-leading-name? text)
  (let (trimmed (string-trim text))
    (and (not (equal? trimmed ""))
         (not (typed-comment-leading-name-blocked-prefix? trimmed))
         (not (typed-comment-leading-name-blocked-fragment? trimmed)))))

;;; Prefix blockers are intentionally separate from fragment blockers so `|`
;;; metadata lines and `:` signatures stay grammar-level cases.
;; : (-> TypedCommentText Boolean)
(def (typed-comment-leading-name-blocked-prefix? text)
  (ormap (lambda (prefix)
           (string-prefix? prefix text))
         +typed-comment-leading-name-blocked-prefixes+))

;;; Fragment blockers reject prose-like candidates after trimming without
;;; coupling this parser to a specific doc sentence shape.
;; : (-> TypedCommentText Boolean)
(def (typed-comment-leading-name-blocked-fragment? text)
  (ormap (lambda (fragment)
           (string-contains text fragment))
         +typed-comment-leading-name-blocked-fragments+))

;;; Boundary:
;;; - Section grouping is a small fold over source-order comment lines.
;;; - Continuation lines belong to the most recent `|` section.
;; : (-> (List TypedCommentLine) (List TypedCommentSection))
(def (typed-comment-section-groups entries)
  (let* ((state (foldl typed-comment-section-group-step [[] []] entries))
         (current (car state))
         (groups (cadr state)))
    (reverse (typed-comment-section-close current groups))))

;; : (-> TypedCommentLine SectionGroupState SectionGroupState)
(def (typed-comment-section-group-step entry state)
  (let ((current (car state))
        (groups (cadr state)))
    (if (typed-comment-section-start? entry)
      [[entry] (typed-comment-section-close current groups)]
      (if (pair? current)
        [(append current [entry]) groups]
        state))))

;; : (-> (List TypedCommentLine) (List TypedCommentSection) (List TypedCommentSection))
(def (typed-comment-section-close current groups)
  (if (pair? current)
    (cons (typed-comment-section-group current) groups)
    groups))

;; : (-> (List TypedCommentLine) TypedCommentSection)
;; | type TypedCommentSection = (Tuple LineNumber LineNumber SectionKey SectionValue (List SectionLine))
(def (typed-comment-section-group entries)
  (let* ((start (car entries))
         (continuation (cdr entries))
         (body (or (typed-comment-section-body start) ""))
         (key (typed-comment-section-key body))
         (value (typed-comment-section-value body key)))
    [(car start)
     (car (last entries))
     key
     value
     (cons value (map cadr continuation))]))

;; : (-> TypedCommentSection (List QualityFacet))
(def (typed-comment-section-group-facets section)
  (let ((key (typed-comment-section-group-key section))
        (text (typed-comment-section-text section)))
    (append
     (cond
      ((equal? key "type")
       ["local-type-environment"])
      ((equal? key "contract")
       ["runtime-contract-block"])
      ((equal? key "requires")
       ["precondition-block"])
      ((equal? key "warning")
       ["warning-contract-block"])
      ((equal? key "rationale")
       ["rationale-contract-block"])
      ((equal? key "doc")
       ["typed-doc-block"])
      (else []))
     (if (string-contains text "Refine")
       ["refinement-type-block"]
       []))))

;; : (-> TypedCommentSection Json)
(def (typed-comment-section-json section)
  (hash (key (typed-comment-section-group-key section))
        (value (typed-comment-section-text section))
        (start (typed-comment-section-group-start section))
        (end (typed-comment-section-group-end section))))

;; : (-> TypedCommentSection (Maybe Json))
(def (typed-comment-type-section-json section)
  (and (equal? (typed-comment-section-group-key section) "type")
       (let* ((text (typed-comment-section-text section))
              (equals (string-contains text "="))
              (left (if equals
                      (string-trim (substring text 0 equals))
                      (string-trim text)))
              (expression (if equals
                            (string-trim
                             (substring text
                                        (fx1+ equals)
                                        (string-length text)))
                            "")))
         (let (parameters (typed-comment-alias-parameters left))
           (hash (name (typed-comment-alias-name left))
               (parameters parameters)
               (expression expression)
               (expressionType
                (scheme-type-expression-text-json expression parameters))
               (refinement (if (string-contains expression "Refine")
                             #t
                             #f)))))))

;;; Boundary:
;;; - Doc metadata remains parser-owned and section-local.
;;; - Result-example evidence is derived only from fenced example lines.
;; : (-> TypedCommentSection (Maybe Json))
(def (typed-comment-doc-section-json section)
  (and (equal? (typed-comment-section-group-key section) "doc")
       (let* ((lines (typed-comment-section-group-lines section))
              (marker (if (pair? lines) (car lines) ""))
              (body-lines (typed-comment-doc-body-lines lines))
              (examples (typed-comment-doc-examples-json body-lines)))
         (hash (marker marker)
               (body (string-join body-lines "\n"))
               (examples examples)
               (hasExamples (not (null? examples)))
               (hasResultExamples
                (ormap typed-comment-doc-example-has-expected-result?
                       examples))
               (start (typed-comment-section-group-start section))
               (end (typed-comment-section-group-end section))))))

;;; Intent:
;;; - Return only reviewable metadata values for a requested section key.
;;; Invariant:
;;; - Empty `| key` markers are ignored so R013 cannot accept a requires,
;;;   warning, rationale, or doc field without predicate, witness, or prose.
;; : (-> (List TypedCommentSection) SectionKey (List SectionValue))
(def (typed-comment-section-values sections key)
  (filter-map
   (lambda (section)
     (and (equal? (typed-comment-section-group-key section) key)
          (let (text (typed-comment-section-text section))
            (and (not (equal? text "")) text))))
   sections))

;;; Boundary:
;;; - Refinement evidence stays tied to explicit `Refine` syntax in comment metadata.
;;; - Do not infer refinements from prose or generic type names.
;; : (-> (List TypedCommentSection) (List SectionValue))
(def (typed-comment-refinement-values sections)
  (filter (lambda (text)
            (string-contains text "Refine"))
          (map typed-comment-section-text sections)))

;; : (-> TypedCommentSection LineNumber)
(def (typed-comment-section-group-start section)
  (car section))

;; : (-> TypedCommentSection LineNumber)
(def (typed-comment-section-group-end section)
  (cadr section))

;; : (-> TypedCommentSection SectionKey)
(def (typed-comment-section-group-key section)
  (caddr section))

;; : (-> TypedCommentSection (List SectionLine))
(def (typed-comment-section-group-lines section)
  (list-ref section 4))

;; : (-> TypedCommentSection SectionValue)
(def (typed-comment-section-text section)
  (join-nonblank-with-space (typed-comment-section-group-lines section)))

;; : (-> TypedCommentLine (Maybe TypedCommentSectionBody))
(def (typed-comment-section-body entry)
  (and (typed-comment-section-start? entry)
       (let (text (string-trim (cadr entry)))
         (string-trim (substring text 1 (string-length text))))))

;; : (-> TypedCommentSectionBody SectionKey)
(def (typed-comment-section-key body)
  (let (index (typed-comment-first-whitespace-index body))
    (if index
      (substring body 0 index)
      body)))

;; : (-> TypedCommentSectionBody SectionKey SectionValue)
(def (typed-comment-section-value body key)
  (let (key-length (string-length key))
    (if (< key-length (string-length body))
      (string-trim (substring body key-length (string-length body)))
      "")))

;; : (-> String AliasName)
(def (typed-comment-alias-name left)
  (let (index (typed-comment-first-whitespace-index left))
    (if index
      (substring left 0 index)
      left)))

;; : (-> String (List AliasParameter))
(def (typed-comment-alias-parameters left)
  (let (index (typed-comment-first-whitespace-index left))
    (if index
      (split-top-level-type-exprs
       (string-trim (substring left (fx1+ index) (string-length left))))
      [])))

;; : (-> (List SectionLine) (List SectionLine))
(def (typed-comment-doc-body-lines lines)
  (let (body (if (and (pair? lines) (equal? (car lines) "m%"))
              (cdr lines)
              lines))
    (if (and (pair? body) (equal? (last body) "%"))
      (drop-right body 1)
      body)))

;;; Boundary:
;;; - Example parsing is deliberately doc-section local. The parser records
;;;   fenced examples under "# Examples" without trying to execute them.
;; : (-> (List SectionLine) (List Json))
(def (typed-comment-doc-examples-json lines)
  (reverse
   (typed-comment-doc-example-state-examples
    (foldl typed-comment-doc-example-step
           (typed-comment-doc-example-state #f #f "" [] [])
           lines))))

;;; Boundary:
;;; - Example parsing is a fold state, not an executable loop driver.
;;; - The state keeps only doc-section parser facts: heading, fence, language,
;;;   reversed block lines, and reversed examples.
;; : (-> Boolean Boolean String (List SectionLine) (List Json) DocExampleState)
(def (typed-comment-doc-example-state in-examples? in-fence? language block-lines examples)
  [in-examples? in-fence? language block-lines examples])

;; : (-> DocExampleState Boolean)
(def (typed-comment-doc-example-state-in-examples? state)
  (list-ref state 0))

;; : (-> DocExampleState Boolean)
(def (typed-comment-doc-example-state-in-fence? state)
  (list-ref state 1))

;; : (-> DocExampleState String)
(def (typed-comment-doc-example-state-language state)
  (list-ref state 2))

;; : (-> DocExampleState (List SectionLine))
(def (typed-comment-doc-example-state-block-lines state)
  (list-ref state 3))

;; : (-> DocExampleState (List Json))
(def (typed-comment-doc-example-state-examples state)
  (list-ref state 4))

;;; Boundary:
;;; - Each section line produces one immutable state transition.
;;; - Closing a fence is the only transition that appends an example packet.
;; : (-> SectionLine DocExampleState DocExampleState)
(def (typed-comment-doc-example-step line state)
  (let* ((trimmed (string-trim line))
         (in-examples? (typed-comment-doc-example-state-in-examples? state))
         (in-fence? (typed-comment-doc-example-state-in-fence? state))
         (language (typed-comment-doc-example-state-language state))
         (block-lines (typed-comment-doc-example-state-block-lines state))
         (examples (typed-comment-doc-example-state-examples state)))
    (cond
     ((and in-fence? (typed-comment-doc-fence-line? trimmed))
      (typed-comment-doc-example-state
       in-examples?
       #f
       ""
       []
       (typed-comment-doc-cons-example
        language
        (reverse block-lines)
        examples)))
     (in-fence?
      (typed-comment-doc-example-state
       in-examples?
       #t
       language
       (cons line block-lines)
       examples))
     ((typed-comment-doc-examples-heading? trimmed)
      (typed-comment-doc-example-state #t #f "" [] examples))
     ((and in-examples? (typed-comment-doc-fence-line? trimmed))
      (typed-comment-doc-example-state
       #t
       #t
       (typed-comment-doc-fence-language trimmed)
       []
       examples))
     ((and in-examples? (typed-comment-doc-heading-line? trimmed))
      (typed-comment-doc-example-state #f #f "" [] examples))
     (else
      (typed-comment-doc-example-state in-examples? #f "" [] examples)))))

;; : (-> String (List SectionLine) (List Json) (List Json))
(def (typed-comment-doc-cons-example language lines examples)
  (if (null? lines)
    examples
    (cons (typed-comment-doc-example-json language lines) examples)))

;;; Boundary:
;;; - Code/body/expected result fields are split without executing examples.
;;; - This packet is evidence for docs quality, not a test runner.
;; : (-> String (List SectionLine) Json)
(def (typed-comment-doc-example-json language lines)
  (let* ((code-lines
          (filter (lambda (line)
                    (not (typed-comment-doc-result-line? line)))
                  lines))
         (expected-lines
          (filter-map typed-comment-doc-result-text lines)))
    (hash (language language)
          (code (string-join code-lines "\n"))
          (expected (string-join expected-lines "\n"))
          (body (string-join lines "\n"))
          (hasExpectedResult (not (null? expected-lines))))))

;; : (-> Json Boolean)
(def (typed-comment-doc-example-has-expected-result? example)
  (if (hash-get example 'hasExpectedResult) #t #f))

;; : (-> SectionLine Boolean)
(def (typed-comment-doc-examples-heading? line)
  (or (equal? line "# Examples")
      (equal? line "## Examples")))

;; : (-> SectionLine Boolean)
(def (typed-comment-doc-heading-line? line)
  (or (string-prefix? "# " line)
      (string-prefix? "## " line)))

;; : (-> SectionLine Boolean)
(def (typed-comment-doc-fence-line? line)
  (string-prefix? "```" line))

;; : (-> SectionLine String)
(def (typed-comment-doc-fence-language line)
  (string-trim (substring line 3 (string-length line))))

;; : (-> SectionLine Boolean)
(def (typed-comment-doc-result-line? line)
  (let (trimmed (string-trim line))
    (or (string-prefix? ";; =>" trimmed)
        (string-prefix? "# =>" trimmed)
        (string-prefix? "=>" trimmed))))

;; : (-> SectionLine (Maybe String))
(def (typed-comment-doc-result-text line)
  (let* ((trimmed (string-trim line))
         (index (string-contains trimmed "=>")))
    (and index
         (typed-comment-doc-result-line? trimmed)
         (string-trim
          (substring trimmed
                     (+ index 2)
                     (string-length trimmed))))))

;;; Boundary:
;;; - Whitespace detection is a parser utility for section keys and alias heads.
;;; - Use indexed search so the helper stays pure and avoids hand-rolled loops.
;; : (-> String (Maybe Index))
(def (typed-comment-first-whitespace-index text)
  (find (lambda (index)
          (typed-comment-whitespace? (string-ref text index)))
        (iota (string-length text))))

;; : (-> Character Boolean)
(def (typed-comment-whitespace? ch)
  (or (char=? ch #\space)
      (char=? ch #\tab)))
