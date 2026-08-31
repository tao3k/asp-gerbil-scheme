;;; -*- Gerbil -*-
;;; Comment-quality policy findings over parser-owned comment facts.
;;; The gate rejects absence, contract-only rationale, and compressed multi-clause comments while leaving wording flexible.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-support
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/srfi/1 take)
        (only-in :std/sugar cut filter filter-map hash ormap)
        :asp-gerbil-scheme/src/types/findings)

(export comment-quality-findings
        comment-quality-finding)

;;; Entry boundary: scan parser-owned comment facts independently from typed-combinator style.
;; : (-> ProjectIndex (List TypeFinding) )
(def (comment-quality-findings index)
  (filter-map (cut comment-quality-finding index <>)
              (project-index-files index)))

;;; Finding gate: only required weak or absent comment facts become warnings.
;; : (-> ProjectIndex SourceFile TypeFinding )
(def (comment-quality-finding index file)
  (and (source-file-path file)
       (comment-quality-source-file? index file)
       (let (weak-facts (file-weak-required-comment-quality-facts file))
         (and (pair? weak-facts)
              (make-type-finding
               (policy-rule-id +agent-comment-quality-rule+)
               (policy-rule-severity +agent-comment-quality-rule+)
               (source-file-path file)
               (comment-quality-message weak-facts)
               (source-file-path file)
               (comment-quality-details weak-facts))))))

;;; Repair payload separates typed contracts from engineering rationale.
;;; Labels are examples, so agents can choose concise prose or bullets when clearer.
;; : (-> (List CommentQualityFact) PolicyDetails )
(def (comment-quality-details weak-facts)
  (let ((examples (take weak-facts (min 6 (length weak-facts))))
        (targets (take weak-facts (min 12 (length weak-facts)))))
    (hash (styleGuide "engineering-comment-quality")
          (styleCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-015 --intent style")
          (factSource "native-parser")
          (evidenceSource "parser-owned commentQualityFacts.evidence")
          (profileSource "parser-owned functionQualityProfiles when available")
          (repairInstruction "write adjacent engineering comment lines when parserEvidence needs them; concise prose, bullets, or Boundary/Invariant/Intent labels are all valid")
          (repairOrder "run after grouped structural/style repairs such as typed-combinator, controlled-branch, or predicate-family combinator fixes")
          (expectedCommentPrefix ";;;")
          (commentLinePolicy "split multi-clause engineering rationale across adjacent comment lines when it improves confidence; do not squeeze rationale clauses into one semicolon-separated line")
          (typedContractBoundary "Scheme-native typed blocks describe algebraic shape only and may use adjacent multi-line contract blocks when needed")
          (expectedEngineeringComment "cover the specific responsibility, invariant, boundary, risk, or optimization exposed by parserEvidence; labels are examples, not required syntax")
          (antiPattern "comment repeats code mechanics, leaves only a type contract, or compresses multiple rationale clauses into one semicolon-separated line")
          (weakCommentCount (length weak-facts))
          (weakCommentExamples (map comment-quality-fact-summary examples))
          (commentEvidenceExamples (map comment-quality-fact-evidence examples))
          (repairTargets (map comment-quality-fact-target-name targets))
          (scope "source-runtime-key-locations"))))

;; : (-> (List CommentQualityFact) String )
(def (comment-quality-message weak-facts)
  (string-append
   (number->string (length weak-facts))
   " key comment locations need engineering comments beyond typed contracts"))

;;; Scope filter keeps generated files and vendor caches outside style repair.
;; : (-> ProjectIndex SourceFile Boolean )
(def (comment-quality-source-file? index file)
  (let (path (source-file-path file))
    (and path (index-source-runtime-file-path? index path))))

;;; Required weak facts are the hard gate for comment-quality warnings.
;;; Advisory parser evidence remains available without failing the check.
;; : (-> SourceFile (List CommentQualityFact) )
(def (file-weak-required-comment-quality-facts file)
  (filter weak-required-comment-quality-fact?
          (source-file-comment-quality-facts file)))

;;; Weakness boundary: contract-only comments are not engineering rationale for key owners.
;; : (-> CommentQualityFact Boolean )
(def (weak-required-comment-quality-fact? fact)
  (and (comment-quality-fact-required fact)
       (ormap (cut equal? (comment-quality-fact-quality fact) <>)
              '("absent" "weak"))))

;;; Summary packets give agents target, reason, and parser evidence in one bounded object.
;; : (-> CommentQualityFact Json )
(def (comment-quality-fact-summary fact)
  (hash (target (comment-quality-fact-target-name fact))
        (targetKind (comment-quality-fact-target-kind fact))
        (context (comment-quality-fact-context fact))
        (commentKind (comment-quality-fact-comment-kind fact))
        (quality (comment-quality-fact-quality fact))
        (selector (comment-quality-fact-selector fact))
        (reasons (comment-quality-fact-reasons fact))
        (parserEvidence (comment-quality-fact-evidence fact))))
