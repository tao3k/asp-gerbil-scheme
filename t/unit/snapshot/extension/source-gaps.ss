;;; -*- Gerbil -*-
;;; Boundary:
;;; - source-gap snapshot fixtures exercise real pattern registry evidence.
;;; - Keep this owner separate from schema-shape snapshots so R007 stays useful.
(import :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/snapshot/facade
        :std/test)
(export check-pattern-search-snapshot-source-gap-fixtures)
;; Snapshot
(def (check-pattern-search-snapshot-source-gap-fixtures)
  (let* ((index (collect-project "."))
         (prototype (poo-pattern-evidence index ["poo" "prototype" "compose-proto"]))
         (trace-debug (poo-pattern-evidence index ["poo" "trace" "debug"]))
         (slot-cache (poo-pattern-evidence index ["poo" "slot" "cache" "computed"]))
         (io-json (poo-pattern-evidence index ["poo" "json" "fallback"]))
         (lens (poo-pattern-evidence index ["poo" "lens" "slot-lens"]))
         (type-validation (poo-pattern-evidence index ["poo" "sealed" "validate"])))
    (check (pattern-search-snapshot "poo prototype compose-proto"
                                    prototype
                                    (hash-get prototype 'missing)
                                    (hash-get prototype 'next))
           => (snapshot-load "t/snapshots/poo-prototype-composition-pattern.ss"))
    (check (pattern-search-snapshot "poo trace debug"
                                    trace-debug
                                    (hash-get trace-debug 'missing)
                                    (hash-get trace-debug 'next))
           => (snapshot-load "t/snapshots/poo-trace-debug-pattern.ss"))
    (check (pattern-search-snapshot "poo slot cache computed"
                                    slot-cache
                                    (hash-get slot-cache 'missing)
                                    (hash-get slot-cache 'next))
           => (snapshot-load "t/snapshots/poo-slot-cache-pattern.ss"))
    (check (pattern-search-snapshot "poo json fallback"
                                    io-json
                                    (hash-get io-json 'missing)
                                    (hash-get io-json 'next))
           => (snapshot-load "t/snapshots/poo-io-json-fallback-partial.ss"))
    (check (pattern-search-snapshot "poo lens slot-lens"
                                    lens
                                    (hash-get lens 'missing)
                                    (hash-get lens 'next))
           => (snapshot-load "t/snapshots/poo-lens-pattern.ss"))
    (check (pattern-search-snapshot "poo sealed validate"
                                    type-validation
                                    (hash-get type-validation 'missing)
                                    (hash-get type-validation 'next))
           => (snapshot-load "t/snapshots/poo-type-validation-pattern.ss"))))
