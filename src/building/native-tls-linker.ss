;;; -*- Gerbil -*-
;; Native TLS closure shim for the building framework.  The build spec owns
;; platform linker flags; this module supplies the Standard Library import.
(import :std/net/ssl)
