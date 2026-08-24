;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :std/test
        :gslph/src/commands/guide
        :gslph/src/commands/info
        :gslph/src/commands/search
        :gslph/src/support/args
        :std/misc/ports
        (only-in :std/text/json read-json)
        "../poo/runtime-witness"
        "./structural-index")
(export search-test-part-9)
;; : (-> Table Key Json )
(def (json-get table key)
  (hash-get table key))
;; : (-> (List String) String )
(def (search-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (search-main args)))))))
    (check status => 0)
    output))
;; : (-> (List String) String )
(def (guide-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (guide-main args)))))))
    (check status => 0)
    output))
;; : (-> (List String) String )
(def (info-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (info-main args)))))))
    (check status => 0)
    output))
;; : (-> OutputPort Fragment Boolean )
(def (contains? output fragment)
  (and (string-contains output fragment) #t))
;; : (-> OutputPort Boolean )
(def (guide-code-render-metadata-free? output)
  (not (or (contains? output "[guide")
           (contains? output "|primaryExemplar")
           (contains? output "|exemplar")
           (contains? output "|code begin")
           (contains? output "selector=")
           (contains? output "nextCommand=")
           (contains? output "\n|"))))
;; : (-> OutputPort Fragments Boolean )
(def (check-output-contains output fragments)
  (for-each
   (lambda (fragment)
     (check (contains? output fragment) => #t))
   fragments))
;; SearchTest
;; TestSuite
(def search-test-part-9
  (test-suite "gerbil scheme harness search part 9"
    (test-case "capability search projects Gerbil engineering posture"
          (let (output (search-output ["capability" "posture" "."]))
            (check-output-contains
             output
             ["[gerbil-search-capability] query=posture"
              "authority=project-capability-posture"
              "|fact id=package-module-posture"
              "|capability name=package-module status=active"
              "|fact id=macro-posture"
              "|capability name=macro status=active policyRules=GERBIL-SCHEME-AGENT-POLICY-011"
              "|fact id=poo-posture"
              "|capability name=poo status=active policyRules=GERBIL-SCHEME-AGENT-POLICY-008,GERBIL-SCHEME-AGENT-POLICY-012"
              "|fact id=higher-order-posture"
              "|fact id=control-flow-posture"
              "|fact id=configurable-interface-posture"
              "|fact id=quality-closure-posture"
              "|capability name=quality-closure status=declared-closure"
              "|qualitySignal id=policy-covered"
              "|qualitySignal id=guide-covered"
              "|qualitySignal id=snapshot-covered"
              "|qualitySignal id=bench-covered"
              "|failureCase id=basic-scheme-fallback"])))
    (test-case "compiler evidence search exposes medium-weight proof boundary"
          (let (output (search-output ["compiler-evidence" "optimizer" "subtype"
                                        "assertion" "."]))
            (check-output-contains
             output
             ["[gerbil-search-compiler-evidence] query=optimizer subtype assertion"
              "authority=compiler-metadata-source"
              "|fact id=gerbil-compiler-medium-weight-evidence"
              "runtime-source-compiler-optimizer-metadata-and-local-assertion-env"
              "|sourceRef kind=runtime-version-source"
              "|selectorResolver scheme=gerbil-runtime-source"
              "|sourceExample id=compiler-signature-metadata role=optimizer-metadata symbol=!signature selector=gerbil-runtime-source://src/gerbil/compiler/optimize-base.ss#!signature"
              "|sourceExample id=compiler-subtype-relation role=subtype-relation symbol=!type-subtype? selector=gerbil-runtime-source://src/gerbil/compiler/optimize-base.ss#!type-subtype?"
              "|sourceExample id=compiler-local-assertion-env role=local-assertion-env symbol=fold-assert-type selector=gerbil-runtime-source://src/gerbil/compiler/optimize-ann.ss#fold-assert-type"
              "|sourceExample id=compiler-assert-type role=assertion-check symbol=assert-type selector=gerbil-runtime-source://src/gerbil/compiler/optimize-ann.ss#assert-type"
              "|selector role=optimizer-class symbol=!class selector=gerbil-runtime-source://src/gerbil/compiler/optimize-base.ss#!class"
              "|selector role=local-assertion-check symbol=assert-type selector=gerbil-runtime-source://src/gerbil/compiler/optimize-ann.ss#assert-type"
              "|failureCase id=full-proof-system-claim"
              "|failureCase id=pseudo-type-comment"
              "|qualitySignal id=medium-weight-only"
              "|qualitySignal id=no-full-proof-claim"
              "next=search compiler-evidence optimizer subtype assertion"])))
    (test-case "compiler evidence json remains generic language evidence packet"
          (let* ((output (search-output ["compiler-evidence" "assert-type"
                                          "--json" "."]))
                 (packet (call-with-input-string output read-json))
                 (facts (json-get packet "facts"))
                 (fact (car facts))
                 (details (json-get fact "details"))
                 (model (json-get details "model"))
                 (rejected (json-get model "rejectedClaims"))
                 (selectors (json-get fact "selectors"))
                 (assert-selector (list-ref selectors 6)))
            (check (json-get packet "schemaId")
                   => "agent.semantic-protocols.semantic-language-evidence")
            (check (json-get packet "namespace") => "compiler-evidence")
            (check (json-get packet "authority") => "compiler-metadata-source")
            (check (json-get packet "evidenceGrade") => "fact")
            (check (json-get packet "quality") => "verified")
            (check (json-get fact "id")
                   => "gerbil-compiler-medium-weight-evidence")
            (check (json-get details "proofBoundary")
                   => "medium-weight-compiler-evidence")
            (check (member "proof-term-calculus" rejected) => #t)
            (check (json-get assert-selector "symbol") => "assert-type")
            (check (json-get assert-selector "selector")
                   => "gerbil-runtime-source://src/gerbil/compiler/optimize-ann.ss#assert-type")
            (check (json-get packet "next")
                   => "search compiler-evidence optimizer subtype assertion")))
    (test-case "proof search exposes medium-weight TypeSpec proof system"
          (let (output (search-output ["proof" "record" "."]))
            (check-output-contains
             output
             ["[gerbil-search-proof] query=record"
              "authority=medium-weight-type-proof"
              "|proofSystem id=gerbil-medium-weight-type-proof level=medium-weight engine=src/types/subtyping.ss model=TypeSpec claim=positive-derivation-witness"
              "|proof id=record-width-subtype relation=subtype rootRule=record depth=4 nodeCount=4"
              "rules=record,record-field,refine-base,type-equal"
              "|compilerEvidence namespace=compiler-evidence authority=compiler-metadata-source nextCommand=search compiler-evidence optimizer subtype assertion"
              "|failureCase id=proof-without-typespec-validation"
              "|qualitySignal id=schema-backed-proof-packet"
              "|qualitySignal id=compiler-evidence-linked"
              "next=search compiler-evidence optimizer subtype assertion"])))
    (test-case "proof json carries recursive proof tree and compiler boundary"
          (let* ((output (search-output ["proof" "record" "--json" "."]))
                 (packet (call-with-input-string output read-json))
                 (system (json-get packet "proofSystem"))
                 (compiler-evidence (json-get packet "compilerEvidence"))
                 (proofs (json-get packet "proofs"))
                 (proof (car proofs))
                 (profile (json-get proof "profile"))
                 (proof-tree (json-get proof "proof"))
                 (first-premise (car (json-get proof-tree "premises"))))
            (check (json-get packet "schemaId")
                   => "agent.semantic-protocols.semantic-type-proof")
            (check (json-get packet "namespace") => "proof")
            (check (json-get packet "quality") => "verified")
            (check (json-get system "level") => "medium-weight")
            (check (member "cross-module-theorem-prover"
                           (json-get system "notA"))
                   => #t)
            (check (json-get compiler-evidence "namespace")
                   => "compiler-evidence")
            (check (json-get proof "id") => "record-width-subtype")
            (check (json-get profile "rootRule") => "record")
            (check (json-get profile "depth") => 4)
            (check (json-get profile "nodeCount") => 4)
            (check (json-get proof-tree "rule") => "record")
            (check (json-get first-premise "rule") => "record-field")))
    (test-case "env search exposes active runtime witness"
          (let (output (search-output ["env" "gxi" "."]))
            (check (contains? output "evidenceGrade=fact") => #t)
            (check (contains? output "|runtime gerbilHome=") => #t)
            (check (contains? output "gxiExists=#t") => #t)
            (check (contains? output "gscExists=#t") => #t)
            (check (not (contains? output "pending")) => #t)))))
