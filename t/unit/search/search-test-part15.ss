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
(export search-test-part-15)
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
(def search-test-part-15
  (test-suite "gerbil scheme harness search part 15"
    (test-case "pattern search exposes verified runnable witnesses"
          (let ((macro-output (search-output ["pattern" "hygienic-macro" "."]))
                (poo-output (search-output ["pattern" "poo" "object" "."]))
                (adapter-output
                 (search-output ["pattern" "poo" "rationaldict" "adapter" "."]))
                (inherited-output
                 (search-output ["pattern" "higher-order-control" "gerbil-utils" "inherited" "."])))
            (check (contains? macro-output "quality=verified") => #t)
            (check (contains? macro-output "witness=parser-and-test-backed-hygienic-macro-pattern") => #t)
            (check (contains? macro-output "missing=-") => #t)
            (check (contains? poo-output "sourceRef=package-manager-source:gxpkg:git.cons.io/mighty-gerbils/gerbil-poo:runtime-resolved") => #t)
            (check (contains? poo-output "|sourceLookup order=local-source-before-git") => #t)
            (check (contains? poo-output "missingLocalAction=install-package-before-repository-fallback") => #t)
            (check (contains? poo-output "localRootHint=~/.gerbil") => #t)
            (check (contains? poo-output "installHint=\"gxpkg install git.cons.io/mighty-gerbils/gerbil-poo\"") => #t)
            (check (contains? poo-output "repositoryUrl=https://git.cons.io/mighty-gerbils/gerbil-poo indexOwner=asp-client indexBackend=rust-sql") => #t)
            (check (contains? poo-output "selector=gerbil-poo://object.ss#defclass") => #t)
            (check (contains? poo-output "witness=dependency-backed-poo-mapping") => #t)
            (check (contains? poo-output "missing=-") => #t)
            (check-output-contains
             poo-output
             ["|selector role=thin-macro-bridge symbol=@method selector=gerbil-poo://brace.ss#@method"
              "|selector role=slot-resolution symbol=compute-precedence-list! selector=gerbil-poo://object.ss#compute-precedence-list!"
              "|selector role=io-serialization-method-family symbol=marshal selector=gerbil-poo://io.ss#marshal"
              "|form role=thin-macro-bridge symbol=@method head=defsyntax-for-match"
              "|form role=slot-resolution symbol=.all-slots head=.all-slots"
              "|qualitySignal id=thin-macro-bridge"
              "|qualitySignal id=object-slot-resolution-model"
              "|qualitySignal id=io-serialization-method-family"
              "selectorCount=11 formCount=9 failureCaseCount=7"])
            (check-output-contains
             adapter-output
             ["quality=verified"
              "|pattern id=poo-rationaldict-adapter"
              "|agentSteering dependency already owns the storage primitives"
              "selector=gerbil-poo://rationaldict.ss#RationalDict."
              "selector=gerbil-poo://rationaldict.ss#RationalSet"
              "selector=gerbil-poo-test://t/table-testing.ss#table-tests"
              "|form role=typed-protocol-adapter symbol=RationalDict. head=define-type"
              "|form role=derived-set-adapter symbol=RationalSet head=define-type"
              "|form role=minimal-protocol-surface symbol=methods.table head=define-type"
              "|form role=reusable-contract-test symbol=table-tests head=table-tests"
              "|form role=serialization-method-family symbol=methods.bytes<-marshal head=define-type"
              "|failureCase id=manual-hash-or-alist-adapter"
              "|failureCase id=copied-monolithic-contract-suite"
              "|qualitySignal id=define-type-protocol-slots"
              "|qualitySignal id=minimal-protocol-surface"
              "|qualitySignal id=reusable-contract-test"
              "|qualitySignal id=serialization-method-family"
              "|qualitySignal id=poo-prototype-object-extension"
              "selectorCount=9 formCount=7 failureCaseCount=4"
              "next=search pattern poo rationaldict adapter"])
            (check-output-contains
             inherited-output
             ["quality=verified"
              "|pattern id=gerbil-utils-higher-order-control"
              "origin=inherited"
              "via=git.cons.io/mighty-gerbils/gerbil-poo->git.cons.io/mighty-gerbils/gerbil-utils"
              "sourceRef=package-manager-source:gxpkg:git.cons.io/mighty-gerbils/gerbil-utils:runtime-resolved"
              "|sourceLookup order=local-source-before-git"
              "missingLocalAction=install-package-before-repository-fallback"
              "localRootHint=~/.gerbil localPackage=git.cons.io/mighty-gerbils/gerbil-utils"
              "installHint=\"gxpkg install git.cons.io/mighty-gerbils/gerbil-utils\""
              "|importWitness status=verified module=:clan/base"
              "minimalImport=(import (only-in :clan/base curry rcurry fold<-reduce-map compose rcompose !>))"
              "|selector role=left-curry symbol=curry selector=gerbil-utils://base.ss#curry"
              "|form role=fold-from-reduce-map symbol=fold<-reduce-map head=fold<-reduce-map"
              "|qualitySignal id=package-closure-inheritance"
              "missing=-"])
            (check (not (contains? inherited-output "pending")) => #t)))
    (test-case "agent scenario routes unknown POO usage through extension then pattern guidance"
          (let ((extension-output (search-output ["extension" "poo" "syntax" "."]))
                (pattern-output (search-output ["pattern" "how" "do" "I" "write" "poo" "class" "method" "protocol" "."])))
            (check-output-contains
             extension-output
             ["[gerbil-search-extension]"
              "|extension name=poo"
              "next=search pattern gerbil-poo syntax"])
            (check (not (contains? extension-output "|form role=")) => #t)
            (check-output-contains
             pattern-output
             ["quality=verified"
              "|agentScenario id=agent-does-not-know-gerbil-poo-object-system"
              "intent=write-gerbil-poo-object-system-without-racket-or-generic-scheme-guessing"
              "sourceRef=package-manager-source:gxpkg:git.cons.io/mighty-gerbils/gerbil-poo:runtime-resolved"
              "|sourceLookup order=local-source-before-git"
              "missingLocalAction=install-package-before-repository-fallback"
              "localRootHint=~/.gerbil"
              "installHint=\"gxpkg install git.cons.io/mighty-gerbils/gerbil-poo\""
              "repositoryUrl=https://git.cons.io/mighty-gerbils/gerbil-poo indexOwner=asp-client indexBackend=rust-sql"
              "|selector role=class-definition symbol=defclass selector=gerbil-poo://object.ss#defclass"
              "|selector role=generic-definition symbol=.defgeneric selector=gerbil-poo://mop.ss#.defgeneric"
              "|selector role=method-dispatch symbol=defmethod selector=gerbil-poo://mop.ss#defmethod"
              "|selector role=prototype-composition symbol=compose-proto selector=gerbil-poo://proto.ss#compose-proto"
              "|selector role=thin-macro-bridge symbol=@method selector=gerbil-poo://brace.ss#@method"
              "|selector role=slot-resolution symbol=compute-precedence-list! selector=gerbil-poo://object.ss#compute-precedence-list!"
              "|selector role=io-serialization-method-family symbol=marshal selector=gerbil-poo://io.ss#marshal"
              "|selector role=method-resolution-order symbol=class-precedence-list selector=gerbil-runtime://c3.ss#class-precedence-list"
              "|selector role=real-project-semantic-test symbol=c3-test selector=gerbil-runtime-test://src/gerbil/test/c3-test.ss#c3-test"
              "|form role=class-definition symbol=defclass head=defclass operands=(<Class> <Base>),(<slot> ...) keywords=transparent: #t"
              "|form role=mro-regression-test symbol=class-precedence-list head=check"
              "|form role=slot-order-regression-test symbol=class-type-slot-vector head=check"
              "|failureCase id=racket-class-syntax"
              "|failureCase id=method-without-generic"
              "|failureCase id=unchecked-mro-assumption"
              "|failureCase id=macro-bridge-with-runtime-semantics"
              "|failureCase id=direct-slot-hash-guess"
              "|failureCase id=io-method-without-family"
              "|qualitySignal id=dependency-backed-mapping"
              "|qualitySignal id=real-project-c3-test"
              "|qualitySignal id=mro-linearization-witness"
              "|qualitySignal id=slot-order-witness"
              "|qualitySignal id=thin-macro-bridge"
              "|qualitySignal id=object-slot-resolution-model"
              "|qualitySignal id=io-serialization-method-family"
              "selectorCount=11 formCount=9 failureCaseCount=7"
              "missing=-"])
            (check (not (contains? pattern-output (string-append ".data" "/gerbil-poo"))) => #t)
            (check (not (contains? pattern-output "pending")) => #t)))))
