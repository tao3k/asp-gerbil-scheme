;;; -*- Gerbil -*-
(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/protocol/json
        :std/misc/process
        :std/sort
        :std/test)
(export check-structural-index-required-envelope
        check-structural-index-queryable-facts
        check-structural-index-quality-shape-facts
        check-structural-index-dependency-adapter-facts)
;; Integer
(def +structural-interface-summary-preview-limit+ 20)
;; String
(def +structural-interface-owner-path+ "src/commands/projection.ss")

;; : (-> (List Json) OwnerPath Boolean)
(def (summary-owner-present? summaries owner-path)
  (cond
   ((null? summaries) #f)
   ((equal? (hash-get (car summaries) 'ownerPath) owner-path) #t)
   (else (summary-owner-present? (cdr summaries) owner-path))))

;; : (-> (List Json) Boolean)
(def (summary-family-detail-present? summaries)
  (cond
   ((null? summaries) #f)
   ((hash-get (car summaries) 'families) #t)
   (else (summary-family-detail-present? (cdr summaries)))))

;; Integer
(def (check-structural-index-required-envelope)
  (let* ((index (collect-project "."))
         (packet (structural-index-packet-json index))
         (generation-id (hash-get packet 'generationId))
         (summaries (hash-get packet 'nativeSyntaxFactSummaries)))
    (check (hash-get packet 'schemaId)
           => "agent.semantic-protocols.semantic-structural-index")
    (check (hash-get packet 'schemaVersion) => "1")
    (check (hash-get packet 'protocolId)
           => "agent.semantic-protocols.semantic-language")
    (check (hash-get packet 'protocolVersion) => "1")
    (check (hash-get packet 'languageId) => "gerbil-scheme")
    (check (hash-get packet 'providerId) => "asp-gerbil-scheme")
    (check (hash-get packet 'exportMethod) => "index/structural")
    (check (hash-get packet 'projectRoot) => (project-index-root index))
    (check (hash-get packet 'packageRoot) => ".")
    (check (hash-get packet 'rawSourceStored) => #f)
    (check (hash-get packet 'indexMode) => "interface")
    (check (string? generation-id) => #t)
    (check (hash-get packet 'sourceArtifactId)
           => (string-append "structural-index/" generation-id ".json"))
    (check (> (length (hash-get packet 'fileHashes)) 0) => #t)
    (check (> (length (hash-get packet 'owners)) 0) => #t)
    (check (length (hash-get packet 'symbols)) => 0)
    (check (> (hash-get packet 'symbolTotal) 0) => #t)
    (check (length (hash-get packet 'syntaxFacts)) => 0)
    (check (> (hash-get packet 'nativeSyntaxFactTotal) 0) => #t)
    (check (> (length summaries) 0) => #t)
    (check (<= (length summaries)
               +structural-interface-summary-preview-limit+)
           => #t)
    (check (summary-owner-present? summaries +structural-interface-owner-path+)
           => #t)
    (check (summary-family-detail-present? summaries) => #f)
    (check (hash-get (hash-get packet 'factInterface) 'ownerFactsCommand)
           => "asp-gerbil-scheme projection --native-index --owner <path> --json --workspace .")
    (check (length (hash-get packet 'dependencyUsages)) => 0)
    (check (>= (hash-get packet 'dependencyUsageTotal) 0) => #t)))

;; (List OwnerPath)
(def +poo-structural-fixture-owners+
  ["t/fixtures/parser/poo-object-slots.ss"
   "t/fixtures/parser/poo-io-hooks.ss"
   "t/fixtures/parser/poo-fq-descriptors.ss"
   "t/fixtures/parser/poo-trie-descriptor.ss"
   "t/fixtures/parser/poo-rationaldict-adapter.ss"
   "t/fixtures/parser/poo-type-validation.ss"
   "t/fixtures/parser/poo-trace-debug.ss"
   "t/fixtures/parser/poo-slot-cache-inheritance.ss"
   "t/fixtures/parser/poo-method-dispatch.ss"])

;; (List PooStructuralSpec)
(def +poo-structural-specs+
  [["custom" "point"
    [['role "object"]
     ['supers ["base"]]
     ['slots ["x" "y" "total" "level" "child" "label" "greeting"]]]
    ["slot:level:inherited-computed" "slot:child:mixin-override"]]
   ["method" ":pr"
    [['specializers ["object"]]
     ['options ["hookFamily:poo-io" "runtimeHook:printer"]]]
    ["hookFamily:poo-io" "runtimeHook:printer"]]
   ["method" ":wr"
    [['specializers ["object"]]
     ['options ["hookFamily:poo-io" "runtimeHook:writeenv"]]]
    ["hookFamily:poo-io" "runtimeHook:writeenv"]]
   ["method" ":json"
    [['specializers ["object"]]
     ['options ["hookFamily:poo-io" "runtimeHook:json-read"]]]
    ["hookFamily:poo-io" "runtimeHook:json-read"]]
   ["method" ":write-json"
    [['specializers ["object"]]
     ['options ["hookFamily:poo-io" "runtimeHook:json-write"]]
     ['dispatchArity 1]]
    ["object" "hookFamily:poo-io" "runtimeHook:json-write"]]
   ["custom" "methods.string<-json"
    [['role "type"]
     ['slots [".json<-" ".<-json" ".string<-" ".<-string"]]]
    [".json<-" ".<-json" ".string<-" ".<-string"]]
   ["custom" "methods.bytes<-marshal"
    [['role "type"]
     ['slots [".marshal" ".unmarshal" ".bytes<-" ".<-bytes"]]]
    [".marshal" ".unmarshal" ".bytes<-" ".<-bytes"]]
   ["custom" "cache-node"
    [['role "object"]
     ['supers ["left-cache" "right-cache"]]
     ['slots ["stable" "inherited-count" "cached-child"
              "super-label" "local-cache"]]]
    ["slot:stable:default"
     "slot:inherited-count:inherited-computed"
     "slot:cached-child:mixin-override"
     "slot:super-label:inherited-computed"]]
   ["call" ".ref"
    [['role "slot-cache-boundary"]
     ['slotCacheRole "slot-cache-read"]
     ['cacheOperation "ref"]
     ['sourceSelector "gerbil-poo://object.ss#.ref"]]
    ["slot-cache-boundary" "slot-cache-read" "cacheOperation:ref"
     "sourceSelector:gerbil-poo://object.ss#.ref"]]
   ["call" ".ref/cached"
    [['role "slot-cache-boundary"]
     ['slotCacheRole "slot-cache-read-existing"]
     ['cacheOperation "ref-cached"]
     ['sourceSelector "gerbil-poo://object.ss#.ref/cached"]]
    ["slot-cache-boundary" "slot-cache-read-existing" "cacheOperation:ref-cached"
     "sourceSelector:gerbil-poo://object.ss#.ref/cached"]]
   ["call" "apply-slot-spec"
    [['role "slot-cache-boundary"]
     ['slotCacheRole "slot-spec-application"]
     ['cacheOperation "apply-slot-spec"]
     ['sourceSelector "gerbil-poo://object.ss#apply-slot-spec"]]
    ["slot-cache-boundary" "slot-spec-application"
     "cacheOperation:apply-slot-spec"
     "sourceSelector:gerbil-poo://object.ss#apply-slot-spec"]]
   ["custom" "F_q."
    [['role "type"]
     ['supers ["expt<-mul-inv."]]]
    ["expt<-mul-inv." ".mul" ".n<-" ".<-n"]]
   ["custom" "F_2^n."
    [['supers ["F_q."]]]
    [".element?" ".=?"]]
   ["custom" "F_2^8"
    [['supers ["F_2^n."]]
     ['slots [".n" ".xn"]]]
    []]
   ["custom" "Costep."
    [['role "type"]
     ['supers ["Type."]]]
    ["height" "key" ".validate"]]
   ["custom" "Trie."
    [['supers ["Wrap." "methods.table"]]]
    ["methods.table" "T" "Unstep" "Step" ".acons" ".<-list"]]
   ["custom" "RationalDict."
    [['supers ["methods.table"]]]
    ["Key" ".key?" ".sexp<-"]]
   ["custom" "RationalSet"
    [['supers ["Set<-Table."]]]
    ["Table" ".min-elt"]]
   ["custom" "EmailAddress."
    [['role "type"]
     ['supers ["String."]]]
    [".validate" ".sexp<-"]]
   ["custom" "Tuple."
    [['role "type"]
     ['supers ["Type."]]]
    ["types" ".json<-" ".marshal"]]
   ["custom" "PositiveList."
    [['supers ["List."]]]
    ["Elt" ".validate"]]
   ["custom" "trace-probe"
    [['role "object"]
     ['supers ["base"]]]
    ["slot:value:inherited-computed" "slot:runner:self-computed"]]
   ["method" ":pr" [['specializers ["trace-probe"]]] []]
   ["method" ":wr" [['specializers ["trace-probe"]]] []]
   ["generic" "distance" [['generic "distance"]] []]
   ["method" "distance"
    [['specializers ["Point" "Point"]]
     ['specializerTypes ["Point" "Point"]]
     ['dispatchArity 2]]
    []]
   ["generic" ":intersect" [['generic ":intersect"]] []]
   ["method" ":intersect"
    [['receiver "line"]
     ['receiverType "<Line>"]
     ['specializers ["line:<Line>" "circle:<Circle>" "ctx:<Ctx>"]]
     ['dispatchArity 3]]
    []]
   ["call" "raise-type-error" [] []]
   ["call" "trace-inherited-slot" [] []]
   ["call" "traced-function" [] []]
   ["call" "trace-poo" [] []]])

;; Integer
(def (check-structural-index-queryable-facts)
  (let* ((fixture-owners
          (append ["t/fixtures/parser/complex-syntax.ss"]
                  +poo-structural-fixture-owners+
                  ["t/fixtures/parser/higher-order.ss"
                   "t/fixtures/parser/control-flow.ss"]))
         (index (collect-project "."))
         (fixture-index
          (collect-selected-source-scope "." fixture-owners))
         (packet (structural-index-packet-json index))
         (facts-packet
          (owner-facts-packet fixture-index fixture-owners)))
    (check (packet-has-owner? packet "src/commands/projection.ss") => #t)
    (check (> (hash-get packet 'symbolTotal) 0) => #t)
    (check (packet-has-syntax-fact? facts-packet "macro" "capture-safe") => #t)
    (check (packet-has-syntax-fact? facts-packet "import" ":std/text/json") => #t)
    (check (packet-has-syntax-fact? facts-packet "export" ":render") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "export" ":render" 'modifier "direct") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "export" ":render" 'symbols [":render"]) => #t)
    (check (packet-has-syntax-fact-query-key? facts-packet "export" ":render" "module-export") => #t)
    (check (packet-has-syntax-fact? facts-packet "binding" "again") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "method" ":render" 'receiverType "<Widget>") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "method" ":render" 'specializers ["widget:<Widget>"]) => #t)
    (check (packet-has-syntax-fact-field? facts-packet "method" ":render" 'dispatchArity 1) => #t)
    (check (packet-has-syntax-fact-field? facts-packet "class" "<Widget>" 'slots ["name" "count"]) => #t)
    (check (packet-has-syntax-fact-field? facts-packet "interface" "<Renderable>" 'role "protocol") => #t)
    (check-structural-index-poo-facts facts-packet)
    (check (packet-has-syntax-fact-field? facts-packet "function" "case-lambda" 'role "multi-arity-function") => #t)
    (check (packet-has-syntax-fact-query-key? facts-packet "function" "case-lambda" "case-lambda-optimization-boundary") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "function" "lambda" 'formals ["widget"]) => #t)
    (check (packet-has-syntax-fact-field? facts-packet "call" "map" 'role "sequence-map") => #t)
    (check (packet-has-syntax-fact-query-key? facts-packet "call" "map" "expression-level-composition") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "call" "filter" 'role "sequence-filter") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "call" "fold-left" 'role "sequence-fold") => #t)
    (check (packet-has-syntax-fact-query-key? facts-packet "call" "fold-left" "expression-level-composition") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "call" "cut" 'role "partial-application") => #t)
    (check (packet-has-syntax-fact-query-key? facts-packet "call" "cut" "combinator-composition") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "call" "for/fold" 'role "loop-fold") => #t)
    (check (packet-has-syntax-fact-query-key? facts-packet "call" "for/fold" "builder-or-fold-combinator") => #t)
    (check (packet-has-syntax-fact-query-key? facts-packet "macro" "with-widget" "macro-sugar") => #t)
    (check (packet-has-syntax-fact-query-key? facts-packet "macro" "capture-safe" "syntax-case-transformer") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "custom" "loop" 'role "manual-loop") => #t)
    (check (packet-has-syntax-fact-query-key? facts-packet "custom" "loop" "control-flow") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "custom" "loop" 'bindingCount 2) => #t)
    (check (packet-has-syntax-fact-field? facts-packet "custom" "loop" 'bodyFormCount 1) => #t)
    (check (packet-has-syntax-fact-field? facts-packet "custom" "let/cc" 'role "continuation-control") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "custom" "try" 'role "protected-control") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "custom" "finally" 'role "protected-handler") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "custom" "call-with-output-string" 'role "resource-scope") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "custom" "match" 'role "pattern-branch") => #t)
    (check (packet-has-syntax-fact-query-key? facts-packet "custom" "match" "control-flow") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "comment" "make-widget" 'role "typed-combinator-style") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "comment" "make-widget" 'contract "(-> String (List String) String )") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "comment" "make-widget" 'contractOutput "String") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "comment" "make-widget" 'contractInputs ["String" "(List String)"]) => #t)
    (check (packet-has-syntax-fact-field? facts-packet "comment" "make-widget" 'definitionArity 2) => #t)
    (check (packet-has-syntax-fact-field? facts-packet "comment" "make-widget" 'contractInputCount 2) => #t)
    (check (packet-has-syntax-fact-field? facts-packet "comment" "make-widget" 'arityAlignment "aligned") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "comment" "make-widget" 'quality "domain-transform") => #t)
    (check (packet-has-syntax-fact-query-key? facts-packet "comment" "make-widget" "combinator-candidate") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "comment" "<Widget>" 'quality "weak") => #t)
    (check (packet-has-syntax-fact-query-key? facts-packet "comment" "make-widget" "typed-combinator-style") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "comment" "with-widget" 'role "engineering-comment-quality") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "comment" "with-widget" 'context "macro") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "comment" "with-widget" 'commentKind "contract-only") => #t)
    (check (packet-has-syntax-fact-field? facts-packet "comment" "with-widget" 'quality "weak") => #t)
    (check (packet-has-syntax-fact-field?
            facts-packet "comment" "with-widget" 'required
            ["defrule" "defsyntax" "defclass" "defgeneric" "defmethod" "defprotocol"])
           => #t)
    (check (packet-has-syntax-fact-query-key? facts-packet "comment" "with-widget" "comment-quality") => #t)
    (check (packet-syntax-fact-ids-are-sorted? facts-packet) => #t)
    (check (> (hash-get packet 'dependencyUsageTotal) 0) => #t)
    (check (packet-file-hashes-are-64-hex? packet) => #t)))

;; : (-> Packet Unit )
(def (check-structural-index-poo-facts facts-packet)
  (for-each (lambda (spec)
              (check-poo-structural-spec facts-packet spec))
            +poo-structural-specs+))

;; : (-> Packet PooStructuralSpec Unit )
(def (check-poo-structural-spec facts-packet spec)
  (match spec
    ([kind name fields query-keys]
     (check (packet-has-syntax-fact? facts-packet kind name) => #t)
     (for-each (lambda (field-spec)
                 (check-poo-structural-field facts-packet kind name field-spec))
               fields)
     (for-each (lambda (query-key)
                 (check (packet-has-syntax-fact-query-key?
                         facts-packet kind name query-key)
                        => #t))
               query-keys))))

;; : (-> Packet Kind Name PooStructuralFieldSpec Unit )
(def (check-poo-structural-field facts-packet kind name spec)
  (match spec
    ([field expected]
     (check (packet-has-syntax-fact-field? facts-packet kind name field expected)
            => #t))))

;; Unit
(def (check-structural-index-quality-shape-facts)
  (let* ((root ".run/structural-quality-shape")
         (_ (write-quality-shape-structural-project root))
         (index (collect-project root))
         (packet (owner-facts-packet index ["src/orders/core.ss"])))
    (check (packet-has-syntax-fact-field? packet "custom" "predicate-family:fact" 'role "repeated-predicate-family") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "predicate-family:fact" "gerbil-utils-combinator-style") => #t)
    (check (packet-has-syntax-fact-field? packet "custom" "field-access:role" 'role "repeated-field-access") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "field-access:role" "selector-helper") => #t)
    (check (packet-has-syntax-fact-field? packet "custom" "created-event?" 'role "predicate-condition") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "created-event?" "predicate-helper") => #t)
    (check (packet-has-syntax-fact-field? packet "custom" "created-event?" 'suggestedRepairClass "predicate-family-combinator") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "created-event?" "functionQualityProfile") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "created-event?" "repairPlan") => #t)
    (check (packet-has-syntax-fact-field? packet "custom" "loop" 'driverKind "pure-transform-candidate") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "loop" "loop-driver") => #t)))

;; Unit
(def (check-structural-index-dependency-adapter-facts)
  (let* ((root ".run/structural-dependency-adapter")
         (_ (write-dependency-adapter-structural-project root))
         (index (collect-project root))
         (packet (owner-facts-packet index ["src/orders/dict.ss"
                                            "src/orders/rationaldict.ss"])))
    (check (packet-has-syntax-fact-field? packet "custom" "OrderDict." 'role "dependency-protocol-adapter") => #t)
    (check (packet-has-syntax-fact-field? packet "custom" "OrderDict." 'dependency ":clan/pure/dict/orderdict") => #t)
    (check (packet-has-syntax-fact-field? packet "custom" "OrderDict." 'quality "complete") => #t)
    (check (packet-has-syntax-fact-field? packet "custom" "OrderDict." 'manualObjectEncodingRisk "none") => #t)
    (check (packet-has-syntax-fact-field? packet "custom" "OrderDict." 'genericContractWitnessKind "table-protocol-contract-witness") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "OrderDict." "dependency-protocol-adapter") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "OrderDict." "table") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "OrderDict." "list") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "OrderDict." "table-derived-capability") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "OrderDict." "orderdict-put") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "OrderDict." "orderdict=?") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "OrderDict." "precise-only-in-import") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "OrderDict." "thin-wrapper-over-dependency-api") => #t)
    (check (packet-has-syntax-fact-field? packet "custom" "RationalDict." 'dependency ":clan/pure/dict/rationaldict") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "RationalDict." "methods.table") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "RationalDict." ".key?") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "RationalDict." "rationaldict-put") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "RationalDict." "set-derived-capability") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "RationalDict." "sexp-derived-capability") => #t)
    (check (packet-has-syntax-fact-field? packet "custom" "RationalSet" 'dependency ":clan/pure/dict/rationaldict") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "RationalSet" "Set<-Table.") => #t)
    (check (packet-has-syntax-fact-query-key? packet "custom" "RationalSet" "rationaldict-keys") => #t)))

;; : (-> ProjectIndex (List OwnerPath) Packet )
(def (owner-facts-packet index owners)
  (hash (facts
         (sort (owner-facts index owners)
               (lambda (a b)
                 (string<? (hash-get a 'id) (hash-get b 'id)))))))

;; : (-> ProjectIndex (List OwnerPath) (List SyntaxFact) )
(def (owner-facts index owners)
  (apply append
         (map (lambda (owner)
                (let (file (find-owner index owner))
                  (unless file (error "owner not found" owner))
                  (hash-get (native-syntax-owner-facts-packet-json index file)
                            'facts)))
              owners)))

;; : (-> String Unit )
(def (write-quality-shape-structural-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (reset-fixture-root root)
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/structural-quality)\n;; : (-> EventSyntaxFact Boolean)\n(def (created-event? fact)\n  (let (fields (hash-get fact 'fields))\n    (and fields (equal? (field-string fields 'role) \"created\"))))\n;; : (-> EventSyntaxFact Boolean)\n(def (paid-event? fact)\n  (let (fields (hash-get fact 'fields))\n    (and fields (member (field-string fields 'role) '(\"paid\" \"settled\")))))\n;; : (-> EventSyntaxFact Boolean)\n(def (cancelled-event? fact)\n  (let (fields (hash-get fact 'fields))\n    (and fields (equal? (field-string fields 'role) \"cancelled\"))))\n;; : (-> (List EventSyntaxFact) (List EventId))\n(def (collect-ids rows)\n  (let loop ((rest rows) (out []))\n    (if (null? rest)\n      (reverse out)\n      (loop (cdr rest) (cons (hash-get (car rest) 'id) out)))))\n")))

;; : (-> String Unit )
(def (write-dependency-adapter-structural-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (reset-fixture-root root)
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/dict.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import\n  (only-in :clan/pure/dict/orderdict\n           orderdict-empty? orderdict-ref orderdict-put orderdict->list\n           list->orderdict orderdict=?)\n  (only-in :clan/poo/mop define-type Any raise-type-error)\n  (only-in ./table methods.table))\n(define-type (OrderDict. @ [methods.table] Value)\n  Key: String\n  Value: Any\n  .validate: => (lambda (super) (lambda (x) (super x)))\n  .empty: orderdict-empty?\n  .ref: orderdict-ref\n  .acons: (lambda (k v d) (orderdict-put d k v))\n  .foldl: (lambda (f seed d) seed)\n  .<-list: list->orderdict\n  .list<-: orderdict->list\n  .sexp<-: (lambda (x) `(list->orderdict ,(orderdict->list x)))\n  .=?: (lambda (a b) (orderdict=? a b)))\n")
    (write-text (string-append owner "/rationaldict.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import\n  (only-in :clan/pure/dict/rationaldict\n           rationaldict-keys rationaldict-min-key rationaldict-max-key\n           rationaldict-empty? empty-rationaldict\n           rationaldict-put rationaldict-ref rationaldict-has-key? rationaldict-remove\n           list->rationaldict rationaldict->list\n           rationaldict? rationaldict=?)\n  (only-in :clan/poo/mop define-type Any raise-type-error)\n  (only-in ./type Rational Unit)\n  (only-in ./table Set<-Table. methods.table))\n(define-type (RationalDict. @ [methods.table] Value)\n  Key: Rational\n  Value: Any\n  .validate: => (lambda (super) (lambda (x) (unless (rationaldict? x) (raise-type-error \"not rationaldict\" x)) (super x)))\n  .empty: empty-rationaldict\n  .empty?: rationaldict-empty?\n  .ref: rationaldict-ref\n  .key?: rationaldict-has-key?\n  .acons: (lambda (k v d) (rationaldict-put d k v))\n  .remove: rationaldict-remove\n  .foldl: (lambda (f seed d) (foldl (lambda (kv acc) (f (car kv) (cdr kv) acc)) seed (rationaldict->list d)))\n  .foldr: (lambda (f seed d) (foldr (lambda (kv acc) (f (car kv) (cdr kv) acc)) seed (rationaldict->list d)))\n  .<-list: list->rationaldict\n  .list<-: rationaldict->list\n  .sexp<-: (lambda (x) `(list->rationaldict ,(rationaldict->list x)))\n  .=?: (lambda (d1 d2) (rationaldict=? d1 d2)))\n(define-type (RationalSet @ [Set<-Table.])\n  Elt: Rational\n  Table: {(:: @T RationalDict.) Key: Elt Value: Unit}\n  .list<-: rationaldict-keys\n  .min-elt: rationaldict-min-key\n  .max-elt: rationaldict-max-key)\n")))

;; : (-> String Unit )
(def (reset-fixture-root root)
  (when (file-exists? root)
    (void
     (run-process ["rm" "-rf" root]
                  stderr-redirection: #t))))

;; : (-> String EnsureDir )
(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))

;; : (-> String SourceText Unit )
(def (write-text path text)
  (call-with-output-file path
    (lambda (port) (display text port))))
;; : (-> Packet String Boolean )
(def (packet-has-owner? packet path)
  (ormap (lambda (owner)
           (equal? (hash-get owner 'ownerPath) path))
         (hash-get packet 'owners)))
;; : (-> Packet String Boolean )
(def (packet-has-symbol? packet name)
  (ormap (lambda (symbol)
           (equal? (hash-get symbol 'name) name))
         (hash-get packet 'symbols)))
;; : (-> Packet Key Boolean )
(def (packet-has-symbol-query-key? packet key)
  (ormap (lambda (symbol)
           (and (member key (hash-get symbol 'queryKeys)) #t))
         (hash-get packet 'symbols)))
;; : (-> Packet String String Boolean )
(def (packet-has-syntax-fact? packet kind name)
  (ormap (lambda (fact)
           (and (equal? (hash-get fact 'kind) kind)
                (equal? (hash-get fact 'name) name)))
         (packet-syntax-facts packet)))
;; : (-> Packet String String String Expected Boolean )
(def (packet-has-syntax-fact-field? packet kind name field expected)
  (ormap (lambda (fact)
           (and (equal? (hash-get fact 'kind) kind)
                (equal? (hash-get fact 'name) name)
                (let (fields (hash-get fact 'fields))
                  (and fields (equal? (hash-get fields field) expected)))))
         (packet-syntax-facts packet)))
;; : (-> Packet String String Key Boolean )
(def (packet-has-syntax-fact-query-key? packet kind name key)
  (ormap (lambda (fact)
           (and (equal? (hash-get fact 'kind) kind)
                (equal? (hash-get fact 'name) name)
                (member key (hash-get fact 'queryKeys))
                #t))
         (packet-syntax-facts packet)))
;; : (-> Packet String String String Boolean )
(def (packet-has-syntax-fact-id? packet kind name id)
  (ormap (lambda (fact)
           (and (equal? (hash-get fact 'kind) kind)
                (equal? (hash-get fact 'name) name)
                (equal? (hash-get fact 'id) id)))
         (packet-syntax-facts packet)))
;; : (-> Packet Boolean )
(def (packet-syntax-fact-ids-are-sorted? packet)
  (let (ids (map (cut hash-get <> 'id) (packet-syntax-facts packet)))
    (equal? ids (sort ids string<?))))
;; : (-> Packet (List SyntaxFact) )
(def (packet-syntax-facts packet)
  (if (hash-key? packet 'syntaxFacts)
    (hash-get packet 'syntaxFacts)
    (hash-get packet 'facts)))
;; : (-> Packet ImportPath Boolean )
(def (packet-has-dependency? packet import-path)
  (ormap (lambda (usage)
           (equal? (hash-get usage 'importPath) import-path))
         (hash-get packet 'dependencyUsages)))
;; : (-> Packet Boolean )
(def (packet-file-hashes-are-64-hex? packet)
  (andmap (lambda (entry)
            (let (sha256 (hash-get entry 'sha256))
              (and (string? sha256)
                   (fx= (string-length sha256) 64))))
          (hash-get packet 'fileHashes)))
