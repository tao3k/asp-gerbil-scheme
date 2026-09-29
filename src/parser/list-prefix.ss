;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(export take-while/proper)

;; take-while/proper
;;   : (forall (a) (-> (-> a Boolean) (List a) (List a)))
;;   : (-> Predicate SourceItems SourcePrefix)
;;   | doc m%
;;       Return the accepted prefix as a proper list. Gerbil 2591dcd's
;;       `std/list/list take-while` leaves `#!void` at the first rejected
;;       entry, which is unsuitable for parser facts.
;;
;;       # Examples
;;
;;       ```scheme
;;       (take-while/proper number? '(1 2 x))
;;       ;; => (1 2)
;;       ```
;;     %
(def (take-while/proper predicate items)
  (match items
    ([head . tail]
     (if (predicate head)
       (cons head (take-while/proper predicate tail))
       []))
    (else [])))
