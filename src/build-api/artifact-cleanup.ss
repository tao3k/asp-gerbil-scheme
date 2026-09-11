;;; -*- Gerbil -*-
;;; Cleanup helpers for package-local generated artifacts.

(import :gerbil/gambit)
(export cleanup-generated-artifacts!)

;; : (-> Path Void)
;; Delete a generated artifact when it is present.
(def (delete-file-if-present! path)
  (with-catch
   (lambda (_) #!void)
   (lambda ()
     (when (file-exists? path)
       (delete-file path)))))

;; : (-> (List Path) Void)
;; Delete generated outputs before their source closure is rebuilt.
(def (cleanup-generated-artifacts! paths)
  (for-each delete-file-if-present! paths))
