(parserSourceFile
 (path "t/fixtures/parser/complex-syntax.ss")
 (definitions
  ((definition
    (name "with-widget")
    (kind "defrule")
    (formals ("value" "body"))
    (arity 2)
    (selector "t/fixtures/parser/complex-syntax.ss:14-16"))
   (definition
    (name "capture-safe")
    (kind "defsyntax")
    (formals ("stx"))
    (arity 1)
    (selector "t/fixtures/parser/complex-syntax.ss:18-22"))
   (definition
    (name "<Widget>")
    (kind "defclass")
    (formals ())
    (arity 0)
    (selector "t/fixtures/parser/complex-syntax.ss:24-24"))
   (definition
    (name ":render")
    (kind "defgeneric")
    (formals ())
    (arity 0)
    (selector "t/fixtures/parser/complex-syntax.ss:26-26"))
   (definition
    (name "<Renderable>")
    (kind "defprotocol")
    (formals ())
    (arity 0)
    (selector "t/fixtures/parser/complex-syntax.ss:28-28"))
   (definition
    (name ":render")
    (kind "defmethod")
    (formals ())
    (arity 0)
    (selector "t/fixtures/parser/complex-syntax.ss:30-36"))
   (definition
    (name "make-widget")
    (kind "def")
    (formals ("name" "rest"))
    (arity 2)
    (selector "t/fixtures/parser/complex-syntax.ss:38-41"))
   (definition
    (name "dispatch")
    (kind "def")
    (formals ("value"))
    (arity 1)
    (selector "t/fixtures/parser/complex-syntax.ss:43-46"))
   (definition
    (name "select")
    (kind "def")
    (formals ("x"))
    (arity 1)
    (selector "t/fixtures/parser/complex-syntax.ss:48-51"))))
 (moduleImports
  ((moduleImport
    (module ":std/string/path")
    (phase "template")
    (modifier "for-template")
    (symbols ())
    (selector "t/fixtures/parser/complex-syntax.ss:11-11"))
   (moduleImport
    (module ":std/misc/repr")
    (phase "phase:1")
    (modifier "phi:")
    (symbols ())
    (selector "t/fixtures/parser/complex-syntax.ss:10-10"))
   (moduleImport
    (module ":std/hash/misc")
    (phase "runtime")
    (modifier "except-in")
    (symbols ("hash-copy"))
    (selector "t/fixtures/parser/complex-syntax.ss:9-9"))
   (moduleImport
    (module ":std/list/list")
    (phase "runtime")
    (modifier "rename-in")
    (symbols ("foldl" "fold-left"))
    (selector "t/fixtures/parser/complex-syntax.ss:8-8"))
   (moduleImport
    (module ":std/stxutil")
    (phase "syntax")
    (modifier "for-syntax")
    (symbols ())
    (selector "t/fixtures/parser/complex-syntax.ss:7-7"))
   (moduleImport
    (module ":std/encoding/json")
    (phase "runtime")
    (modifier "only-in")
    (symbols ("read-json"))
    (selector "t/fixtures/parser/complex-syntax.ss:6-6"))
   (moduleImport
    (module ":std/sugar")
    (phase "runtime")
    (modifier "direct")
    (symbols ())
    (selector "t/fixtures/parser/complex-syntax.ss:5-5"))))
 (moduleExports
  ((moduleExport
    (name ":render")
    (modifier "direct")
    (alias "")
    (module "")
    (symbols (":render"))
    (selector "t/fixtures/parser/complex-syntax.ss:12-12"))
   (moduleExport
    (name "<Renderable>")
    (modifier "direct")
    (alias "")
    (module "")
    (symbols ("<Renderable>"))
    (selector "t/fixtures/parser/complex-syntax.ss:12-12"))
   (moduleExport
    (name "<Widget>")
    (modifier "direct")
    (alias "")
    (module "")
    (symbols ("<Widget>"))
    (selector "t/fixtures/parser/complex-syntax.ss:12-12"))
   (moduleExport
    (name "with-widget")
    (modifier "direct")
    (alias "")
    (module "")
    (symbols ("with-widget"))
    (selector "t/fixtures/parser/complex-syntax.ss:12-12"))
   (moduleExport
    (name "make-widget")
    (modifier "direct")
    (alias "")
    (module "")
    (symbols ("make-widget"))
    (selector "t/fixtures/parser/complex-syntax.ss:12-12"))))
 (macros ((macro (name "with-widget")
                 (kind "defrule")
                 (transformer "macro-transformer")
                 (phase "syntax")
                 (patternCount 1)
                 (hygienicSyntax #t)
                 (qualityFacets ("hygienic-macro" "macro-sugar"))
                 (selector "t/fixtures/parser/complex-syntax.ss:14-16"))
          (macro (name "capture-safe")
                 (kind "defsyntax")
                 (transformer "syntax-case")
                 (phase "syntax")
                 (patternCount 0)
                 (hygienicSyntax #t)
                 (qualityFacets
                  ("hygienic-macro"
                   "syntax-case-transformer"
                   "syntax-template-witness"))
                 (selector "t/fixtures/parser/complex-syntax.ss:18-22"))))
 (bindings
  ((binding (name "body")
            (kind "macro-formal")
            (scope "with-widget")
            (valueType "unknown")
            (selector "t/fixtures/parser/complex-syntax.ss:14-16"))
   (binding (name "value")
            (kind "macro-formal")
            (scope "with-widget")
            (valueType "unknown")
            (selector "t/fixtures/parser/complex-syntax.ss:14-16"))
   (binding (name "stx")
            (kind "macro-formal")
            (scope "capture-safe")
            (valueType "unknown")
            (selector "t/fixtures/parser/complex-syntax.ss:18-22"))
   (binding (name "n")
            (kind "let*")
            (scope ":render")
            (valueType "number")
            (selector "t/fixtures/parser/complex-syntax.ss:33-33"))
   (binding (name "again")
            (kind "let*")
            (scope ":render")
            (valueType "string")
            (selector "t/fixtures/parser/complex-syntax.ss:32-32"))
   (binding (name "label")
            (kind "let*")
            (scope ":render")
            (valueType "string")
            (selector "t/fixtures/parser/complex-syntax.ss:31-31"))
   (binding (name "count")
            (kind "let")
            (scope "make-widget")
            (valueType "number")
            (selector "t/fixtures/parser/complex-syntax.ss:39-39"))
   (binding (name "rest")
            (kind "formal")
            (scope "make-widget")
            (valueType "unknown")
            (selector "t/fixtures/parser/complex-syntax.ss:38-41"))
   (binding (name "name")
            (kind "formal")
            (scope "make-widget")
            (valueType "unknown")
            (selector "t/fixtures/parser/complex-syntax.ss:38-41"))
   (binding (name "value")
            (kind "formal")
            (scope "dispatch")
            (valueType "unknown")
            (selector "t/fixtures/parser/complex-syntax.ss:43-46"))
   (binding (name "x")
            (kind "formal")
            (scope "select")
            (valueType "unknown")
            (selector "t/fixtures/parser/complex-syntax.ss:48-51"))))
 (pooForms
  ((pooForm (name "<Widget>")
            (kind "defclass")
            (role "class")
            (generic "")
            (receiver "")
            (receiverType "")
            (supers (":object"))
            (slots ("name" "count"))
            (options ("transparent:"))
            (specializers ())
            (specializerTypes ())
            (selector "t/fixtures/parser/complex-syntax.ss:24-24"))
   (pooForm (name ":render")
            (kind "defgeneric")
            (role "generic")
            (generic ":render")
            (receiver "")
            (receiverType "")
            (supers ())
            (slots ())
            (options ("dispatchSource:instance"))
            (specializers ())
            (specializerTypes ())
            (selector "t/fixtures/parser/complex-syntax.ss:26-26"))
   (pooForm (name "<Renderable>")
            (kind "defprotocol")
            (role "protocol")
            (generic "")
            (receiver "")
            (receiverType "")
            (supers ())
            (slots ())
            (options ())
            (specializers ())
            (specializerTypes ())
            (selector "t/fixtures/parser/complex-syntax.ss:28-28"))
   (pooForm (name ":render")
            (kind "defmethod")
            (role "method")
            (generic ":render")
            (receiver "widget")
            (receiverType "<Widget>")
            (supers ())
            (slots ())
            (options ())
            (specializers ("widget:<Widget>"))
            (specializerTypes ("<Widget>"))
            (selector "t/fixtures/parser/complex-syntax.ss:30-36"))))
 (higherOrderForms
  ((higherOrderForm
    (name "match")
    (kind "match")
    (role "pattern-matching-function")
    (operandCount 3)
    (arities ())
    (formals ())
    (caller "dispatch")
    (qualityFacets ("lambda-match-destructuring"))
    (selector "t/fixtures/parser/complex-syntax.ss:44-46"))
   (higherOrderForm
    (name "case-lambda")
    (kind "case-lambda")
    (role "multi-arity-function")
    (operandCount 2)
    (arities (0 1))
    (formals ("x"))
    (caller "select")
    (qualityFacets
     ("case-lambda-optimization-boundary" "multi-arity-abstraction"))
    (selector "t/fixtures/parser/complex-syntax.ss:49-51"))))
 (controlFlowForms
  ((controlFlowForm
    (name "match")
    (kind "match")
    (role "pattern-branch")
    (caller "dispatch")
    (bindingCount 0)
    (bodyFormCount 2)
    (qualityFacets ("extensible-match-dsl"))
    (selector "t/fixtures/parser/complex-syntax.ss:44-46"))))
 (predicateFamilyFacts ())
 (fieldAccessPatternFacts ())
 (booleanConditionFacts ())
 (loopDriverFacts ())
 (functionQualityProfiles
  ((functionQualityProfile
    (name "with-widget")
    (kind "function-quality-profile")
    (role "macro-helper")
    (exported #t)
    (formals ("value" "body"))
    (arity 2)
    (typedContractQuality "domain-transform")
    (commentQuality "weak")
    (controlFlowRoles ())
    (higherOrderRoles ())
    (predicateFamilyRefs ())
    (fieldAccessPatternRefs ())
    (loopDriverRefs ())
    (macroRefs ("with-widget"))
    (pooProtocolRefs ())
    (qualityFacets
     ("function-quality-profile"
      "functionQualityProfile"
      "quality-profile"
      "function-quality"
      "macro-helper"
      "public-api"
      "typed-contract-domain-transform"
      "comment-quality-weak"
      "macro-runtime-source-witness"
      "contract-valid"
      "scheme-native-block"
      "domain-transform"
      "aligned"
      "arity-bearing-definition"
      "contract-only-is-not-engineering-comment"))
    (preservationReasons
     ("preserve-public-api" "macro-runtime-source-witness-required"))
    (suggestedRepairClass "engineering-comment-quality")
    (parserConfidence "medium")
    (advice "write as many adjacent engineering comment lines as the parser evidence needs after code shape is stable")
    (selector "t/fixtures/parser/complex-syntax.ss:14-16"))
   (functionQualityProfile
    (name "capture-safe")
    (kind "function-quality-profile")
    (role "macro-helper")
    (exported #f)
    (formals ("stx"))
    (arity 1)
    (typedContractQuality "domain-transform")
    (commentQuality "weak")
    (controlFlowRoles ())
    (higherOrderRoles ())
    (predicateFamilyRefs ())
    (fieldAccessPatternRefs ())
    (loopDriverRefs ())
    (macroRefs ("capture-safe"))
    (pooProtocolRefs ())
    (qualityFacets
     ("function-quality-profile"
      "functionQualityProfile"
      "quality-profile"
      "function-quality"
      "macro-helper"
      "typed-contract-domain-transform"
      "comment-quality-weak"
      "macro-runtime-source-witness"
      "contract-valid"
      "scheme-native-block"
      "domain-transform"
      "aligned"
      "arity-bearing-definition"
      "contract-only-is-not-engineering-comment"))
    (preservationReasons ("macro-runtime-source-witness-required"))
    (suggestedRepairClass "engineering-comment-quality")
    (parserConfidence "medium")
    (advice "write as many adjacent engineering comment lines as the parser evidence needs after code shape is stable")
    (selector "t/fixtures/parser/complex-syntax.ss:18-22"))
   (functionQualityProfile
    (name "<Widget>")
    (kind "function-quality-profile")
    (role "poo-protocol-boundary")
    (exported #t)
    (formals ())
    (arity 0)
    (typedContractQuality "declaration-contract")
    (commentQuality "weak")
    (controlFlowRoles ())
    (higherOrderRoles ())
    (predicateFamilyRefs ())
    (fieldAccessPatternRefs ())
    (loopDriverRefs ())
    (macroRefs ())
    (pooProtocolRefs ("<Widget>"))
    (qualityFacets
     ("function-quality-profile"
      "functionQualityProfile"
      "quality-profile"
      "function-quality"
      "poo-protocol-boundary"
      "public-api"
      "typed-contract-declaration-contract"
      "comment-quality-weak"
      "poo-protocol-evidence"
      "contract-valid"
      "declaration-contract"
      "declaration"
      "weak-engineering-comment"))
    (preservationReasons ("preserve-public-api" "poo-protocol-boundary"))
    (suggestedRepairClass "engineering-comment-quality")
    (parserConfidence "medium")
    (advice "write as many adjacent engineering comment lines as the parser evidence needs after code shape is stable")
    (selector "t/fixtures/parser/complex-syntax.ss:24-24"))
   (functionQualityProfile
    (name ":render")
    (kind "function-quality-profile")
    (role "protocol-method")
    (exported #f)
    (formals ())
    (arity 0)
    (typedContractQuality "declaration-contract")
    (commentQuality "weak")
    (controlFlowRoles ())
    (higherOrderRoles ())
    (predicateFamilyRefs ())
    (fieldAccessPatternRefs ())
    (loopDriverRefs ())
    (macroRefs ())
    (pooProtocolRefs (":render" ":render"))
    (qualityFacets
     ("function-quality-profile"
      "functionQualityProfile"
      "quality-profile"
      "function-quality"
      "protocol-method"
      "typed-contract-declaration-contract"
      "comment-quality-weak"
      "poo-protocol-evidence"
      "contract-valid"
      "declaration-contract"
      "declaration"
      "call-backed"
      "weak-engineering-comment"))
    (preservationReasons ("poo-protocol-boundary"))
    (suggestedRepairClass "engineering-comment-quality")
    (parserConfidence "high")
    (advice "write as many adjacent engineering comment lines as the parser evidence needs after code shape is stable")
    (selector "t/fixtures/parser/complex-syntax.ss:26-26"))
   (functionQualityProfile
    (name "<Renderable>")
    (kind "function-quality-profile")
    (role "protocol-method")
    (exported #t)
    (formals ())
    (arity 0)
    (typedContractQuality "declaration-contract")
    (commentQuality "weak")
    (controlFlowRoles ())
    (higherOrderRoles ())
    (predicateFamilyRefs ())
    (fieldAccessPatternRefs ())
    (loopDriverRefs ())
    (macroRefs ())
    (pooProtocolRefs ("<Renderable>"))
    (qualityFacets
     ("function-quality-profile"
      "functionQualityProfile"
      "quality-profile"
      "function-quality"
      "protocol-method"
      "public-api"
      "typed-contract-declaration-contract"
      "comment-quality-weak"
      "poo-protocol-evidence"
      "contract-valid"
      "declaration-contract"
      "declaration"
      "weak-engineering-comment"))
    (preservationReasons ("preserve-public-api" "poo-protocol-boundary"))
    (suggestedRepairClass "engineering-comment-quality")
    (parserConfidence "medium")
    (advice "write as many adjacent engineering comment lines as the parser evidence needs after code shape is stable")
    (selector "t/fixtures/parser/complex-syntax.ss:28-28"))
   (functionQualityProfile
    (name ":render")
    (kind "function-quality-profile")
    (role "protocol-method")
    (exported #f)
    (formals ())
    (arity 0)
    (typedContractQuality "declaration-contract")
    (commentQuality "weak")
    (controlFlowRoles ())
    (higherOrderRoles ())
    (predicateFamilyRefs ())
    (fieldAccessPatternRefs ())
    (loopDriverRefs ())
    (macroRefs ())
    (pooProtocolRefs (":render" ":render"))
    (qualityFacets
     ("function-quality-profile"
      "functionQualityProfile"
      "quality-profile"
      "function-quality"
      "protocol-method"
      "typed-contract-declaration-contract"
      "comment-quality-weak"
      "poo-protocol-evidence"
      "contract-valid"
      "declaration-contract"
      "declaration"
      "call-backed"
      "weak-engineering-comment"))
    (preservationReasons ("poo-protocol-boundary"))
    (suggestedRepairClass "engineering-comment-quality")
    (parserConfidence "high")
    (advice "write as many adjacent engineering comment lines as the parser evidence needs after code shape is stable")
    (selector "t/fixtures/parser/complex-syntax.ss:30-36"))
   (functionQualityProfile
    (name "make-widget")
    (kind "function-quality-profile")
    (role "public-api")
    (exported #t)
    (formals ("name" "rest"))
    (arity 2)
    (typedContractQuality "domain-transform")
    (commentQuality "weak")
    (controlFlowRoles ())
    (higherOrderRoles ())
    (predicateFamilyRefs ())
    (fieldAccessPatternRefs ())
    (loopDriverRefs ())
    (macroRefs ())
    (pooProtocolRefs ())
    (qualityFacets
     ("function-quality-profile"
      "functionQualityProfile"
      "quality-profile"
      "function-quality"
      "public-api"
      "typed-contract-domain-transform"
      "comment-quality-weak"
      "contract-valid"
      "scheme-native-block"
      "domain-transform"
      "aligned"
      "arity-bearing-definition"
      "call-backed"
      "combinator-candidate"
      "contract-only-is-not-engineering-comment"))
    (preservationReasons ("preserve-public-api"))
    (suggestedRepairClass "engineering-comment-quality")
    (parserConfidence "medium")
    (advice "write as many adjacent engineering comment lines as the parser evidence needs after code shape is stable")
    (selector "t/fixtures/parser/complex-syntax.ss:38-41"))
   (functionQualityProfile
    (name "dispatch")
    (kind "function-quality-profile")
    (role "internal-helper")
    (exported #f)
    (formals ("value"))
    (arity 1)
    (typedContractQuality "domain-transform")
    (commentQuality "weak")
    (controlFlowRoles ("pattern-branch"))
    (higherOrderRoles ("pattern-matching-function"))
    (predicateFamilyRefs ())
    (fieldAccessPatternRefs ())
    (loopDriverRefs ())
    (macroRefs ())
    (pooProtocolRefs ())
    (qualityFacets
     ("function-quality-profile"
      "functionQualityProfile"
      "quality-profile"
      "function-quality"
      "internal-helper"
      "typed-contract-domain-transform"
      "comment-quality-weak"
      "contract-valid"
      "scheme-native-block"
      "domain-transform"
      "aligned"
      "arity-bearing-definition"
      "call-backed"
      "higher-order-used"
      "combinator-backed"
      "control-flow:pattern-branch"
      "contract-only-is-not-engineering-comment"
      "pattern-branch"
      "pattern-matching-function"
      "lambda-match-destructuring"))
    (preservationReasons ())
    (suggestedRepairClass "engineering-comment-quality")
    (parserConfidence "high")
    (advice "write as many adjacent engineering comment lines as the parser evidence needs after code shape is stable")
    (selector "t/fixtures/parser/complex-syntax.ss:43-46"))
   (functionQualityProfile
    (name "select")
    (kind "function-quality-profile")
    (role "internal-helper")
    (exported #f)
    (formals ("x"))
    (arity 1)
    (typedContractQuality "domain-transform")
    (commentQuality "weak")
    (controlFlowRoles ())
    (higherOrderRoles ("multi-arity-function"))
    (predicateFamilyRefs ())
    (fieldAccessPatternRefs ())
    (loopDriverRefs ())
    (macroRefs ())
    (pooProtocolRefs ())
    (qualityFacets
     ("function-quality-profile"
      "functionQualityProfile"
      "quality-profile"
      "function-quality"
      "internal-helper"
      "typed-contract-domain-transform"
      "comment-quality-weak"
      "contract-valid"
      "scheme-native-block"
      "domain-transform"
      "aligned"
      "arity-bearing-definition"
      "call-backed"
      "higher-order-used"
      "combinator-backed"
      "contract-only-is-not-engineering-comment"
      "multi-arity-function"
      "case-lambda-optimization-boundary"
      "multi-arity-abstraction"))
    (preservationReasons ())
    (suggestedRepairClass "engineering-comment-quality")
    (parserConfidence "medium")
    (advice "write as many adjacent engineering comment lines as the parser evidence needs after code shape is stable")
    (selector "t/fixtures/parser/complex-syntax.ss:48-51"))))
 (typedContractFacts
  ((typedContractFact
    (definition "with-widget")
    (definitionKind "defrule")
    (definitionFormals ("value" "body"))
    (definitionArity 2)
    (contract "(-> Value SourceLine String )")
    (contractOutput "String")
    (contractInputs ("Value" "SourceLine"))
    (contractInputCount 2)
    (arityAlignment "aligned")
    (tokens ("Value" "SourceLine" "String"))
    (quality "domain-transform")
    (reasons ())
    (qualityFacets
     ("contract-valid"
      "scheme-native-block"
      "domain-transform"
      "aligned"
      "arity-bearing-definition"))
    (repairEvidence
     (repairEvidence
      (factSource "native-parser")
      (trigger "typed-combinator-style")
      (definition "with-widget")
      (definitionKind "defrule")
      (definitionFormals ("value" "body"))
      (definitionArity 2)
      (path "t/fixtures/parser/complex-syntax.ss")
      (lineSpan (14 16))
      (selector "t/fixtures/parser/complex-syntax.ss:14-16")
      (contract "(-> Value SourceLine String )")
      (quality "domain-transform")
      (qualityFacets
       ("contract-valid"
        "scheme-native-block"
        "domain-transform"
        "aligned"
        "arity-bearing-definition"))
      (matchedCalls ())
      (matchedHigherOrder ())
      (matchedControlFlow ())
      (allowedMoves ("add-or-expand-adjacent-typed-contract-block"))
      (forbiddenMoves
       ("change-public-export-without-policy-evidence"
        "rewrite-io-or-runtime-boundary-without-witness"
        "replace-macro-transformer-without-runtime-source-witness"))
      (witnessNeeded ("parser-snapshot-or-policy-check"))
      (agentRepairMode
       "use parserEvidence to choose the smallest helper/combinator rewrite; keep names and exact composition flexible when tests and selectors preserve behavior")))
    (arrowCount 1)
    (groupCount 0)
    (selector "t/fixtures/parser/complex-syntax.ss:13-13"))
   (typedContractFact
    (definition "capture-safe")
    (definitionKind "defsyntax")
    (definitionFormals ("stx"))
    (definitionArity 1)
    (contract "(-> Stx CaptureSafe )")
    (contractOutput "CaptureSafe")
    (contractInputs ("Stx"))
    (contractInputCount 1)
    (arityAlignment "aligned")
    (tokens ("Stx" "CaptureSafe"))
    (quality "domain-transform")
    (reasons ())
    (qualityFacets
     ("contract-valid"
      "scheme-native-block"
      "domain-transform"
      "aligned"
      "arity-bearing-definition"))
    (repairEvidence
     (repairEvidence
      (factSource "native-parser")
      (trigger "typed-combinator-style")
      (definition "capture-safe")
      (definitionKind "defsyntax")
      (definitionFormals ("stx"))
      (definitionArity 1)
      (path "t/fixtures/parser/complex-syntax.ss")
      (lineSpan (18 22))
      (selector "t/fixtures/parser/complex-syntax.ss:18-22")
      (contract "(-> Stx CaptureSafe )")
      (quality "domain-transform")
      (qualityFacets
       ("contract-valid"
        "scheme-native-block"
        "domain-transform"
        "aligned"
        "arity-bearing-definition"))
      (matchedCalls ())
      (matchedHigherOrder ())
      (matchedControlFlow ())
      (allowedMoves ("add-or-expand-adjacent-typed-contract-block"))
      (forbiddenMoves
       ("change-public-export-without-policy-evidence"
        "rewrite-io-or-runtime-boundary-without-witness"
        "replace-macro-transformer-without-runtime-source-witness"))
      (witnessNeeded ("parser-snapshot-or-policy-check"))
      (agentRepairMode
       "use parserEvidence to choose the smallest helper/combinator rewrite; keep names and exact composition flexible when tests and selectors preserve behavior")))
    (arrowCount 1)
    (groupCount 0)
    (selector "t/fixtures/parser/complex-syntax.ss:17-17"))
   (typedContractFact
    (definition "<Widget>")
    (definitionKind "defclass")
    (definitionFormals ())
    (definitionArity 0)
    (contract "String")
    (contractOutput "String")
    (contractInputs ())
    (contractInputCount 0)
    (arityAlignment "declaration")
    (tokens ("String"))
    (quality "declaration-contract")
    (reasons ())
    (qualityFacets
     ("contract-valid" "declaration-contract" "declaration"))
    (repairEvidence
     (repairEvidence
      (factSource "native-parser")
      (trigger "typed-combinator-style")
      (definition "<Widget>")
      (definitionKind "defclass")
      (definitionFormals ())
      (definitionArity 0)
      (path "t/fixtures/parser/complex-syntax.ss")
      (lineSpan (24 24))
      (selector "t/fixtures/parser/complex-syntax.ss:24-24")
      (contract "String")
      (quality "declaration-contract")
      (qualityFacets
       ("contract-valid"
        "declaration-contract"
        "declaration"))
      (matchedCalls ())
      (matchedHigherOrder ())
      (matchedControlFlow ())
      (allowedMoves ("add-or-expand-adjacent-typed-contract-block"))
      (forbiddenMoves
       ("change-public-export-without-policy-evidence"
        "rewrite-io-or-runtime-boundary-without-witness"
        "replace-macro-transformer-without-runtime-source-witness"))
      (witnessNeeded ("parser-snapshot-or-policy-check"))
      (agentRepairMode
       "use parserEvidence to choose the smallest helper/combinator rewrite; keep names and exact composition flexible when tests and selectors preserve behavior")))
    (arrowCount 0)
    (groupCount 0)
    (selector "t/fixtures/parser/complex-syntax.ss:23-23"))
   (typedContractFact
    (definition ":render")
    (definitionKind "defgeneric")
    (definitionFormals ())
    (definitionArity 0)
    (contract "Integer")
    (contractOutput "Integer")
    (contractInputs ())
    (contractInputCount 0)
    (arityAlignment "declaration")
    (tokens ("Integer"))
    (quality "declaration-contract")
    (reasons ())
    (qualityFacets
     ("contract-valid"
      "declaration-contract"
      "declaration"
      "call-backed"))
    (repairEvidence
     (repairEvidence
      (factSource "native-parser")
      (trigger "typed-combinator-style")
      (definition ":render")
      (definitionKind "defgeneric")
      (definitionFormals ())
      (definitionArity 0)
      (path "t/fixtures/parser/complex-syntax.ss")
      (lineSpan (26 26))
      (selector "t/fixtures/parser/complex-syntax.ss:26-26")
      (contract "Integer")
      (quality "declaration-contract")
      (qualityFacets
       ("contract-valid"
        "declaration-contract"
        "declaration"
        "call-backed"))
      (matchedCalls
       ((repairCall
         (kind "call")
         (name "displayln")
         (arity 1)
         (selector "t/fixtures/parser/complex-syntax.ss:34-34"))
        (repairCall
         (kind "call")
         (name "read-json")
         (arity 1)
         (selector "t/fixtures/parser/complex-syntax.ss:35-35"))
        (repairCall
         (kind "call")
         (name "open-input-string")
         (arity 1)
         (selector "t/fixtures/parser/complex-syntax.ss:35-35"))
        (repairCall
         (kind "call")
         (name ":render")
         (arity 1)
         (selector "t/fixtures/parser/complex-syntax.ss:36-36"))))
      (matchedHigherOrder ())
      (matchedControlFlow ())
      (allowedMoves ("add-or-expand-adjacent-typed-contract-block"))
      (forbiddenMoves
       ("change-public-export-without-policy-evidence"
        "rewrite-io-or-runtime-boundary-without-witness"
        "replace-macro-transformer-without-runtime-source-witness"))
      (witnessNeeded ("parser-snapshot-or-policy-check"))
      (agentRepairMode
       "use parserEvidence to choose the smallest helper/combinator rewrite; keep names and exact composition flexible when tests and selectors preserve behavior")))
    (arrowCount 0)
    (groupCount 0)
    (selector "t/fixtures/parser/complex-syntax.ss:25-25"))
   (typedContractFact
    (definition "<Renderable>")
    (definitionKind "defprotocol")
    (definitionFormals ())
    (definitionArity 0)
    (contract "Integer")
    (contractOutput "Integer")
    (contractInputs ())
    (contractInputCount 0)
    (arityAlignment "declaration")
    (tokens ("Integer"))
    (quality "declaration-contract")
    (reasons ())
    (qualityFacets
     ("contract-valid" "declaration-contract" "declaration"))
    (repairEvidence
     (repairEvidence
      (factSource "native-parser")
      (trigger "typed-combinator-style")
      (definition "<Renderable>")
      (definitionKind "defprotocol")
      (definitionFormals ())
      (definitionArity 0)
      (path "t/fixtures/parser/complex-syntax.ss")
      (lineSpan (28 28))
      (selector "t/fixtures/parser/complex-syntax.ss:28-28")
      (contract "Integer")
      (quality "declaration-contract")
      (qualityFacets
       ("contract-valid"
        "declaration-contract"
        "declaration"))
      (matchedCalls ())
      (matchedHigherOrder ())
      (matchedControlFlow ())
      (allowedMoves ("add-or-expand-adjacent-typed-contract-block"))
      (forbiddenMoves
       ("change-public-export-without-policy-evidence"
        "rewrite-io-or-runtime-boundary-without-witness"
        "replace-macro-transformer-without-runtime-source-witness"))
      (witnessNeeded ("parser-snapshot-or-policy-check"))
      (agentRepairMode
       "use parserEvidence to choose the smallest helper/combinator rewrite; keep names and exact composition flexible when tests and selectors preserve behavior")))
    (arrowCount 0)
    (groupCount 0)
    (selector "t/fixtures/parser/complex-syntax.ss:27-27"))
   (typedContractFact
    (definition ":render")
    (definitionKind "defmethod")
    (definitionFormals ())
    (definitionArity 0)
    (contract "Integer")
    (contractOutput "Integer")
    (contractInputs ())
    (contractInputCount 0)
    (arityAlignment "declaration")
    (tokens ("Integer"))
    (quality "declaration-contract")
    (reasons ())
    (qualityFacets
     ("contract-valid"
      "declaration-contract"
      "declaration"
      "call-backed"))
    (repairEvidence
     (repairEvidence
      (factSource "native-parser")
      (trigger "typed-combinator-style")
      (definition ":render")
      (definitionKind "defmethod")
      (definitionFormals ())
      (definitionArity 0)
      (path "t/fixtures/parser/complex-syntax.ss")
      (lineSpan (30 36))
      (selector "t/fixtures/parser/complex-syntax.ss:30-36")
      (contract "Integer")
      (quality "declaration-contract")
      (qualityFacets
       ("contract-valid"
        "declaration-contract"
        "declaration"
        "call-backed"))
      (matchedCalls
       ((repairCall
         (kind "call")
         (name "displayln")
         (arity 1)
         (selector "t/fixtures/parser/complex-syntax.ss:34-34"))
        (repairCall
         (kind "call")
         (name "read-json")
         (arity 1)
         (selector "t/fixtures/parser/complex-syntax.ss:35-35"))
        (repairCall
         (kind "call")
         (name "open-input-string")
         (arity 1)
         (selector "t/fixtures/parser/complex-syntax.ss:35-35"))
        (repairCall
         (kind "call")
         (name ":render")
         (arity 1)
         (selector "t/fixtures/parser/complex-syntax.ss:36-36"))))
      (matchedHigherOrder ())
      (matchedControlFlow ())
      (allowedMoves ("add-or-expand-adjacent-typed-contract-block"))
      (forbiddenMoves
       ("change-public-export-without-policy-evidence"
        "rewrite-io-or-runtime-boundary-without-witness"
        "replace-macro-transformer-without-runtime-source-witness"))
      (witnessNeeded ("parser-snapshot-or-policy-check"))
      (agentRepairMode
       "use parserEvidence to choose the smallest helper/combinator rewrite; keep names and exact composition flexible when tests and selectors preserve behavior")))
    (arrowCount 0)
    (groupCount 0)
    (selector "t/fixtures/parser/complex-syntax.ss:29-29"))
   (typedContractFact
    (definition "make-widget")
    (definitionKind "def")
    (definitionFormals ("name" "rest"))
    (definitionArity 2)
    (contract "(-> String (List String) String )")
    (contractOutput "String")
    (contractInputs ("String" "(List String)"))
    (contractInputCount 2)
    (arityAlignment "aligned")
    (tokens ("String" "List" "String" "String"))
    (quality "domain-transform")
    (reasons ())
    (qualityFacets
     ("contract-valid"
      "scheme-native-block"
      "domain-transform"
      "aligned"
      "arity-bearing-definition"
      "call-backed"
      "combinator-candidate"))
    (repairEvidence
     (repairEvidence
      (factSource "native-parser")
      (trigger "typed-combinator-style")
      (definition "make-widget")
      (definitionKind "def")
      (definitionFormals ("name" "rest"))
      (definitionArity 2)
      (path "t/fixtures/parser/complex-syntax.ss")
      (lineSpan (38 41))
      (selector "t/fixtures/parser/complex-syntax.ss:38-41")
      (contract "(-> String (List String) String )")
      (quality "domain-transform")
      (qualityFacets
       ("contract-valid"
        "scheme-native-block"
        "domain-transform"
        "aligned"
        "arity-bearing-definition"
        "call-backed"
        "combinator-candidate"))
      (matchedCalls
       ((repairCall
         (kind "call")
         (name "with-widget")
         (arity 2)
         (selector "t/fixtures/parser/complex-syntax.ss:40-41"))
        (repairCall
         (kind "call")
         (name "make-<Widget>")
         (arity 2)
         (selector "t/fixtures/parser/complex-syntax.ss:41-41"))))
      (matchedHigherOrder ())
      (matchedControlFlow ())
      (allowedMoves
       ("add-or-expand-adjacent-typed-contract-block"
        "extract-predicate-mapper-or-reducer-helper"
        "compose-with-map-filter-fold-cut-curry-or-compose"))
      (forbiddenMoves
       ("change-public-export-without-policy-evidence"
        "rewrite-io-or-runtime-boundary-without-witness"
        "replace-macro-transformer-without-runtime-source-witness"))
      (witnessNeeded ("parser-snapshot-or-policy-check"))
      (agentRepairMode
       "use parserEvidence to choose the smallest helper/combinator rewrite; keep names and exact composition flexible when tests and selectors preserve behavior")))
    (arrowCount 1)
    (groupCount 0)
    (selector "t/fixtures/parser/complex-syntax.ss:37-37"))
   (typedContractFact
    (definition "dispatch")
    (definitionKind "def")
    (definitionFormals ("value"))
    (definitionArity 1)
    (contract "(-> Value Dispatch )")
    (contractOutput "Dispatch")
    (contractInputs ("Value"))
    (contractInputCount 1)
    (arityAlignment "aligned")
    (tokens ("Value" "Dispatch"))
    (quality "domain-transform")
    (reasons ())
    (qualityFacets
     ("contract-valid"
      "scheme-native-block"
      "domain-transform"
      "aligned"
      "arity-bearing-definition"
      "call-backed"
      "higher-order-used"
      "combinator-backed"
      "control-flow:pattern-branch"))
    (repairEvidence
     (repairEvidence
      (factSource "native-parser")
      (trigger "typed-combinator-style")
      (definition "dispatch")
      (definitionKind "def")
      (definitionFormals ("value"))
      (definitionArity 1)
      (path "t/fixtures/parser/complex-syntax.ss")
      (lineSpan (43 46))
      (selector "t/fixtures/parser/complex-syntax.ss:43-46")
      (contract "(-> Value Dispatch )")
      (quality "domain-transform")
      (qualityFacets
       ("contract-valid"
        "scheme-native-block"
        "domain-transform"
        "aligned"
        "arity-bearing-definition"
        "call-backed"
        "higher-order-used"
        "combinator-backed"
        "control-flow:pattern-branch"))
      (matchedCalls
       ((repairCall
         (kind "call")
         (name "make-widget")
         (arity 1)
         (selector "t/fixtures/parser/complex-syntax.ss:45-45"))
        (repairCall
         (kind "call")
         (name "make-widget")
         (arity 1)
         (selector "t/fixtures/parser/complex-syntax.ss:46-46"))))
      (matchedHigherOrder
       ((repairHigherOrder
         (kind "higher-order")
         (name "match")
         (role "pattern-matching-function")
         (operandCount 3)
         (selector "t/fixtures/parser/complex-syntax.ss:44-46"))))
      (matchedControlFlow
       ((repairControlFlow
         (kind "control-flow")
         (name "match")
         (role "pattern-branch")
         (bindingCount 0)
         (bodyFormCount 2)
         (selector "t/fixtures/parser/complex-syntax.ss:44-46"))))
      (allowedMoves ("add-or-expand-adjacent-typed-contract-block"))
      (forbiddenMoves
       ("change-public-export-without-policy-evidence"
        "rewrite-io-or-runtime-boundary-without-witness"
        "replace-macro-transformer-without-runtime-source-witness"))
      (witnessNeeded ("parser-snapshot-or-policy-check"))
      (agentRepairMode
       "use parserEvidence to choose the smallest helper/combinator rewrite; keep names and exact composition flexible when tests and selectors preserve behavior")))
    (arrowCount 1)
    (groupCount 0)
    (selector "t/fixtures/parser/complex-syntax.ss:42-42"))
   (typedContractFact
    (definition "select")
    (definitionKind "def")
    (definitionFormals ("x"))
    (definitionArity 1)
    (contract "(-> Value Widget )")
    (contractOutput "Widget")
    (contractInputs ("Value"))
    (contractInputCount 1)
    (arityAlignment "aligned")
    (tokens ("Value" "Widget"))
    (quality "domain-transform")
    (reasons ())
    (qualityFacets
     ("contract-valid"
      "scheme-native-block"
      "domain-transform"
      "aligned"
      "arity-bearing-definition"
      "call-backed"
      "higher-order-used"
      "combinator-backed"))
    (repairEvidence
     (repairEvidence
      (factSource "native-parser")
      (trigger "typed-combinator-style")
      (definition "select")
      (definitionKind "def")
      (definitionFormals ("x"))
      (definitionArity 1)
      (path "t/fixtures/parser/complex-syntax.ss")
      (lineSpan (48 51))
      (selector "t/fixtures/parser/complex-syntax.ss:48-51")
      (contract "(-> Value Widget )")
      (quality "domain-transform")
      (qualityFacets
       ("contract-valid"
        "scheme-native-block"
        "domain-transform"
        "aligned"
        "arity-bearing-definition"
        "call-backed"
        "higher-order-used"
        "combinator-backed"))
      (matchedCalls
       ((repairCall
         (kind "call")
         (name "make-widget")
         (arity 1)
         (selector "t/fixtures/parser/complex-syntax.ss:50-50"))
        (repairCall
         (kind "call")
         (name "dispatch")
         (arity 1)
         (selector "t/fixtures/parser/complex-syntax.ss:51-51"))))
      (matchedHigherOrder
       ((repairHigherOrder
         (kind "higher-order")
         (name "case-lambda")
         (role "multi-arity-function")
         (operandCount 2)
         (selector "t/fixtures/parser/complex-syntax.ss:49-51"))))
      (matchedControlFlow ())
      (allowedMoves ("add-or-expand-adjacent-typed-contract-block"))
      (forbiddenMoves
       ("change-public-export-without-policy-evidence"
        "rewrite-io-or-runtime-boundary-without-witness"
        "replace-macro-transformer-without-runtime-source-witness"))
      (witnessNeeded ("parser-snapshot-or-policy-check"))
      (agentRepairMode
       "use parserEvidence to choose the smallest helper/combinator rewrite; keep names and exact composition flexible when tests and selectors preserve behavior")))
    (arrowCount 1)
    (groupCount 0)
    (selector "t/fixtures/parser/complex-syntax.ss:47-47"))))
 (commentQualityFacts
  ((commentQualityFact
    (targetKind "module")
    (targetName "t/fixtures/parser/complex-syntax.ss")
    (context "module")
    (commentKind "boundary")
    (quality "engineering-grade")
    (required #t)
    (reasons ())
    (commentLines
     ("Boundary:"
      "- test owner records policy expectations."
      "- Keep typed contracts and fixture intent explicit."))
    (targetStart 1)
    (targetEnd 1)
    (parserEvidence
     (commentEvidence
      (factSource "native-parser")
      (targetKind "module")
      (path "t/fixtures/parser/complex-syntax.ss")
      (lineCount 51)
      (existingCommentLineCount 3)
      (commentFocus
       "module responsibility, public boundary, package/import/export assumptions, and parser/policy ownership")
      (commentQuestions
       ("What responsibility does this module own for the harness?"
        "Which package/import/export or runtime boundary must future edits preserve?"
        "Which parser-owned facts or policy outputs should an agent trust from this owner?"))
      (agentRepairMode
       "generate as many adjacent engineering comment lines as needed from parser evidence; completeness and confidence matter more than line count")))
    (selector "t/fixtures/parser/complex-syntax.ss:1-3"))
   (commentQualityFact
    (targetKind "definition")
    (targetName "with-widget")
    (context "macro")
    (commentKind "contract-only")
    (quality "weak")
    (required
     ("defrule" "defsyntax" "defclass" "defgeneric" "defmethod" "defprotocol"))
    (reasons ("contract-only-is-not-engineering-comment"))
    (commentLines (": (-> Value SourceLine String )"))
    (targetStart 14)
    (targetEnd 16)
    (parserEvidence
     (commentEvidence
      (factSource "native-parser")
      (targetKind "definition")
      (definition "with-widget")
      (definitionKind "defrule")
      (definitionFormals ("value" "body"))
      (definitionArity 2)
      (lineSpan 3)
      (context "macro")
      (existingCommentLineCount 1)
      (matchedFactCount 1)
      (matchedFacts
       ((matchedFact
         (factKind "macro")
         (name "with-widget")
         (formKind "defrule")
         (transformer "macro-transformer")
         (phase "syntax")
         (patternCount 1)
         (hygienicSyntax #t)
         (qualityFacets ("hygienic-macro" "macro-sugar"))
         (selector "t/fixtures/parser/complex-syntax.ss:14-16"))))
      (commentFocus
       "macro expansion boundary, hygiene assumptions, runtime-source witness, and safe edit constraints")
      (commentQuestions
       ("What expansion or hygiene boundary does this macro enforce?"
        "Which runtime-source witness should be checked before editing the transformer?"
        "What generated shape or phase assumption would break downstream policy?"))
      (agentRepairMode
       "write as many adjacent comment lines as needed from these parser witnesses; preserve typed-contract comments as shape evidence, not rationale")
      (selector "t/fixtures/parser/complex-syntax.ss:14-16")))
    (selector "t/fixtures/parser/complex-syntax.ss:13-13"))
   (commentQualityFact
    (targetKind "definition")
    (targetName "capture-safe")
    (context "macro")
    (commentKind "contract-only")
    (quality "weak")
    (required ("defsyntax" "defclass" "defgeneric" "defmethod" "defprotocol"))
    (reasons ("contract-only-is-not-engineering-comment"))
    (commentLines (": (-> Stx CaptureSafe )"))
    (targetStart 18)
    (targetEnd 22)
    (parserEvidence
     (commentEvidence
      (factSource "native-parser")
      (targetKind "definition")
      (definition "capture-safe")
      (definitionKind "defsyntax")
      (definitionFormals ("stx"))
      (definitionArity 1)
      (lineSpan 5)
      (context "macro")
      (existingCommentLineCount 1)
      (matchedFactCount 1)
      (matchedFacts
       ((matchedFact
         (factKind "macro")
         (name "capture-safe")
         (formKind "defsyntax")
         (transformer "syntax-case")
         (phase "syntax")
         (patternCount 0)
         (hygienicSyntax #t)
         (qualityFacets
          ("hygienic-macro"
           "syntax-case-transformer"
           "syntax-template-witness"))
         (selector "t/fixtures/parser/complex-syntax.ss:18-22"))))
      (commentFocus
       "macro expansion boundary, hygiene assumptions, runtime-source witness, and safe edit constraints")
      (commentQuestions
       ("What expansion or hygiene boundary does this macro enforce?"
        "Which runtime-source witness should be checked before editing the transformer?"
        "What generated shape or phase assumption would break downstream policy?"))
      (agentRepairMode
       "write as many adjacent comment lines as needed from these parser witnesses; preserve typed-contract comments as shape evidence, not rationale")
      (selector "t/fixtures/parser/complex-syntax.ss:18-22")))
    (selector "t/fixtures/parser/complex-syntax.ss:17-17"))
   (commentQualityFact
    (targetKind "definition")
    (targetName "<Widget>")
    (context "poo")
    (commentKind "weak")
    (quality "weak")
    (required ("defclass" "defgeneric" "defmethod" "defprotocol"))
    (reasons ("weak-engineering-comment"))
    (commentLines ("String"))
    (targetStart 24)
    (targetEnd 24)
    (parserEvidence
     (commentEvidence
      (factSource "native-parser")
      (targetKind "definition")
      (definition "<Widget>")
      (definitionKind "defclass")
      (definitionFormals ())
      (definitionArity 0)
      (lineSpan 1)
      (context "poo")
      (existingCommentLineCount 1)
      (matchedFactCount 1)
      (matchedFacts
       ((matchedFact
         (factKind "poo")
         (name "<Widget>")
         (formKind "defclass")
         (role "class")
         (generic "")
         (receiver "")
         (receiverType "")
         (supers (":object"))
         (slots ("name" "count"))
         (specializers ())
         (specializerTypes ())
         (selector "t/fixtures/parser/complex-syntax.ss:24-24"))))
      (commentFocus
       "object/protocol/generic invariant, method specializers, and runtime witness boundary")
      (commentQuestions
       ("What object, generic, method, or protocol contract is being implemented?"
        "Which receiver, specializer, slot, or protocol evidence constrains the edit?"
        "What runtime witness proves this is not a loose alist/hash object encoding?"))
      (agentRepairMode
       "write as many adjacent comment lines as needed from these parser witnesses; preserve typed-contract comments as shape evidence, not rationale")
      (selector "t/fixtures/parser/complex-syntax.ss:24-24")))
    (selector "t/fixtures/parser/complex-syntax.ss:23-23"))
   (commentQualityFact
    (targetKind "definition")
    (targetName ":render")
    (context "poo")
    (commentKind "weak")
    (quality "weak")
    (required ("defgeneric" "defmethod" "defprotocol"))
    (reasons ("weak-engineering-comment"))
    (commentLines ("Integer"))
    (targetStart 26)
    (targetEnd 26)
    (parserEvidence
     (commentEvidence
      (factSource "native-parser")
      (targetKind "definition")
      (definition ":render")
      (definitionKind "defgeneric")
      (definitionFormals ())
      (definitionArity 0)
      (lineSpan 1)
      (context "poo")
      (existingCommentLineCount 1)
      (matchedFactCount 2)
      (matchedFacts
       ((matchedFact
         (factKind "poo")
         (name ":render")
         (formKind "defmethod")
         (role "method")
         (generic ":render")
         (receiver "widget")
         (receiverType "<Widget>")
         (supers ())
         (slots ())
         (specializers ("widget:<Widget>"))
         (specializerTypes ("<Widget>"))
         (selector "t/fixtures/parser/complex-syntax.ss:30-36"))
        (matchedFact
         (factKind "poo")
         (name ":render")
         (formKind "defgeneric")
         (role "generic")
         (generic ":render")
         (receiver "")
         (receiverType "")
         (supers ())
         (slots ())
         (specializers ())
         (specializerTypes ())
         (selector "t/fixtures/parser/complex-syntax.ss:26-26"))))
      (commentFocus
       "object/protocol/generic invariant, method specializers, and runtime witness boundary")
      (commentQuestions
       ("What object, generic, method, or protocol contract is being implemented?"
        "Which receiver, specializer, slot, or protocol evidence constrains the edit?"
        "What runtime witness proves this is not a loose alist/hash object encoding?"))
      (agentRepairMode
       "write as many adjacent comment lines as needed from these parser witnesses; preserve typed-contract comments as shape evidence, not rationale")
      (selector "t/fixtures/parser/complex-syntax.ss:26-26")))
    (selector "t/fixtures/parser/complex-syntax.ss:25-25"))
   (commentQualityFact
    (targetKind "definition")
    (targetName "<Renderable>")
    (context "poo")
    (commentKind "weak")
    (quality "weak")
    (required ("defprotocol"))
    (reasons ("weak-engineering-comment"))
    (commentLines ("Integer"))
    (targetStart 28)
    (targetEnd 28)
    (parserEvidence
     (commentEvidence
      (factSource "native-parser")
      (targetKind "definition")
      (definition "<Renderable>")
      (definitionKind "defprotocol")
      (definitionFormals ())
      (definitionArity 0)
      (lineSpan 1)
      (context "poo")
      (existingCommentLineCount 1)
      (matchedFactCount 1)
      (matchedFacts
       ((matchedFact
         (factKind "poo")
         (name "<Renderable>")
         (formKind "defprotocol")
         (role "protocol")
         (generic "")
         (receiver "")
         (receiverType "")
         (supers ())
         (slots ())
         (specializers ())
         (specializerTypes ())
         (selector "t/fixtures/parser/complex-syntax.ss:28-28"))))
      (commentFocus
       "object/protocol/generic invariant, method specializers, and runtime witness boundary")
      (commentQuestions
       ("What object, generic, method, or protocol contract is being implemented?"
        "Which receiver, specializer, slot, or protocol evidence constrains the edit?"
        "What runtime witness proves this is not a loose alist/hash object encoding?"))
      (agentRepairMode
       "write as many adjacent comment lines as needed from these parser witnesses; preserve typed-contract comments as shape evidence, not rationale")
      (selector "t/fixtures/parser/complex-syntax.ss:28-28")))
    (selector "t/fixtures/parser/complex-syntax.ss:27-27"))
   (commentQualityFact
    (targetKind "definition")
    (targetName ":render")
    (context "poo")
    (commentKind "weak")
    (quality "weak")
    (required ("defmethod" "defprotocol"))
    (reasons ("weak-engineering-comment"))
    (commentLines ("Integer"))
    (targetStart 30)
    (targetEnd 36)
    (parserEvidence
     (commentEvidence
      (factSource "native-parser")
      (targetKind "definition")
      (definition ":render")
      (definitionKind "defmethod")
      (definitionFormals ())
      (definitionArity 0)
      (lineSpan 7)
      (context "poo")
      (existingCommentLineCount 1)
      (matchedFactCount 2)
      (matchedFacts
       ((matchedFact
         (factKind "poo")
         (name ":render")
         (formKind "defmethod")
         (role "method")
         (generic ":render")
         (receiver "widget")
         (receiverType "<Widget>")
         (supers ())
         (slots ())
         (specializers ("widget:<Widget>"))
         (specializerTypes ("<Widget>"))
         (selector "t/fixtures/parser/complex-syntax.ss:30-36"))
        (matchedFact
         (factKind "poo")
         (name ":render")
         (formKind "defgeneric")
         (role "generic")
         (generic ":render")
         (receiver "")
         (receiverType "")
         (supers ())
         (slots ())
         (specializers ())
         (specializerTypes ())
         (selector "t/fixtures/parser/complex-syntax.ss:26-26"))))
      (commentFocus
       "object/protocol/generic invariant, method specializers, and runtime witness boundary")
      (commentQuestions
       ("What object, generic, method, or protocol contract is being implemented?"
        "Which receiver, specializer, slot, or protocol evidence constrains the edit?"
        "What runtime witness proves this is not a loose alist/hash object encoding?"))
      (agentRepairMode
       "write as many adjacent comment lines as needed from these parser witnesses; preserve typed-contract comments as shape evidence, not rationale")
      (selector "t/fixtures/parser/complex-syntax.ss:30-36")))
    (selector "t/fixtures/parser/complex-syntax.ss:29-29"))
   (commentQualityFact
    (targetKind "definition")
    (targetName "make-widget")
    (context "definition")
    (commentKind "contract-only")
    (quality "weak")
    (required #f)
    (reasons ("contract-only-is-not-engineering-comment"))
    (commentLines (": (-> String (List String) String )"))
    (targetStart 38)
    (targetEnd 41)
    (parserEvidence
     (commentEvidence
      (factSource "native-parser")
      (targetKind "definition")
      (definition "make-widget")
      (definitionKind "def")
      (definitionFormals ("name" "rest"))
      (definitionArity 2)
      (lineSpan 4)
      (context "definition")
      (existingCommentLineCount 1)
      (matchedFactCount 0)
      (matchedFacts ())
      (commentFocus
       "definition purpose, stable invariant, and non-obvious edit boundary")
      (commentQuestions
       ("What stable responsibility does this definition own?"
        "Which invariant or boundary is not obvious from the code mechanics?"
        "What parser fact should an agent use before rewriting this owner?"))
      (agentRepairMode
       "write as many adjacent comment lines as needed from these parser witnesses; preserve typed-contract comments as shape evidence, not rationale")
      (selector "t/fixtures/parser/complex-syntax.ss:38-41")))
    (selector "t/fixtures/parser/complex-syntax.ss:37-37"))
   (commentQualityFact
    (targetKind "definition")
    (targetName "dispatch")
    (context "higher-order")
    (commentKind "contract-only")
    (quality "weak")
    (required #f)
    (reasons ("contract-only-is-not-engineering-comment"))
    (commentLines (": (-> Value Dispatch )"))
    (targetStart 43)
    (targetEnd 46)
    (parserEvidence
     (commentEvidence
      (factSource "native-parser")
      (targetKind "definition")
      (definition "dispatch")
      (definitionKind "def")
      (definitionFormals ("value"))
      (definitionArity 1)
      (lineSpan 4)
      (context "higher-order")
      (existingCommentLineCount 1)
      (matchedFactCount 2)
      (matchedFacts
       ((matchedFact
         (factKind "higher-order")
         (name "match")
         (formKind "match")
         (role "pattern-matching-function")
         (operandCount 3)
         (arities ())
         (formals ())
         (caller "dispatch")
         (selector "t/fixtures/parser/complex-syntax.ss:44-46"))
        (matchedFact
         (factKind "control-flow")
         (name "match")
         (formKind "match")
         (role "pattern-branch")
         (caller "dispatch")
         (bindingCount 0)
         (bodyFormCount 2)
         (selector "t/fixtures/parser/complex-syntax.ss:44-46"))))
      (commentFocus
       "expression-level data flow, combinator choice, arity shape, and why the transform is safe")
      (commentQuestions
       ("What data-flow transform does this expression-level combinator encode?"
        "Which arity/formal evidence makes map/filter/fold/cut/compose appropriate?"
        "What invariant would be hidden if this became a hand-written loop?"))
      (agentRepairMode
       "write as many adjacent comment lines as needed from these parser witnesses; preserve typed-contract comments as shape evidence, not rationale")
      (selector "t/fixtures/parser/complex-syntax.ss:43-46")))
    (selector "t/fixtures/parser/complex-syntax.ss:42-42"))
   (commentQualityFact
    (targetKind "definition")
    (targetName "select")
    (context "higher-order")
    (commentKind "contract-only")
    (quality "weak")
    (required #f)
    (reasons ("contract-only-is-not-engineering-comment"))
    (commentLines (": (-> Value Widget )"))
    (targetStart 48)
    (targetEnd 51)
    (parserEvidence
     (commentEvidence
      (factSource "native-parser")
      (targetKind "definition")
      (definition "select")
      (definitionKind "def")
      (definitionFormals ("x"))
      (definitionArity 1)
      (lineSpan 4)
      (context "higher-order")
      (existingCommentLineCount 1)
      (matchedFactCount 1)
      (matchedFacts
       ((matchedFact
         (factKind "higher-order")
         (name "case-lambda")
         (formKind "case-lambda")
         (role "multi-arity-function")
         (operandCount 2)
         (arities (0 1))
         (formals ("x"))
         (caller "select")
         (selector "t/fixtures/parser/complex-syntax.ss:49-51"))))
      (commentFocus
       "expression-level data flow, combinator choice, arity shape, and why the transform is safe")
      (commentQuestions
       ("What data-flow transform does this expression-level combinator encode?"
        "Which arity/formal evidence makes map/filter/fold/cut/compose appropriate?"
        "What invariant would be hidden if this became a hand-written loop?"))
      (agentRepairMode
       "write as many adjacent comment lines as needed from these parser witnesses; preserve typed-contract comments as shape evidence, not rationale")
      (selector "t/fixtures/parser/complex-syntax.ss:48-51")))
    (selector "t/fixtures/parser/complex-syntax.ss:47-47"))))
 (calls ((call (callee ":render")
               (arity 1)
               (caller ":render")
               (arguments ("widget"))
               (argumentTypes ("unknown"))
               (selector "t/fixtures/parser/complex-syntax.ss:36-36"))
         (call (callee "open-input-string")
               (arity 1)
               (caller ":render")
               (arguments ("{}"))
               (argumentTypes ("string"))
               (selector "t/fixtures/parser/complex-syntax.ss:35-35"))
         (call (callee "read-json")
               (arity 1)
               (caller ":render")
               (arguments ("(open-input-string {})"))
               (argumentTypes ("unknown"))
               (selector "t/fixtures/parser/complex-syntax.ss:35-35"))
         (call (callee "displayln")
               (arity 1)
               (caller ":render")
               (arguments ("again"))
               (argumentTypes ("string"))
               (selector "t/fixtures/parser/complex-syntax.ss:34-34"))
         (call (callee "make-<Widget>")
               (arity 2)
               (caller "make-widget")
               (arguments ("name" "count"))
               (argumentTypes ("unknown" "number"))
               (selector "t/fixtures/parser/complex-syntax.ss:41-41"))
         (call (callee "with-widget")
               (arity 2)
               (caller "make-widget")
               (arguments ("name" "(make-<Widget> name count)"))
               (argumentTypes ("unknown" "unknown"))
               (selector "t/fixtures/parser/complex-syntax.ss:40-41"))
         (call (callee "make-widget")
               (arity 1)
               (caller "dispatch")
               (arguments ("fallback"))
               (argumentTypes ("string"))
               (selector "t/fixtures/parser/complex-syntax.ss:46-46"))
         (call (callee "make-widget")
               (arity 1)
               (caller "dispatch")
               (arguments ("s"))
               (argumentTypes ("unknown"))
               (selector "t/fixtures/parser/complex-syntax.ss:45-45"))
         (call (callee "dispatch")
               (arity 1)
               (caller "select")
               (arguments ("x"))
               (argumentTypes ("unknown"))
               (selector "t/fixtures/parser/complex-syntax.ss:51-51"))
         (call (callee "make-widget")
               (arity 1)
               (caller "select")
               (arguments ("empty"))
               (argumentTypes ("string"))
               (selector "t/fixtures/parser/complex-syntax.ss:50-50")))))
