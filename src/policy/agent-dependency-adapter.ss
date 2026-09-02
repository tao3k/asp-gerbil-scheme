;;; -*- Gerbil -*-
;;; Agent-facing dependency protocol adapter policy over parser-owned facts.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-support
        :asp-gerbil-scheme/src/policy/dependency-adapter-profile
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/misc/list unique)
        (only-in :std/srfi/13 string-contains string-join string-prefix?)
        :asp-gerbil-scheme/src/types/findings)

(export dependency-protocol-adapter-findings
        dependency-protocol-adapter-finding)

;; (List String)
(def +dependency-adapter-contract-witness-callees+
  '("test-suite" "test-case" "table-tests" "universal-tests"
    "check" "check-equal?" "assert-equal!"))

;; (List String)
(def +dependency-adapter-generic-contract-witness-callees+
  '("adapter-contract-tests" "protocol-contract-tests" "table-contract-tests"
    "table-tests" "universal-tests" "json-contract-tests"
    "marshal-contract-tests" "list-contract-tests"))

;; Command
(def +dependency-adapter-repair-code-command+
  "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-017 --intent repair")
;; Command
(def +dependency-adapter-fact-command+
  "asp-gerbil-scheme evidence graph --json .")

;;; Entry boundary: policy only consumes parser-owned adapter facts.
;;; It does not infer adapter quality from raw source text.
;; : (-> ProjectIndex (List TypeFinding) )
(def (dependency-protocol-adapter-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (cut dependency-protocol-adapter-finding index file <>)
                 (source-file-dependency-adapter-quality-facts file)))
              (project-index-files index))))

;;; Finding gate: incomplete local adapter evidence or missing visible project
;;; contract witness triggers repair. Package policy can intentionally disable
;;; test-owner scanning for fast self-apply indexes.
;; : (-> ProjectIndex SourceFile DependencyAdapterQualityFact TypeFinding )
(def (dependency-protocol-adapter-finding index file fact)
  (and (index-source-runtime-file-path? index (source-file-path file))
       (let (missing (dependency-protocol-adapter-missing-evidence index fact))
         (and (pair? missing)
              (make-type-finding
               (policy-rule-id +agent-dependency-protocol-adapter-rule+)
               (policy-rule-severity +agent-dependency-protocol-adapter-rule+)
               (source-file-path file)
               (dependency-protocol-adapter-message fact missing)
               (dependency-adapter-quality-fact-selector fact)
               (dependency-protocol-adapter-details index fact missing))))))

;; : (-> ProjectIndex DependencyAdapterQualityFact (List MissingEvidence) )
(def (dependency-protocol-adapter-missing-evidence index fact)
  (unique
   (append (dependency-adapter-quality-fact-missing-evidence fact)
           (if (or (not (dependency-adapter-generic-contract-witness-required? index))
                   (dependency-adapter-generic-contract-witness-exists? index fact))
             []
             ["generic-contract-test-witness"]))))

;; : (-> DependencyAdapterQualityFact MissingEvidence String )
(def (dependency-protocol-adapter-message fact missing)
  (string-append
   "dependency adapter " (dependency-adapter-quality-fact-name fact)
   " wraps " (dependency-adapter-quality-fact-dependency fact)
   " but is missing " (string-join missing ",")
   "; lift dependency primitives into a thin typed protocol adapter and add a contract witness"))

;;; Boundary:
;;; - Details packet is the agent repair contract for adapter quality.
;;; - Keep fields evidence-shaped so the model can repair without reading policy code.
;;; - Do not inline source snippets.
;;; - Parser facts and guide commands own follow-up.
;; : (-> ProjectIndex DependencyAdapterQualityFact MissingEvidence Json )
(def (dependency-protocol-adapter-details index fact missing)
  (dependency-adapter-profile-details
   (dependency-adapter-standard-profile
    +dependency-adapter-fact-command+
    +dependency-adapter-repair-code-command+)
   fact
   missing
   (dependency-adapter-generic-contract-witness-exists? index fact)
   (or (dependency-adapter-contract-witness-kind index fact) "missing")))

