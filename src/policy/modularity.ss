;;; -*- Gerbil -*-
;;; Modularity policy checks over parser-owned source-file facts.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/srfi/13
                 string-contains
                 string-empty?
                 string-prefix?
                 string-suffix?
                 string-trim)
        (only-in :std/sugar cut filter filter-map find foldl hash ormap with-catch)
        :asp-gerbil-scheme/src/types/findings)

(export run-modularity-policy
        +max-source-line-count+
        +max-test-line-count+
        +hard-max-leaf-line-count+
        +min-source-definition-count+
        +min-test-definition-count+
        +max-test-case-count+
        +max-test-definition-span+
        facade-source-file?
        facade-implementation-finding
        sibling-file-dir-owner-collision-finding
        repeated-owner-entry-finding
        bin-entrypoint-implementation-finding
        source-leaf-bloat-finding
        test-leaf-bloat-finding
        file-name-mismatch-finding)
;; Integer
(def +max-source-line-count+ 650)
;; Integer
(def +max-test-line-count+ 650)
;; Integer
(def +hard-max-leaf-line-count+ 1000)
;; Integer
(def +min-source-definition-count+ 40)
;; Integer
(def +min-test-definition-count+ 1)
;; Integer
(def +max-test-case-count+ 24)
;; Integer
(def +max-test-definition-span+ 260)
;; ConfigConstant
(def +default-test-directory+ "t")
;; Integer
(def +min-test-directory-policy-explanation-length+ 24)
;;; Boundary:
;;; - project-modularity-policy is the only package policy lookup for this rule family.
;;; - Keep root/package ownership separate from per-file policy decisions.
;; : (-> ProjectIndex PackageModularityPolicy )
(def (project-modularity-policy index)
  (and (project-index-package index)
       (project-package-modularity-policy (project-index-package index))))
;; : (-> MaybePolicy Boolean )
(def (modularity-policy-disabled? policy)
  (and policy (modularity-policy-disabled policy)))
;;; Boundary:
;;; - filter-enabled-modularity-findings applies package rule lists after detection.
;;; - Detector coverage stays project-wide even when gerbil.pkg filters output.
;; : (-> MaybePolicy (List TypeFinding) (List TypeFinding) )
(def (filter-enabled-modularity-findings policy findings)
  (if policy
    (filter (cut modularity-finding-enabled? policy <>)
            findings)
    findings))
;; : (-> Policy TypeFinding Boolean )
(def (modularity-finding-enabled? policy finding)
  (let ((rule-id (type-finding-rule-id finding))
        (enabled (modularity-policy-enabled-rules policy))
        (disabled (modularity-policy-disabled-rules policy)))
    (and (or (null? enabled) (member rule-id enabled))
         (not (member rule-id disabled)))))
;;; Boundary:
;;; - sibling-file-dir-owner-collision-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (sibling-file-dir-owner-collision-findings index)
  (filter-map
   (lambda (file)
     (let* ((path (source-file-path file))
            (owner-prefix (sibling-owner-prefix index path)))
       (and owner-prefix
            (owner-prefix-has-child-source? index owner-prefix path)
            (sibling-file-dir-owner-collision-finding file owner-prefix))))
   (project-index-files index)))
;;; Boundary:
;;; - repeated-owner-entry-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (repeated-owner-entry-findings index)
  (filter-map
   (lambda (file)
     (and (repeated-owner-entry-path? index (source-file-path file))
          (repeated-owner-entry-finding file)))
   (project-index-files index)))
;;; Boundary:
;;; - file-name-mismatch-findings uses parser-owned namespace facts.
;;; - Only explicit declarations are checked; implicit Gerbil path modules stay
;;;   owned by the filesystem and existing owner-entry rules.
;; : (-> ProjectIndex (List TypeFinding) )
(def (file-name-mismatch-findings index)
  (filter-map
   (lambda (file)
     (let ((declared-name (source-file-declared-file-name file))
           (actual-name (source-file-path-file-name file)))
       (and declared-name
            (project-gerbil-source-path? index (source-file-path file))
            (not (project-gerbil-test-path? (source-file-path file)))
            (not (equal? declared-name actual-name))
            (file-name-mismatch-finding file declared-name actual-name))))
   (project-index-files index)))
