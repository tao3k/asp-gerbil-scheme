;;; -*- Gerbil -*-
;;; Shared fixtures for policy test suites.

(import :gerbil/gambit
        :std/misc/process
        (only-in :std/srfi/13 string-prefix? string-tokenize)
        (only-in :asp-gerbil-scheme/src/constants +language-id+ +provider-id+)
        (only-in :asp-gerbil-scheme/src/parser/facade
                 collect-project
                 collect-source-scope
                 project-definitions
                 project-index-files)
        (only-in :asp-gerbil-scheme/src/policy/core run-policy-checks)
        (only-in :asp-gerbil-scheme/src/policy/facade
                 agent-repair-report-json
                 agent-repair-summary-parts
                 finding-agent-repair-json
                 finding-agent-repair-parts
                 finding-guide-detail-parts)
        (only-in :asp-gerbil-scheme/src/protocol/json write-json-line)
        (only-in :asp-gerbil-scheme/src/types/core type-status)
        :asp-gerbil-scheme/src/types/facade)
(export filter-rule
        json-finding-by-rule
        policy-check-output
        write-policy-project
        write-owner-entry-policy-project
        write-facade-policy-project
        write-bin-entrypoint-project
        write-test-directory-layout-project
        write-vague-definition-project
        write-top-level-executable-project
        write-search-fast-entrypoint-project
        write-ffi-declare-project
        write-poo-declarative-project
        write-functional-idiom-project
        write-functional-idiom-positive-project
        write-functional-idiom-calibrated-project
        write-functional-idiom-caller-scope-project
        write-functional-idiom-reader-project
        write-controlled-branch-shape-project
        write-controlled-branch-loop-shape-project
        write-controlled-branch-conditional-dispatch-project
        write-predicate-family-combinator-project
        write-projection-burst-project
        write-dependency-protocol-adapter-project
        write-dependency-protocol-adapter-argument-witness-project
        write-dependency-manual-object-adapter-project
        write-check-changed-project
        initialize-git-fixture
        run-git
        reset-fixture-root
        write-functional-idiom-control-context-project
        write-macro-runtime-source-project
        write-protocol-evidence-project
        ensure-dir
        write-text
        delete-file-if-exists
        write-large-policy-source
        write-large-policy-test
        write-padded-policy-test
        write-ledger-padded-policy-test
        write-complex-policy-test)
;; : (-> RuleId (List TypeFinding) FilterRule )
(def (filter-rule rule-id findings)
  (filter (lambda (finding)
            (equal? (type-finding-rule-id finding) rule-id))
          findings))
;; : (-> (List TypeFinding) RuleId Json )
(def (json-finding-by-rule findings rule-id)
  (cond
   ((null? findings) #f)
   ((equal? (hash-get (car findings) "ruleId") rule-id) (car findings))
   (else (json-finding-by-rule (cdr findings) rule-id))))
;; : (-> (List TypeFinding) CheckOutput )
(def (policy-check-output args)
  (let* ((root (policy-check-root args))
         (scope (policy-check-scope args))
         (changed-paths (if (equal? scope "changed")
                          (policy-check-changed-paths root)
                          []))
         (json? (or (member "--json" args)
                    (member "--profile-json" args)))
         (index (if (equal? scope "changed")
                  (collect-source-scope root changed-paths)
                  (collect-project root)))
         (findings (run-policy-checks index))
         (status (type-status findings))
         (report
          (hash (schemaId "agent.semantic-protocols.asp-gerbil-scheme-report")
                (schemaVersion "1")
                (languageId +language-id+)
                (providerId +provider-id+)
                (status status)
                (scope scope)
                (changedPaths changed-paths)
                (files (length (project-index-files index)))
                (definitions (length (project-definitions index)))
                (agentRepair (agent-repair-report-json findings))
                (findings (map policy-finding-json findings))))
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (if json?
                  (write-json-line report)
                  (policy-check-display-report report findings)))))))
    (cons (if (equal? status "pass") 0 1) output)))

