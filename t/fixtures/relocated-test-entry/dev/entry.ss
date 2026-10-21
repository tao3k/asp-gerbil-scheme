;;; -*- Gerbil -*-
(import (only-in :std/source this-source-file)
        (only-in :std/cli/multicall call-entry-point)
        "../../../../src/testing/discovery-runner"
        "../../../../src/testing/extension")
(export main entry-source)
(def entry-source (this-source-file))
(init-profiled-test-environment! +asp-testing-interface+ pkgdir: "..")
