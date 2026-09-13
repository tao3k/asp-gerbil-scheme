;;; -*- Gerbil -*-
;;; Lightweight registry for POO performance scenarios.

(export #t)

(def +poo-performance-scenario-ids+
  '("poo-clone-override-loop-performance"
    "poo-composition-loop-performance"
    "poo-construction-performance"
    "poo-debug-instrumentation-loop-performance"
    "poo-fq-type-construction-loop-performance"
    "poo-function-type-construction-loop-performance"
    "poo-generated-receipt-boundary-performance"
    "poo-integer-range-type-construction-loop-performance"
    "poo-lens-loop-performance"
    "poo-marlin-config-interface-large-object-performance"
    "poo-materialization-loop-performance"
    "poo-object-construction-loop-performance"
    "poo-object-iteration-loop-performance"
    "poo-real-dashboard-workflow-performance"
    "poo-slot-predicate-loop-performance"
    "poo-slot-projection-loop-performance"
    "poo-slot-spec-mutation-loop-performance"
    "poo-type-construction-loop-performance"
    "poo-validation-loop-performance"
    "poo-z-type-construction-loop-performance"))

(def +poo-native-primary-scenario-ids+
  '("poo-clone-override-loop-performance"
    "poo-composition-loop-performance"
    "poo-construction-performance"
    "poo-debug-instrumentation-loop-performance"
    "poo-lens-loop-performance"
    "poo-marlin-config-interface-large-object-performance"
    "poo-materialization-loop-performance"
    "poo-object-construction-loop-performance"
    "poo-object-iteration-loop-performance"
    "poo-real-dashboard-workflow-performance"
    "poo-slot-predicate-loop-performance"
    "poo-slot-projection-loop-performance"
    "poo-slot-spec-mutation-loop-performance"
    "poo-validation-loop-performance"))

(def +poo-optimizer-visible-scenario-ids+
  '("poo-clone-override-loop-performance"
    "poo-composition-loop-performance"
    "poo-lens-loop-performance"
    "poo-marlin-config-interface-large-object-performance"
    "poo-materialization-loop-performance"
    "poo-object-construction-loop-performance"
    "poo-slot-projection-loop-performance"
    "poo-validation-loop-performance"))

(def +poo-generated-boundary-scenario-ids+
  '())
