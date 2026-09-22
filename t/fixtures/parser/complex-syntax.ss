;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :std/sugar
        (only-in :std/encoding/json read-json)
        (for-syntax :std/stxutil)
        (rename-in :std/list/list (foldl fold-left))
        (except-in :std/hash/misc hash-copy)
        (phi: +1 :std/misc/repr)
        (for-template :std/string/path))
(export make-widget with-widget <Widget> <Renderable> :render)
;; : (-> Value SourceLine String )
(defrule (with-widget value body ...)
  (let ((tmp value))
    body ...))
;; : (-> Stx CaptureSafe )
(defsyntax (capture-safe stx)
  (syntax-case stx ()
    ((_ id expr)
     #'(let ((id expr))
         id))))
;; String
(defclass (<Widget> :object) (name count) transparent: #t)
;; Integer
(defgeneric :render)
;; Integer
(defprotocol <Renderable>)
;; Integer
(defmethod (:render (widget <Widget>))
  (let* ((label "ok")
         (again label)
         (n 1))
    (displayln again)
    (read-json (open-input-string "{}"))
    (:render widget)))
;; : (-> String (List String) String )
(def (make-widget name . rest)
  (let ((count 0))
    (with-widget name
      (make-<Widget> name count))))
;; : (-> Value Dispatch )
(def (dispatch value)
  (match value
    ([? string? s] (make-widget s))
    (else (make-widget "fallback"))))
;; : (-> Value Widget )
(def select
  (case-lambda
    (() (make-widget "empty"))
    ((x) (dispatch x))))
