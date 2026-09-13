;;; Module boundary: functional helpers stay pure and dependency-light so macro
;;; generated contract code can reuse them without creating policy/build cycles.

(import (only-in :std/iter for/fold in-range)
        (only-in :std/srfi/1 any every filter-map)
        :gerbil/gambit)

(export constant-value
        maybe-map
        ensure-list
        alist-ref/default
        fold-state
        drop-right-while
        repeat-char-string
        flat-map
        list-contains?
        list-intersects?
        non-empty-string?
        string-join-with
        u8vector-line-start-offsets
        list-all?
        list-any?)

;;; Boundary: keep these helpers expression-level and data-shape neutral.
;;; They provide small combinators for contract code without becoming a second
;;; collection abstraction over Gerbil's list library.

;;; Intent: build constant thunks without allocating wrapper collections.
;; constant-value
;; : (forall (a ignored) (-> a (-> ignored a)))
;; : (-> CapturedValue ConstantCallback)
;; | doc m%
;; Captures a value and returns a thunk that always yields that value.
;; # Examples
;; ```scheme
;; ((constant-value 'ready))
;; => ready
;; ```
;; Result: allocation-free constant thunk over the captured value.
(def (constant-value value)
  (lambda _
    value))

;;; Intent: keep optional transforms as one compact filter-map expression.
;; maybe-map
;; : (forall (a b) (-> (-> a b) (Maybe a) (Maybe b)))
;; : (-> OptionalMapper OptionalValue OptionalValue)
;; | doc m%
;; Applies `proc` only when the candidate value is present.
;; # Examples
;; ```scheme
;; (maybe-map symbol->string 'owner)
;; => "owner"
;; ```
;; Result: transformed value or false when no value is present.
(def (maybe-map proc value)
  (let (results (filter-map (lambda (candidate)
                              (and candidate (proc candidate)))
                            (list value)))
    (and (pair? results) (car results))))

;;; Intent: normalize scalar-or-list inputs at module boundaries.
;; ensure-list
;; : (forall (a) (-> (U a (List a)) (List a)))
;; : (-> ScalarOrList NormalizedList)
;; | doc m%
;; Returns existing lists unchanged and wraps scalar values once.
;; # Examples
;; ```scheme
;; (ensure-list 'owner)
;; => (owner)
;; ```
;; Result: list-shaped value for downstream sequence combinators.
(def (ensure-list value)
  (if (list? value) value (list value)))

;;; Intent: make alist lookup fallback behavior explicit and reusable.
;; alist-ref/default
;; : (forall (k v) (-> k (List (Pair k v)) v v))
;; : (-> LookupKey Alist FallbackValue ResolvedValue)
;; | doc m%
;; Reads an assq-backed alist entry and returns `fallback` when absent.
;; # Examples
;; ```scheme
;; (alist-ref/default 'mode '((mode . fast)) 'slow)
;; => fast
;; ```
;; Result: resolved alist value or caller-supplied fallback.
(def (alist-ref/default key alist fallback)
  (let (entry (assq key alist))
    (if entry (cdr entry) fallback)))

;;; Intent: name the common accumulator shape while keeping foldl local and fast.
;; fold-state
;; : (forall (state value) (-> (-> state value state) state (List value) state))
;; : (-> StateStep InitialState Sequence FinalState)
;; | doc m%
;; Threads state through values with a state-first step procedure.
;; # Examples
;; ```scheme
;; (fold-state (lambda (state value) (+ state value)) 0 '(1 2))
;; => 3
;; ```
;; Result: final accumulator after one left-to-right pass.
(def (fold-state step initial values)
  (foldl (lambda (value state)
           (step state value))
         initial
         values))

