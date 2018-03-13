bb.import "bb/tty.sh"
bb.import "bb/stacktrace.sh"

# ((): Boolean, String): void
function bb.invariant() {
  local predicate="${@:1:$(($#-1))}"
  local message="${@:$#:1}"

  if ! $predicate; then
    printf "${TTY_RED}InvariantViolation:${TTY_RESET} ${message}\n" 1>&2

    bb.stacktrace.track

    exit 1
  fi

  return 0
}