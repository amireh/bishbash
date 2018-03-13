function bb.at_exit() {
  trap "${1}" INT TERM HUP EXIT
}