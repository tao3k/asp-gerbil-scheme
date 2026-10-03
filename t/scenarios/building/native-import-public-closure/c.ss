;;; -*- Gerbil -*-
prelude: "./fixture-prelude"
(import (only-in "./b" fixture-b)
        (for-syntax "./syntax-helper"))
(export fixture-c)
(def fixture-c (+ fixture-b 1))
