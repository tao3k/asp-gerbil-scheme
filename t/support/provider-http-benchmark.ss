;;; -*- Gerbil -*-
;;; Test-only concurrent HTTP sampler. One curl multi loop starts every
;;; transfer together so reported duration excludes independent process-launch
;;; latency while still crossing the production loopback transport.

(import :gerbil/gambit
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/1 append-map iota)
        (only-in :std/srfi/13 string-tokenize))

(export parallel-live-corpus-samples)

(def (parallel-curl-transfer-arguments url body first?)
  (append
   (if first? '() '("--next"))
   (list "--http1.1"
         "--fail-with-body"
         "--silent"
         "--show-error"
         "--max-time"
         "2"
         "--header"
         "content-type: application/json"
         "--data"
         body
         "--output"
         "/dev/null"
         "--write-out"
         "%{http_code} %{time_total}\n"
         url)))

(def (parallel-live-corpus-samples endpoint body count)
  (let* ((url (string-append endpoint "v1/provider-runtime"))
         (arguments
          (append
           (list "curl" "--parallel" "--parallel-max"
                 (number->string count))
           (append-map
            (lambda (index)
              (parallel-curl-transfer-arguments url body (zero? index)))
            (iota count))))
         (output
          (run-process arguments
                       coprocess: read-all-as-string
                       stderr-redirection: #t))
         (port (open-input-string output)))
    (let parse ((samples '()))
      (let (line (read-line port))
        (if (eof-object? line)
            (reverse samples)
            (let (tokens (string-tokenize line))
              (unless (and (= (length tokens) 2)
                           (string=? (car tokens) "200"))
                (error "concurrent provider HTTP transfer failed" line))
              (parse
               (cons
                (inexact->exact
                 (round (* (string->number (cadr tokens)) 1000000.0)))
                samples))))))))
