;;; -*- Gerbil -*-
;;; Internal Build API projection of machine capacity into Gerbil's two
;;; upstream native consumers. This module owns no scheduling or Build Graph.

(import :gerbil/gambit
        (only-in :gerbil/compiler/base __available-cores))

(export native-build-core-count
        native-build-available-cores
        initialize-native-build-core-capacity!)

;; : (-> (Maybe String) Integer Integer)
(def (native-build-core-count override host-core-count)
  (let (configured (and override (string->number override)))
    (if (and (integer? configured) (> configured 0))
      configured
      (max 1 host-core-count))))

;; : (-> Integer)
(def (native-build-available-cores)
  (max 1 __available-cores))

;; Package BuildSpec projection calls this before std/make constructs settings.
;; A user override wins; otherwise the machine CPU count is inherited into the
;; upstream environment and the compiler's already-captured available cores.
;; : (-> Integer)
(def (initialize-native-build-core-capacity!)
  (let (selected
        (native-build-core-count
         (getenv "GERBIL_BUILD_CORES" #f)
         (##cpu-count)))
    (setenv "GERBIL_BUILD_CORES" (number->string selected))
    (set! __available-cores selected)
    selected))
