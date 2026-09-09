;;; -*- Gerbil -*-
;;; POO-backed slot prototype helpers for policy descriptors.

(import :gerbil/gambit
        (only-in :clan/poo/mop define-type Any raise-type-error validate)
        (only-in :clan/poo/object
                 .alist
                 .call
                 .ref
                 .slot?
                 compute-precedence-list!
                 object?
                 object<-alist)
        (only-in :clan/poo/proto compose-proto* instantiate-proto)
        (only-in :clan/poo/table methods.table)
        (only-in :std/srfi/1 find fold)
        (only-in :std/sugar filter))

(export SlotPrototypeTable.
        slot-prototype-compose
        slot-prototype-extend
        slot-prototype-override
        slot-prototype-ref
        slot-profile
        slot-profile?
        slot-profile-compose
        slot-profile-extend
        slot-profile-override
        slot-profile-ref
        slot-profile->prototype
        slot-profile-precedence-names)

;;; Slot lookup boundary:
;;; - Association-list scanning is kept behind one helper.
;;; - Method-table slots call named helpers instead of embedding lambdas.
;; : (-> SlotPrototype Symbol MaybeSlotBinding )
(def (slot-prototype-find-slot prototype key)
  (find (lambda (candidate) (eq? (car candidate) key))
        prototype))

;;; Slot removal boundary:
;;; - Replacement helpers share the same key equality rule.
;;; - Filtering remains data-shaped and does not mutate descriptor order.
;; : (-> SlotPrototype Symbol SlotPrototype )
(def (slot-prototype-without-key prototype key)
  (filter (lambda (slot) (not (eq? (car slot) key)))
          prototype))

