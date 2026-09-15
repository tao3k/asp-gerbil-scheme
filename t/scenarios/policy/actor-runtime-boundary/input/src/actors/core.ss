;;; -*- Gerbil -*-
;;; Input: one helper owns actor lifecycle, mailbox delivery, and shutdown.
(package: scenario/actor-runtime-boundary/input)
(export run-actor)

;; : (-> Actor Mailbox Send Receive Spawn Join Shutdown Parameter Result)
(def (run-actor mailbox messages)
  (let* ((done? #f)
         (worker
          (spawn
           (lambda ()
             (let loop ((rest messages)
                        (out '()))
               (if (null? rest)
                 (reverse out)
                 (let (message (car rest))
                   (send mailbox message)
                   (if done?
                     (loop (cdr rest) out)
                     (loop (cdr rest)
                           (cons (receive mailbox) out))))))))))
    (for-each (lambda (message) (send mailbox message)) messages)
    (set! done? #t)
    (thread-join! worker)))
