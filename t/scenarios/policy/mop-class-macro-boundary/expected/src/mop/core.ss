;;; -*- Gerbil -*-
;;; Boundary:
;;; - The class descriptor is declared once through Gerbil MOP syntax.
;;; - Runtime behavior stays in method helpers instead of a generated table.
(package: sample/mop)
(export model-record record-value update-record-value)

;; model-record
;;   : (-> Name Value ModelRecord)
;;   | type Name = Symbol
;;   | type Value = Any
;;   | doc m%
;;       `model-record` is a compact class descriptor boundary.
;;     %
(defclass model-record (name value)
  final: #t transparent: #t)

;; record-value
;;   : (-> ModelRecord Value)
;;   | type Value = Any
;;   | doc m%
;;       `record-value record` keeps runtime access separate from the class
;;       descriptor declaration.
;;     %
(defmethod (@method record-value model-record)
  (lambda (record)
    (using (record :- model-record)
      record.value)))

;; update-record-value
;;   : (-> ModelRecord Value ModelRecord)
;;   | type Value = Any
;;   | doc m%
;;       `update-record-value record value` is the narrow method boundary for
;;       changing the value slot.
;;     %
(defmethod (@method update-record-value model-record)
  (lambda (record value)
    (using (record :- model-record)
      (model-record name: record.name value: value))))
