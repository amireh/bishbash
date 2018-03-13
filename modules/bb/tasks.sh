import "bb/array.sh"
import "bb/invariant.sh"
import "bb/stacktrace.sh"
import "bb/tty.sh"

declare -g  __tasks_bail=false
declare -ga __tasks_blacklist=()
declare -ga __tasks_custom_options=()
declare -g  __tasks_latest=""
declare -g  __tasks_latest_description=""
declare -ga __tasks_names=()
declare -g  __tasks_wants_help=false
declare -ga __tasks_whitelist=()

function tasks.define() {
  __tasks_names+=("${1}")
}

function tasks.describe() {
  __tasks_latest_description="${1}"
}

# (env_key: String, desc: String)
function tasks.option() {
  local IFS=''
  __tasks_custom_options+=("${__tasks_latest}" "${1}" "${2}")
}

function tasks.abort() {
  stacktrace.track

  exit 1
}

# @private
function tasks.ensure_task_is_defined() {
  invariant array.contains "${__tasks_names[@]}" "${1}" "Unrecognized task \"${1}\"."
}

# @private
#
# (name: String, ...args: Any): Boolean
function tasks.run() {
  local name="${1}"
  local header="${TTY_YELLOW}[${name}]${TTY_RESET}"

  shift 1

  local task_fn=$@

  printf "$header STARTING\n"

  # eval tasks in a subshell to avoid side effects like `cd` and allow them to
  # `exec` for convenience
  ( $task_fn 2>&1 ) | while IFS="" read line; do
    printf "$header %s\n" "${line}"
  done

  local exit_status=${PIPESTATUS[0]}

  if [ $exit_status != 0 ]; then
    printf "$header ${TTY_RED}FAILED!${TTY_RESET} (exit code ${exit_status})\n"

    stacktrace.print

    exit $exit_status
  else
    printf "$header ${TTY_GREEN}OK${TTY_RESET}\n"
  fi

  printf "\n"
}


# (argv: Array): Number
#
# The return value is the number of arguments that were consumed. You are
# responsible for shifting them if you need to further process the arglist.
#
#     tasks.read_wants $@
#     shift $?
function tasks.read_wants() {
  while getopts ":s:o:Chb" opt
  do
    case $opt in
      s)
        tasks.ensure_task_is_defined "${OPTARG}"
        __tasks_blacklist+=("${OPTARG}")
      ;;
      o)
        tasks.ensure_task_is_defined "${OPTARG}"
        __tasks_whitelist+=("${OPTARG}")
      ;;
      b)
        __tasks_bail=true
      ;;
      C)
        tty.disable_colors
      ;;
      h)
        __tasks_wants_help=true
      ;;
      *) printf "tasks: invalid option: -$OPTARG\n" 1>&2 ;;
    esac
  done

  return $((OPTIND-1))
}

# (task: String): Boolean
#
# Check if the user has requested to either skip a task or run it exclusively
function tasks.wants() {
  if [[ " ${__tasks_blacklist[@]} " =~ " $1 " ]]; then
    return 1
  elif [[ ${#__tasks_whitelist[@]} -ne 0 && ! " ${__tasks_whitelist[@]} " =~ " $1 " ]]; then
    return 1
  else
    return 0
  fi
}
# (task: String): Boolean
#
# Check if the user has requested to either skip a task or run it exclusively
function tasks.wants_help() {
  [[ $__tasks_wants_help == true ]]
}

# @private
#
# (String): Boolean
function tasks.is_hook_defined() {
  test "$(type -t $1)" == "function"
}

# (stage: String, ...Any): Boolean
function tasks.run_all() {
  local task_path="${1}"
  local stage="${2:-"up"}"
  local exit_status=0

  invariant $(test -n "${task_path}") "task directory must be provided!"

  shift 1

  for task in "${__tasks_names[@]}"; do
    if tasks.wants "${task}"; then
      (
        import "${task_path}/${task}.sh"

        if test "${stage}" == "up" && tasks.is_hook_defined "up"; then
          tasks.run "${task}:up" "up" $@
        elif test "${stage}" == "down" && tasks.is_hook_defined "down"; then
          tasks.run "${task}:down" "down" $@
        fi
      )

      exit_status=$?

      if [[ $exit_status -gt 0 && $__tasks_bail == "1" ]]; then
        break
      fi
    fi
  done

  return $exit_status
}

# (): void
function tasks.print_help() {
  local task_path="${1}"
  local task=""
  local tasks=()
  local progname=$(tty.progname)
  local args=(
    "up"   "apply a task ${TTY_YELLOW}(default)${TTY_RESET}"
    "down" "attempt to undo the effects of a previous call to \"up\""
  )

  local options=(
    "-o [TASK]" "run only the specified task(s)"
    "-s [TASK]" "skip the specified task(s)"
    "-b"        "stop as soon as any task fails (e.g. bail)"
    "-C"        "do not colorize the output"
  )

  invariant $(test -n "${task_path}") "task directory must be provided!"

  for task in "${__tasks_names[@]}"; do
    __tasks_latest_description=""
    __tasks_latest="${task}"

    import "${task_path}/${task}.sh"

    tasks+=("${task}" "${__tasks_latest_description:-" "}")
  done

  printf "$progname\n"
  printf "\nUsage:\n\n"
  printf "    [TASK_ENV_OPTIONS] $progname [options] [up|down]\n"

  printf "\nExamples:\n"
  printf "\n    $progname                        # up everything"
  printf "\n    $progname up                     # up everything"
  printf "\n    OPT=1 $progname up               # up everything and define OPT=1 for tasks that can use it"
  printf "\n    $progname down                   # down everything"
  printf "\n    $progname -o some-task           # up only 'some-task'"
  printf "\n    $progname -o some-task down      # down only 'some-task'"
  printf "\n    $progname -s some-task down      # down all but 'some-task'"

  printf "\n"

  printf "\nArguments:\n\n"

  tty.print_columnized_list "${args[@]}"

  printf "\nOptions:\n\n"

  tty.print_columnized_list "${options[@]}"

  printf "\nTasks:\n\n"

  tty.print_columnized_list "${tasks[@]}"

  printf "\nTask environment options:\n\n"

  for i in `seq 0 3 "${#__tasks_custom_options[@]}"`; do
    local task_name="${__tasks_custom_options[i]}"
    local task_optkey="${__tasks_custom_options[i+1]}"
    local task_optdesc="${__tasks_custom_options[i+2]}"

    if [ -z "${task_name}" ]; then
      break
    elif [ "${task}" != "${task_name}" ]; then
      task="${task_name}"

      printf "  ${task_name}\n\n"
    fi

    tty.print_columnized_list "  ${task_optkey}" "${task_optdesc}"
  done

  printf "\n"
}
