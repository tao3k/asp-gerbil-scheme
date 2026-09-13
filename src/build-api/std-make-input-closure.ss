;;; -*- Gerbil -*-
;;; POO extension that projects transitive Gerbil imports to std/make inputs.
;;; It never executes a compiler and never reads or owns GERBIL_PATH artifacts.

(import :gerbil/gambit
        :gerbil/expander
        (only-in :std/misc/path path-default-extension)
        (only-in :std/misc/plist pgetq psetq)
        (only-in :clan/poo/object .def)
        (only-in "../object-family/syntax"
                 defpoo-object-family poo-family-ref)
        (only-in "./funcs"
                 ordered-unique memoized-transitive-closure))

(export asp-gerbil-scheme-std-make-input-closure-prototype
        asp-gerbil-scheme-default-std-make-input-closure
        asp-gerbil-scheme-project-std-make-input-closure)

(def (native-gxc-module spec)
  (match spec
    ((? string? module) module)
    ([gxc: (? string? module) . _] module)
    (else #f)))

(def (native-gxc-source module)
  (path-default-extension module ".ss"))

(def (import-context-id value)
  (cond
   ((or (module-context? value) (prelude-context? value))
    (expander-context-id value))
   ((module-import? value) (import-context-id (module-import-source value)))
   ((module-export? value) (import-context-id (module-export-context value)))
   ((import-set? value) (import-context-id (import-set-source value)))
   (else #f)))

(def (module-index build-spec)
  (let (index (make-hash-table))
    (for-each
     (lambda (spec)
       (alet (module (native-gxc-module spec))
         (let (source (native-gxc-source module))
           (when (file-exists? source)
             (let* ((context (import-module source #f #f))
                    (id (expander-context-id context))
                    (entry (cons module context)))
               (hash-put! index module entry)
               (hash-put! index id entry))))))
     build-spec)
    index))

(def (module-direct-dependencies module context index)
  (filter-map
   (lambda (imported)
     (alet* ((id (import-context-id imported))
             (entry (hash-get index id))
             (dependency (car entry)))
       (and (not (equal? dependency module)) dependency)))
   (module-context-import context)))

(def (project-extra-inputs spec extra-inputs)
  (match spec
    ((? string? module)
     [gxc: module [extra-inputs: extra-inputs]])
    ([gxc: module [plist ...] . options]
     [gxc: module
           (psetq plist extra-inputs:
                  (ordered-unique
                   (append (pgetq extra-inputs: plist []) extra-inputs)))
           . options])
    ([gxc: module . options]
     [gxc: module [extra-inputs: extra-inputs] . options])
    (else spec)))

(def (project-native-import-closure build-spec)
  (let* ((index (module-index build-spec))
         (module->context
          (lambda (module)
            (hash-get index module)))
         (successors
          (lambda (module)
            (alet (entry (module->context module))
              (module-direct-dependencies module (cdr entry) index))))
         (closure (memoized-transitive-closure successors)))
    (map
     (lambda (spec)
       (cond
        ((native-gxc-module spec)
         => (lambda (module)
              (if (hash-get index module)
                (project-extra-inputs
                 spec
                 (map native-gxc-source (closure module)))
                spec)))
        (else spec)))
     build-spec)))

(defpoo-object-family
  (prototype asp-gerbil-scheme-std-make-input-closure-prototype
             (projector project-native-import-closure))
  (accessors poo-family-ref
             (required
              (std-make-input-closure-projector projector))
             (optional)))

(.def (asp-gerbil-scheme-default-std-make-input-closure
       @ asp-gerbil-scheme-std-make-input-closure-prototype))

(def (asp-gerbil-scheme-project-std-make-input-closure profile build-spec)
  ((std-make-input-closure-projector profile) build-spec))
