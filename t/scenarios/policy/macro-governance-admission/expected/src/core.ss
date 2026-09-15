;;; -*- Gerbil -*-
(package: sample/macro-governance)

(export define-value)

(defrules define-value ()
  ((_ name value)
   (def name value)))
