;;; -*- Gerbil -*-
;;; Lightweight POO scenario fixture contracts.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/benchmark/framework
        :policy/agent-poo-scenario-registry)

(export #t)

(def +poo-native-source-markers+
  '("(.o" "(.cc" "(.get" "(.ref" "(.mix" "(defpoo" "(defclass" "(defgeneric"))

(def +poo-adapter-construction-markers+
  '("(object<-alist (list"
    "(object<-alist\n   (list"
    "(object<-hash (list"
    "(object<-hash\n   (list"
    "(object<-fun (lambda"
    "(object<-fun\n   (lambda"))

(def +poo-generated-boundary-source-markers+
  '("(defstruct" "->alist"))

(def +poo-scenario-benchmark-datum-cache+ (make-hash-table))
(def +poo-scenario-expected-source-cache+ (make-hash-table))

;; : (-> String Alist MaybePair)
(def (poo-scenario-cache-ref scenario-id cache)
  (hash-get cache scenario-id))

;; : (-> String String)
(def (poo-scenario-root scenario-id)
  (string-append "t/scenarios/policy/" scenario-id))

;; : (-> String String)
(def (poo-performance-scenario-benchmark-path scenario-id)
  (benchmark-contract-path (poo-scenario-root scenario-id)))

;; : (-> String String)
(def (poo-performance-scenario-expected-root scenario-id)
  (path-expand "expected" (poo-scenario-root scenario-id)))

;; : (-> String Alist)
(def (poo-performance-scenario-benchmark-datum scenario-id)
  (let (cached
        (poo-scenario-cache-ref
         scenario-id
         +poo-scenario-benchmark-datum-cache+))
    (if cached
      cached
      (let (datum
            (benchmark-contract-read
             (poo-performance-scenario-benchmark-path scenario-id)))
        (hash-put! +poo-scenario-benchmark-datum-cache+
                   scenario-id
                   datum)
        datum))))

;; : (-> String String)
(def (poo-performance-scenario-expected-source-text scenario-id)
  (let (cached
        (poo-scenario-cache-ref
         scenario-id
         +poo-scenario-expected-source-cache+))
    (if cached
      cached
      (let (text
            (benchmark-source-tree-text
             (poo-performance-scenario-expected-root scenario-id)))
        (hash-put! +poo-scenario-expected-source-cache+
                   scenario-id
                   text)
        text))))

;; : (-> (List String) (List String))
(def (missing-poo-performance-scenario-benchmarks scenario-ids)
  (cond
   ((null? scenario-ids) [])
   ((file-exists? (poo-performance-scenario-benchmark-path (car scenario-ids)))
    (missing-poo-performance-scenario-benchmarks (cdr scenario-ids)))
   (else
    (cons (poo-performance-scenario-benchmark-path (car scenario-ids))
          (missing-poo-performance-scenario-benchmarks (cdr scenario-ids))))))

;; : (-> String Boolean)
(def (poo-performance-scenario-hot-path-exemption-complete? scenario-id)
  (let (datum (poo-performance-scenario-benchmark-datum scenario-id))
    (and (benchmark-contract-value datum 'hotPathExemption)
         (pair? (benchmark-contract-value datum 'hotPathEvidence))
         (benchmark-contract-value datum 'styleRewriteBoundary))))

;; : (-> (List String) (List String))
(def (poo-performance-scenarios-missing-hot-path-exemptions scenario-ids)
  (cond
   ((null? scenario-ids) [])
   ((poo-performance-scenario-hot-path-exemption-complete? (car scenario-ids))
    (poo-performance-scenarios-missing-hot-path-exemptions (cdr scenario-ids)))
   (else
    (cons (car scenario-ids)
          (poo-performance-scenarios-missing-hot-path-exemptions
           (cdr scenario-ids))))))

;; : (-> String Boolean)
(def (poo-performance-scenario-native-poo-primary? scenario-id)
  (let (datum (poo-performance-scenario-benchmark-datum scenario-id))
    (and (benchmark-contract-value datum 'nativePooPrimary)
         (benchmark-string-list-member?
          "native-poo-primary"
          (benchmark-contract-value datum 'hotPathEvidence)))))

;; : (-> (List String) (List String))
(def (poo-performance-scenarios-missing-native-poo-primary scenario-ids)
  (cond
   ((null? scenario-ids) [])
   ((poo-performance-scenario-native-poo-primary? (car scenario-ids))
    (poo-performance-scenarios-missing-native-poo-primary (cdr scenario-ids)))
   (else
    (cons (car scenario-ids)
          (poo-performance-scenarios-missing-native-poo-primary
           (cdr scenario-ids))))))

;; : (-> String Boolean)
(def (poo-performance-scenario-native-source-complete? scenario-id)
  (let* ((datum (poo-performance-scenario-benchmark-datum scenario-id))
         (source-text
          (poo-performance-scenario-expected-source-text scenario-id)))
    (and (benchmark-string-contains-any-fragment?
          source-text
          +poo-native-source-markers+)
         (or (benchmark-contract-value datum 'adapterBoundary)
             (not (benchmark-string-contains-any-fragment?
                   source-text
                   +poo-adapter-construction-markers+))))))

;; : (-> (List String) (List String))
(def (poo-performance-scenarios-missing-native-source scenario-ids)
  (cond
   ((null? scenario-ids) [])
   ((poo-performance-scenario-native-source-complete? (car scenario-ids))
    (poo-performance-scenarios-missing-native-source (cdr scenario-ids)))
   (else
    (cons (car scenario-ids)
          (poo-performance-scenarios-missing-native-source
           (cdr scenario-ids))))))

;; : (-> String Boolean)
(def (poo-performance-scenario-optimizer-visible? scenario-id)
  (let (datum (poo-performance-scenario-benchmark-datum scenario-id))
    (and (benchmark-contract-value datum 'optimizerVisibility)
         (pair? (benchmark-contract-value datum 'expectedQualitySignals))
         (pair? (benchmark-contract-value datum 'learnedStyleSources))
         (benchmark-string-list-member?
          "optimizer-visible-poo-hot-path"
          (benchmark-contract-value datum 'hotPathEvidence)))))

;; : (-> (List String) (List String))
(def (poo-performance-scenarios-missing-optimizer-visibility scenario-ids)
  (cond
   ((null? scenario-ids) [])
   ((poo-performance-scenario-optimizer-visible? (car scenario-ids))
    (poo-performance-scenarios-missing-optimizer-visibility (cdr scenario-ids)))
   (else
    (cons (car scenario-ids)
          (poo-performance-scenarios-missing-optimizer-visibility
           (cdr scenario-ids))))))

;; : (-> String Boolean)
(def (poo-performance-scenario-generated-boundary? scenario-id)
  (let* ((datum (poo-performance-scenario-benchmark-datum scenario-id))
         (source-text
          (poo-performance-scenario-expected-source-text scenario-id)))
    (and (benchmark-contract-value datum 'generatedRuntimeBoundary)
         (benchmark-string-list-member?
          "defstruct-internal-state"
          (benchmark-contract-value datum 'hotPathEvidence))
         (benchmark-string-list-member?
          "bounded-alist-boundary"
          (benchmark-contract-value datum 'hotPathEvidence))
         (benchmark-string-contains-any-fragment?
          source-text
          +poo-generated-boundary-source-markers+)
         (not (benchmark-string-contains-any-fragment?
               source-text
               +poo-adapter-construction-markers+)))))

;; : (-> (List String) (List String))
(def (poo-performance-scenarios-missing-generated-boundary scenario-ids)
  (cond
   ((null? scenario-ids) [])
   ((poo-performance-scenario-generated-boundary? (car scenario-ids))
    (poo-performance-scenarios-missing-generated-boundary (cdr scenario-ids)))
   (else
    (cons (car scenario-ids)
          (poo-performance-scenarios-missing-generated-boundary
           (cdr scenario-ids))))))
