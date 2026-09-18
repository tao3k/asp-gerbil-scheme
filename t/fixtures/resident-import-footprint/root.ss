;;; -*- Gerbil -*-

(import "./left" "./right")

(export resident-footprint-root-witness)

(def resident-footprint-root-witness
  (list resident-left-witness resident-right-witness))
