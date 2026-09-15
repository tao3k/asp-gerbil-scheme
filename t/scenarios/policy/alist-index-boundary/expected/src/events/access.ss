;;; -*- Gerbil -*-
;;; Event lookup shape is owned by one symbolic index boundary.
(package: sample/events)
(import :gerbil/gambit)
(export make-event-index
        event-index-ref
        event-name
        event-owner
        event-route
        event-priority)

;; make-event-index
;;   : (-> Alist HashTable)
;;   | warning symbolic event keys are indexed once before repeated lookup
;;   | doc m%
;;       `make-event-index` precomputes symbolic event keys so downstream
;;       accessors do not repeat alist scans or local key spelling.
;;     %
(def (make-event-index event)
  (let (index (make-hash-table-eq))
    (for-each
     (lambda (entry)
       (hash-put! index (car entry) (cdr entry)))
     event)
    index))

;; event-index-ref
;;   : (-> HashTable Symbol Value)
(def (event-index-ref index key)
  (hash-get index key))

;; event-name
;;   : (-> HashTable Value)
(def (event-name index)
  (event-index-ref index 'name))

;; event-owner
;;   : (-> HashTable Value)
(def (event-owner index)
  (event-index-ref index 'owner))

;; event-route
;;   : (-> HashTable Value)
(def (event-route index)
  (event-index-ref index 'route))

;; event-priority
;;   : (-> HashTable Value)
(def (event-priority index)
  (event-index-ref index 'priority))
