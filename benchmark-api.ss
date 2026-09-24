;;; -*- Gerbil -*-
;;; Public opt-in scenario and micro-kernel benchmark API.

(import "./src/benchmark/gate"
        "./src/benchmark/micro-kernel"
        "./src/testing/performance")

(export (import: "./src/benchmark/gate")
        (import: "./src/benchmark/micro-kernel")
        (import: "./src/testing/performance"))
