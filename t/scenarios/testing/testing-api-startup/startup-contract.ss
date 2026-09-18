((scenarioKind . testing-api-process-startup)
 (attemptCount . 1)
 (maxNanoseconds . 4000000000)
 (forbiddenBaseDependencies
  . ("only-in ../build-api/native-import-closure"
     "only-in :clan/testing"
     "only-in :clan/timestamp"
     "only-in :clan/poo/debug"
     "\"./src/testing/performance\""
     "\"./src/testing/discovery-runner\""
     "\"./src/testing/source-admission\"")))
