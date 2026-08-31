;;; -*- Gerbil -*-
;;; Extension search renderer for registered package capability facts.

(import :asp-gerbil-scheme/src/constants
        :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/protocol/json
        :asp-gerbil-scheme/src/support/args
        (only-in :std/srfi/13 string-contains string-join)
        (only-in :std/sugar cut ormap when))

(export emit-extension-search)
;; emit-extension-search
;;   : (-> ProjectIndex (List String) Boolean Integer)
;;   | doc m%
;;       `emit-extension-search index args json?` renders project extension
;;       facts and registered POO routes without treating registry knowledge as
;;       project activation.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-extension-search index '("gerbil-poo") #f)
;;       ;; => 0
;;       ```
;;     %
(def (emit-extension-search index args json?)
  (let* ((positionals (positional-args args))
         (query (if (pair? positionals) (string-join positionals " ") "-"))
         (matches (matching-extension-facts index positionals))
         (grade (if (null? matches) "unknown" "fact")))
    (if json?
      (write-json-line
       (hash (languageId +language-id+)
             (providerId +provider-id+)
             (namespace "extension")
             (authority "ecosystem-extension")
             (evidenceGrade grade)
             (query query)
             (matches (map extension-fact-json matches))
             (sourceRefs (registered-extension-source-refs positionals))
             (next (extension-evidence-next positionals matches))))
      (begin
        (displayln "[gerbil-search-extension] query=" query
                   " matches=" (length matches)
                   " evidenceGrade=" grade
                   " authority=ecosystem-extension")
        (for-each
         (lambda (fact)
           (displayln (extension-fact-search-line fact)))
         matches)
        (when (poo-extension-lookup-query? positionals)
          (displayln "|agentAction action=follow-next"
                     " registeredKnowledge=gerbil-poo://"
                     " notProjectActivation=true"
                     " missingLocalAction=install-package-before-repository-fallback"
                     " fallback=repository-source-after-install-check"
                     " command=\"asp gerbil-scheme "
                     (extension-evidence-next positionals matches)
                     " --view seeds\"")
          (emit-source-lookup-line (poo-source-ref #f)))
        (displayln "next=" (extension-evidence-next positionals matches))))
    0))
;; : (-> (List SearchTerm) (List SourceRef) )
(def (registered-extension-source-refs terms)
  (if (poo-extension-lookup-query? terms)
    [(poo-source-ref #f)]
    []))
;; matching-extension-facts
;;   : (-> ProjectIndex (List String) (List Fact))
;;   | doc m%
;;       `matching-extension-facts index terms` returns project extension facts
;;       first, then registered facts for known ecosystem routes.
;;
;;       # Examples
;;
;;       ```scheme
;;       (matching-extension-facts index '("gerbil-poo"))
;;       ;; => matching extension facts
;;       ```
;;     %
(def (matching-extension-facts index terms)
  (if index
    (let (facts (project-extension-facts index))
      (if (null? terms)
        facts
        (let (matches
              (filter (lambda (fact)
                        (ormap (cut extension-fact-matches-term? fact <>)
                               terms))
                      facts))
          (if (null? matches)
            (poo-registered-extension-facts terms)
            matches))))
    (poo-registered-extension-facts terms)))
;;; Boundary:
;;; - extension-fact-matches-term? owns lexical fact matching for extensions.
;;; - Keep matching on declared names, dependencies, and capabilities only.
;; : (-> ExtensionFact SearchTerm Boolean )
(def (extension-fact-matches-term? fact term)
  (or (string-contains (extension-fact-name fact) term)
      (ormap (cut string-contains <> term)
             (extension-fact-dependencies fact))
      (ormap (cut string-contains <> term)
             (extension-fact-capabilities fact))))
;; : (-> (List String) Matches String )
(def (extension-evidence-extension-name terms matches)
  (cond
   ((poo-extension-lookup-query? terms) "gerbil-poo")
   ((pair? matches) (extension-fact-name (car matches)))
   ((pair? terms) (car terms))
   (else "<extension>")))
;; : (-> (List String) String )
(def (extension-evidence-focus terms)
  (cond
   ((poo-extension-lookup-query? terms)
    (poo-registered-extension-focus terms))
   ((and (pair? terms) (pair? (cdr terms)))
    (string-join (cdr terms) " "))
   (else "<api|syntax|pattern>")))
;; : (-> (List String) Matches String )
(def (extension-evidence-next terms matches)
  (let ((extension-name (extension-evidence-extension-name terms matches))
        (focus (extension-evidence-focus terms)))
    (string-append "search pattern " extension-name " " focus)))
;;; Boundary:
;;; - emit-source-lookup-line mirrors pattern/query source lookup output.
;;; - Keep local-source-before-git visible for non-interactive agents.
;; : (-> SourceRef Unit )
(def (emit-source-lookup-line source-ref)
  (let* ((local-source (hash-get source-ref 'localSource))
         (repository-source (hash-get source-ref 'repositorySource))
         (index-hint (hash-get source-ref 'indexHint)))
    (displayln "|sourceLookup order=local-source-before-git"
               " missingLocalAction=" (hash-get index-hint 'missingLocalAction)
               " fallbackPolicy=" (hash-get index-hint 'fallbackPolicy)
               " localRootHint=" (hash-get local-source 'rootHint)
               " localPackage=" (hash-get local-source 'package)
               " localStatus=" (hash-get local-source 'status)
               " localMissingAction=" (hash-get local-source 'missingAction)
               " installHint=\"" (hash-get local-source 'installHint) "\""
               " repository=" (hash-get repository-source 'repository)
               " repositoryUrl=" (hash-get repository-source 'url)
               " indexOwner=" (hash-get index-hint 'owner)
               " indexBackend=" (hash-get index-hint 'backend)
               " indexPackageManager=" (hash-get index-hint 'packageManager))))
