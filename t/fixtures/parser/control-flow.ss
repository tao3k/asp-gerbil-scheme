;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(package: sample/control-flow)
(import :std/list/list-builder
        :std/misc/ports)
;; : (-> Boolean Parameter )
(def current-setting
  (make-parameter #f))
;; : (-> (List Number) Integer )
(def (total xs)
  (let loop ((rest xs) (acc 0)) (if (null? rest) acc (loop (cdr rest) (+ acc (car rest))))))
;; : (-> XX PlainLet )
(def (plain-let x)
  (let ((value x)) value))
;; : (-> (List XX) FirstOrStop )
(def (first-or-stop xs)
  (let/cc stop
    (if (null? xs) (stop #f) (car xs))))
;; : (-> Generating SafeTake )
(def (safe-take generating)
  (with-list-builder (collect!)
    (try
     (collect! (generating))
     (catch (lambda (c) (and (eof-object? c))) => void)
     (finally (void)))))
;; : (-> Thunk CaptureOutput )
(def (capture-output thunk)
  (call-with-output-string
   (lambda (port)
     (parameterize ((current-output-port port))
       (thunk)))))
;; : (-> Thunk Dynamic )
(def (with-dynamic thunk)
  (dynamic-wind
    (lambda () (void))
    thunk
    (lambda () (void))))
;; : (-> Thunk ParameterCall )
(def (parameter-call thunk)
  (call-with-parameters thunk current-setting #t))
;; : (-> Thunk Worker )
(def (worker thunk)
  (spawn/name 'worker thunk))
;; : (-> Thunk CoroutineSource )
(def (coroutine-source thunk)
  (in-cothread thunk))
;; : (-> Thunk ContinuationDebug )
(def (continuation-debug thunk)
  (continuation-capture
   (lambda (cont)
     (thunk))))
;; : (-> Event DecodeEvent )
(def (decode-event event)
  (match event
    (['ok value] value)
    (else #f)))
