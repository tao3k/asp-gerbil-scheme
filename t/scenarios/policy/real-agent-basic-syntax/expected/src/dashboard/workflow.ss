;;; -*- Gerbil -*-
;;; Boundary:
;;; - Dashboard workflow owns the public policy repair shape for this scenario.
;;; - Preserve explicit imports, exported helpers, and parser-owned quality facts.
(package: sample/dashboard)
(import (only-in :clan/poo/object object<-alist .cc)
        (only-in :clan/base lambda-match curry !>)
        (only-in :std/list/list iota))
(export build-profile score-events dispatch-dashboard update-profile dashboard-threshold
        event-priority)

;; +profile
;;   : (List Value)
;;   | doc m%
;;       `+profile+` is the stable dashboard object seed.
;;     %
(def +profile+
  '((id . "orders")
    (status . "hot")
    (score . 0)
    (rows . 8)
    (columns . 5)
    (alerts . 6)
    (priority . "high")))

;; build-profile
;;   : (-> Profile)
;;   | doc m%
;;       `build-profile` materializes the POO object once at the boundary.
;;     %
(def (build-profile)
  (object<-alist +profile+))

;; event-delta
;;   : (-> Event (Values Number (List Event)))
;;   | type Event = (Pair Symbol Value)
;;   | doc m%
;;       `event-delta event` projects one event through a shape dispatcher.
;;     %
(def (event-delta event)
  ((lambda-match
     (('order . amount) (values amount [event]))
     (('alert . _) (values (event-priority 'critical) []))
     (_ (values 0 [])))
   event))

;; event-priority
;;   : (-> Symbol Number)
;;   | doc m%
;;       `event-priority level` keeps closed symbolic dispatch data-shaped.
;;     %
(def (event-priority level)
  (case level
    ((critical) 3)
    ((warning) 2)
    ((notice) 1)
    (else 0)))

;; score-event
;;   : (-> Event (List Value) (List Value))
;;   | doc m%
;;       `score-event event state` folds one projected event into scalar state.
;;     %
(def (score-event event state)
  (call-with-values
    (lambda () (event-delta event))
    (lambda (amount matched)
      (list (+ (car state) amount)
            (append matched (cadr state))))))

;; score-events
;;   : (-> (List Event) (List Value))
;;   | doc m%
;;       `score-events events` replaces rest/accumulator traversal with foldl.
;;     %
;;; Boundary:
;;; - Event traversal owns scalar accumulation only; POO object state stays out.
(def (score-events events)
  (foldl score-event '(0 ()) events))

;; dashboard-threshold
;;   : (-> Symbol Number)
;;   | doc m%
;;       `dashboard-threshold mode` keeps threshold defaults as arity behavior.
;;     %
(def (dashboard-threshold mode)
  (let (threshold*
        (case-lambda
          ((mode)
           ((lambda-match
              ('fast 10)
              ('safe 2)
              (_ 5))
            mode))
          ((mode fallback)
           ((lambda-match
              ('fast 10)
              ('safe 2)
              (_ fallback))
            mode))))
    (threshold* mode)))

;; dispatch-dashboard
;;   : (-> Command Args Result)
;;   | doc m%
;;       `dispatch-dashboard command args` dispatches command shape explicitly.
;;     %
(def (dispatch-dashboard command args)
  ((lambda-match
     ("score" (score-events args))
     ("profile" (build-profile))
     ("threshold" (dashboard-threshold (car args)))
     ("update" (update-profile (build-profile) (cdr args)))
     (_ (error "unknown dashboard command" command)))
   command))

;; profile-score-limit
;;   : (-> Integer Integer)
;;   | doc m%
;;       `profile-score-limit limit` keeps the hot loop scalar-only.
;;     %
(def (profile-score-limit limit)
  (foldl (lambda (index score) index)
         0
         (iota limit)))

;; update-profile
;;   : (-> Profile Integer Profile)
;;   | doc m%
;;       `update-profile profile limit` applies one final POO clone boundary.
;;     %
;;; Boundary:
;;; - The hot traversal is complete here; this is the single clone/update point.
(def (update-profile profile limit)
  (dynamic-wind
    void
    (lambda ()
      (.cc profile 'score (profile-score-limit limit)))
    void))
