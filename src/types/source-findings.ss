;;; -*- Gerbil -*-
;;; Reader diagnostics for parser-owned source files.

(import :asp-gerbil-scheme/src/parser/model
        (only-in :std/sugar hash)
        :asp-gerbil-scheme/src/types/findings)

(export source-file-type-findings)

;; : (-> SourceFile (List TypeFinding) )
(def (source-file-type-findings file)
  (let (error (source-file-parse-error file))
    (if error
      [(make-type-finding "GERBIL-SCHEME-READ-R001"
                          "error"
                          (source-file-path file)
                          error
                          (read-error-selector file)
                          (read-error-diagnostic-details file error))]
      '())))

;;; Read errors block every downstream parser fact, so the finding has to be
;;; usable by an agent without re-reading the whole file. The selector is a
;;; conservative file range until native reader exceptions expose exact columns.
;; : (-> SourceFile Selector )
(def (read-error-selector file)
  (let ((path (source-file-path file))
        (line-count (source-file-line-count file)))
    (if (> line-count 0)
      (string-append path ":1-" (number->string line-count))
      path)))

;;; Diagnostic projection boundary:
;;; - This layer formats reader failures for agents; it does not reinterpret
;;;   Gerbil syntax or retry parsing.
;;; - `file-range-fallback` is explicit so a later native line/column extractor
;;;   can tighten the location without changing the packet contract.
;; : (-> SourceFile String Json )
(def (read-error-diagnostic-details file error)
  (let* ((path (source-file-path file))
         (line-count (source-file-line-count file))
         (line-end (if (> line-count 0) line-count 1))
         (selector (read-error-selector file)))
    (hash (schema "gerbil-read-diagnostic-v1")
          (diagnosticKind "read-error")
          (category "syntax")
          (source "native-reader-exception")
          (path path)
          (selector selector)
          (location
           (hash (path path)
                 (lineStart 1)
                 (lineEnd line-end)
                 (columnStart 1)
                 (columnEnd #f)
                 (precision "file-range-fallback")))
          (rawMessage error)
          (agentInstruction
           "read errors block parser facts; repair this syntax issue before semantic checks")
          (nextAction "open selector and fix reader syntax")
          (successCriteria ["parse-source-file returns no parse-error"
                            "asp gerbil-scheme check reports no GERBIL-SCHEME-READ-R001"]))))
