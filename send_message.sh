#!/bin/bash
 
# Path to the input pipe
SERVER_IN="/tmp/hocon_ls_test/server_in"

# Create a document open message
MESSAGE='{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":"file:///tmp/test.conf","languageId":"hocon","version":1,"text":"foo = \"bar\"\n"}}}'

# Calculate byte length correctly
LENGTH=$(echo -n "$MESSAGE" | wc -c | tr -d ' ')

# Write properly formatted LSP message to the pipe
echo -ne "Content-Length: $LENGTH\r\n\r\n$MESSAGE" > "$SERVER_IN"

# # Wait a moment and check output
# sleep 1
# cat "/tmp/hocon_ls_test/server_output.log"
