;;; -*- Gerbil -*-

(defrules emitted-helper ()
  ((_ value) value))

(defrules declarative-public ()
  ((_ value) (emitted-helper value)))

(defsyntax (procedural-public stx)
  (syntax-case stx ()
    ((_ value) (syntax (emitted-helper value)))))

(defsyntax identifier-public
  (identifier-rules (id (emitted-helper id))))

(defsyntax (quoted-only stx)
  (let ((datum '(emitted-helper 1)))
    (syntax-case stx ()
      ((_) (syntax datum)))))

(defsyntax (quasi-public stx)
  (quasisyntax
   (emitted-helper (unsyntax (compute stx)))))

(defsyntax (located-public stx)
  (syntax/loc (source-helper stx)
    (emitted-helper stx)))

(defsyntax (binding-public stx)
  (syntax
   (let ((emitted-helper (initializer-helper stx)))
     (lambda (lambda-helper)
       (def (definition-helper value)
         (body-helper emitted-helper lambda-helper value))))))
