;;; -*- Gerbil -*-
;;; Shared macro-heavy target for the native and PackageSpec lanes.

(import (only-in :clan/poo/object .def .get)
        (only-in :asp-gerbil-scheme/src/object-family/syntax
                 defpoo-object-family
                 poo-family-ref))
(export ab-probe ab-probe-role ab-probe-capabilities)

(defpoo-object-family
  (prototype ab-probe-base
             (role 'native-ab)
             (capabilities '(projection std-make macro-expansion)))
  (accessors poo-family-ref
             (required (ab-probe-role role)
                       (ab-probe-capabilities capabilities))
             (optional)))

(.def (ab-probe @ ab-probe-base)
  (role 'package-spec-native-ab))
