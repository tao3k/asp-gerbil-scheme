;;; -*- Gerbil -*-
;;; Data model for parser-owned Gerbil source facts.

(export make-definition
        definition-name
        definition-kind
        definition-path
        definition-start
        definition-end
        definition-formals
        definition-arity
        make-call-fact
        call-fact-callee
        call-fact-arity
        call-fact-path
        call-fact-start
        call-fact-end
        call-fact-arguments
        call-fact-argument-types
        call-fact-caller
        make-module-import-fact
        module-import-fact-module
        module-import-fact-phase
        module-import-fact-modifier
        module-import-fact-alias
        module-import-fact-symbols
        module-import-fact-path
        module-import-fact-start
        module-import-fact-end
        make-module-export-fact
        module-export-fact-name
        module-export-fact-modifier
        module-export-fact-alias
        module-export-fact-module
        module-export-fact-symbols
        module-export-fact-path
        module-export-fact-start
        module-export-fact-end
        make-macro-fact
        macro-fact-name
        macro-fact-kind
        macro-fact-path
        macro-fact-start
        macro-fact-end
        macro-fact-transformer
        macro-fact-phase
        macro-fact-pattern-count
        macro-fact-hygienic
        macro-fact-quality-facets
        make-macro-family-fact
        macro-family-fact-name
        macro-family-fact-kind
        macro-family-fact-path
        macro-family-fact-start
        macro-family-fact-end
        macro-family-fact-role
        macro-family-fact-prefix
        macro-family-fact-macro-names
        macro-family-fact-macro-count
        macro-family-fact-transformer
        macro-family-fact-quality-facets
        macro-family-fact-advice
        make-binding-fact
        binding-fact-name
        binding-fact-kind
        binding-fact-path
        binding-fact-start
        binding-fact-end
        binding-fact-scope
        binding-fact-value-type
        make-poo-form-fact
        poo-form-fact-name
        poo-form-fact-kind
        poo-form-fact-path
        poo-form-fact-start
        poo-form-fact-end
        poo-form-fact-role
        poo-form-fact-generic
        poo-form-fact-receiver
        poo-form-fact-receiver-type
        poo-form-fact-supers
        poo-form-fact-slots
        poo-form-fact-options
        poo-form-fact-specializers
        poo-form-fact-specializer-types
        make-higher-order-fact
        higher-order-fact-name
        higher-order-fact-kind
        higher-order-fact-path
        higher-order-fact-start
        higher-order-fact-end
        higher-order-fact-role
        higher-order-fact-operand-count
        higher-order-fact-arities
        higher-order-fact-formals
        higher-order-fact-caller
        make-control-flow-fact
        control-flow-fact-name
        control-flow-fact-kind
        control-flow-fact-path
        control-flow-fact-start
        control-flow-fact-end
        control-flow-fact-role
        control-flow-fact-caller
        control-flow-fact-binding-count
        control-flow-fact-body-form-count
        make-predicate-family-fact
        predicate-family-fact-name
        predicate-family-fact-kind
        predicate-family-fact-path
        predicate-family-fact-start
        predicate-family-fact-end
        predicate-family-fact-role
        predicate-family-fact-subject
        predicate-family-fact-predicate-names
        predicate-family-fact-predicate-count
        predicate-family-fact-field-keys
        predicate-family-fact-repeated-callees
        predicate-family-fact-condition-count
        predicate-family-fact-quality-facets
        predicate-family-fact-advice
        make-field-access-pattern-fact
        field-access-pattern-fact-name
        field-access-pattern-fact-kind
        field-access-pattern-fact-path
        field-access-pattern-fact-start
        field-access-pattern-fact-end
        field-access-pattern-fact-role
        field-access-pattern-fact-field-key
        field-access-pattern-fact-callers
        field-access-pattern-fact-access-count
        field-access-pattern-fact-accessors
        field-access-pattern-fact-quality-facets
        field-access-pattern-fact-advice
        make-projection-burst-fact
        projection-burst-fact-name
        projection-burst-fact-kind
        projection-burst-fact-path
        projection-burst-fact-start
        projection-burst-fact-end
        projection-burst-fact-role
        projection-burst-fact-caller
        projection-burst-fact-field-keys
        projection-burst-fact-access-count
        projection-burst-fact-accessor-count
        projection-burst-fact-emitter-count
        projection-burst-fact-accessors
        projection-burst-fact-emitters
        projection-burst-fact-quality-facets
        projection-burst-fact-advice
        make-boolean-condition-fact
        boolean-condition-fact-name
        boolean-condition-fact-kind
        boolean-condition-fact-path
        boolean-condition-fact-start
        boolean-condition-fact-end
        boolean-condition-fact-role
        boolean-condition-fact-caller
        boolean-condition-fact-formals
        boolean-condition-fact-condition-callees
        boolean-condition-fact-field-keys
        boolean-condition-fact-condition-count
        boolean-condition-fact-quality-facets
        boolean-condition-fact-advice
        make-loop-driver-fact
        loop-driver-fact-name
        loop-driver-fact-kind
        loop-driver-fact-path
        loop-driver-fact-start
        loop-driver-fact-end
        loop-driver-fact-role
        loop-driver-fact-caller
        loop-driver-fact-driver-kind
        loop-driver-fact-binding-count
        loop-driver-fact-body-form-count
        loop-driver-fact-quality-facets
        loop-driver-fact-advice
        make-dependency-adapter-quality-fact
        dependency-adapter-quality-fact-name
        dependency-adapter-quality-fact-kind
        dependency-adapter-quality-fact-path
        dependency-adapter-quality-fact-start
        dependency-adapter-quality-fact-end
        dependency-adapter-quality-fact-role
        dependency-adapter-quality-fact-dependency
        dependency-adapter-quality-fact-imports
        dependency-adapter-quality-fact-imported-symbols
        dependency-adapter-quality-fact-used-symbols
        dependency-adapter-quality-fact-protocol-refs
        dependency-adapter-quality-fact-slots
        dependency-adapter-quality-fact-derived-capabilities
        dependency-adapter-quality-fact-manual-object-encoding-risk
        dependency-adapter-quality-fact-generic-contract-witness-kind
        dependency-adapter-quality-fact-quality
        dependency-adapter-quality-fact-quality-facets
        dependency-adapter-quality-fact-missing-evidence
        dependency-adapter-quality-fact-advice
        make-function-quality-profile
        function-quality-profile-name
        function-quality-profile-kind
        function-quality-profile-path
        function-quality-profile-start
        function-quality-profile-end
        function-quality-profile-formals
        function-quality-profile-arity
        function-quality-profile-role
        function-quality-profile-exported
        function-quality-profile-typed-contract-quality
        function-quality-profile-comment-quality
        function-quality-profile-control-flow-roles
        function-quality-profile-higher-order-roles
        function-quality-profile-predicate-family-refs
        function-quality-profile-field-access-pattern-refs
        function-quality-profile-loop-driver-refs
        function-quality-profile-macro-refs
        function-quality-profile-poo-protocol-refs
        function-quality-profile-quality-facets
        function-quality-profile-preservation-reasons
        function-quality-profile-suggested-repair-class
        function-quality-profile-parser-confidence
        function-quality-profile-advice
        make-typed-contract-fact
        typed-contract-fact-definition-name
        typed-contract-fact-definition-kind
        typed-contract-fact-definition-formals
        typed-contract-fact-definition-arity
        typed-contract-fact-path
        typed-contract-fact-definition-start
        typed-contract-fact-definition-end
        typed-contract-fact-comment-start
        typed-contract-fact-comment-end
        typed-contract-fact-contract
        typed-contract-fact-contract-output
        typed-contract-fact-contract-inputs
        typed-contract-fact-contract-input-count
        typed-contract-fact-arity-alignment
        typed-contract-fact-tokens
        typed-contract-fact-arrow-count
        typed-contract-fact-group-count
        typed-contract-fact-quality
        typed-contract-fact-reasons
        typed-contract-fact-quality-facets
        typed-contract-fact-repair-evidence
        typed-contract-fact-typed-comment
        make-comment-quality-fact
        comment-quality-fact-target-kind
        comment-quality-fact-target-name
        comment-quality-fact-path
        comment-quality-fact-target-start
        comment-quality-fact-target-end
        comment-quality-fact-comment-start
        comment-quality-fact-comment-end
        comment-quality-fact-comment-lines
        comment-quality-fact-comment-kind
        comment-quality-fact-quality
        comment-quality-fact-reasons
        comment-quality-fact-required
        comment-quality-fact-context
        comment-quality-fact-evidence
        make-syntax-relation
        syntax-relation-kind
        syntax-relation-name
        syntax-relation-start
        syntax-relation-end
        syntax-relation-phase
        syntax-relation-context
        syntax-relation-structural-path
        make-syntax-ast
        syntax-ast-version
        syntax-ast-path
        syntax-ast-owner
        syntax-ast-relations
        make-top-form
        top-form-kind
        top-form-head
        top-form-path
        top-form-start
        top-form-end
        top-form-syntax-ast
        source-file::t
        make-source-file
        source-file-path
        source-file-line-count
        source-file-package
        source-file-prelude
        source-file-namespace
        source-file-imports
        source-file-exports
        source-file-includes
        source-file-definitions
        source-file-calls
        source-file-forms
        source-file-module-imports
        source-file-module-exports
        source-file-macros
        source-file-macro-family-facts
        source-file-bindings
        source-file-poo-forms
        source-file-higher-order-forms
        source-file-control-flow-forms
        source-file-predicate-family-facts
        source-file-field-access-pattern-facts
        source-file-projection-burst-facts
        source-file-boolean-condition-facts
        source-file-loop-driver-facts
        source-file-dependency-adapter-quality-facts
        source-file-function-quality-profiles
        source-file-typed-contract-facts
        source-file-comment-quality-facts
        source-file-parse-error
        make-project-index
        project-index-root
        project-index-files
        project-index-package)
