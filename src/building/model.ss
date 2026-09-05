;;; Immutable building values describe stages, profiles, requests, and receipts.
;;; Execution belongs to Builder implementations; this owner must remain free
;;; of environment discovery and process side effects.
(import :gerbil/gambit)

(export build-stage
        build-stage?
        make-build-stage
        build-stage-label
        build-stage-kind
        build-stage-spec
        build-stage-current-pred
        build-stage-runner
        build-stage-after
        build-stage-description
        build-stage-receipt
        build-stage-receipt?
        make-build-stage-receipt
        build-stage-receipt-label
        build-stage-receipt-kind
        build-stage-receipt-status
        build-stage-receipt-description
        build-stage-receipt-result
        build-stage-receipt-elapsed-jiffies
        build-stage-receipt->alist
        build-plan-receipts->alist
        build-plan-receipts-summary
        build-stage-status
        build-stage-run!
        build-plan-run!
        make-build-profile
        build-profile?
        build-profile-name
        build-profile-builder
        build-profile-label-of
        build-profile-extra-options
        build-profile-after
        build-profile-description
        make-build-request
        build-request?
        build-request-label
        build-request-profile
        build-request-stage-specs
        build-request-current-pred
        build-request-context)

(defstruct build-stage
  (label kind spec current-pred runner after description))

(defstruct build-profile
  (name builder label-of extra-options after description))

(defstruct build-request
  (label profile stage-specs current-pred context))

(defstruct build-stage-receipt
  (label kind status description result elapsed-jiffies))

(def (build-stage-status stage context)
  (if ((build-stage-current-pred stage) stage context)
    'current
    'stale))

(def (build-stage-receipt/elapsed stage status result start-jiffy)
  (make-build-stage-receipt
   (build-stage-label stage)
   (build-stage-kind stage)
   status
   (build-stage-description stage)
   result
   (- (current-jiffy) start-jiffy)))

(def (build-stage-receipt->alist receipt)
  `((label . ,(build-stage-receipt-label receipt))
    (kind . ,(build-stage-receipt-kind receipt))
    (status . ,(build-stage-receipt-status receipt))
    (description . ,(build-stage-receipt-description receipt))
    (result . ,(build-stage-receipt-result receipt))
    (elapsed-jiffies . ,(build-stage-receipt-elapsed-jiffies receipt))))

(def (build-plan-receipts->alist receipts)
  `((version . 1)
    (stages . ,(map build-stage-receipt->alist receipts))))

(def (build-plan-receipts-summary receipts)
  (let ((compiled
         (filter (lambda (receipt)
                   (eq? (build-stage-receipt-status receipt) 'compiled))
                 receipts))
        (skipped
         (filter (lambda (receipt)
                   (eq? (build-stage-receipt-status receipt) 'skipped))
                 receipts)))
    `((version . 1)
      (stage-count . ,(length receipts))
      (compiled . ,(length compiled))
      (skipped . ,(length skipped))
      (elapsed-jiffies
       . ,(apply + (map build-stage-receipt-elapsed-jiffies receipts)))
      (active-stages . ,(map build-stage-receipt->alist compiled)))))

(def (build-stage-run! stage context)
  (let (start-jiffy (current-jiffy))
    (if (eq? (build-stage-status stage context) 'current)
      (build-stage-receipt/elapsed stage 'skipped #f start-jiffy)
      (let (result ((build-stage-runner stage) stage context))
        ((build-stage-after stage) stage context result)
        (build-stage-receipt/elapsed stage 'compiled result start-jiffy)))))

(def (build-plan-run! stages context)
  (map (lambda (stage) (build-stage-run! stage context)) stages))
