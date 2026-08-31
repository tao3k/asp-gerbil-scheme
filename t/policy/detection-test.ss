;;; -*- Gerbil -*-
;;; Direct tests for policy detection combinators.

(import :std/test
        :asp-gerbil-scheme/src/policy/detection
        :asp-gerbil-scheme/src/policy/prototype)

(export detection-policy-test)

;; PolicyTest
(def detection-policy-test
  (test-suite "gerbil scheme harness policy detection"
    (test-case "threshold prototype carries POO source overlay details"
      (let* ((syntax-evidence
              (lambda (_subject)
                (evidence-group "syntax-shape" 2 "sample.ss:3-5")))
             (runtime-evidence
              (lambda (_subject)
                (evidence-group "runtime-shape" 1 "sample.ss:7-7")))
             (prototype
              (detection-prototype-extend
               +threshold-detection-prototype+
               (detection-prototype-source-overlay
                "poo-prototype-composition"
                ["gerbil-poo://proto" "gerbil-utils://composition"]
                ["extend" "override" "compose"]
                "poo prototype overlay should survive detector composition")
               (detection-prototype
                "poo-backed-threshold"
                'threshold
                [syntax-evidence runtime-evidence]
                2
                '()
                "two independent parser-owned groups are required")))
             (result (run-detection-prototype 'subject prototype))
             (details (detection-result-details result)))
        (check (not (not result)) => #t)
        (check (detection-result-combiner result) => "poo-backed-threshold")
        (check (detection-result-combiner-kind result) => "threshold")
        (check (detection-result-selector result "fallback.ss")
               => "sample.ss:3-5")
        (check (hash-get details 'detectionSourcePattern)
               => "poo-prototype-composition")
        (check (hash-get details 'detectionSourceOwners)
               => ["gerbil-poo://proto" "gerbil-utils://composition"])
        (check (hash-get details 'detectionProfilePrecedence)
               => ["threshold-detection-extension"
                   "poo-backed-threshold"
                   "poo-prototype-composition"
                   "threshold-detection"])
        (check (hash-get details 'evidenceGroups)
               => ["syntax-shape" "runtime-shape"])))
    (test-case "slot profile C3 linearizes shared base once"
      (let* ((base
              (slot-profile
               "base-profile"
               [(cons 'slot "base")
                (cons 'baseOnly #t)]))
             (left
              (slot-profile
               "left-profile"
               [(cons 'slot "left")]
               supers: [base]))
             (right
              (slot-profile
               "right-profile"
               [(cons 'slot "right")]
               supers: [base]))
             (joined
              (slot-profile-compose "joined-profile" [right left])))
        (check (slot-profile-precedence-names joined)
               => ["joined-profile"
                   "right-profile"
                   "left-profile"
                   "base-profile"])
        (check (slot-profile-ref joined 'slot "") => "right")
        (check (slot-profile-ref joined 'baseOnly #f) => #t)))
    (test-case "threshold prototype requires enough independent groups"
      (let* ((syntax-evidence
              (lambda (_subject)
                (evidence-group "syntax-shape" 1 "sample.ss:3-5")))
             (prototype
              (detection-prototype
               "two-group-threshold"
               'threshold
               [syntax-evidence]
               2
               '()
               "single parser-owned group is insufficient")))
        (check (run-detection-prototype 'subject prototype) => #f)))
    (test-case "all-of prototype requires every named group"
      (let* ((syntax-evidence
              (lambda (_subject)
                (evidence-group "syntax-shape" 1 "sample.ss:3-5")))
             (runtime-evidence
              (lambda (_subject)
                (evidence-group "runtime-shape" 1 "sample.ss:7-7")))
             (missing-prototype
              (detection-prototype
               "strict-all-of"
               'all-of
               [syntax-evidence]
               0
               ["syntax-shape" "runtime-shape"]
               "strict detector requires every named group"))
             (matched-prototype
              (detection-prototype
               "strict-all-of"
               'all-of
               [syntax-evidence runtime-evidence]
               0
               ["syntax-shape" "runtime-shape"]
               "strict detector requires every named group"))
             (result (run-detection-prototype 'subject matched-prototype)))
        (check (run-detection-prototype 'subject missing-prototype) => #f)
        (check (not (not result)) => #t)
        (check (detection-result-required-groups result)
               => ["syntax-shape" "runtime-shape"])
        (check (detection-result-missing-groups result) => [])))
    (test-case "prototype override replaces inherited detector slots"
      (let* ((syntax-evidence
              (lambda (_subject)
                (evidence-group "syntax-shape" 1 "sample.ss:3-5")))
             (runtime-evidence
              (lambda (_subject)
                (evidence-group "runtime-shape" 1 "sample.ss:7-7")))
             (base
              (detection-prototype
               "base-detector"
               'threshold
               [syntax-evidence]
               1
               '()
               "base threshold"))
             (overlay
              (detection-prototype
               "override-detector"
               'threshold
               [syntax-evidence runtime-evidence]
               2
               '()
               "override threshold"))
             (prototype (detection-prototype-override base overlay))
             (result (run-detection-prototype 'subject prototype)))
        (check (detection-result-prototype result) => "override-detector")
        (check (detection-result-threshold result) => 2)
        (check (hash-get (detection-result-details result)
                         'detectionDescription)
               => "override threshold")))))