;;; Method-table .ref helper:
;;; - methods.table owns fallback plumbing; this helper owns only alist lookup.
;;; - The optional fail thunk keeps missing-key behavior caller supplied.
;; : (-> SlotPrototype Symbol Procedure Value )
(def (slot-prototype-table-ref prototype key (fail (lambda _ #f)))
  (let (slot (slot-prototype-find-slot prototype key))
    (if slot (cdr slot) (fail))))

;;; Method-table key predicate:
;;; - Boolean conversion is explicit because find returns a binding or false.
;;; - The slot scan is shared with .ref so lookup semantics cannot drift.
;; : (-> SlotPrototype Symbol Boolean )
(def (slot-prototype-table-key? prototype key)
  (if (slot-prototype-find-slot prototype key) #t #f))

;;; Method-table insertion helper:
;;; - New values are consed at the front, matching override precedence.
;;; - Existing bindings for the key are removed before the new value appears.
;; : (-> Symbol Value SlotPrototype SlotPrototype )
(def (slot-prototype-table-acons key value prototype)
  (cons (cons key value)
        (slot-prototype-without-key prototype key)))

;;; Method-table removal helper:
;;; - The named helper keeps the slot body protocol-shaped.
;;; - Callers receive a fresh descriptor list without the requested key.
;; : (-> SlotPrototype Symbol SlotPrototype )
(def (slot-prototype-table-remove prototype key)
  (slot-prototype-without-key prototype key))

;;; Method-table fold helper:
;;; - methods.table fold callbacks receive key, value, and accumulator.
;;; - std/srfi/1 fold owns traversal order.
;; : (-> Procedure Value SlotPrototype Value )
(def (slot-prototype-table-foldl f seed prototype)
  (fold (lambda (slot acc) (f (car slot) (cdr slot) acc))
        seed
        prototype))

;;; Method-table reverse fold helper:
;;; - Reverse traversal preserves right-fold semantics for alist-backed tables.
;;; - The callback shape stays identical to .foldl.
;; : (-> Procedure Value SlotPrototype Value )
(def (slot-prototype-table-foldr f seed prototype)
  (fold (lambda (slot acc) (f (car slot) (cdr slot) acc))
        seed
        (reverse prototype)))

;;; Method-table list projection:
;;; - Slot prototypes are already stored in list form.
;;; - The helper documents that no conversion or copy is implied.
;; : (-> SlotPrototype SlotPrototype )
(def (slot-prototype-table-list<- prototype)
  prototype)

;;; Method-table list intake:
;;; - Importing from a list preserves caller order and validation boundary.
;;; - Validation remains the responsibility of the table adapter.
;; : (-> SlotPrototype SlotPrototype )
(def (slot-prototype-table-<-list slots)
  slots)

;;; Table adapter boundary:
;;; - SlotPrototype is an association-list backed table from slot keys to values.
;;; - methods.table owns the derived .ref/opt, .merge, .update, and list helpers.
;;; - Local code uses the protocol calls instead of open-coding table behavior.
;; SlotPrototypeTable
(define-type (SlotPrototypeTable. @ [methods.table])
  Key: Any
  Value: Any
  .validate: => (lambda (super)
                  (lambda (prototype)
                    (unless (list? prototype)
                      (raise-type-error "Not a slot prototype alist" prototype))
                    (for-each
                     (lambda (slot)
                       (unless (and (pair? slot) (symbol? (car slot)))
                         (raise-type-error "Not a slot prototype binding" slot))
                       (validate Key (car slot))
                       (validate Value (cdr slot)))
                     prototype)
                    (super prototype)))
  .empty: []
  .empty?: null?
  .ref: slot-prototype-table-ref
  .key?: slot-prototype-table-key?
  .acons: slot-prototype-table-acons
  .remove: slot-prototype-table-remove
  .foldl: slot-prototype-table-foldl
  .foldr: slot-prototype-table-foldr
  .list<-: slot-prototype-table-list<-
  .<-list: slot-prototype-table-<-list
  .=?: equal?)

;;; Boundary:
;;; - Slot prototypes are plain descriptor data until this edge.
;;; - clan/poo/proto owns ordered inheritance and override resolution.
;;; - Policy modules consume instantiated descriptor data, not raw proto thunks.
;; : (-> (List SlotPrototype) SlotPrototype )
(def (slot-prototype-compose prototypes)
  (instantiate-proto
   (compose-proto* (map slot-prototype->poo-proto prototypes))
   '()))

;;; Boundary:
;;; - Extension order mirrors POO source order.
;;; - Overlays are placed outside the base prototype, so later descriptors
;;;   override inherited slots without mutating the base descriptor.
;; : (-> SlotPrototype SlotPrototype ... SlotPrototype )
(def (slot-prototype-extend base . overlays)
  (slot-prototype-compose
   (fold cons [base] overlays)))

;;; Boundary:
;;; - Single-overlay override stays explicit for callers replacing one profile.
;;; - The same POO composition path is used, so override behavior remains
;;;   auditable through slot-prototype-compose.
;; : (-> SlotPrototype SlotPrototype SlotPrototype )
(def (slot-prototype-override base overlay)
  (slot-prototype-compose [overlay base]))

;;; Lookup boundary:
;;; - The composed descriptor is still data, so slot reads are pure lookups.
;;; - Missing slots return caller-owned fallbacks to keep base profiles partial.
;; : (-> SlotPrototype Symbol Value Value )
(def (slot-prototype-ref prototype key fallback)
  (.call SlotPrototypeTable. .ref prototype key (lambda _ fallback)))

;;; Adapter boundary:
;;; - compose-proto* expects a two-argument proto function.
;;; - The recursive self accessor is intentionally unused.
;;; - Descriptor slots are merged by explicit key replacement at the data edge.
;; : (-> SlotPrototype PooProto )
(def (slot-prototype->poo-proto prototype)
  (lambda (_ inherited)
    (merge-slot-prototype inherited prototype)))

;;; Merge boundary:
;;; - The outer descriptor wins slot-by-slot, matching POO override semantics.
;;; - fold keeps the merge expression-level and leaves precedence in data.
;; : (-> SlotPrototype SlotPrototype SlotPrototype )
(def (merge-slot-prototype inherited prototype)
  (.call SlotPrototypeTable.
         .merge
         (lambda (_ inherited-value prototype-value)
           (or prototype-value inherited-value))
         inherited
         prototype))

;;; Replacement invariant:
;;; - Only one effective value exists for each slot key after composition.
;;; - Other slots retain their original order so details remain stable.
;; : (-> SlotPrototype Symbol Value SlotPrototype )
(def (put-slot-prototype-slot prototype key value)
  (.call SlotPrototypeTable.
         .update
         key
         (lambda (_) value)
         prototype
         #f))

;;; Native POO profile boundary:
;;; - A profile is an actual gerbil-poo object, not a parallel defstruct that
;;;   reimplements object precedence and caches.
;;; - Dynamic descriptor slots make object<-alist the correct semantic
;;;   constructor here; the returned public value remains POO-native.
;; : (-> String SlotPrototype supers: (List SlotProfile) SlotProfile )
(def (slot-profile profile-name slots supers: (profile-supers '()))
  (object<-alist
   (append
    [(cons 'slot-profile? #t)
     (cons 'profile-node-name profile-name)]
    slots)
   supers: profile-supers))

;;; Predicate boundary:
;;; - The marker is inherited through native POO composition.
;;; - Unrelated POO objects are not accepted as policy profiles.
;; : (-> SlotProfileCandidate Boolean )
(def (slot-profile? value)
  (and (object? value)
       (.slot? value 'slot-profile?)
       (.ref value 'slot-profile?)))

;;; Composition boundary:
;;; - The synthetic profile has no slots of its own.
;;; - C3 still records the join point in profilePrecedence details.
;; : (-> String (List SlotProfile) SlotProfile )
(def (slot-profile-compose name profiles)
  (slot-profile name '() supers: profiles))

;;; Extension boundary:
;;; - Later overlays are placed to the left in the C3 super list.
;;; - This preserves previous outer-wins descriptor semantics.
;; : (-> SlotProfile SlotProfile ... SlotProfile )
(def (slot-profile-extend base . overlays)
  (slot-profile-compose
   (string-append (slot-profile-node-name base) "-extension")
   (fold cons [base] overlays)))

;;; Override boundary:
;;; - Single replacement remains a two-super C3 graph.
;;; - The overlay wins while the base remains inspectable in precedence data.
;; : (-> SlotProfile SlotProfile SlotProfile )
(def (slot-profile-override base overlay)
  (slot-profile-compose
   (string-append (slot-profile-node-name overlay) "-override")
   [overlay base]))

;;; Compatibility projection boundary:
;;; - Legacy table consumers may still request the effective slot alist.
;;; - Native gerbil-poo owns C3 and slot resolution before this projection.
;; : (-> SlotProfile SlotPrototype )
(def (slot-profile->prototype profile)
  (filter
   (lambda (slot)
     (not (member (car slot) '(slot-profile? profile-node-name))))
   (.alist profile)))

;;; Lookup boundary:
;;; - Profile callers use native POO reads while legacy materialized slot lists
;;;   retain the table-adapter fallback.
;; : (-> SlotProfile Symbol Value Value )
(def (slot-profile-ref profile key fallback)
  (if (slot-profile? profile)
    (if (.slot? profile key) (.ref profile key) fallback)
    (slot-prototype-ref profile key fallback)))

;;; Metadata boundary:
;;; - Agent-facing details need names, not private profile structures.
;;; - The list comes directly from gerbil-poo's C3 linearization.
;; : (-> SlotProfile (List String) )
(def (slot-profile-precedence-names profile)
  (map slot-profile-node-name (compute-precedence-list! profile)))

;; : (-> SlotProfile String )
(def (slot-profile-node-name profile)
  (.ref profile 'profile-node-name))
