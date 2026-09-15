#!/usr/bin/env gxi
;;; Scenario entrypoint for parent-side native batch observability.

(import (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 testing-interface-run-test-files!))

(testing-interface-run-test-files!
 +asp-testing-interface+
 '("t/scenarios/policy/upstream-gxtest-delegation/expected/t/alpha-test.ss"
   "t/scenarios/policy/upstream-gxtest-delegation/expected/t/beta-test.ss"
   "t/scenarios/policy/upstream-gxtest-delegation/expected/t/gamma-test.ss"
   "t/scenarios/policy/upstream-gxtest-delegation/expected/t/delta-test.ss"))