;;; Boundary:
;;; - bin-entrypoint-implementation-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (bin-entrypoint-implementation-findings index)
  (filter-map
   (lambda (file)
     (and (bin-entrypoint-source-file? file)
          (pair? (source-file-definitions file))
          (bin-entrypoint-implementation-finding file)))
   (project-index-files index)))
;;; Boundary:
;;; - facade-implementation-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (facade-implementation-findings index)
  (filter-map
   (lambda (file)
     (and (facade-source-file? index file)
          (pair? (source-file-definitions file))
          (facade-implementation-finding file)))
   (project-index-files index)))
;; : (-> ProjectIndex SourceFile Boolean )
(def (facade-source-file? index file)
  (let* ((path (source-file-path file))
         (owner-prefix (owner-entry-prefix index path)))
    (and owner-prefix
         (owner-prefix-has-child-source? index owner-prefix path))))
;;; Boundary:
;;; - owner-prefix-has-child-source? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex OwnerPrefix String Boolean )
(def (owner-prefix-has-child-source? index owner-prefix path)
  (ormap
   (lambda (candidate)
     (let (candidate-path (source-file-path candidate))
       (and (not (equal? candidate-path path))
            (project-gerbil-source-path? index candidate-path)
            (string-prefix? owner-prefix candidate-path))))
   (project-index-files index)))
;; : (-> ProjectIndex String String )
(def (sibling-owner-prefix index path)
  (and (project-gerbil-source-path? index path)
       (string-append (path-strip-extension path) "/")))
;; : (-> ProjectIndex String String )
(def (owner-entry-prefix index path)
  (and (project-gerbil-source-path? index path)
       (facade-entry-path? index path)
       (let (parent (path-directory path))
         (and (not (string-empty? parent)) parent))))
;; : (-> ProjectIndex String Boolean )
(def (facade-entry-path? index path)
  (let (parent (path-directory path))
    (and (project-gerbil-source-path? index path)
         (equal? (path-strip-directory (path-strip-extension path)) "facade")
         (not (string-empty? parent))
         (not (source-root-parent-prefix? index parent)))))
;; : (-> ProjectIndex String Boolean )
(def (repeated-owner-entry-path? index path)
  (let* ((parent (path-directory path))
         (stem (path-strip-directory (path-strip-extension path)))
         (owner (path-strip-directory (path-strip-trailing-directory-separator parent))))
    (and (not (string-empty? parent))
         (project-gerbil-source-path? index path)
         (not (source-root-parent-prefix? index parent))
         (equal? stem owner))))
;; : (-> ProjectIndex String Boolean )
(def (owner-entry-path? index path)
  (repeated-owner-entry-path? index path))
;; : (-> SourceFile MaybeFileName )
(def (source-file-declared-file-name file)
  (let (namespace (source-file-namespace file))
    (and namespace
         (not (string-empty? namespace))
         (declared-module-leaf-name namespace))))
;; : (-> Namespace FileName )
(def (declared-module-leaf-name namespace)
  (strip-leading-module-prefix (path-strip-directory namespace)))
;; : (-> FileName FileName )
(def (strip-leading-module-prefix name)
  (if (string-prefix? ":" name)
    (substring name 1 (string-length name))
    name))
;; : (-> SourceFile FileName )
(def (source-file-path-file-name file)
  (path-strip-directory
   (path-strip-extension (source-file-path file))))
;;; Boundary:
;;; - project-gerbil-source-path? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex String Boolean )
(def (project-gerbil-source-path? index path)
  (and (string-suffix? ".ss" path)
       (not (config-file-path? path))
       (ormap (lambda (root)
                (source-path-under-root? path root))
              (project-source-roots index))))
;;; Boundary:
;;; - config-file-path? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> String Boolean )
(def (config-file-path? path)
  (find (lambda (candidate) (string=? path candidate)) +config-files+))
;; : (-> ProjectIndex (List String) )
(def (project-source-roots index)
  (let* ((package (project-index-package index))
         (policy (and package
                      (project-package-source-scope-policy package)))
         (roots (and policy (source-scope-policy-roots policy))))
    (cond
     ((and roots (pair? roots)) roots)
     ((and policy (pair? (source-scope-policy-runtime-roots policy)))
      (source-scope-policy-runtime-roots policy))
     (else ["src"]))))
