;;; -*- Gerbil -*-
;;; Upstream owns test selection and execution; this file declares only the
;;; optional instrumentation bound to an explicit upstream test file.

(import :clan/poo/object
        :asp-gerbil-scheme/testing-api)

(export upstream-testing)

(def upstream-testing
  (testing-interface-map-profile
   +asp-testing-interface+
   "t/upstream-tests.ss"
   (.cc +testing-memory-profile+ maxHeapMiB: 512)))
