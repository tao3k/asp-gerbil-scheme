;;; -*- Gerbil -*-
;;; Marlin keeps its file selection in gerbil test. ASP only maps POO profiles
;;; onto the explicit files that need different resource envelopes.

(import :clan/poo/object
        :asp-gerbil-scheme/build-api)

(export marlin-testing)

(def marlin-testing
  (!> +asp-testing-interface+
      (cut testing-interface-map-profile
           <> "t/deck-runtime-tests.ss"
           (.cc +testing-memory-profile+ maxHeapMiB: 2048))
      (cut testing-interface-map-profile
           <> "t/config-interface-tests.ss"
           (.cc +testing-memory-profile+ maxHeapMiB: 512))))