;; DefinitionStruct
(defstruct definition (name kind path start end formals arity))
;; CallFactStruct
(defstruct call-fact (callee arity path start end arguments argument-types caller))
;; ModuleImportFactStruct
(defstruct module-import-fact (module phase modifier alias symbols path start end))
;; ModuleExportFactStruct
(defstruct module-export-fact (name modifier alias module symbols path start end))
;; MacroFactStruct
(defstruct macro-fact (name kind path start end transformer phase pattern-count hygienic quality-facets))
;; MacroFamilyFactStruct
(defstruct macro-family-fact (name kind path start end role prefix macro-names macro-count transformer quality-facets advice))
;; BindingFactStruct
(defstruct binding-fact (name kind path start end scope value-type))
;; PooFormFactStruct
(defstruct poo-form-fact (name kind path start end role generic receiver receiver-type supers slots options specializers specializer-types))
;; HigherOrderFactStruct
(defstruct higher-order-fact (name kind path start end role operand-count arities formals caller))
;; ControlFlowFactStruct
(defstruct control-flow-fact (name kind path start end role caller binding-count body-form-count))
;; PredicateFamilyFactStruct
(defstruct predicate-family-fact (name kind path start end role subject predicate-names predicate-count field-keys repeated-callees condition-count quality-facets advice))
;; FieldAccessPatternFactStruct
(defstruct field-access-pattern-fact (name kind path start end role field-key callers access-count accessors quality-facets advice))
;; ProjectionBurstFactStruct
(defstruct projection-burst-fact (name kind path start end role caller field-keys access-count accessor-count emitter-count accessors emitters quality-facets advice))
;; BooleanConditionFactStruct
(defstruct boolean-condition-fact (name kind path start end role caller formals condition-callees field-keys condition-count quality-facets advice))
;; LoopDriverFactStruct
(defstruct loop-driver-fact (name kind path start end role caller driver-kind binding-count body-form-count quality-facets advice))
;; DependencyAdapterQualityFactStruct
(defstruct dependency-adapter-quality-fact (name kind path start end role dependency imports imported-symbols used-symbols protocol-refs slots derived-capabilities manual-object-encoding-risk generic-contract-witness-kind quality quality-facets missing-evidence advice))
;; FunctionQualityProfileStruct
(defstruct function-quality-profile (name kind path start end formals arity role exported typed-contract-quality comment-quality control-flow-roles higher-order-roles predicate-family-refs field-access-pattern-refs loop-driver-refs macro-refs poo-protocol-refs quality-facets preservation-reasons suggested-repair-class parser-confidence advice))
;; TypedContractFactStruct
(defstruct typed-contract-fact (definition-name definition-kind definition-formals definition-arity path definition-start definition-end comment-start comment-end contract contract-output contract-inputs contract-input-count arity-alignment tokens arrow-count group-count quality reasons quality-facets repair-evidence typed-comment))
;; CommentQualityFactStruct
(defstruct comment-quality-fact (target-kind target-name path target-start target-end comment-start comment-end comment-lines comment-kind quality reasons required context evidence))
;; SyntaxRelationStruct
;;
;; A compact retained projection of one native syntax occurrence. Native
;; syntax objects never cross into this model or the JSON/protocol boundary.
(defstruct syntax-relation
  (kind name start end phase context reverse-structural-path))

;; The walker retains reverse-cons paths so sibling and descendant relations
;; share their prefix spine.  Consumers continue to receive source order.
;; : (-> SyntaxRelation (List Integer))
(def (syntax-relation-structural-path relation)
  (reverse (syntax-relation-reverse-structural-path relation)))
;; SyntaxAstStruct
;;
;; Gerbil's native syntax object is traversed exactly once, then released.  The
;; retained AST owns shared source identity plus compact phase-aware relations.
(defstruct syntax-ast (version path owner relations))
;; TopFormStruct
(defstruct top-form (kind head path start end syntax-ast))
;; SourceFileStruct
(defstruct source-file (path line-count package prelude namespace imports exports includes definitions calls forms module-imports module-exports macros macro-family-facts bindings poo-forms higher-order-forms control-flow-forms predicate-family-facts field-access-pattern-facts projection-burst-facts boolean-condition-facts loop-driver-facts dependency-adapter-quality-facts function-quality-profiles typed-contract-facts comment-quality-facts parse-error))
;; ProjectIndexStruct
(defstruct project-index (root files package))
