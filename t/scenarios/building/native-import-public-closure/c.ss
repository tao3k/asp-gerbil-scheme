;;; -*- Gerbil -*-
(import (only-in "./b" fixture-b))
(export fixture-c)
(def fixture-c (+ fixture-b 1))
