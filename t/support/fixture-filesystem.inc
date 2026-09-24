;;; -*- Gerbil -*-
;;; Bounded cleanup for repository-local test fixtures.

(def +test-fixture-directory+
  (path-expand ".run" (current-directory)))

(def (test-fixture-child-path? boundary path)
  (and (> (string-length path) (string-length boundary))
       (equal? boundary
               (substring path 0 (string-length boundary)))))

;; : (-> Path Unit)
(def (reset-test-fixture-root! root)
  (let* ((expanded (path-expand root (current-directory)))
         (boundary (string-append +test-fixture-directory+ "/")))
    (unless (test-fixture-child-path? boundary expanded)
      (error "test fixture cleanup is restricted to a child of .run" root))
    (when (file-exists? expanded)
      (delete-file-or-directory expanded #t))))
