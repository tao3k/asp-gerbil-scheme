;;; -*- Gerbil -*-
;;; Policy bridge for source-backed Gerbil POO pattern metadata.

(import (only-in :asp-gerbil-scheme/src/extensions/poo-patterns
                 poo-pattern-id
                 poo-pattern-quality-signals
                 poo-pattern-source-owners
                 poo-pattern-witness)
        :asp-gerbil-scheme/src/policy/detection)

(export poo-source-pattern-detection-overlay)

;;; Boundary:
;;; - :asp-gerbil-scheme/src/extensions/poo-patterns owns gerbil-poo:// selectors and pattern facts.
;;; - :asp-gerbil-scheme/src/policy/detection owns detector prototype slots and result details.
;;; - This bridge keeps policy rules source-backed without making every rule
;;;   know the pattern registry shape.
;; : (-> PatternKind DetectionPrototype )
(def (poo-source-pattern-detection-overlay kind)
  (detection-prototype-source-overlay
   (poo-pattern-id kind)
   (poo-pattern-source-owners kind)
   (poo-pattern-quality-signals kind)
   (poo-pattern-witness kind)))
