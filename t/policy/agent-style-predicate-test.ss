;;; -*- Gerbil -*-
;;; gerbil scheme harness agent style predicate policy.

(import :gerbil/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        :std/sort
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-style
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/policy/gxtest
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(import :policy/agent-style-support)
(export agent-style-predicate-policy-test)

;; PolicyTest
(def agent-style-predicate-policy-test
  (test-suite "gerbil scheme harness agent style predicate policy"
(test-case "agent policy reports predicate family combinator repair"
          (let* ((root ".run/policy-predicate-family-combinator")
                 (_ (write-predicate-family-combinator-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-016" findings))
                 (finding (car matching))
                 (details (type-finding-details finding))
                 (repair (finding-agent-repair-json finding)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-severity finding) => "warning")
            (check (hash-get details 'styleGuide) => "predicate-family-combinator")
            (check (hash-get details 'subject) => "fact")
            (check (hash-get details 'predicateCount) => 3)
            (check (hash-get (hash-get details 'qualityReference)
                             'referencePattern)
                   => "gerbil-utils-predicate-combinator")
            (check (not (not (member "gerbil-utils/base.ss#compose"
                                     (hash-get (hash-get details
                                                         'qualityReference)
                                               'referenceExamples))))
                   => #t)
            (check (not (not (member "role" (hash-get details 'fieldKeys)))) => #t)
            (check (not (not (member "hash-get" (hash-get details 'repeatedCallees)))) => #t)
            (check (hash-get repair 'active) => #t)
            (check (hash-get repair 'guideTopic) => "predicate-family-combinator")
            (check (hash-get repair 'nextCommand)
                   => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-016 --intent style")))
(test-case "agent policy keeps single-caller high-count field access advisory only"
          (let* ((root ".run/policy-field-access-single-caller-advisory")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text
             (string-append owner "/core.ss")
             ";;; -*- Gerbil -*-\n(package: sample/orders)\n(def (duration-summary row)\n  (+ (hash-get row 'durationMs)\n     (hash-get row 'durationMs)\n     (hash-get row 'durationMs)\n     (hash-get row 'durationMs)\n     (hash-get row 'durationMs)\n     (hash-get row 'durationMs)\n     (hash-get row 'durationMs)\n     (hash-get row 'durationMs)))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-016" findings)))
              (check matching => []))))
(test-case "agent policy reports combined field access selector repair"
          (let* ((root ".run/policy-field-access-selector-helper")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text
             (string-append owner "/core.ss")
             ";;; -*- Gerbil -*-\n(package: sample/orders)\n(def (duration-total row)\n  (+ (hash-get row 'durationMs)\n     (hash-get row 'durationMs)\n     (hash-get row 'durationMs)))\n(def (duration-max row)\n  (if (> (hash-get row 'durationMs) 0)\n    (hash-get row 'durationMs)\n    0))\n(def (duration-label row)\n  (string-append \"duration=\" (hash-get row 'durationMs)))\n(def (duration-warning? row)\n  (or (> (hash-get row 'durationMs) 100)\n      (< (hash-get row 'durationMs) 0)))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-016" findings))
                   (finding (car matching))
                   (details (type-finding-details finding))
                   (field-evidence (hash-get details 'fieldAccessPattern))
                   (repair (finding-agent-repair-json finding)))
              (check (length matching) => 1)
              (check (type-finding-path finding) => "src/orders/core.ss")
              (check (type-finding-severity finding) => "warning")
              (check (hash-get details 'evidenceSource)
                     => "parser-owned fieldAccessPatternFacts")
              (check (hash-get details 'policySignals)
                     => ["high-field-access-count"
                         "cross-caller-field-access"])
              (check (hash-get details 'detectionCombiner)
                     => "field-access-helper-all-of")
              (check [(hash-get details 'detectionPrototype)
                      (hash-get details 'detectionCombinerKind)]
                     => ["field-access-helper-all-of" "all-of"])
              (check (hash-get details 'detectionDescription)
                     => "field access helper repair requires high access count and cross-caller spread")
              (check (hash-get details 'detectionSourcePattern)
                     => "gerbil-utils-predicate-combinator")
              (check (not (not (member "gerbil-utils/base.ss#compose"
                                       (hash-get details 'detectionSourceOwners))))
                     => #t)
              (check (not (not (member "predicate-combinator"
                                       (hash-get details 'detectionQualitySignals))))
                     => #t)
              (check (hash-get details 'detectionWitness)
                     => "gerbil-utils study: compose/cut/curry helpers and generator map/fold are style witnesses for bounded predicate or selector helper repair")
              (check (hash-get details 'requiredGroups)
                     => ["high-field-access-count"
                         "cross-caller-field-access"])
              (check (hash-get details 'evidenceGroups)
                     => ["high-field-access-count"
                         "cross-caller-field-access"])
              (check (hash-get details 'evidenceCounts) => [8 4])
              (check (hash-get field-evidence 'fieldKey) => "durationMs")
              (check (hash-get field-evidence 'accessCount) => 8)
              (check (length (hash-get field-evidence 'callers)) => 4)
              (check (hash-get details 'accessCountGate) => 8)
              (check (hash-get details 'callerCountGate) => 3)
              (check (hash-get repair 'active) => #t)
              (check (hash-get repair 'guideTopic) => "predicate-family-combinator")
              (check (hash-get repair 'nextCommand)
                     => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-016 --intent style")))
    (test-case "agent policy reports emitter projection burst through multiple signals"
          (let* ((root ".run/policy-emitter-projection-burst")
                 (_ (write-projection-burst-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-016" findings))
                 (finding (car matching))
                 (details (type-finding-details finding))
                 (burst-evidence (hash-get details 'projectionBurst))
                 (repair (finding-agent-repair-json finding)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-severity finding) => "warning")
            (check (hash-get details 'evidenceSource)
                   => "parser-owned projectionBurstFacts")
            (check (hash-get details 'policySignals)
                   => ["high-projection-access-count"
                       "multi-field-projection"
                       "emitter-output-boundary"])
            (check (hash-get details 'detectionCombiner)
                   => "emitter-projection-burst-all-of")
            (check [(hash-get details 'detectionPrototype)
                    (hash-get details 'detectionCombinerKind)]
                   => ["emitter-projection-burst-all-of" "all-of"])
            (check (hash-get details 'detectionDescription)
                   => "emitter projection repair requires access density, field spread, and output boundary evidence")
            (check (hash-get details 'detectionSourcePattern)
                   => "gerbil-utils-projection-builder")
            (check (not (not (member "gerbil-utils/base.ss#compose"
                                     (hash-get details 'detectionSourceOwners))))
                   => #t)
            (check (not (not (member "list-builder-output-shape"
                                     (hash-get details 'detectionQualitySignals))))
                   => #t)
            (check (not (not (member "projection-builder"
                                     (hash-get details 'detectionProfilePrecedence))))
                   => #t)
            (check (hash-get details 'requiredGroups)
                   => ["high-projection-access-count"
                       "multi-field-projection"
                       "emitter-output-boundary"])
            (check (hash-get details 'evidenceGroups)
                   => ["high-projection-access-count"
                       "multi-field-projection"
                       "emitter-output-boundary"])
            (check (hash-get details 'evidenceCounts) => [12 4 2])
            (check (hash-get burst-evidence 'caller) => "emit-order-line")
            (check (hash-get burst-evidence 'accessCount) => 12)
            (check (hash-get burst-evidence 'accessorCount) => 4)
            (check (hash-get burst-evidence 'emitterCount) => 2)
            (check (not (not (member "id"
                                     (hash-get burst-evidence 'fieldKeys))))
                   => #t)
            (check (hash-get repair 'active) => #t)
            (check (hash-get repair 'guideTopic) => "predicate-family-combinator")
            (check (hash-get repair 'nextCommand)
                   => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-016 --intent style"))))
(test-case "agent policy reports emitter projection burst through multiple signals"
          (let* ((root ".run/policy-emitter-projection-burst")
                 (_ (write-projection-burst-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-016" findings))
                 (finding (car matching))
                 (details (type-finding-details finding))
                 (burst-evidence (hash-get details 'projectionBurst))
                 (repair (finding-agent-repair-json finding)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-severity finding) => "warning")
            (check (hash-get details 'evidenceSource)
                   => "parser-owned projectionBurstFacts")
            (check (hash-get details 'policySignals)
                   => ["high-projection-access-count"
                       "multi-field-projection"
                       "emitter-output-boundary"])
            (check (hash-get details 'detectionCombiner)
                   => "emitter-projection-burst-all-of")
            (check [(hash-get details 'detectionPrototype)
                    (hash-get details 'detectionCombinerKind)]
                   => ["emitter-projection-burst-all-of" "all-of"])
            (check (hash-get details 'detectionDescription)
                   => "emitter projection repair requires access density, field spread, and output boundary evidence")
            (check (hash-get details 'detectionSourcePattern)
                   => "gerbil-utils-projection-builder")
            (check (not (not (member "gerbil-utils/base.ss#compose"
                                     (hash-get details 'detectionSourceOwners))))
                   => #t)
            (check (not (not (member "list-builder-output-shape"
                                     (hash-get details 'detectionQualitySignals))))
                   => #t)
            (check (not (not (member "projection-builder"
                                     (hash-get details 'detectionProfilePrecedence))))
                   => #t)
            (check (hash-get details 'requiredGroups)
                   => ["high-projection-access-count"
                       "multi-field-projection"
                       "emitter-output-boundary"])
            (check (hash-get details 'evidenceGroups)
                   => ["high-projection-access-count"
                       "multi-field-projection"
                       "emitter-output-boundary"])
            (check (hash-get details 'evidenceCounts) => [12 4 2])
            (check (hash-get burst-evidence 'caller) => "emit-order-line")
            (check (hash-get burst-evidence 'accessCount) => 12)
            (check (hash-get burst-evidence 'accessorCount) => 4)
            (check (hash-get burst-evidence 'emitterCount) => 2)
            (check (not (not (member "id"
                                     (hash-get burst-evidence 'fieldKeys))))
                   => #t)
            (check (hash-get repair 'active) => #t)
            (check (hash-get repair 'guideTopic) => "predicate-family-combinator")
            (check (hash-get repair 'nextCommand)
                   => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-016 --intent style")))
  ))