;; : (-> String String Boolean )
(def (source-path-under-root? path root)
  (or (equal? root ".")
      (equal? path root)
      (string-prefix? (source-root-prefix root) path)))
;;; Boundary:
;;; - source-root-parent-prefix? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex Parent Boolean )
(def (source-root-parent-prefix? index parent)
  (ormap (lambda (root)
           (equal? parent (source-root-prefix root)))
         (project-source-roots index)))
;; : (-> String String )
(def (source-root-prefix root)
  (cond
   ((equal? root ".") "")
   ((string-suffix? "/" root) root)
   (else (string-append root "/"))))
;; : (-> SourceFile Boolean )
(def (bin-entrypoint-source-file? file)
  (let (path (source-file-path file))
    (and (string-prefix? "bin/" path)
         (string-suffix? ".ss" path))))
;; : (-> SourceFile SourceFile )
(def (non-t-test-directory-source-file file)
  (let* ((path (source-file-path file))
         (directory (non-t-test-directory-name path)))
    (and directory
         (string-suffix? ".ss" path)
         directory)))
;; : (-> String NonTTestDirectoryName )
(def (non-t-test-directory-name path)
  (cond
   ((path-contains-directory? path "test") "test")
   ((path-contains-directory? path "tests") "tests")
   (else #f)))
;; : (-> String Directory Boolean )
(def (path-contains-directory? path directory)
  (or (string-prefix? (string-append directory "/") path)
      (string-contains path (string-append "/" directory "/"))))
;; : (-> SourceFile TypeFinding )
(def (facade-implementation-finding file)
  (let* ((definition (car (source-file-definitions file)))
         (selector (definition-selector definition)))
    (make-type-finding
     (policy-rule-id +modularity-facade-rule+)
     (policy-rule-severity +modularity-facade-rule+)
     (source-file-path file)
     (string-append "facade " (source-file-path file)
                    " contains implementation definitions")
     selector
     (hash (definition (definition-name definition))
           (selector selector)))))
;; : (-> SourceFile OwnerPrefix TypeFinding )
(def (sibling-file-dir-owner-collision-finding file owner-prefix)
  (make-type-finding
   (policy-rule-id +modularity-owner-collision-rule+)
   (policy-rule-severity +modularity-owner-collision-rule+)
   (source-file-path file)
   (string-append (source-file-path file)
                  " and "
                  owner-prefix
                  " share the same owner name at one filesystem level")
   (source-file-path file)
   (hash (ownerDirectory owner-prefix))))
;; : (-> SourceFile TypeFinding )
(def (repeated-owner-entry-finding file)
  (let* ((path (source-file-path file))
         (parent (path-directory path))
         (owner (path-strip-directory (path-strip-trailing-directory-separator parent))))
    (make-type-finding
     (policy-rule-id +modularity-repeated-owner-entry-rule+)
     (policy-rule-severity +modularity-repeated-owner-entry-rule+)
     path
     (string-append path
                    " repeats owner name "
                    owner
                    " inside its own directory")
     path
     (hash (owner owner)
           (replacement "facade.ss")))))
;; : (-> SourceFile DeclaredFileName ActualFileName TypeFinding )
(def (file-name-mismatch-finding file declared-name actual-name)
  (let ((namespace (source-file-namespace file))
        (path (source-file-path file)))
    (make-type-finding
     (policy-rule-id +modularity-file-name-rule+)
     (policy-rule-severity +modularity-file-name-rule+)
     path
     (string-append path
                    " declares file.name "
                    declared-name
                    " through namespace "
                    namespace
                    " but the physical file name is "
                    actual-name)
     path
     (hash (declaredFileName declared-name)
           (actualFileName actual-name)
           (declaredNamespace namespace)))))
;; : (-> SourceFile TypeFinding )
(def (bin-entrypoint-implementation-finding file)
  (let* ((definition (car (source-file-definitions file)))
         (selector (definition-selector definition)))
    (make-type-finding
     (policy-rule-id +modularity-bin-entrypoint-rule+)
     (policy-rule-severity +modularity-bin-entrypoint-rule+)
     (source-file-path file)
     (string-append "entrypoint "
                    (source-file-path file)
                    " contains implementation definition "
                    (definition-name definition))
     selector
     (hash (definition (definition-name definition))
           (selector selector)))))
;;; Boundary:
;;; - test-directory-layout-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (test-directory-layout-findings index)
  (filter-map
   (lambda (file)
     (let (actual-directory (non-t-test-directory-source-file file))
       (and actual-directory
            (not (test-directory-policy-allows? index actual-directory))
            (test-directory-layout-finding index file actual-directory))))
   (project-index-files index)))
;; : (-> ProjectIndex Directory Boolean )
(def (test-directory-policy-allows? index directory)
  (and (test-directory-policy-directory-listed? index directory)
       (test-directory-policy-explanation-clear? (project-test-directory-policy index))))
;; : (-> ProjectIndex Directory Boolean )
(def (test-directory-policy-directory-listed? index directory)
  (let (policy (project-test-directory-policy index))
    (and policy
         (member directory (test-directory-policy-allowed-directories policy)))))
;; : (-> Policy Boolean )
(def (test-directory-policy-explanation-clear? policy)
  (and policy
       (let (explanation (test-directory-policy-explanation policy))
         (and explanation
              (fx>= (string-length (string-trim explanation))
                    +min-test-directory-policy-explanation-length+)))))
;; : (-> ProjectIndex ProjectTestDirectoryPolicy )
(def (project-test-directory-policy index)
  (and (project-index-package index)
       (project-package-test-directory-policy (project-index-package index))))
;; : (-> ProjectIndex SourceFile ActualDirectory TypeFinding )
(def (test-directory-layout-finding index file actual-directory)
  (let* ((policy (project-test-directory-policy index))
         (listed? (test-directory-policy-directory-listed? index actual-directory))
         (explanation (and policy (test-directory-policy-explanation policy)))
         (reason (test-directory-policy-rejection-reason policy listed?)))
    (make-type-finding
     (policy-rule-id +modularity-test-directory-rule+)
     (policy-rule-severity +modularity-test-directory-rule+)
     (source-file-path file)
     (string-append "Gerbil unit test owner "
                    (source-file-path file)
                    " uses non-t "
                    actual-directory
                    "/ layout; use t/ unless gerbil.pkg policy explicitly allows this directory with a clear explanation ("
                    reason
                    ")")
     (source-file-path file)
     (hash (expectedDirectory +default-test-directory+)
           (actualDirectory actual-directory)
           (policyDirectoryAllowed listed?)
           (policyExplanation explanation)
           (policyExplanationMinimumChars
            +min-test-directory-policy-explanation-length+)))))
;; : (-> Policy Listed String )
(def (test-directory-policy-rejection-reason policy listed?)
  (cond
   ((not policy) "no policy override")
   ((not listed?) "directory is not allowed by policy")
   (else "policy override is missing a clear explanation")))
;;; Boundary:
;;; - source-leaf-bloat-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex MaybePolicy (List TypeFinding) )
(def (source-leaf-bloat-findings index policy)
  (let ((max-line-count (modularity-max-source-line-count policy))
        (min-definition-count (modularity-min-source-definition-count policy)))
    (filter-map
     (lambda (file)
       (let (effective-line-count (source-leaf-effective-line-count index file))
         (and (project-gerbil-source-path? index (source-file-path file))
              (not (project-gerbil-test-path? (source-file-path file)))
              (or (fx>= effective-line-count +hard-max-leaf-line-count+)
                  (and (fx>= effective-line-count max-line-count)
                       (fx>= (length (source-file-definitions file))
                             min-definition-count)))
              (source-leaf-bloat-finding
               file
               effective-line-count
               max-line-count
               min-definition-count))))
     (project-index-files index))))
;;; Boundary:
;;; - test-leaf-bloat-findings covers package-local t/ owners explicitly.
;;; - Keep it separate from runtime source bloat so agents can read the rule intent.
;; : (-> ProjectIndex MaybePolicy (List TypeFinding) )
(def (test-leaf-bloat-findings index policy)
  (let ((max-line-count (modularity-max-test-line-count policy))
        (min-definition-count (modularity-min-test-definition-count policy))
        (max-test-case-count (modularity-max-test-case-count policy))
        (max-definition-span (modularity-max-test-definition-span policy)))
    (filter-map
     (lambda (file)
       (let* ((effective-line-count (test-leaf-effective-line-count file))
              (test-case-count (test-leaf-test-case-count file))
              (definition-span (test-leaf-max-definition-span file)))
         (and (project-gerbil-test-path? (source-file-path file))
              (or (fx>= effective-line-count +hard-max-leaf-line-count+)
                  (and (fx>= effective-line-count max-line-count)
                       (fx>= (length (source-file-definitions file))
                             min-definition-count)))
              (test-leaf-bloat-finding
               file
               effective-line-count
               max-line-count
               min-definition-count
               test-case-count
               max-test-case-count
               definition-span
               max-definition-span
               policy))))
     (project-index-files index))))
;;; Boundary:
;;; - modularity-max-source-line-count resolves package thresholds.
;;; - Defaults remain provider-owned when gerbil.pkg does not opt in.
;; : (-> MaybePolicy Integer )
(def (modularity-max-source-line-count policy)
  (modularity-line-count-limit
   (and policy (modularity-policy-max-source-line-count policy))
   +max-source-line-count+))
;; : (-> MaybePolicy Integer )
(def (modularity-max-test-line-count policy)
  (modularity-line-count-limit
   (and policy (modularity-policy-max-test-line-count policy))
   +max-test-line-count+))
;; : (-> MaybeInteger Integer Integer )
(def (modularity-line-count-limit configured-count default-count)
  (let (line-count (or configured-count default-count))
    (if (fx< line-count +hard-max-leaf-line-count+)
      line-count
      +hard-max-leaf-line-count+)))
;; : (-> MaybePolicy Integer )
(def (modularity-min-source-definition-count policy)
  (or (and policy (modularity-policy-min-source-definition-count policy))
      +min-source-definition-count+))
;; : (-> MaybePolicy Integer )
(def (modularity-min-test-definition-count policy)
  (or (and policy (modularity-policy-min-test-definition-count policy))
      +min-test-definition-count+))
;; : (-> MaybePolicy Integer )
(def (modularity-max-test-case-count policy)
  (or (and policy (modularity-policy-max-test-case-count policy))
      +max-test-case-count+))
;; : (-> MaybePolicy Integer )
(def (modularity-max-test-definition-span policy)
  (or (and policy (modularity-policy-max-test-definition-span policy))
      +max-test-definition-span+))
;;; Boundary:
;;; - run-modularity-policy composes project-wide findings, then policy filters.
;;; - Do not narrow coverage by folder before package policy has been resolved.
;; : (-> ProjectIndex Integer )
(def (run-modularity-policy index)
  (let (policy (project-modularity-policy index))
    (if (modularity-policy-disabled? policy)
      '()
      (filter-enabled-modularity-findings
       policy
       (append
        (sibling-file-dir-owner-collision-findings index)
        (repeated-owner-entry-findings index)
        (file-name-mismatch-findings index)
        (bin-entrypoint-implementation-findings index)
        (facade-implementation-findings index)
        (test-directory-layout-findings index)
        (source-leaf-bloat-findings index policy)
        (test-leaf-bloat-findings index policy))))))
;; : (-> String Boolean )
(def (project-gerbil-test-path? path)
  (equal? (source-path-class path) "test"))
;;; Boundary:
;;; - source-leaf-effective-line-count composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex SourceFile Integer )
(def (source-leaf-effective-line-count index file)
  (with-catch
   (lambda (_) (source-file-line-count file))
   (lambda ()
     (typed-ledger-effective-line-count
      (read-file-lines
       (path-expand (source-file-path file)
                    (project-index-root index)))))))

