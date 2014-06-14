source ../core.sh

log_debug "test"
log_info "test2"

log "test"

LOG_OUTPUT=./test

log "test_in_file"
cat ./test
rm ./test


LOG_LEVEL=$LOG_LEVEL_DEBUG
unset LOG_OUTPUT
log_trace "trace msg 1"
log_debug "debug msg 1"

LOG_LEVEL=$LOG_LEVEL_TRACE
log_trace "trace msg 2"