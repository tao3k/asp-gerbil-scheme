;;; Reader-only fixture: the named owners need not resolve.
(import (only-in :fixture/heavy-a value-a)
        (only-in :fixture/heavy-b value-b))
