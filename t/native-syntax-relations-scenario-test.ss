;;; -*- Gerbil -*-
;;; Checked-in scenario owner for the Gerbil-native syntax relation contract.

(import :std/test
        (only-in :std/misc/list unique)
        :asp-gerbil-scheme/src/benchmark/framework
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/testing/memory-profile)

(export native-syntax-relations-scenario-test)

(declare-gxtest-memory-exception
 '((maxHeapMiB . 512)))

(def +native-syntax-scenario-root+
  "t/scenarios/parser/native-syntax-relations")
(def +native-syntax-source+ "src/macros.ss")

;; : (-> SourceFile String TopForm)
(def (native-syntax-owner-form file owner)
  (find (lambda (form)
          (equal? (syntax-ast-owner (top-form-syntax-ast form)) owner))
        (source-file-forms file)))

;; : (-> TopForm Symbol Symbol (List SyntaxRelation))
(def (native-syntax-relations form name context)
  (filter (lambda (relation)
            (and (eq? (syntax-relation-name relation) name)
                 (eq? (syntax-relation-context relation) context)))
          (syntax-ast-relations (top-form-syntax-ast form))))

;; Source identity is shared by SyntaxAst.  This key covers every field that
;; identifies one retained occurrence and detects duplicate traversal edges.
;; : (-> SyntaxAst SyntaxRelation List)
(def (native-syntax-relation-key ast relation)
  (list (syntax-ast-path ast)
        (syntax-ast-owner ast)
        (syntax-relation-kind relation)
        (syntax-relation-name relation)
        (syntax-relation-start relation)
        (syntax-relation-end relation)
        (syntax-relation-phase relation)
        (syntax-relation-context relation)
        (syntax-relation-structural-path relation)))

;; : (-> SourceFile (List List))
(def (native-syntax-relation-keys file)
  (apply append
         (map (lambda (form)
                (let (ast (top-form-syntax-ast form))
                  (map (cut native-syntax-relation-key ast <>)
                       (syntax-ast-relations ast))))
              (source-file-forms file))))

;; : (-> SourceFile (List List))
(def (native-syntax-projection file)
  (map (lambda (form)
         (map (lambda (projection)
                (list (hash-get projection 'kind)
                      (hash-get projection 'name)
                      (hash-get projection 'owner)
                      (hash-get projection 'path)
                      (hash-get projection 'start)
                      (hash-get projection 'end)
                      (hash-get projection 'phase)
                      (hash-get projection 'context)
                      (hash-get projection 'structuralPath)))
              (syntax-ast-relation-projection
               (top-form-syntax-ast form))))
       (source-file-forms file)))

(def native-syntax-relations-scenario-test
  (test-suite "native syntax relations parser scenario"
    (test-case "classifies emitted calls, phases, syntax/loc, and binders once"
      (let* ((file (parse-source-file +native-syntax-scenario-root+
                                      +native-syntax-source+))
             (again (parse-source-file +native-syntax-scenario-root+
                                       +native-syntax-source+))
             (declarative (native-syntax-owner-form file "declarative-public"))
             (procedural (native-syntax-owner-form file "procedural-public"))
             (identifier (native-syntax-owner-form file "identifier-public"))
             (quoted (native-syntax-owner-form file "quoted-only"))
             (quasi (native-syntax-owner-form file "quasi-public"))
             (located (native-syntax-owner-form file "located-public"))
             (binding (native-syntax-owner-form file "binding-public"))
             (quasi-helper (car (native-syntax-relations
                                 quasi 'emitted-helper
                                 'quasisyntax-template)))
             (quasi-compute (car (native-syntax-relations
                                  quasi 'compute 'transformer)))
             (located-source (car (native-syntax-relations
                                   located 'source-helper 'transformer)))
             (keys (native-syntax-relation-keys file)))
        (check (and declarative procedural identifier quoted quasi located binding)
               ? true)
        (check (syntax-ast-template-callees
                (top-form-syntax-ast declarative))
               => ["emitted-helper"])
        (check (syntax-ast-template-callees
                (top-form-syntax-ast procedural))
               => ["emitted-helper"])
        (check (syntax-ast-template-callees
                (top-form-syntax-ast identifier))
               => ["emitted-helper"])
        (check (syntax-ast-template-callees
                (top-form-syntax-ast quoted))
               => [])
        (check (syntax-ast-template-callees
                (top-form-syntax-ast located))
               => ["emitted-helper"])
        (check (syntax-ast-template-callees
                (top-form-syntax-ast binding))
               => ["let" "initializer-helper" "lambda" "def" "body-helper"])
        (check (syntax-relation-phase quasi-helper) => 0)
        (check (syntax-relation-phase quasi-compute) => 1)
        (check (syntax-relation-phase located-source) => 1)
        (check (member "emitted-helper"
                       (syntax-ast-template-callees
                        (top-form-syntax-ast binding)))
               => #f)
        (check (member "lambda-helper"
                       (syntax-ast-template-callees
                        (top-form-syntax-ast binding)))
               => #f)
        (check (member "definition-helper"
                       (syntax-ast-template-callees
                        (top-form-syntax-ast binding)))
               => #f)
        (check (length keys) => (length (unique keys)))
        (check (native-syntax-projection file)
               => (native-syntax-projection again))
        (check (andmap (lambda (form)
                         (equal? (syntax-ast-version
                                  (top-form-syntax-ast form))
                                 "gerbil-native-syntax-relations.v2"))
                       (source-file-forms file))
               => #t)))
    (test-case "scenario parse stays inside its benchmark contract"
      (check (benchmark-contract-valid/root? +native-syntax-scenario-root+)
             => #t)
      (let (receipt
            (benchmark-contract-run/root
             +native-syntax-scenario-root+
             (lambda ()
               (parse-source-file +native-syntax-scenario-root+
                                  +native-syntax-source+))))
        (check (benchmark-contract-receipt-pass? receipt) => #t)))))
