bb.import "bb/at_exit.sh"
bb.import "bb/tty.sh"

# we have to go through a file since the the stack may be traced from a
# different subshell which won't have (write) access to this variable
export __bb_stacktrace_file=$(mktemp '/tmp/bash-stacktrace-helper.XXXXXXXXX')

bb.at_exit "stacktrace.clean"

# (): void
function stacktrace.print() {
  local stack=( $(cat "${__bb_stacktrace_file}") )

  if test "${#stack[@]}" -eq 0; then
    return 0
  else
    stacktrace.clean
  fi

  printf "\nStack trace:\n\n"

  for frame in `seq 1 3 ${#stack[@]}`; do
    local line="${stack[frame -1]}"
    local func="${stack[frame + 0]}"
    local file=$(echo "${stack[frame + 1]}" | sed -e 's|'"$(pwd)"'/||')

    tty.columnize "$(tty.lpad "${func}" 20)" "${file}:${line}"
  done
}

# (): void
function stacktrace.track() {
  printf "" > "${__bb_stacktrace_file}"

  caller 0 >> "${__bb_stacktrace_file}"
  caller 1 >> "${__bb_stacktrace_file}"
  caller 2 >> "${__bb_stacktrace_file}"
}

# @private
#
# (): void
function stacktrace.clean() {
  rm -f -- "${__bb_stacktrace_file}"
}