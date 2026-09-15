;;; -*- Gerbil -*-

(export prepared-source-witness-ready?
        mark-prepared-source-witness-ready!)

(def prepared-source-witness-ready? #f)

(def (mark-prepared-source-witness-ready!)
  (set! prepared-source-witness-ready? #t))
