;;; -*- Gerbil -*-
;;; Token helpers for Scheme-native typed contracts.

(import :gerbil/runtime/gambit)

(export typed-contract-token-char?
        typed-contract-arrow-count
        typed-contract-group-count)

;;; Character classification is shared by typed comment token extraction and
;;; Gerbil contract projection parsing so source signatures split type names equally.
;; typed-contract-token-char?
;;   : (-> Character Boolean )
;;   | doc m%
;;       `typed-contract-token-char? ch` identifies characters that belong to
;;       Scheme-native typed comment and Gerbil contract projection type tokens.
;;
;;       # Examples
;;       ```scheme
;;       (typed-contract-token-char? #\A)
;;       ;; => #t
;;       ```
;;     %
(def (typed-contract-token-char? ch)
  (or (char-upper-case? ch)
      (char-lower-case? ch)
      (char-numeric? ch)))

;;; Boundary:
;;; - Count only literal top-level arrow tokens in the source contract text.
;;; - Indexed character pairs keep the two-character lookahead bounded.
;; typed-contract-arrow-count
;;   : (-> SignatureContract Integer )
;;   | doc m%
;;       `typed-contract-arrow-count contract` counts arrow markers for contract
;;       quality classification without changing parsed type facts.
;;
;;       # Examples
;;       ```scheme
;;       (typed-contract-arrow-count "(-> A B)")
;;       ;; => 1
;;       ```
;;     %
(def (typed-contract-arrow-count contract)
  (typed-contract-token-pair-count contract #\- #\>))

;;; Pair counting intentionally avoids full parsing and only looks for the
;;; canonical adjacent arrow token pair.
;; : (-> SignatureContract Character Character Integer)
(def (typed-contract-token-pair-count contract first second)
  (let (text-length (string-length contract))
    (typed-contract-token-pair-count-from contract
                                          first
                                          second
                                          (fx1- text-length)
                                          0
                                          0)))

;; : (-> SignatureContract Character Character Integer Integer Integer Integer)
(def (typed-contract-token-pair-count-from contract first second stop index count)
  (if (< index stop)
    (typed-contract-token-pair-count-from
     contract
     first
     second
     stop
     (fx1+ index)
     (if (typed-contract-token-pair-at? contract index first second)
       (fx1+ count)
       count))
    count))

;; : (-> SignatureContract Integer Character Character Boolean)
(def (typed-contract-token-pair-at? contract index first second)
  (and (char=? (string-ref contract index) first)
       (char=? (string-ref contract (fx1+ index)) second)))

;;; Boundary:
;;; - Scheme-native type expressions use parentheses as syntax, not quality risk.
;; typed-contract-group-count
;;   : (-> SignatureContract Integer )
;;   | doc m%
;;       `typed-contract-group-count contract` keeps the typed-contract fact
;;       shape stable while treating Scheme-native parentheses as grammar syntax.
;;
;;       # Examples
;;       ```scheme
;;       (typed-contract-group-count "(-> (List A) (List B))")
;;       ;; => 0
;;       ```
;;     %
(def (typed-contract-group-count contract)
  0)
