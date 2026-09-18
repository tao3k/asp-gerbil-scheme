;;; -*- Gerbil -*-
;;; Package-qualified ASP API usage is limited to optional POO profiles.
;;; gerbil test and clan/testing remain the downstream testing interface.

(import :clan/poo/object
        :asp-gerbil-scheme/testing-api)

(export downstream-testing)

(def downstream-testing
  (!> +asp-testing-interface+
      (cut testing-interface-map-profile
           <> "t/performance-test.ss"
           (.cc +testing-memory-profile+ maxHeapMiB: 1024))
      (cut testing-interface-map-profile
           <> "t/scenario-a-test.ss"
           +testing-performance-profile+)))