;; : (-> TypeFinding Json )
(def (policy-finding-json finding)
  (hash (ruleId (type-finding-rule-id finding))
        (severity (type-finding-severity finding))
        (path (type-finding-path finding))
        (selector (type-finding-selector finding))
        (message (type-finding-message finding))
        (agentRepair (finding-agent-repair-json finding))
        (details (or (type-finding-details finding) (hash)))))

;; : (-> PolicyReport (List TypeFinding) Void )
(def (policy-check-display-report report findings)
  (displayln "[gerbil-policy] status=" (hash-get report 'status)
             " scope=" (hash-get report 'scope)
             " files=" (hash-get report 'files)
             " definitions=" (hash-get report 'definitions)
             " findings=" (length findings))
  (policy-check-display-parts-line "|agent-repair-info"
                                   (agent-repair-summary-parts findings))
  (for-each policy-check-display-finding findings))

;; : (-> TypeFinding Void )
(def (policy-check-display-finding finding)
  (displayln "|finding rule=" (type-finding-rule-id finding)
             " severity=" (type-finding-severity finding)
             " path=" (type-finding-path finding)
             " selector=" (or (type-finding-selector finding) "")
             " message=" (type-finding-message finding))
  (policy-check-display-parts-line "|agent-repair"
                                   (finding-agent-repair-parts finding))
  (policy-check-display-parts-line "|finding-detail"
                                   (finding-guide-detail-parts finding)))

;; : (-> String (List String) Void )
(def (policy-check-display-parts-line prefix parts)
  (when (and parts (pair? parts))
    (display prefix)
    (for-each (lambda (part)
                (display " ")
                (display part))
              parts)
    (newline)))

;; : (-> (List String) String )
(def (policy-check-scope args)
  (if (or (member "--changed" args)
          (member "changed" args))
    "changed"
    "project"))

;; : (-> Root (List Path) )
(def (policy-check-changed-paths root)
  (let (output
        (run-process ["git" "status" "--porcelain" "--untracked-files=all" "--"
                      ":(glob)**/*.ss"
                      ":(glob)**/*.scm"
                      ":(glob)**/gerbil.pkg"
                      "gerbil.pkg"]
                     directory: root
                     stderr-redirection: #t))
    (policy-check-status-paths output)))

;; : (-> String (List Path) )
(def (policy-check-status-paths output)
  (let loop ((tokens (string-tokenize output)) (paths []))
    (match tokens
      ([] (reverse paths))
      ([_status path . rest]
       (loop rest (cons path paths)))
      ([_] (reverse paths)))))

;; : (-> (List String) Root )
(def (policy-check-root args)
  (or (policy-check-option "--workspace" args)
      (let (positionals (policy-check-positionals args))
        (if (pair? positionals)
          (car (reverse positionals))
          "."))))

;; : (-> String (List String) MaybeString )
(def (policy-check-option name args)
  (cond
   ((null? args) #f)
   ((equal? (car args) name)
    (and (pair? (cdr args)) (cadr args)))
   (else
    (policy-check-option name (cdr args)))))

;; : (-> (List String) (List String) )
(def (policy-check-positionals args)
  (let loop ((rest args) (out []) (skip-next? #f))
    (cond
     ((null? rest)
      (reverse out))
     (skip-next?
      (loop (cdr rest) out #f))
     ((member (car rest) '("--workspace" "--whitelist"))
      (loop (cdr rest) out #t))
     ((string-prefix? "-" (car rest))
      (loop (cdr rest) out #f))
     (else
      (loop (cdr rest) (cons (car rest) out) #f)))))
;; : (-> String FacadeName FacadeSource CoreSource Unit )
(def (write-policy-project root facade-name facade-source core-source)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/" facade-name))
         (facade-path (string-append src "/" facade-name ".ss"))
         (owner-entry-path (string-append owner "/" facade-name ".ss"))
         (core-path (string-append owner "/core.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (delete-file-if-exists owner-entry-path)
    (write-text facade-path facade-source)
    (write-text core-path core-source)))
;; : (-> String OwnerName FacadeSource CoreSource Unit )
(def (write-owner-entry-policy-project root owner-name facade-source core-source)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/" owner-name))
         (sibling-path (string-append src "/" owner-name ".ss"))
         (facade-entry-path (string-append owner "/facade.ss"))
         (facade-path (string-append owner "/" owner-name ".ss"))
         (core-path (string-append owner "/core.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (delete-file-if-exists sibling-path)
    (delete-file-if-exists facade-entry-path)
    (write-text facade-path facade-source)
    (write-text core-path core-source)))
;; : (-> String OwnerName FacadeSource CoreSource Unit )
(def (write-facade-policy-project root owner-name facade-source core-source)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/" owner-name))
         (sibling-path (string-append src "/" owner-name ".ss"))
         (repeated-entry-path (string-append owner "/" owner-name ".ss"))
         (facade-path (string-append owner "/facade.ss"))
         (core-path (string-append owner "/core.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (delete-file-if-exists sibling-path)
    (delete-file-if-exists repeated-entry-path)
    (write-text facade-path facade-source)
    (write-text core-path core-source)))
;; : (-> String Source Unit )
(def (write-bin-entrypoint-project root source)
  (let* ((bin (string-append root "/bin"))
         (entrypoint-path (string-append bin "/run.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir bin)
    (write-text entrypoint-path source)))
;; : (-> String MaybePackageSource Unit )
(def (write-test-directory-layout-project root . maybe-package-source)
  (let ((retired-test (string-append root "/test"))
        (retired-tests (string-append root "/tests"))
        (native-test (string-append root "/t"))
        (package-path (string-append root "/gerbil.pkg")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir retired-test)
    (ensure-dir retired-tests)
    (ensure-dir native-test)
    (if (pair? maybe-package-source)
      (write-text package-path (car maybe-package-source))
      (delete-file-if-exists package-path))
    (write-text (string-append retired-test "/bad-test.ss")
                ";;; -*- Gerbil -*-\n(import :std/test)\n(def bad-test (test-suite \"bad\"))\n")
    (write-text (string-append retired-tests "/bad-tests-test.ss")
                ";;; -*- Gerbil -*-\n(import :std/test)\n(def bad-tests-test (test-suite \"bad tests\"))\n")
    (write-text (string-append native-test "/good-test.ss")
                ";;; -*- Gerbil -*-\n(import :std/test)\n(def good-test (test-suite \"good\"))\n")))
;; : (-> String Unit )
(def (write-vague-definition-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(def (process order) order)\n(def (order-total order) order)\n")))
;; : (-> String Unit )
(def (write-top-level-executable-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(import :std/misc/ports)\n(displayln \"bad\")\n(def (named) #t)\n")))
;; : (-> String Unit )
(def (write-search-fast-entrypoint-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/search-fast")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text
     (string-append owner "/gerbil-scheme-search-example.ss")
     ";;; -*- Gerbil -*-\n(import :gerbil/gambit)\n(export main)\n(def (main . args) 0)\n(exit (apply main (cdr (command-line))))\n")))
;; : (-> String Unit )
(def (write-ffi-declare-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/ffi")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(declare\n  (block)\n  (standard-bindings))\n(def (named) #t)\n")))
;; : (-> String Unit )
(def (write-poo-declarative-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/poo")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text
     (string-append owner "/core.ss")
     ";;; -*- Gerbil -*-\n(import :clan/poo/object)\n(.def +sample-pattern+\n  selectors:\n      [(hash (role \"selector\")\n             (symbol \"defclass\"))]\n  qualitySignals: [\"source-backed\"])\n(def (named) #t)\n")))
;; : (-> String String )
(def (write-functional-idiom-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export total)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export total)\n(def (total xs)\n  (let loop ((rest xs) (acc 0))\n    (if (null? rest) acc (loop (cdr rest) (+ acc (car rest))))))\n")))
;; : (-> String String )
(def (write-functional-idiom-positive-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export total)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import (only-in :clan/base !> compose curry fun lambda-match))\n(export total total+fee classify-order)\n;; total\n;;   : (-> (List Number) Number)\n;;   | doc m%\n;;       `total xs` sums order totals with a pure fold.\n;;     %\n(def (total xs)\n  (foldl + 0 xs))\n;; total+fee\n;;   : (-> Number (List Number) Number)\n;;   | doc m%\n;;       `total+fee fee xs` composes the base total with a fee transform.\n;;     %\n(def (total+fee fee xs)\n  (!> xs total (curry + fee)))\n;; classify-order\n;;   : (-> Order Symbol)\n;;   | type Order = HashTable\n;;   | doc m%\n;;       `classify-order order` keeps local destructuring in a lambda-match helper.\n;;     %\n(def classify-order\n  (fun (classify order)\n    ((lambda-match\n       ((hash ('state \"paid\")) 'paid)\n       (_ 'open))\n     order)))\n")))
;; : (-> String String )
(def (write-functional-idiom-calibrated-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade exports calibrated repair targets.\n;;; Keep public names aligned with the core combinator helpers.\n(export total total+fee classify-order)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n;;; Orders core owns pure order-total combinators.\n;;; Invariant: exported helpers stay expression-level and parser-readable.\n(package: sample/orders)\n(import (only-in :clan/base !> compose curry fun lambda-match))\n(export total total+fee classify-order)\n;;; Boundary:\n;;; - total is the reduction boundary for order amounts.\n;;; - Keep accumulator state inside fold, not a handwritten loop.\n;; total\n;;   : (-> (List Number) Number)\n;;   | doc m%\n;;       `total xs` sums order totals with a pure fold.\n;;     %\n(def (total xs)\n  (foldl + 0 xs))\n;;; Boundary:\n;;; - total+fee specializes total with a fee transform.\n;;; - Keep the pipeline visible as reusable composition evidence.\n;; total+fee\n;;   : (-> Number (List Number) Number)\n;;   | doc m%\n;;       `total+fee fee xs` composes the base total with a fee transform.\n;;     %\n(def (total+fee fee xs)\n  (!> xs total (curry + fee)))\n;;; Boundary:\n;;; - classify-order owns local destructuring for order state.\n;;; - Keep lambda-match isolated so callers see one named classifier.\n;; classify-order\n;;   : (-> Order Symbol)\n;;   | type Order = HashTable\n;;   | doc m%\n;;       `classify-order order` keeps local destructuring in a lambda-match helper.\n;;     %\n(def classify-order\n  (fun (classify order)\n    ((lambda-match\n       ((hash ('state \"paid\")) 'paid)\n       (_ 'open))\n     order)))\n")))
;; : (-> String String )
(def (write-functional-idiom-caller-scope-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export total manual-total)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export total manual-total)\n(def (total xs)\n  (for/fold ((acc 0)) ((x xs)) (+ acc x)))\n(def (manual-total xs)\n  (let loop ((rest xs) (acc 0))\n    (if (null? rest) acc (loop (cdr rest) (+ acc (car rest))))))\n")))
;; : (-> String String )
(def (write-functional-idiom-reader-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export read-values)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :std/misc/ports)\n(export read-values)\n(def (read-values port)\n  (let loop ((out '()))\n    (let (line (read-line port))\n      (if (eof-object? line) (reverse out) (loop (cons line out))))))\n")))
;; : (-> String Unit )
(def (write-controlled-branch-shape-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export decode-order)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export decode-order)\n(def (decode-order event)\n  (match event\n    (['created id] id)\n    (else #f))\n  (match event\n    (['cancelled id] id)\n    (else #f)))\n")))
;; : (-> String Unit )
(def (write-controlled-branch-loop-shape-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export select-orders)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export select-orders)\n(def (select-orders facts state)\n  (match state\n    ([seen out remaining]\n     (let lp ((rest facts) (seen seen) (out out) (remaining remaining))\n       (cond\n        ((or (null? rest) (<= remaining 0))\n         [seen out remaining])\n        (else\n         (lp (cdr rest) seen out remaining)))))))\n")))
;; : (-> String Unit )
(def (write-controlled-branch-conditional-dispatch-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export dispatch-order)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export dispatch-order)\n(def (dispatch-order command args)\n  (let (fast-result\n        (and (equal? command \"search\")\n             (try-fast-search args)))\n    (if fast-result\n      fast-result\n      (let (binary-name (command-binary-name command))\n        (if (known-command? command)\n          (if binary-name\n            (let (binary (sibling-binary-path binary-name))\n              (if (file-exists? binary)\n                (run-binary binary args)\n                (run-source command args)))\n            (run-source command args))\n          (usage-error))))))\n")))
;; : (-> String Unit )
(def (write-predicate-family-combinator-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n;;; Predicate boundary:\n;;; - Keep duplicated role extraction visible for predicate-family policy tests.\n;; : (-> CreatedEventFact Boolean)\n(def (created-event? fact)\n  (let (fields (hash-get fact 'fields))\n    (and fields (equal? (field-string fields 'role) \"created\"))))\n;;; Predicate boundary:\n;;; - Keep the accepted role set inline so repeated field access remains detectable.\n;; : (-> PaymentEventFact Boolean)\n(def (paid-event? fact)\n  (let (fields (hash-get fact 'fields))\n    (and fields (member (field-string fields 'role) '(\"paid\" \"settled\")))))\n;;; Predicate boundary:\n;;; - Keep cancellation as a single-purpose predicate for family grouping evidence.\n;; : (-> CancelledEventFact Boolean)\n(def (cancelled-event? fact)\n  (let (fields (hash-get fact 'fields))\n    (and fields (equal? (field-string fields 'role) \"cancelled\"))))\n")))
;; : (-> String Unit )
(def (write-projection-burst-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append root "/gerbil.pkg")
                "(package: sample/orders)\n")
    (write-text
     (string-append owner "/core.ss")
     ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; : (-> OrderFact String)\n(def (emit-order-line order)\n  (displayln\n   (string-append\n    \"id=\" (hash-get order 'id)\n    \" state=\" (hash-get order 'state)\n    \" total=\" (hash-get order 'total)\n    \" currency=\" (hash-get order 'currency)\n    \" id2=\" (hash-get order 'id)\n    \" state2=\" (hash-get order 'state)))\n  (displayln\n   (string-append\n    \"total2=\" (hash-get order 'total)\n    \" currency2=\" (hash-get order 'currency)\n    \" id3=\" (hash-get order 'id)\n    \" state3=\" (hash-get order 'state)\n    \" total3=\" (hash-get order 'total)\n    \" currency3=\" (hash-get order 'currency))))\n")))
;; : (-> String Complete Witness Unit )
(def (write-dependency-protocol-adapter-project root complete? witness?)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders"))
         (test-dir (string-append root "/t")))
    (reset-fixture-root root)
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (ensure-dir test-dir)
    (write-text (string-append root "/gerbil.pkg")
                "(package: sample/orders\n  depend: (\"git.cons.io/mighty-gerbils/gerbil-poo\"))\n")
    (write-text (string-append owner "/dict.ss")
                (string-append
                 ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import\n"
                 "  (only-in :clan/pure/dict/orderdict\n"
                 "           orderdict-empty? orderdict-ref orderdict-put orderdict-remove\n"
                 "           orderdict-foldl orderdict-foldr orderdict->list\n"
                 "           list->orderdict orderdict=?)\n"
                 "  (only-in :clan/poo/mop define-type Any raise-type-error)\n"
                 "  (only-in ./table methods.table))\n"
                 "(define-type (OrderDict. @ [methods.table] Value)\n"
                 "  Key: String\n"
                 "  Value: Any\n"
                 (if complete?
                   "  .validate: => (lambda (super) (lambda (x) (super x)))\n  .empty: orderdict-empty?\n  .ref: orderdict-ref\n  .acons: (lambda (k v d) (orderdict-put d k v))\n  .remove: (lambda (d k) (orderdict-remove d k))\n  .foldl: (lambda (f seed d) (orderdict-foldl f seed d))\n  .foldr: (lambda (f seed d) (orderdict-foldr f seed d))\n  .<-list: list->orderdict\n  .list<-: orderdict->list\n  .sexp<-: (lambda (x) `(list->orderdict ,(orderdict->list x)))\n  .=?: (lambda (a b) (orderdict=? a b)))\n"
                   "  .empty: orderdict-empty?\n  .ref: orderdict-ref\n  .acons: (lambda (k v d) (orderdict-put d k v)))\n")))
    (if witness?
      (write-text (string-append test-dir "/dict-test.ss")
                  ";;; -*- Gerbil -*-\n(import :std/test ../src/orders/dict)\n(def (table-contract-tests adapter) adapter)\n(def order-dict-test\n  (test-suite \"order dict\"\n    (test-case \"adapter contract witness\"\n      (check (table-contract-tests (OrderDict. String)) => (OrderDict. String)))))\n")
      (delete-file-if-exists (string-append test-dir "/dict-test.ss")))))
;; : (-> String Unit )
(def (write-dependency-protocol-adapter-argument-witness-project root)
  (write-dependency-protocol-adapter-project root #t #f)
  (let (test-dir (string-append root "/t"))
    (write-text (string-append test-dir "/dict-test.ss")
                ";;; -*- Gerbil -*-\n(import :std/test ../src/orders/dict)\n(def order-dict-adapter OrderDict.)\n(def (table-contract-tests adapter sample) adapter)\n(def order-dict-test\n  (test-suite \"order dict\"\n    (test-case \"adapter contract witness\"\n      (check (table-contract-tests OrderDict. \"sample\") => OrderDict.))))\n")))
;; : (-> String Unit )
(def (write-dependency-manual-object-adapter-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders"))
         (test-dir (string-append root "/t")))
    (reset-fixture-root root)
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (ensure-dir test-dir)
    (write-text (string-append root "/gerbil.pkg")
                "(package: sample/orders\n  depend: (\"git.cons.io/mighty-gerbils/gerbil-poo\"))\n")
    (write-text (string-append owner "/dict.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import\n  (only-in :clan/pure/dict/orderdict\n           orderdict-empty? orderdict-ref orderdict-put orderdict-remove\n           orderdict-foldl orderdict-foldr orderdict->list\n           list->orderdict orderdict=?)\n  (only-in :clan/poo/mop define-type Any raise-type-error)\n  (only-in ./table methods.table))\n(define-type (OrderDict. @ [methods.table] Value)\n  Key: String\n  Value: Any\n  .validate: => (lambda (super) (lambda (x) (super x)))\n  .empty: orderdict-empty?\n  .ref: (lambda (d k) (hash-get (hash) k))\n  .acons: (lambda (k v d) (orderdict-put d k v))\n  .remove: (lambda (d k) d)\n  .foldl: (lambda (f seed d) seed)\n  .foldr: (lambda (f seed d) seed)\n  .<-list: list->orderdict\n  .list<-: orderdict->list\n  .sexp<-: (lambda (x) `(list->orderdict ,(orderdict->list x)))\n  .=?: (lambda (a b) (orderdict=? a b)))\n")
    (write-text (string-append test-dir "/dict-test.ss")
                ";;; -*- Gerbil -*-\n(import :std/test ../src/orders/dict)\n(def (table-contract-tests adapter) adapter)\n(def order-dict-test\n  (test-suite \"order dict\"\n    (test-case \"adapter contract witness\"\n      (check (table-contract-tests (OrderDict. String)) => (OrderDict. String)))))\n")))
;; : (-> String Unit )
(def (write-check-changed-project root)
  (let* ((src (string-append root "/src"))
         (changed (string-append src "/changed"))
         (stable (string-append src "/stable")))
    (reset-fixture-root root)
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir changed)
    (ensure-dir stable)
    (write-text (string-append changed "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/changed)\n(def changed-value 1)\n")
    (write-text (string-append stable "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/stable)\n(def stable-value 1)\n")))
;; : (-> String InitializeGitFixture )
(def (initialize-git-fixture root)
  (run-git root ["init"])
  (run-git root ["config" "user.email" "gerbil-harness@example.invalid"])
  (run-git root ["config" "user.name" "Gerbil Harness Test"])
  (run-git root ["add" "."])
  (run-git root ["commit" "-m" "baseline"]))
;; : (-> String (List String) Unit )
(def (run-git root args)
  (void
   (run-process (cons "git" args)
                directory: root
                stderr-redirection: #t)))
;; : (-> String ResetFixtureRoot )
(def (reset-fixture-root root)
  (when (file-exists? root)
    (void
     (run-process ["rm" "-rf" root]
                  stderr-redirection: #t))))
;; : (-> String String )
(def (write-functional-idiom-control-context-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export drain)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export drain)\n(def (drain xs)\n  (let/cc stop\n    (let loop ((rest xs))\n      (if (null? rest) (stop #f) (loop (cdr rest)))))\n  (try (void) (finally (void))))\n")))
;; : (-> String Allowed Unit )
(def (write-macro-runtime-source-project root allowed?)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/macros")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (if allowed?
      (write-text (string-append root "/gerbil.pkg")
                  "(package: sample/macros\n  policy: ((macro-governance explanation: \"Macro transformer edits are allowed only with runtime-source and expansion evidence.\" witnesses: ((\"with-order\" \"src/macros/use.ss\")))))\n")
      (delete-file-if-exists (string-append root "/gerbil.pkg")))
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/macros)\n(defsyntax (with-order stx)\n  #'(void))\n")
    (write-text (string-append owner "/use.ss")
                ";;; -*- Gerbil -*-\n(package: sample/macros)\n(import ./core)\n(with-order)\n")))
;; : (-> String Declared String )
(def (write-protocol-evidence-project root declared?)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/protocol.ss")
                (string-append
                 ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :clan/poo/protocol)\n"
                 (if declared? "(defprotocol <Renderable>)\n" "")
                 "(defgeneric :render)\n"
                 "(defmethod (:render (value <Renderable>)) value)\n"))))
;; : (-> String EnsureDir )
(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))
;; : (-> String SourceLine Unit )
(def (write-text path text)
  (delete-file-if-exists path)
  (call-with-output-file path
    (lambda (port) (display text port))))
;; : (-> String DeleteFileIfExists )
(def (delete-file-if-exists path)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path))))
;; write-large-policy-source
;;   : (-> String OwnerName Unit )
;;   | doc m%
;;       `write-large-policy-source root owner-name` creates a generated
;;       policy source owner under `root/src` for large-file policy fixtures.
;;
;;       # Examples
;;       ```scheme
;;       (write-large-policy-source ".run/policy" "orders")
;;       ;; => writes .run/policy/src/orders/core.ss
;;       ```
;;     %
(def (write-large-policy-source root owner-name)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/" owner-name))
         (source-path (string-append owner "/core.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (with-catch
     (lambda (_) #f)
     (lambda () (delete-file source-path)))
    (call-with-output-file source-path
      (lambda (port)
        (display ";;; -*- Gerbil -*-\n;;; Large source leaf.\n" port)
        (let lp ((index 0))
          (when (fx< index 45)
            (display "(def value" port)
            (display index port)
            (display " " port)
            (display index port)
            (display ")\n" port)
            (lp (fx1+ index))))
        (let lp ((index 0))
          (when (fx< index 610)
            (display ";; padding\n" port)
            (lp (fx1+ index))))))))
;; : (-> String OwnerName Unit )
(def (write-large-policy-test root owner-name)
  (write-padded-policy-test root owner-name 650))
;; write-padded-policy-test
;;   : (-> String OwnerName PaddingLineCount Unit )
;;   | doc m%
;;       `write-padded-policy-test root owner-name padding-line-count` creates
;;       a generated test owner with replay padding for policy-size fixtures.
;;
;;       # Examples
;;       ```scheme
;;       (write-padded-policy-test ".run/policy" "orders" 650)
;;       ;; => writes .run/policy/t/orders-test.ss
;;       ```
;;     %
(def (write-padded-policy-test root owner-name padding-line-count)
  (let* ((test-dir (string-append root "/t"))
         (source-path (string-append test-dir "/" owner-name "-test.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir test-dir)
    (with-catch
     (lambda (_) #f)
     (lambda () (delete-file source-path)))
    (call-with-output-file source-path
      (lambda (port)
        (display ";;; -*- Gerbil -*-\n(import :std/test)\n" port)
        (display "(def " port)
        (display owner-name port)
        (display "-test (test-suite \"" port)
        (display owner-name port)
        (display "\"))\n" port)
        (let lp ((index 0))
          (when (fx< index padding-line-count)
            (display ";; generated replay padding\n" port)
            (lp (fx1+ index))))))))
;; write-ledger-padded-policy-test
;;   : (-> String OwnerName PaddingLineCount Unit )
;;   | doc m%
;;       `write-ledger-padded-policy-test root owner-name padding-line-count`
;;       creates a generated test owner whose first comments model an existing
;;       typed-combinator-style ledger before replay padding.
;;
;;       # Examples
;;       ```scheme
;;       (write-ledger-padded-policy-test ".run/policy" "orders" 200)
;;       ;; => writes .run/policy/t/orders-test.ss
;;       ```
;;     %
(def (write-ledger-padded-policy-test root owner-name padding-line-count)
  (let* ((test-dir (string-append root "/t"))
         (source-path (string-append test-dir "/" owner-name "-test.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir test-dir)
    (delete-file-if-exists source-path)
    (call-with-output-file source-path
      (lambda (port)
        (display ";;; -*- Gerbil -*-\n(import :std/test)\n" port)
        (display ";;; typed-combinator-style ledger\n" port)
        (let lp ((index 0))
          (when (fx< index padding-line-count)
            (display ";; generated replay padding after ledger\n" port)
            (lp (fx1+ index))))))))
;; write-complex-policy-test
;;   : (-> String OwnerName TestCaseCount Unit )
;;   | doc m%
;;       `write-complex-policy-test root owner-name test-case-count` creates a
;;       generated std/test owner with many test cases for complex policy
;;       scenario fixtures.
;;
;;       # Examples
;;       ```scheme
;;       (write-complex-policy-test ".run/policy" "orders" 12)
;;       ;; => writes .run/policy/t/orders-test.ss
;;       ```
;;     %
(def (write-complex-policy-test root owner-name test-case-count)
  (let* ((test-dir (string-append root "/t"))
         (source-path (string-append test-dir "/" owner-name "-test.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir test-dir)
    (with-catch
     (lambda (_) #f)
     (lambda () (delete-file source-path)))
    (call-with-output-file source-path
      (lambda (port)
        (display ";;; -*- Gerbil -*-\n(import :std/test)\n" port)
        (display "(def " port)
        (display owner-name port)
        (display "-test\n  (test-suite \"" port)
        (display owner-name port)
        (display "\"\n" port)
        (let lp ((index 0))
          (when (fx< index test-case-count)
            (display "    (test-case \"case-" port)
            (display index port)
            (display "\" (check " port)
            (display index port)
            (display " => " port)
            (display index port)
            (display "))\n" port)
            (lp (fx1+ index))))
        (display "    ))\n" port)))))
