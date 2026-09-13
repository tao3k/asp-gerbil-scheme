;;; -*- Gerbil -*-
;;; Public opt-in testing profiles and performance instrumentation.

(import (only-in :clan/testing init-test-environment!)
        "./src/testing/extension"
        "./src/testing/performance")

(export init-test-environment!
        (import: "./src/testing/extension")
        (import: "./src/testing/performance"))
