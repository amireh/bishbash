import "bb/tty.sh"
import "bb/stacktrace.sh"

# (Boolean, String): void
function invariant() {
  local last_rc=$?
  local message="${@:$#:1}"

  if [[ "${#@}" -gt 1 ]]; then
    printf "${TTY_RED}invariant: wrong number of arguments, expecting 1 (a message)${TTY_RESET}\n" 1>&2

    stacktrace.track
    stacktrace.print
  fi

  if [[ $last_rc -eq 0 ]]; then
    return 0
  fi

  printf "${TTY_RED}InvariantViolation:${TTY_RESET} ${message}\n" 1>&2

  stacktrace.track

  exit 1
}