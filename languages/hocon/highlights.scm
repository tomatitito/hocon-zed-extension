; Inherit from the tree-sitter-hocon grammar queries
; or define custom highlighting rules

; Comments
(comment) @comment

; Strings
(string) @string
(quoted_string) @string
(unquoted_string) @string
(triple_quoted_string) @string

; Numbers
(number) @number

; Booleans and constants
(boolean) @constant.builtin
(null) @constant.builtin

; Keys and properties
(path) @property
(identifier) @property

; References and substitutions
(reference) @variable
(substitution
  "${" @punctuation.special
  "}" @punctuation.special)

; Operators
["=" ":" "+="] @operator

; Punctuation
["{" "}"] @punctuation.bracket
["[" "]"] @punctuation.bracket
["(" ")"] @punctuation.bracket
["," "."] @punctuation.delimiter

; Keywords
"include" @keyword.import
["file" "classpath" "url" "required"] @function.builtin

; Special HOCON types
(duration) @number
(size) @number

; Escape sequences
(escape_sequence) @string.escape