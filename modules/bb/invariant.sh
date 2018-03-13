import "bb/tty.sh"
import "bb/stacktrace.sh"

# ((): Boolean, String): void
function invariant() {
  local predicate="${@:1:$(($#-1))}"
  local message="${@:$#:1}"

  if $predicate; then
    return 0
  fi

  printf "${TTY_RED}InvariantViolation:${TTY_RESET} ${message}\n" 1>&2

  stacktrace.track

  exit 1
}