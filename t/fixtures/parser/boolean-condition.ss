;;; -*- Gerbil -*-
(import :std/string/misc)

;; : (-> Path String Boolean )
(def (path-matches-token? relpath token)
  (or (string-prefix? (string-append token "/") relpath)
      (string-contains relpath (string-append "/" token "/"))
      (string-suffix? (string-append "/" token) relpath)
      (and (not (string-contains token "/"))
           (string-contains relpath token))))
