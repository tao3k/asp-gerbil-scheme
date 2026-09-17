;;; Reader-only fixture: one declared heavy owner is within budget.
(import (only-in :fixture/heavy-a value-a)
        (only-in :fixture/light value-light))
