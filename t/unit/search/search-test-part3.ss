;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :std/test
        :asp-gerbil-scheme/src/commands/guide
        :asp-gerbil-scheme/src/commands/info
        :asp-gerbil-scheme/src/commands/search
        :asp-gerbil-scheme/src/support/args
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
            (check (string-prefix? "asp-gerbil-scheme guide" output) => #t)
            (check (contains? output "|cmd guide-code=asp-gerbil-scheme guide --code") => #t)
            (check (contains? output "|cmd guide-code-typed-combinator=asp-gerbil-scheme guide --code --topic typed-combinator-style --intent style") => #t)
            (check (contains? output "|cmd guide-code-more=asp-gerbil-scheme guide --code --topic higher-order-control --more") => #t)
            (check (contains? output "|cmd guide-code-repair=asp-gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-009 --intent repair") => #t)
            (check (contains? output "|cmd guide-code-poo-repair=asp-gerbil-scheme guide --code --topic poo-policy --intent repair") => #t)
            (check (contains? output "|cmd guide-code-macro-witness=asp-gerbil-scheme guide --code --topic macro-runtime-source --intent witness") => #t)
            (check (contains? output "|cmd guide-code-branch-shape=asp-gerbil-scheme guide --code --topic controlled-branch-shape --intent style") => #t)
            (check (contains? output "|cmd guide-code-dependency-adapter=asp-gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-017 --intent repair") => #t)
            (check (contains? output "|cmd guide-code-advanced=asp-gerbil-scheme guide --code --topic higher-order-control --level advanced") => #t)
            (check (contains? output "|cmd prime=asp-gerbil-scheme search prime --workspace . --view seeds") => #t)
            (check (contains? output "|cmd pipe=asp-gerbil-scheme search pipe '<term>' --workspace . --view seeds") => #t)
            (check (contains? output "|cmd exact-source=asp-gerbil-scheme query --selector <gerbil-scheme://owner#item/kind/name> --projection source --workspace .") => #t)
            (check (contains? output "|cmd callable-skeleton=asp-gerbil-scheme query --selector <gerbil-scheme://owner#item/kind/name> --projection callable-skeleton --workspace .") => #t)
            (check (contains? output "|cmd env=asp-gerbil-scheme search env [term ...] --workspace . --view seeds") => #t)
            (check (contains? output "|cmd runtime-source=asp-gerbil-scheme search runtime-source [term ...] --workspace . --view seeds") => #t)
            (check (contains? output "|cmd compiler-evidence=asp-gerbil-scheme search compiler-evidence optimizer subtype assertion --workspace . --view seeds") => #t)
            (check (contains? output "|cmd proof=asp-gerbil-scheme search proof subtype record alias --workspace . --view seeds") => #t)
            (check (contains? output "|cmd lang=asp-gerbil-scheme search lang [term ...] --workspace . --view seeds") => #t)
            (check (contains? output "|cmd std=asp-gerbil-scheme search std [term ...] --workspace . --view seeds") => #t)
            (check (contains? output "|cmd capability=asp-gerbil-scheme search capability [term ...] --workspace . --view seeds") => #t)
            (check (contains? output "|cmd extension=asp-gerbil-scheme search extension <extension> [term ...] --view seeds") => #t)
            (check (contains? output "|cmd pattern=asp-gerbil-scheme search pattern <feature-or-extension> [term ...] --view seeds") => #t)
            (check (contains? output "|cmd compare=asp-gerbil-scheme search compare <axis> [left right] --workspace . --view seeds") => #t)
            (check (contains? output "|cmd structural=asp-gerbil-scheme search structural --workspace . --view seeds") => #t)
            (check (contains? output "|cmd structural-interface-json=asp-gerbil-scheme search structural --json .") => #t)
            (check (contains? output "|cmd structural-owner-facts-json=asp-gerbil-scheme search structural --owner <path> --json .") => #t)
            (check (contains? output "|cmd structural-artifact-json=asp-gerbil-scheme search structural --json --artifact .") => #t)
            (check (contains? output "|cmd info=asp-gerbil-scheme info --json .") => #t)
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
            (check (contains? output "nextCommand=\"asp-gerbil-scheme search structural --owner t/fixtures/parser/poo-method-dispatch.ss --json .\"") => #t)
            (check (contains? output "|guideExemplar id=gerbil.macro-runtime-source.witness topic=macro-runtime-source intent=witness rule=GERBIL-SCHEME-AGENT-POLICY-011") => #t)
            (check (contains? output "|guideExemplar id=gerbil.controlled-branch-shape.bounded-selector topic=controlled-branch-shape intent=style rule=GERBIL-SCHEME-AGENT-POLICY-014") => #t)
            (check (contains? output "|guideExemplar id=gerbil.engineering-comment-quality.contract-boundary topic=engineering-comment-quality intent=style rule=GERBIL-SCHEME-AGENT-POLICY-015") => #t)
            (check (contains? output "|guideExemplar id=gerbil.dependency-protocol-adapter.rationaldict-shape topic=dependency-protocol-adapter intent=repair rule=GERBIL-SCHEME-AGENT-POLICY-017") => #t)
            (check (contains? output "repairAction=inspect-code-shape guideCodeFlag=--code") => #t)
            (check (contains? output "nextCommand=\"asp-gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-017 --intent repair\"") => #t)
            (check (contains? output "|policy guide-code-default=guide --code writes only extracted source comment plus source code; guide without --code carries selectors and next commands") => #t)
            (check (contains? output "|policy guide-code-progressive=guide --code defaults to one source-backed excerpt; --more adds one adjacent exemplar; --level advanced includes the macro runtime-source witness path") => #t)
            (check (contains? output "|policy guide-code-routing=--rule/--finding route known policy ids to source-backed exemplars before agent repair; --intent witness routes to macro runtime-source evidence") => #t)
            (check (contains? output "|policy guide-workspace=guide does not require a positional .; use --workspace . only when project-local exemplar selection needs context") => #t)
            (check (contains? output "|policy poo-io-runtime-source=POO :wr/writeenv changes should cite search runtime-source writeenv printer hook; hook guidance remains soft until real-project noise is reviewed") => #t)))))
