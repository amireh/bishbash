export TTY_BOLD="\033[1m"
export TTY_GREEN="\033[0;32m"
export TTY_RED="\033[0;31m"
export TTY_RESET="\033[0m"
export TTY_UNDERLINE="\033[4m"
export TTY_YELLOW="\033[1;33m"

# (): void
function tty.disable_colors() {
  TTY_BOLD=''
  TTY_GREEN=''
  TTY_RED=''
  TTY_RESET=''
  TTY_UNDERLINE=''
  TTY_YELLOW=''
}

# (String, Number): String
function tty.lpad() {
  local str=$1
  local size=$2
  local delta=$(( $size - ${#str} ))

  if test $delta -gt 0; then
    local padding=$(yes ' ' | head -$delta | tr -d '\n')
    echo "${padding}${str}"
  else
    echo "${str}"
  fi
}

# (shortdesc: String, longdesc: String, keycol_sz: Number = 24): void
function tty.columnize() {
  local key="${1}"
  local value="${2}"
  local keycol_sz="${3:-18}"
  local valcol_sz=$(( ${4:-72} - $keycol_sz ))
  local IFS=$'\n'
  local lines=( $(printf "${value}" | fold -s -w $valcol_sz) )
  local printf_key="%-${keycol_sz}s"

  for i in "${!lines[@]}"; do
    if [ $i -gt 0 ]; then
      printf "${printf_key} %s\n" "" "${lines[i]}"
    else
      printf "${TTY_BOLD}${printf_key}${TTY_RESET} %s\n" "${key}" "${lines[i]}"
    fi
  done
}

# (Array<Tuple<shortdesc: String, longdesc: String>>): void
function tty.print_columnized_list() {
  local i=""
  local list=("$@")
  local indent="  "

  for i in `seq 0 2 ${#@}`; do
    tty.columnize "${indent}${list[i]}" "${list[i+1]}"
  done
}

# (): String
function tty.progname() {
  echo $(basename $0)
}

# (String): String
function tty.print_error() {
  printf "%s: ${TTY_RED}[error]${TTY_RESET} %s\n" $(tty.progname) "${1}" 1>&2
}