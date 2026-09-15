;;; -*- Gerbil -*-
;;; Boundary:
;;; - Wrapper adapters keep wrap/unwrap as the only representation crossing.
;;; - Protocol methods are lifted through local helpers instead of copied into
;;;   the typeclass declaration body.
(package: sample/wrapper)
(import (only-in :clan/base compose cut))
(export WrappedCodec.)

;; wrapped-marshal
;;   : (-> Type Procedure Procedure)
;;   | doc m%
;;       `wrapped-marshal T unwrap` lifts marshal through the unwrap boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((wrapped-marshal T unwrap) value port)
;;       ;; => writes unwrapped value
;;       ```
;;     %
(def (wrapped-marshal T unwrap)
  (lambda (v port) (marshal T (unwrap v) port)))

;; wrapped-unmarshal
;;   : (-> Type Procedure Procedure)
;;   | doc m%
;;       `wrapped-unmarshal T wrap` lifts unmarshal through the wrap boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((wrapped-unmarshal T wrap) port)
;;       ;; => wrapped value
;;       ```
;;     %
(def (wrapped-unmarshal T wrap)
  (compose wrap (cut unmarshal T <>)))

;; wrapped-bytes<-
;;   : (-> Type Procedure Procedure)
;;   | doc m%
;;       `wrapped-bytes<- T unwrap` lifts raw byte encoding through unwrap.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((wrapped-bytes<- T unwrap) value)
;;       ;; => bytes
;;       ```
;;     %
(def (wrapped-bytes<- T unwrap)
  (compose (cut bytes<- T <>) unwrap))

;; wrapped-<-bytes
;;   : (-> Type Procedure Procedure)
;;   | doc m%
;;       `wrapped-<-bytes T wrap` lifts raw byte decoding through wrap.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((wrapped-<-bytes T wrap) bytes)
;;       ;; => wrapped value
;;       ```
;;     %
(def (wrapped-<-bytes T wrap)
  (compose wrap (cut <-bytes T <>)))

;; wrapped-json<-
;;   : (-> Type Procedure Procedure)
;;   | doc m%
;;       `wrapped-json<- T unwrap` lifts JSON encoding through unwrap.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((wrapped-json<- T unwrap) value)
;;       ;; => json
;;       ```
;;     %
(def (wrapped-json<- T unwrap)
  (compose (cut json<- T <>) unwrap))

;; wrapped-<-json
;;   : (-> Type Procedure Procedure)
;;   | doc m%
;;       `wrapped-<-json T wrap` lifts JSON decoding through wrap.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((wrapped-<-json T wrap) json)
;;       ;; => wrapped value
;;       ```
;;     %
(def (wrapped-<-json T wrap)
  (compose wrap (cut <-json T <>)))

;; wrapped-map
;;   : (-> Procedure Procedure Procedure)
;;   | doc m%
;;       `wrapped-map wrap unwrap` preserves functor map through the wrapper
;;       boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((wrapped-map wrap unwrap) f value)
;;       ;; => wrapped mapped value
;;       ```
;;     %
(def (wrapped-map wrap unwrap)
  (lambda (f x)
    ((compose wrap f unwrap) x)))

;; WrappedCodec.
;;   : (-> Type WrapperCodec)
;;   | doc m%
;;       `WrappedCodec.` binds wrapper protocol methods to local adapter
;;       helpers.
;;
;;       # Examples
;;
;;       ```scheme
;;       (WrappedCodec. T wrap unwrap)
;;       ;; => wrapper codec typeclass
;;       ```
;;     %
(define-type (WrappedCodec. @ [Wrapper. Wrap. ParametricFunctor.] T .wrap .unwrap)
  .marshal: (wrapped-marshal T .unwrap)
  .unmarshal: (wrapped-unmarshal T .wrap)
  .bytes<-: (wrapped-bytes<- T .unwrap)
  .<-bytes: (wrapped-<-bytes T .wrap)
  .json<-: (wrapped-json<- T .unwrap)
  .<-json: (wrapped-<-json T .wrap)
  .map/wrap: (wrapped-map .wrap .unwrap))
