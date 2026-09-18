;;; -*- Gerbil -*-
;;; Direct contract for the native POO object-family declaration macro.

(import :std/test
        (only-in :clan/poo/object .o .ref .slot? object?)
        :asp-gerbil-scheme/src/object-family/syntax)

(def (family-test-ref value key (default #f))
  (if (.slot? value key) (.ref value key) default))

(defpoo-object-family
  (prototype family-test-prototype
             (kind 'family-test)
             (status 'ready))
  (constructor
   (family-test name: (family-name "anonymous")
                score: (family-score 0))
   (name family-name)
   (score family-score))
  (accessors family-test-ref
             (required
              (family-test-name name)
              (family-test-score score))
             (optional (family-test-status status 'unknown))))

(defpoo-object-family
  (prototype family-profile-prototype
             (name 'family-profile)
             (enabled? #t))
  (accessors family-test-ref
             (required (family-profile-name name))
             (optional (family-profile-enabled? enabled? #f))))

(def object-family-syntax-test
  (test-suite "native POO object family syntax"
    (test-case "macro emits one prototype-backed constructor and accessor family"
      (let (value (family-test name: "alpha" score: 7))
        (check (object? value) => #t)
        (check (.ref value 'kind) => 'family-test)
        (check (family-test-name value) => "alpha")
        (check (family-test-score value) => 7)
        (check (family-test-status value) => 'ready)))
    (test-case "optional accessors retain caller-owned fallback semantics"
      (let (value (.o (name "bare") (score 1)))
        (check (family-test-status value) => 'unknown)))
    (test-case "prototype-only form owns profile accessors without a dummy constructor"
      (let (profile (.o (:: @ family-profile-prototype)))
        (check (object? profile) => #t)
        (check (family-profile-name profile) => 'family-profile)
        (check (family-profile-enabled? profile) => #t)))))

(run-tests! object-family-syntax-test)
