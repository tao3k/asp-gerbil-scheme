;;; -*- Gerbil -*-
;;; Formatting facade for command and library callers.

(import :asp-gerbil-scheme/src/format/core
        :asp-gerbil-scheme/src/format/files)

(export fmt-target-files
        fmt-file
        fmt-result-changed?
        fmt-format-text
        fmt-format-lines
        fmt-trim-right
        fmt-source-file?)