;;; Test owners are modularity leaves, not typed-ledger source ledgers.
;;; Physical line count is the hard signal so large tests cannot hide below a
;;; typed-combinator-style ledger marker.
;; : (-> SourceFile Integer )
(def (test-leaf-effective-line-count file)
  (source-file-line-count file))
;;; Invariant:
;;; - typed-ledger-effective-line-count owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; : (-> (List String) Integer )
(def (typed-ledger-effective-line-count lines)
  (car
   (foldl (lambda (line state)
            (let ((count (car state))
                  (ledger? (cdr state)))
              (cond
               (ledger? state)
               ((equal? (string-trim line) ";;; typed-combinator-style ledger")
                (cons count #t))
               (else (cons (+ count 1) #f)))))
          (cons 0 #f)
          lines)))
;;; Boundary: source leaf findings expose effective lines and definitions together.
;; : (-> SourceFile EffectiveLineCount MaybeLimit MaybeLimit TypeFinding )
(def (source-leaf-bloat-finding file effective-line-count . maybe-limits)
  (let ((max-line-count (if (pair? maybe-limits)
                          (car maybe-limits)
                          +max-source-line-count+))
        (min-definition-count (if (and (pair? maybe-limits)
                                       (pair? (cdr maybe-limits)))
                                (cadr maybe-limits)
                                +min-source-definition-count+))
        (severity (if (fx>= effective-line-count +hard-max-leaf-line-count+)
                    "error"
                    (policy-rule-severity +modularity-source-leaf-rule+))))
    (make-type-finding
     (policy-rule-id +modularity-source-leaf-rule+)
     severity
     (source-file-path file)
     (string-append (source-file-path file)
                    " carries " (number->string effective-line-count)
                    " effective lines and "
                    (number->string (length (source-file-definitions file)))
                    " definitions")
     (source-file-path file)
     (hash (lineCount effective-line-count)
           (lineCountLimit max-line-count)
           (hardLineCountLimit +hard-max-leaf-line-count+)
           (physicalLineCount (source-file-line-count file))
           (definitionCount (length (source-file-definitions file)))
           (definitionCountMinimum min-definition-count)))))
;;; Boundary: test-case calls are parser facts, not raw text matches.
;; : (-> SourceFile Integer )
(def (test-leaf-test-case-count file)
  (length
   (filter (lambda (call)
             (equal? (call-fact-callee call) "test-case"))
           (source-file-calls file))))
;;; Boundary: definition span tracks the largest local body before test leaf repair.
;; : (-> SourceFile Integer )
(def (test-leaf-max-definition-span file)
  (let (spans (map definition-span (source-file-definitions file)))
    (if (null? spans) 0 (apply max spans))))
;; : (-> Definition Integer )
(def (definition-span definition)
  (+ 1 (- (definition-end definition) (definition-start definition))))
;;; Boundary: test leaf findings keep count, span, and configured policy in one payload.
;; : (-> SourceFile EffectiveLineCount LineLimit DefinitionLimit TestCaseCount TestCaseLimit DefinitionSpan DefinitionSpanLimit MaybePolicy TypeFinding )
(def (test-leaf-bloat-finding file effective-line-count max-line-count min-definition-count test-case-count max-test-case-count definition-span max-definition-span policy)
  (let (severity (if (fx>= effective-line-count +hard-max-leaf-line-count+)
                   "error"
                   (policy-rule-severity +modularity-test-leaf-rule+)))
    (make-type-finding
     (policy-rule-id +modularity-test-leaf-rule+)
     severity
     (source-file-path file)
     (string-append (source-file-path file)
                    " carries " (number->string effective-line-count)
                    " effective test lines and "
                    (number->string (length (source-file-definitions file)))
                    " definitions; parsed complexity shows "
                    (number->string test-case-count)
                    " test cases and max definition span "
                    (number->string definition-span)
                    "; split the test owner; gerbil.pkg may justify parsed complexity limits, but effective owner lines are hard-capped at "
                    (number->string +hard-max-leaf-line-count+))
     (source-file-path file)
     (hash (sourceClass (source-path-class (source-file-path file)))
           (lineCount effective-line-count)
           (lineCountLimit max-line-count)
           (hardLineCountLimit +hard-max-leaf-line-count+)
           (physicalLineCount (source-file-line-count file))
           (definitionCount (length (source-file-definitions file)))
           (definitionCountMinimum min-definition-count)
           (testCaseCount test-case-count)
           (testCaseCountLimit max-test-case-count)
           (maxDefinitionSpan definition-span)
           (maxDefinitionSpanLimit max-definition-span)
           (policyConfigPath (and policy (modularity-policy-config-path policy)))
           (policyExplanation (and policy (modularity-policy-explanation policy)))))))
