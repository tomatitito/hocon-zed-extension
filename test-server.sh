#!/bin/bash
# Unified test script for HOCON Language Server
# - Uses named pipes for persistent communication
# - If --send-messages is passed, sends a sequence of LSP messages and logs responses
# - Otherwise, starts the server and allows manual interaction

# Settings
SERVER_PATH="./hocon-language-server/target/debug/hocon-language-server"
LOG_DIR="/tmp/hocon_ls_test"
LOG_FILE="$LOG_DIR/merged_test_$(date +%s).log"
SERVER_IN="$LOG_DIR/server_in"
SERVER_OUT="$LOG_DIR/server_out"
SERVER_ERR="$LOG_DIR/server_err"

# LSP Messages
INIT_MSG='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":null,"clientInfo":{"name":"TestClient","version":"1.0.0"},"capabilities":{}}}'
INITIALIZED_MSG='{"jsonrpc":"2.0","method":"initialized","params":{}}'
DID_OPEN_MSG='{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":"file:///tmp/test.conf","languageId":"hocon","version":1,"text":"foo = bar\n"}}}'
SHUTDOWN_MSG='{"jsonrpc":"2.0","id":2,"method":"shutdown","params":null}'
EXIT_MSG='{"jsonrpc":"2.0","method":"exit","params":null}'

# Parse arguments
SEND_MESSAGES=0
for arg in "$@"; do
  if [[ "$arg" == "--send-messages" ]]; then
    SEND_MESSAGES=1
  fi
done

# Logging function
log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG_FILE"
}

# Function to send LSP messages
send_message() {
  local message="$1"
  local length=$(echo -n "$message" | wc -c | tr -d ' ')
  log "Sending message (length $length): $message"
  echo -ne "Content-Length: $length\r\n\r\n$message" > "$SERVER_IN"
}

# Function to read responses
read_response() {
  local timeout="$1"
  log "Reading response (timeout: ${timeout}s)"
  local start_size=$(wc -c < "$SERVER_OUT")
  sleep "$timeout"
  local new_content=$(tail -c +$((start_size+1)) "$SERVER_OUT")
  if [ -n "$new_content" ]; then
    log "Received response:"
    echo "$new_content" | tee -a "$LOG_FILE"
  else
    log "No response received within timeout"
  fi
}

# Setup
mkdir -p "$LOG_DIR"
log "=== HOCON Language Server Merged Test ==="

# Check server binary
if [ ! -f "$SERVER_PATH" ]; then
  log "ERROR: Server binary not found at $SERVER_PATH"
  exit 1
fi
if [ ! -x "$SERVER_PATH" ]; then
  log "Making server executable"
  chmod +x "$SERVER_PATH"
fi

# Create named pipes
log "Creating named pipes for communication"
rm -f "$SERVER_IN" "$SERVER_OUT" "$SERVER_ERR"
mkfifo "$SERVER_IN"
mkfifo "$SERVER_OUT"
mkfifo "$SERVER_ERR"

# Start server
log "Starting language server: $SERVER_PATH"
RUST_LOG=info "$SERVER_PATH" < "$SERVER_IN" > "$SERVER_OUT" 2> "$SERVER_ERR" &
SERVER_PID=$!
log "Server started with PID: $SERVER_PID"

# Keep error pipe open so it doesn't block
cat "$SERVER_ERR" >> "$LOG_DIR/server_errors.log" &
ERROR_PID=$!

if [ "$SEND_MESSAGES" -eq 1 ]; then
  log "Flag --send-messages detected: running automated LSP message sequence"

  # Step 1: Initialize
  log "Step 1: Sending initialize request"
  send_message "$INIT_MSG"
  read_response 1

  # Step 2: Initialized notification
  log "Step 2: Sending initialized notification"
  send_message "$INITIALIZED_MSG"
  read_response 1

  # Step 3: Open document
  log "Step 3: Sending didOpen notification"
  send_message "$DID_OPEN_MSG"
  read_response 2

  # Step 4: Shutdown
  log "Step 4: Sending shutdown request"
  send_message "$SHUTDOWN_MSG"
  read_response 1

  # Step 5: Exit
  log "Step 5: Sending exit notification"
  send_message "$EXIT_MSG"
  read_response 1

  # Check if server process is still running
  if ps -p $SERVER_PID > /dev/null 2>&1; then
    log "WARNING: Server is still running, killing it"
    kill $SERVER_PID
  else
    log "Server process has exited normally"
  fi

  kill $ERROR_PID 2>/dev/null
  rm -f "$SERVER_IN" "$SERVER_OUT" "$SERVER_ERR"
  log "Automated test completed"
  log "Check $LOG_FILE for detailed logs"
else
  log "No --send-messages flag: server running for manual interaction"
  log "You can now manually send messages to the server."
  log "For example:"
  log "  echo -ne \"Content-Length: 145\\r\\n\\r\\n{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"method\\\":\\\"textDocument/didChange\\\",\\\"params\\\":{\\\"textDocument\\\":{\\\"uri\\\":\\\"file:///tmp/test.conf\\\",\\\"version\\\":2},\\\"contentChanges\\\":[{\\\"text\\\":\\\"foo = baz\\n\\\"}]}}\" > $SERVER_IN"
  log "Press Ctrl+C to stop the server when done."
  wait $SERVER_PID
  kill $ERROR_PID 2>/dev/null
  rm -f "$SERVER_IN" "$SERVER_OUT" "$SERVER_ERR"
  log "Manual session ended"
fi
