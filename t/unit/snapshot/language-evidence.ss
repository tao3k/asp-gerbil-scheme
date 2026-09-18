;;; -*- Gerbil -*-
;;; Registry/guide contract for a fact-only language provider.

(import :asp-gerbil-scheme/src/commands/guide
        :asp-gerbil-scheme/src/protocol/registry
        (only-in :std/srfi/13 string-contains string-prefix?)
        :std/test)

(export check-guide-and-registry-fact-boundary)

;; Contract
(def (check-guide-and-registry-fact-boundary)
  (let* ((registry (language-registry "."))
         (language (car (hash-get registry 'languages)))
         (methods (hash-get language 'methods))
         (guide (guide-lines)))
    (check (not (not (member "index/structural" methods))) => #t)
    (check (not (not (member "index/native-syntax-owner-facts" methods))) => #t)
    (check (ormap (lambda (method) (string-prefix? "search/" method)) methods)
           => #f)
    (check (not (not (find (lambda (line)
                             (string-contains line
                                              "projection --native-index --json"))
                           guide)))
           => #t)))
