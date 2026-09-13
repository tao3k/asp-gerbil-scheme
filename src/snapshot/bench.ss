;;; -*- Gerbil -*-
;;; Stable snapshot projections for benchmark packets.

(import :asp-gerbil-scheme/src/constants
        :asp-gerbil-scheme/src/support/time)

(export bench-report-snapshot)

;; : (-> Packet Key Boolean )
(def (bench-packet-has-key? packet key)
  (or (hash-key? packet key)
      (hash-key? packet (symbol->string key))))

;; : (-> Packet Key JsonPacket )
(def (bench-packet-get packet key)
  (if (hash-key? packet key)
    (hash-get packet key)
    (hash-get packet (symbol->string key))))

;; : (-> Benchmark Snapshot )
(def (bench-step-snapshot benchmark)
  (list 'bench
        (list 'name (bench-packet-get benchmark 'name))
        (list 'iterations (bench-packet-get benchmark 'iterations))
        (list 'durationMs
              (duration-state (bench-packet-get benchmark 'durationMs)))
        (list 'averageMicros
              (duration-state (bench-packet-get benchmark 'averageMicros)))
        (list 'averageMs
              (duration-state (bench-packet-get benchmark 'averageMs)))))

;; : (-> Benchmark Snapshot )
(def (bench-slowest-snapshot benchmark)
  (list 'bench
        (list 'name "measured")
        (list 'iterations (bench-packet-get benchmark 'iterations))
        (list 'durationMs
              (duration-state (bench-packet-get benchmark 'durationMs)))
        (list 'averageMicros
              (duration-state (bench-packet-get benchmark 'averageMicros)))
        (list 'averageMs
              (duration-state (bench-packet-get benchmark 'averageMs)))))

;; : (-> TypeFinding Snapshot )
(def (bench-performance-finding-snapshot finding)
  (list 'finding
        (list 'kind (bench-packet-get finding 'kind))
        (list 'severity (bench-packet-get finding 'severity))
        (list 'summary (bench-packet-get finding 'summary))
        (list 'totalMs
              (duration-state (bench-packet-get finding 'totalMs)))
        (list 'maxTotalMs (bench-packet-get finding 'maxTotalMs))
        (list 'exceededByMs
              (duration-state (bench-packet-get finding 'exceededByMs)))
        (list 'slowestBenchmarkName
              (bench-packet-get finding 'slowestBenchmarkName))
        (list 'slowestBenchmarkDurationMs
              (duration-state
               (bench-packet-get finding 'slowestBenchmarkDurationMs)))))

;;; Boundary:
;;; - bench-report-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Packet Snapshot )
(def (bench-report-snapshot packet)
  (list 'benchReport
        (list 'languageId +language-id+)
        (list 'providerId +provider-id+)
        (list 'schemaId (bench-packet-get packet 'schemaId))
        (list 'status (bench-packet-get packet 'status))
        (list 'iterations (bench-packet-get packet 'iterations))
        (list 'maxTotalMs
              (if (bench-packet-has-key? packet 'maxTotalMs)
                (bench-packet-get packet 'maxTotalMs)
                #f))
        (list 'maxInterfaceMs
              (if (bench-packet-has-key? packet 'maxInterfaceMs)
                (bench-packet-get packet 'maxInterfaceMs)
                #f))
        (list 'totalMs
              (duration-state (bench-packet-get packet 'totalMs)))
        (list 'files (bench-packet-get packet 'files))
        (list 'definitions (bench-packet-get packet 'definitions))
        (list 'findings (bench-packet-get packet 'findings))
        (list 'performanceFindings
              (map bench-performance-finding-snapshot
                   (bench-packet-get packet 'performanceFindings)))
        (list 'slowestBenchmark
              (bench-slowest-snapshot
               (bench-packet-get packet 'slowestBenchmark)))
        (list 'benchmarks
              (map bench-step-snapshot
                   (bench-packet-get packet 'benchmarks)))))