;;; Intent: share the byte-to-line index used by exact source projections.
;; u8vector-line-start-offsets
;; : (-> U8Vector Vector)
;; | doc m%
;; Builds zero-based byte offsets for every one-based source line.
;; # Examples
;; ```scheme
;; (u8vector-line-start-offsets (string->utf8 "a\nb"))
;; => #(0 2)
;; ```
;; Result: a compact vector beginning at byte offset zero.
(def (u8vector-line-start-offsets bytes)
  (list->vector
   (reverse
    (for/fold (starts '(0))
              (index (in-range (u8vector-length bytes)))
      (if (= (u8vector-ref bytes index) 10)
        (cons (+ index 1) starts)
        starts)))))

;;; Intent: express suffix trimming with foldr instead of ad hoc reverse loops.
;; drop-right-while
;; : (forall (a) (-> (-> a Boolean) (List a) (List a)))
;; : (-> Predicate List List)
;; | doc m%
;; Drops trailing values while predicate returns true.
;; # Examples
;; ```scheme
;; (drop-right-while zero? '(1 0 0))
;; => (1)
;; ```
;; Result: original list without the longest predicate-matching suffix.
(def (drop-right-while predicate values)
  (cdr
   (foldr (lambda (value acc)
            (let ((dropping? (car acc))
                  (out (cdr acc)))
              ;; Optimization boundary: foldr avoids a reverse pass while
              ;; preserving original order after the first kept suffix value.
              (if (and dropping? (predicate value))
                acc
                (cons #f (cons value out)))))
          (cons #t [])
          values)))

;;; Intent: centralize fixed-width string construction for formatter padding.
;; repeat-char-string
;; : (-> Char Integer String)
;; | doc m%
;; Builds a string by repeating one character count times.
;; # Examples
;; ```scheme
;; (repeat-char-string #\. 3)
;; => "..."
;; ```
;; Result: repeated character string; negative counts become the empty string.
(def (repeat-char-string ch count)
  (let (limit (max 0 count))
    (let loop ((index 0)
               (chars []))
      (if (>= index limit)
        (list->string (reverse chars))
        (loop (+ index 1) (cons ch chars))))))

;;; Intent: expose map-then-append as one algebraic sequence transform.
;; flat-map
;; : (forall (a b) (-> (-> a (List b)) (List a) (List b)))
;; : (-> ListMapper InputSequence OutputSequence)
;; | doc m%
;; Maps each value to a list and appends the results in source order.
;; # Examples
;; ```scheme
;; (flat-map (lambda (value) (list value value)) '(a b))
;; => (a a b b)
;; ```
;; Result: flattened mapped values without a separate intermediate map list.
(def (flat-map proc values)
  (foldr (lambda (value out)
           (append (proc value) out))
         []
         values))

;;; Intent: share short-circuit list intersection checks across policy gates.
;; list-contains?
;; : (forall (a) (-> (List a) a Boolean))
;; : (-> Sequence CandidateValue Boolean)
;; | doc m%
;; Tests whether a list contains a value using Scheme membership semantics.
;; # Examples
;; ```scheme
;; (list-contains? '(owner item) 'item)
;; => #t
;; ```
;; Result: boolean membership evidence instead of a pair-valued `member`.
(def (list-contains? values value)
  (and (member value values) #t))

;;; Intent: share short-circuit list intersection checks across policy gates.
;; list-intersects?
;; : (forall (a) (-> (List a) (List a) Boolean))
;; : (-> LeftSequence RightSequence Boolean)
;; | doc m%
;; Tests whether any value from the first list is a member of the second.
;; # Examples
;; ```scheme
;; (list-intersects? '(a b) '(c b))
;; => #t
;; ```
;; Result: boolean membership intersection result.
(def (list-intersects? left right)
  (and (any (lambda (value) (list-contains? right value)) left) #t))

;;; Intent: keep string evidence filters explicit and reusable.
;; non-empty-string?
;; : (forall (a) (-> a Boolean))
;; : (-> CandidateValue Boolean)
;; | doc m%
;; Accepts strings that contain at least one character.
;; # Examples
;; ```scheme
;; (non-empty-string? "owner")
;; => #t
;; ```
;; Result: boolean predicate for non-empty strings.
(def (non-empty-string? value)
  (and (string? value)
       (not (string-empty? value))))

;;; Intent: keep small string joining needs inside the shared utility layer.
;; string-join-with
;; : (-> (List String) String String)
;; | doc m%
;; Joins a list of strings with the given separator.
;; # Examples
;; ```scheme
;; (string-join-with '("a" "b" "c") ",")
;; => "a,b,c"
;; ```
;; Result: joined string or the empty string for an empty input list.
(def (string-join-with values separator)
  (let ((out (open-output-string))
        (first? #t))
    ;; Optimization boundary: output port avoids repeated string growth.
    (for-each (lambda (value)
                (if first?
                  (set! first? #f)
                  (display separator out))
                (display value out))
              values)
    (get-output-string out)))

;;; Intent: name universal predicate checks as a reusable list combinator.
;; list-all?
;; : (forall (a) (-> (-> a Boolean) (List a) Boolean))
;; : (-> Predicate List Boolean)
;; | doc m%
;; Tests that every value in a list satisfies the predicate.
;; # Examples
;; ```scheme
;; (list-all? symbol? '(owner item))
;; => #t
;; ```
;; Result: boolean universal quantifier over list values.
(def (list-all? predicate values)
  (every predicate values))

;;; Intent: name existential predicate checks as a reusable list combinator.
;; list-any?
;; : (forall (a) (-> (-> a Boolean) (List a) Boolean))
;; : (-> Predicate List Boolean)
;; | doc m%
;; Tests whether at least one value in a list satisfies the predicate.
;; # Examples
;; ```scheme
;; (list-any? symbol? '("owner" item))
;; => #t
;; ```
;; Result: boolean existential quantifier over list values.
(def (list-any? predicate values)
  (any predicate values))
;;; Functional utilities provide small total combinators used by generated
;;; contract and projection code; they are deliberately dependency-light so
;;; expansion products do not duplicate ad hoc lambdas across modules.
