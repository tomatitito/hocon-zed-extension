; For syntax highlighting of embedded languages
; Example: JSON in HOCON strings
((string) @injection.content
 (#match? @injection.content "^\\s*[{\\[]")
 (#set! injection.language "json"))