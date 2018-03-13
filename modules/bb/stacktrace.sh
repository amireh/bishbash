import "bb/at_exit.sh"
import "bb/tty.sh"

# we have to go through a file since the the stack may be traced from a
# different subshell which won't have (write) access to this variable
export __stacktrace_file=$(mktemp '/tmp/bash-stacktrace-helper.XXXXXXXXX')

at_exit "stacktrace.clean"

# (): void
function stacktrace.print() {
  local stack=( $(cat "${__stacktrace_file}") )

  if test "${#stack[@]}" -eq 0; then
    return 0
  else
    stacktrace.clean
  fi

  printf "\nStack trace:\n\n"

  for frame in `seq 1 3 ${#stack[@]}`; do
    local line="${stack[frame -1]}"
    local func="${stack[frame + 0]}"
    local file=$(echo "${stack[frame + 1]}" | sed -e 's|'"$(pwd)"'/|./|')

    tty.columnize "$(tty.lpad "${func}" 20)" "${file}:${line}" 20 $(tput cols)
  done
}

# (): void
function stacktrace.track() {
  printf "" > "${__stacktrace_file}"

  caller 0 >> "${__stacktrace_file}"
  caller 1 >> "${__stacktrace_file}"
  caller 2 >> "${__stacktrace_file}"
  caller 3 >> "${__stacktrace_file}"
  caller 4 >> "${__stacktrace_file}"
}

# @private
#
# (): void
function stacktrace.clean() {
  rm -f -- "${__stacktrace_file}"
}