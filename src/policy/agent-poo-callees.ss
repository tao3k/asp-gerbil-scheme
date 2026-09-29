;;; -*- Gerbil -*-
;;; POO policy callee sets shared by POO policy modules.

(export +manual-object-model-callees+
        +poo-prototype-ref-callees+
        +poo-data-object-literal-min-slot-specs+
        +poo-data-object-literal-callees+
        +poo-clone-override-callees+
        +poo-materialization-callees+
        +poo-composition-callees+
        +poo-super-constructor-callees+
        +poo-validation-callees+
        +poo-lens-modify-callees+
        +poo-object-constructor-callees+
        +poo-type-constructor-callees+
        +poo-debug-instrumentation-callees+
        +poo-slot-spec-mutation-callees+
        +poo-slot-predicate-callees+)

;; : (List String)
(def +manual-object-model-callees+
  '("hash" "make-hash-table" "list->hash-table"))

;; : (List String)
(def +poo-prototype-ref-callees+
  '(".ref" ".@" ".get"))

;; : Integer
(def +poo-data-object-literal-min-slot-specs+ 12)

;; : (List String)
(def +poo-data-object-literal-callees+
  '(".o"))

;; : (List String)
(def +poo-clone-override-callees+
  '(".cc"))

;; : (List String)
(def +poo-materialization-callees+
  '(".alist"
    ".alist/sort"
    ".all-slots"
    ".all-slots/sort"
    ".for-each!"
    ".refs/slots"
    "hash<-object"
    "force-object"))

;; : (List String)
(def +poo-composition-callees+
  '(".mix" ".extend" ".+"))

;; : (List String)
(def +poo-super-constructor-callees+
  '("object<-alist" "object<-hash" "object<-fun"))

;; : (List String)
(def +poo-validation-callees+
  '("validate" "element?" "monomorphic-object?"))

;; : (List String)
(def +poo-lens-modify-callees+
  '(".call" ".modify"))

;; : (List String)
(def +poo-object-constructor-callees+
  '("object<-alist" "object<-hash" "object<-fun" ".o" "make-object"))

;; : (List String)
(def +poo-type-constructor-callees+
  '("MonomorphicObject" "Function" "F_q" "Z/" "IntegerRange"))

;; : (List String)
(def +poo-debug-instrumentation-callees+
  '("trace-poo"))

;; : (List String)
(def +poo-slot-spec-mutation-callees+
  '(".def!" ".putslot!" ".setslot!"))

;; : (List String)
(def +poo-slot-predicate-callees+
  '("o?/slots"))
