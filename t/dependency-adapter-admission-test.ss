;;; -*- Gerbil -*-
;;; Focused admission regression for validation-only POO Type specializations.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/parser/facade
        (only-in :asp-gerbil-scheme/src/policy/agent-dependency-adapter
                 dependency-protocol-adapter-findings)
        :asp-gerbil-scheme/src/types/facade)

(export dependency-adapter-admission-test)

;; : (-> Path Void )
(def (ensure-directory path)
  (unless (file-exists? path)
    (create-directory path)))

;; : (-> Path String Void )
(def (write-source path source)
  (call-with-output-file path
    (lambda (port)
      (display source port))))

;; : (-> Root Void )
(def (write-validation-type-project root)
  (let ((src (string-append root "/src"))
        (owner (string-append root "/src/types")))
    (ensure-directory ".run")
    (ensure-directory root)
    (ensure-directory src)
    (ensure-directory owner)
    (write-source
     (string-append root "/gerbil.pkg")
     "(package: sample/types\n  depend: (\"git.cons.io/mighty-gerbils/gerbil-poo\"))\n")
    (write-source
     (string-append owner "/core.ss")
     ";;; -*- Gerbil -*-\n(package: sample/types)\n(import (only-in :clan/poo/mop define-type Type. element? raise-type-error))\n(define-type (DomainType. @ Type. identity .classify)\n  .element?: (lambda (candidate) (element? Type. candidate))\n  .validate: (lambda (candidate)\n               (if (element? Type. candidate)\n                 candidate\n                 (raise-type-error @ candidate))))\n")))

;; : (-> (List TypeFinding) (List TypeFinding) )
(def (dependency-adapter-findings findings)
  (filter (lambda (finding)
            (equal? (type-finding-rule-id finding)
                    "GERBIL-SCHEME-AGENT-POLICY-017"))
          findings))

(def dependency-adapter-admission-test
  (test-suite "dependency adapter admission"
    (test-case "validation-only POO Type is not a protocol adapter"
      (let* ((root ".run/dependency-adapter-admission")
             (_ (write-validation-type-project root))
             (index (collect-project root))
             (facts (project-dependency-adapter-quality-facts index))
             (findings (dependency-adapter-findings
                        (dependency-protocol-adapter-findings index))))
        (check facts => [])
        (check findings => [])))))