;;; Contract witness detection stays project-level because tests usually live
;;; outside the adapter owner. The predicate still uses parser-owned calls.
;; : (-> ProjectIndex DependencyAdapterQualityFact Boolean )
(def (dependency-adapter-contract-witness-exists? index fact)
  (and (dependency-adapter-contract-witness-kind index fact) #t))

;; : (-> ProjectIndex DependencyAdapterQualityFact Boolean )
(def (dependency-adapter-generic-contract-witness-exists? index fact)
  (equal? (dependency-adapter-contract-witness-kind index fact)
          "generic-contract-test"))

;;; Boundary:
;;; - Generic witnesses live in test owners, but package-level fast self-apply
;;;   can intentionally exclude tests to avoid scenario/fixture noise.
;;; - When tests are excluded by parsed package policy and absent from the
;;;   current index, R017 still enforces local adapter quality but does not
;;;   require invisible project-level witness evidence.
;; : (-> ProjectIndex Boolean )
(def (dependency-adapter-generic-contract-witness-required? index)
  (or (project-index-has-test-owner? index)
      (project-index-test-owner-scan-enabled? index)))

;; : (-> ProjectIndex Boolean )
(def (project-index-test-owner-scan-enabled? index)
  (let* ((package (project-index-package index))
         (policy (and package
                      (project-package-test-directory-policy package))))
    (or (not policy)
        (pair? (test-directory-policy-allowed-directories policy)))))

;;; Index witness scan:
;;; - `ormap` expresses the existential query over parser-owned files.
;;; - The lambda keeps path classification delegated to test-owner-path?.
;;; - A hand-written loop would hide the "any visible test owner" invariant.
;; : (-> ProjectIndex Boolean )
(def (project-index-has-test-owner? index)
  (ormap (lambda (file)
           (test-owner-path? (source-file-path file)))
         (project-index-files index)))

;;; Boundary:
;;; - Contract witness classification is project-wide.
;;; - Tests often live outside the adapter owner.
;;; - The first matching test owner is enough for this policy warning.
;;; - Richer witness ranking belongs to ASP evidence graph consumers.
;; : (-> ProjectIndex DependencyAdapterQualityFact WitnessKind )
(def (dependency-adapter-contract-witness-kind index fact)
  (ormap (cut dependency-adapter-contract-witness-file? fact <>)
         (project-index-files index)))

;; : (-> DependencyAdapterQualityFact SourceFile WitnessKind )
(def (dependency-adapter-contract-witness-file? fact file)
  (and (test-owner-path? (source-file-path file))
       (source-file-references-adapter? file
                                        (dependency-adapter-quality-fact-name fact))
       (source-file-contract-witness-kind file)))

;; : (-> Path Boolean )
(def (test-owner-path? path)
  (and path
       (or (string-prefix? "t/" path)
           (string-contains path "/t/"))))

;;; Boundary:
;;; - Adapter witness lookup is parser evidence, not raw text matching.
;;; - POO type descriptors are often passed as arguments to generic tests or
;;;   bound as local fixtures instead of called as constructors.
;;; - Keep the exact-callee path as the strongest witness, but accept parser
;;;   argument and binding facts so R017 does not force fake adapter calls.
;; : (-> SourceFile AdapterName Boolean )
(def (source-file-references-adapter? file adapter-name)
  (or (source-file-calls-adapter? file adapter-name)
      (source-file-call-mentions-adapter? file adapter-name)
      (source-file-binding-mentions-adapter? file adapter-name)))

;;; Exact callee matches are the strongest adapter reference signal: a single
;;; parser-owned ormap proves at least one call site invokes the descriptor
;;; directly without scanning source text.
;; : (-> SourceFile AdapterName Boolean )
(def (source-file-calls-adapter? file adapter-name)
  (ormap (lambda (call)
           (equal? (call-fact-callee call) adapter-name))
         (source-file-calls file)))

;;; Data-flow transform: project call facts are projected to their argument
;;; lists, then ormap encodes the existential "any call mentions adapter"
;;; query.  The one-argument lambda mirrors the call fact stream shape, so this
;;; stays a parser-fact predicate instead of a hand-written source loop.
;; : (-> SourceFile AdapterName Boolean )
(def (source-file-call-mentions-adapter? file adapter-name)
  (ormap (lambda (call)
           (member adapter-name (call-fact-arguments call)))
         (source-file-calls file)))

;;; Binding mentions preserve witness evidence during fixture extraction:
;;; local adapter aliases still prove the test owner sees the adapter surface.
;; : (-> SourceFile AdapterName Boolean )
(def (source-file-binding-mentions-adapter? file adapter-name)
  (ormap (lambda (binding)
           (equal? (binding-fact-name binding) adapter-name))
         (source-file-bindings file)))

;;; Boundary:
;;; - Contract witness calls prove the adapter is exercised by project tests.
;;; - The accepted call vocabulary is small and data-owned at module scope.
;; : (-> SourceFile WitnessKind )
(def (source-file-contract-witness-kind file)
  (cond
   ((source-file-has-generic-contract-witness? file)
    "generic-contract-test")
   ((source-file-has-basic-contract-witness? file)
    "basic-test-call")
   (else #f)))

;; : (-> SourceFile Boolean )
(def (source-file-has-generic-contract-witness? file)
  (or (source-file-has-generic-contract-witness-call? file)
      (source-file-has-generic-contract-witness-definition? file)))

;;; Generic witness calls prove the adapter is exercised through reusable
;;; protocol/table contract helpers rather than one-off assertions.
;; : (-> SourceFile Boolean )
(def (source-file-has-generic-contract-witness-call? file)
  (source-file-has-any-contract-witness-call?
   file
   +dependency-adapter-generic-contract-witness-callees+))

;;; Generic witness definitions catch local contract helper declarations before
;;; they are invoked, preserving project-level evidence during test refactors.
;; : (-> SourceFile Boolean )
(def (source-file-has-generic-contract-witness-definition? file)
  (source-file-has-any-contract-witness-definition?
   file
   +dependency-adapter-generic-contract-witness-callees+))

;;; Basic witnesses are weaker than generic protocol tests but still useful as
;;; diagnostic evidence when an adapter is first introduced.
;; : (-> SourceFile Boolean )
(def (source-file-has-basic-contract-witness? file)
  (or (source-file-has-basic-contract-witness-call? file)
      (source-file-has-basic-contract-witness-definition? file)))

;;; Basic witness calls keep the fallback path parser-owned instead of letting
;;; arbitrary test text satisfy R017.
;; : (-> SourceFile Boolean )
(def (source-file-has-basic-contract-witness-call? file)
  (source-file-has-any-contract-witness-call?
   file
   +dependency-adapter-contract-witness-callees+))

;;; Basic witness definitions support test helper extraction while preserving
;;; the weaker witness kind until a generic contract helper is present.
;; : (-> SourceFile Boolean )
(def (source-file-has-basic-contract-witness-definition? file)
  (source-file-has-any-contract-witness-definition?
   file
   +dependency-adapter-contract-witness-callees+))

;;; Boundary:
;;; - Witness callees are a closed vocabulary owned by this policy module.
;;; - Parser-owned call facts keep this check independent of source formatting
;;;   and avoid treating comments or string literals as tests.
;; : (-> SourceFile Callees Boolean )
(def (source-file-has-any-contract-witness-call? file callees)
  (ormap (lambda (call) (member (call-fact-callee call) callees))
         (source-file-calls file)))

;;; Data-flow transform: definition facts are projected to names, then ormap
;;; checks whether any helper definition belongs to the closed contract-witness
;;; vocabulary.  The one-argument lambda preserves the definition fact arity and
;;; avoids mixing helper declarations with raw text search.
;; : (-> SourceFile Callees Boolean )
(def (source-file-has-any-contract-witness-definition? file callees)
  (ormap (lambda (definition) (member (definition-name definition) callees))
         (source-file-definitions file)))
