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
(export search-test-part-3)
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
(def search-test-part-3
  (test-suite "gerbil scheme harness search part 3"
    (test-case "gerbil-poo usage search works without positional root"
          (let ((extension-output
                 (search-output ["extension" "gerbil-poo" "usage" "--view" "seeds"]))
                (pattern-output
                 (search-output ["pattern" "gerbil-poo" "usage" "--view" "seeds"]))
                (split-extension-output
                 (search-output ["extension" "gerbil" "poo" "usage" "--view" "seeds"]))
                (split-pattern-output
                 (search-output ["pattern" "gerbil" "poo" "usage" "--view" "seeds"]))
                (workspace-poo-output
                 (search-output ["extension" "poo" "--workspace" "."]))
                (missing-root-extension-output
                 (search-output ["extension" "gerbil-poo" "usage"
                                 "--view" "seeds"
                                 "/tmp/asp-gerbil-poo-registered-root-missing"]))
                (missing-root-poo-output
                 (search-output ["extension" "poo" "usage"
                                 "--view" "seeds"
                                 "--workspace"
                                 "/tmp/asp-gerbil-poo-registered-root-missing"]))
                (missing-root-pattern-output
                 (search-output ["pattern" "gerbil-poo" "usage"
                                 "--view" "seeds"
                                 "--workspace"
                                 "/tmp/asp-gerbil-poo-registered-root-missing"])))
            (check (contains? extension-output
                              "[gerbil-search-extension] query=gerbil-poo usage matches=1 evidenceGrade=fact")
                   => #t)
            (check (contains? extension-output
                              "next=search pattern gerbil-poo usage")
                   => #t)
            (check (contains? extension-output
                              "|agentAction action=follow-next registeredKnowledge=gerbil-poo:// notProjectActivation=true")
                   => #t)
            (check (contains? extension-output
                              "missingLocalAction=install-package-before-repository-fallback")
                   => #t)
            (check (contains? workspace-poo-output
                              "[gerbil-search-extension] query=poo")
                   => #t)
            (check (contains? workspace-poo-output
                              "matches=1 evidenceGrade=fact")
                   => #t)
            (check (contains? workspace-poo-output
                              "|extension name=poo")
                   => #t)
            (check (contains? missing-root-poo-output
                              "[gerbil-search-extension] query=poo usage matches=1 evidenceGrade=fact")
                   => #t)
            (check (contains? missing-root-poo-output
                              "registeredKnowledge=gerbil-poo:// notProjectActivation=true")
                   => #t)
            (check (contains? pattern-output
                              "[gerbil-search-pattern] query=gerbil-poo usage evidenceGrade=fact authority=executable-pattern quality=verified")
                   => #t)
            (check (contains? pattern-output
                              "|pattern id=poo-object-system extension=poo focus=usage")
                   => #t)
            (check (contains? pattern-output
                              "|selectorResolver scheme=gerbil-poo-logical-symbol status=logical-selector querySelector=not-direct")
                   => #t)
            (check (contains? pattern-output
                              "|agentReadOrder first=agentScenario second=agentSteering third=selectorResolver fourth=minimalForms fifth=failureCases sixth=quality")
                   => #t)
            (check (contains? pattern-output
                              "|agentAction action=use-minimalForms-before-editing selectorUse=source-anchor")
                   => #t)
            (check (contains? pattern-output
                              "missingLocalAction=install-package-before-repository-fallback")
                   => #t)
            (check (contains? pattern-output
                              "fallback=repository-source-after-install-check")
                   => #t)
            (check (contains? pattern-output
                              "quality=verified")
                   => #t)
            (check (contains? pattern-output
                              "|selector role=class-definition symbol=defclass selector=gerbil-poo://object.ss#defclass")
                   => #t)
            (check (contains? split-extension-output
                              "[gerbil-search-extension] query=gerbil poo usage matches=1 evidenceGrade=fact")
                   => #t)
            (check (contains? split-extension-output
                              "next=search pattern gerbil-poo usage")
                   => #t)
            (check (contains? split-pattern-output
                              "[gerbil-search-pattern] query=gerbil poo usage evidenceGrade=fact authority=executable-pattern quality=verified")
                   => #t)
            (check (contains? split-pattern-output
                              "|registeredKnowledge")
                   => #f)
            (check (contains? split-pattern-output
                              "|pattern id=poo-object-system extension=poo focus=usage")
                   => #t)
            (check (contains? pattern-output "missing=extension-fact")
                   => #f)
            (check (contains? missing-root-extension-output
                              "matches=1 evidenceGrade=fact")
                   => #t)
            (check (contains? missing-root-pattern-output
                              "evidenceGrade=fact authority=executable-pattern quality=verified")
                   => #t)
            (check (contains? missing-root-pattern-output "origin=registered")
                   => #t)))
    (test-case "search guide routes to provider guide"
          (let (output (search-output ["guide" "--view" "seeds" "."]))
            (check (string-prefix? "gerbil-scheme-harness guide" output) => #t)
            (check (contains? output "|cmd guide-code=gerbil-scheme-harness guide --code") => #t)
            (check (contains? output "|cmd guide-code-typed-combinator=gerbil-scheme-harness guide --code --topic typed-combinator-style --intent style") => #t)
            (check (contains? output "|cmd guide-code-more=gerbil-scheme-harness guide --code --topic higher-order-control --more") => #t)
            (check (contains? output "|cmd guide-code-repair=gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-POLICY-009 --intent repair") => #t)
            (check (contains? output "|cmd guide-code-poo-repair=gerbil-scheme-harness guide --code --topic poo-policy --intent repair") => #t)
            (check (contains? output "|cmd guide-code-macro-witness=gerbil-scheme-harness guide --code --topic macro-runtime-source --intent witness") => #t)
            (check (contains? output "|cmd guide-code-branch-shape=gerbil-scheme-harness guide --code --topic controlled-branch-shape --intent style") => #t)
            (check (contains? output "|cmd guide-code-dependency-adapter=gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-POLICY-017 --intent repair") => #t)
            (check (contains? output "|cmd guide-code-advanced=gerbil-scheme-harness guide --code --topic higher-order-control --level advanced") => #t)
            (check (contains? output "|cmd prime=gerbil-scheme-harness search prime --workspace . --view seeds") => #t)
            (check (contains? output "|cmd pipe=gerbil-scheme-harness search pipe '<term>' --workspace . --view seeds") => #t)
            (check (contains? output "|cmd exact-source=gerbil-scheme-harness query --selector <gerbil-scheme://owner#item/kind/name> --projection source --workspace .") => #t)
            (check (contains? output "|cmd callable-skeleton=gerbil-scheme-harness query --selector <gerbil-scheme://owner#item/kind/name> --projection callable-skeleton --workspace .") => #t)
            (check (contains? output "|cmd env=gerbil-scheme-harness search env [term ...] --workspace . --view seeds") => #t)
            (check (contains? output "|cmd runtime-source=gerbil-scheme-harness search runtime-source [term ...] --workspace . --view seeds") => #t)
            (check (contains? output "|cmd compiler-evidence=gerbil-scheme-harness search compiler-evidence optimizer subtype assertion --workspace . --view seeds") => #t)
            (check (contains? output "|cmd proof=gerbil-scheme-harness search proof subtype record alias --workspace . --view seeds") => #t)
            (check (contains? output "|cmd lang=gerbil-scheme-harness search lang [term ...] --workspace . --view seeds") => #t)
            (check (contains? output "|cmd std=gerbil-scheme-harness search std [term ...] --workspace . --view seeds") => #t)
            (check (contains? output "|cmd capability=gerbil-scheme-harness search capability [term ...] --workspace . --view seeds") => #t)
            (check (contains? output "|cmd extension=gerbil-scheme-harness search extension <extension> [term ...] --view seeds") => #t)
            (check (contains? output "|cmd pattern=gerbil-scheme-harness search pattern <feature-or-extension> [term ...] --view seeds") => #t)
            (check (contains? output "|cmd compare=gerbil-scheme-harness search compare <axis> [left right] --workspace . --view seeds") => #t)
            (check (contains? output "|cmd structural=gerbil-scheme-harness search structural --workspace . --view seeds") => #t)
            (check (contains? output "|cmd structural-interface-json=gerbil-scheme-harness search structural --json .") => #t)
            (check (contains? output "|cmd structural-owner-facts-json=gerbil-scheme-harness search structural --owner <path> --json .") => #t)
            (check (contains? output "|cmd structural-artifact-json=gerbil-scheme-harness search structural --json --artifact .") => #t)
            (check (contains? output "|cmd info=gerbil-scheme-harness info --json .") => #t)
            (check (contains? output "|policy package-module-style=Gerbil package modules should preserve package:/namespace:/import/export style") => #t)
            (check (contains? output "|policy poo-direct-writeenv=GERBIL-SCHEME-AGENT-POLICY-006") => #t)
            (check (contains? output "|policy poo-io-runtime-witness=GERBIL-SCHEME-AGENT-POLICY-007") => #t)
            (check (contains? output "|policy poo-method-shape=GERBIL-SCHEME-AGENT-POLICY-008") => #t)
            (check (contains? output "|policy macro-runtime-source-witness=GERBIL-SCHEME-AGENT-POLICY-011") => #t)
            (check (contains? output "|policy protocol-evidence=GERBIL-SCHEME-AGENT-POLICY-012") => #t)
            (check (contains? output "|policy functional-data-transform=GERBIL-SCHEME-AGENT-POLICY-009") => #t)
            (check (contains? output "|policy manual-object-encoding=GERBIL-SCHEME-AGENT-POLICY-010") => #t)
            (check (contains? output "|policy typed-combinator-style=GERBIL-SCHEME-AGENT-POLICY-013") => #t)
            (check (contains? output "|policy typed-combinator-style-criteria=three criteria are required") => #t)
            (check (contains? output "|policy typed-combinator-style-signature=write an adjacent contract block") => #t)
            (check (contains? output "|policy typed-combinator-style-composition=prefer small helper functions and expression-level") => #t)
            (check (contains? output "|policy typed-combinator-style-optimization-boundary=for case-lambda or common-case specializations") => #t)
            (check (contains? output "|policy controlled-branch-shape=GERBIL-SCHEME-AGENT-POLICY-014") => #t)
            (check (contains? output "|policy engineering-comment-quality=GERBIL-SCHEME-AGENT-POLICY-015") => #t)
            (check (contains? output "|policy dependency-protocol-adapter=GERBIL-SCHEME-AGENT-POLICY-017") => #t)
            (check (contains? output "|policy poo-structural-facts=search structural --owner <path> --json exposes parser-owned POO forms") => #t)
            (check (contains? output "|policy guide-code-default-topic=guide --code defaults to typed-combinator-style") => #t)
            (check (contains? output "|policy namespace-receipt=macro/module/type/poo edits should cite search env/lang/std/pattern/runtime-source/proof/compiler-evidence output before editing") => #t)
            (check (contains? output "|policy runtime-source-code-comments=runtime-source results should expose selectorResolver/sourceExample/sourceComment lines before selector code reads") => #t)
            (check (contains? output "|policy compiler-evidence-boundary=type/proof repairs must cite search proof subtype record alias plus search compiler-evidence optimizer subtype assertion") => #t)
            (check (contains? output "|guideExemplar id=gerbil.higher-order-control.filter-map topic=higher-order-control intent=study rule=GERBIL-SCHEME-AGENT-POLICY-009") => #t)
            (check (contains? output "|guideExemplar id=gerbil.functional-data-transform.filter-map topic=functional-data-transform intent=repair rule=GERBIL-SCHEME-AGENT-POLICY-009") => #t)
            (check (contains? output "|guideExemplar id=gerbil.typed-combinator-style.policy-coverage topic=typed-combinator-style intent=style rule=GERBIL-SCHEME-AGENT-POLICY-013") => #t)
            (check (contains? output "|guideExemplar id=gerbil.typed-combinator-style.policy-filter-map topic=typed-combinator-style intent=style rule=GERBIL-SCHEME-AGENT-POLICY-013 level=more") => #t)
            (check (contains? output "locator=parser-definition") => #t)
            (check (contains? output "commentSelector=") => #f)
            (check (contains? output "codeSelector=") => #f)
            (check (contains? output "|guideExemplar id=gerbil.poo-policy.parser-facts topic=poo-policy intent=repair rule=GERBIL-SCHEME-AGENT-POLICY-008") => #t)
            (check (contains? output "|guideExemplar id=gerbil.poo-policy.structural-owner-facts topic=poo-policy intent=witness rule=GERBIL-SCHEME-AGENT-POLICY-008") => #t)
            (check (contains? output "nextCommand=\"gerbil-scheme-harness search structural --owner t/fixtures/parser/poo-method-dispatch.ss --json .\"") => #t)
            (check (contains? output "|guideExemplar id=gerbil.macro-runtime-source.witness topic=macro-runtime-source intent=witness rule=GERBIL-SCHEME-AGENT-POLICY-011") => #t)
            (check (contains? output "|guideExemplar id=gerbil.controlled-branch-shape.bounded-selector topic=controlled-branch-shape intent=style rule=GERBIL-SCHEME-AGENT-POLICY-014") => #t)
            (check (contains? output "|guideExemplar id=gerbil.engineering-comment-quality.contract-boundary topic=engineering-comment-quality intent=style rule=GERBIL-SCHEME-AGENT-POLICY-015") => #t)
            (check (contains? output "|guideExemplar id=gerbil.dependency-protocol-adapter.rationaldict-shape topic=dependency-protocol-adapter intent=repair rule=GERBIL-SCHEME-AGENT-POLICY-017") => #t)
            (check (contains? output "repairAction=inspect-code-shape guideCodeFlag=--code") => #t)
            (check (contains? output "nextCommand=\"gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-POLICY-017 --intent repair\"") => #t)
            (check (contains? output "|policy guide-code-default=guide --code writes only extracted source comment plus source code; guide without --code carries selectors and next commands") => #t)
            (check (contains? output "|policy guide-code-progressive=guide --code defaults to one source-backed excerpt; --more adds one adjacent exemplar; --level advanced includes the macro runtime-source witness path") => #t)
            (check (contains? output "|policy guide-code-routing=--rule/--finding route known policy ids to source-backed exemplars before agent repair; --intent witness routes to macro runtime-source evidence") => #t)
            (check (contains? output "|policy guide-workspace=guide does not require a positional .; use --workspace . only when project-local exemplar selection needs context") => #t)
            (check (contains? output "|policy poo-io-runtime-source=POO :wr/writeenv changes should cite search runtime-source writeenv printer hook; hook guidance remains soft until real-project noise is reviewed") => #t)))))
