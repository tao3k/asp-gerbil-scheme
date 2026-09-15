;;; -*- Gerbil -*-
;;; Boundary:
;;; - Backend projection returns multiple values because the pair is not a
;;;   public domain interface.
;;; - Public config helpers destructure the tuple directly at the consumer.
(package: sample/sandbox)
(export sandbox-config sandbox-backend-ref)

;; profile-form
;;   : (-> Symbol ProfileForms Form Form)
;;   | type ProfileForms = (List Form)
;;   | type Form = (List Datum)
;;   | doc m%
;;       `profile-form key forms` returns the first profile form for `key`.
;;     %
(def (profile-form key forms default-value)
  (cond
   ((null? forms) default-value)
   ((and (pair? (car forms))
         (eq? (caar forms) key))
    (car forms))
   (else
    (profile-form key (cdr forms) default-value))))

;; profile-tail
;;   : (-> Form (List Datum))
;;   | type Form = (List Datum)
;;   | doc m%
;;       `profile-tail form` removes the symbolic form tag.
;;     %
(def (profile-tail form)
  (if (and form (pair? form))
    (cdr form)
    '()))

;; backend-values
;;   : (-> ProfileForms (Values Symbol Symbol))
;;   | type ProfileForms = (List Form)
;;   | type Form = (List Datum)
;;   | doc m%
;;       `backend-values forms` is the tuple projection boundary for sandbox
;;       backend kind and reference.
;;     %
(def (backend-values forms)
  (let* ((backend-form
          (profile-form 'backend forms '(backend nono nono-sandbox)))
         (backend-payload (profile-tail backend-form))
         (backend-kind (if (null? backend-payload)
                         'nono
                         (car backend-payload)))
         (backend-ref (if (or (null? backend-payload)
                              (null? (cdr backend-payload)))
                        backend-kind
                        (cadr backend-payload))))
    (values backend-kind backend-ref)))

;; sandbox-config
;;   : (-> Symbol ProfileForms Config)
;;   | type ProfileForms = (List Form)
;;   | type Config = (List Datum)
;;   | doc m%
;;       `sandbox-config name forms` builds the public sandbox config without
;;       materializing an anonymous Pair result.
;;     %
(def (sandbox-config name forms)
  (call-with-values
    (lambda () (backend-values forms))
    (lambda (backend-kind backend-ref)
      (list 'sandbox name backend-kind backend-ref))))

;; sandbox-backend-ref
;;   : (-> ProfileForms Symbol)
;;   | type ProfileForms = (List Form)
;;   | doc m%
;;       `sandbox-backend-ref forms` projects the backend reference from the
;;       shared tuple boundary.
;;     %
(def (sandbox-backend-ref forms)
  (call-with-values
    (lambda () (backend-values forms))
    (lambda (_ backend-ref) backend-ref)))
