;;; -*- Gerbil -*-
;;; Native gxtest trampoline for a testing-api POO declaration.

(import (only-in :clan/testing init-test-environment!)
        "./src/testing/discovery-runner")

(export init-test-environment!
        (import: "./src/testing/discovery-runner"))
