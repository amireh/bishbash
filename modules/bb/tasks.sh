bb.import "bb/array.sh"
bb.import "bb/invariant.sh"
bb.import "bb/stacktrace.sh"
bb.import "bb/tty.sh"

declare -a __bb_tasks_names=()
declare -a __bb_tasks_whitelist=()
declare -a __bb_tasks_blacklist=()
declare -a __bb_tasks_custom_options=()
declare __bb_tasks_bail="0"
declare __bb_tasks_latest=""
declare __bb_tasks_latest_description=""

function bb.tasks.define() {
  __bb_tasks_names+=("${1}")
}

function bb.tasks.describe() {
  __bb_tasks_latest_description="${1}"
}

# (env_key: String, desc: String)
function bb.tasks.option() {
  local IFS=''
  __bb_tasks_custom_options+=("${__bb_tasks_latest}" "${1}" "${2}")
}

function bb.tasks.abort() {
  bb.stacktrace.track

  exit 1
}

# @private
function bb.tasks.ensure_task_is_defined() {
  bb.invariant bb.array.contains "${__bb_tasks_names[@]}" "${1}" "Unrecognized task \"${1}\"."
}

# @private
#
# (name: String, ...args: Any): Boolean
function bb.tasks.run() {
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

    bb.stacktrace.print

    exit $exit_status
  else
    printf "$header ${TTY_GREEN}OK${TTY_RESET}\n"
  fi

  printf "\n"
}

# (task: String): Boolean
#
# Check if the user has requested to either skip a task or run it exclusively
function bb.tasks.wants() {
  if [[ " ${__bb_tasks_blacklist[@]} " =~ " $1 " ]]; then
    return 1
  elif [[ ${#__bb_tasks_whitelist[@]} -ne 0 && ! " ${__bb_tasks_whitelist[@]} " =~ " $1 " ]]; then
    return 1
  else
    return 0
  fi
}

# (argv: Array): Number
#
# The return value is the number of arguments that were consumed. You are
# responsible for shifting them if you need to further process the arglist.
#
#     bb.tasks.read_wants $@
#     shift $?
function bb.tasks.read_wants() {
  while getopts ":s:o:Chb" opt
  do
    case $opt in
      s)
        bb.tasks.ensure_task_is_defined "${OPTARG}"
        __bb_tasks_blacklist+=("${OPTARG}")
      ;;
      o)
        bb.tasks.ensure_task_is_defined "${OPTARG}"
        __bb_tasks_whitelist+=("${OPTARG}")
      ;;
      b)
        __bb_tasks_bail="1"
      ;;
      C)
        bb.tty.disable_colors
      ;;
      h)
        bb.tasks.print_help
        exit 1
      ;;
      *) echo "Invalid option: -$OPTARG" 1>&2 ;;
    esac
  done

  return $((OPTIND-1))
}

# @private
#
# (String): Boolean
function bb.tasks.is_hook_defined() {
  test "$(type -t $1)" == "function"
}

# (stage: String, ...Any): Boolean
function bb.tasks.run_all() {
  local stage="${1:-"up"}"
  local exit_status=0

  shift 1

  for task in "${__bb_tasks_names[@]}"; do
    if bb.tasks.wants "${task}"; then
      (
        bb.import "tasks/${task}.sh"

        if test "${stage}" == "up" && bb.tasks.is_hook_defined "up"; then
          bb.tasks.run "${task}:up" "up" $@
        elif test "${stage}" == "down" && bb.tasks.is_hook_defined "down"; then
          bb.tasks.run "${task}:down" "down" $@
        fi
      )

      exit_status=$?

      if [[ $exit_status -gt 0 && $__bb_tasks_bail == "1" ]]; then
        break
      fi
    fi
  done

  return $exit_status
}

# (): void
function bb.tasks.print_help() {
  local task=""
  local tasks=()
  local progname=$(bb.tty.progname)
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

  for task in "${__bb_tasks_names[@]}"; do
    __bb_tasks_latest_description=""
    __bb_tasks_latest="${task}"

    bb.import "tasks/${task}.sh"

    tasks+=("${task}" "${__bb_tasks_latest_description:-" "}")
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

  bb.tty.print_columnized_list "${args[@]}"

  printf "\nOptions:\n\n"

  bb.tty.print_columnized_list "${options[@]}"

  printf "\nTasks:\n\n"

  bb.tty.print_columnized_list "${tasks[@]}"

  printf "\nTask environment options:\n\n"

  for i in `seq 0 3 "${#__bb_tasks_custom_options[@]}"`; do
    local task_name="${__bb_tasks_custom_options[i]}"
    local task_optkey="${__bb_tasks_custom_options[i+1]}"
    local task_optdesc="${__bb_tasks_custom_options[i+2]}"

    if [ -z "${task_name}" ]; then
      break
    elif [ "${task}" != "${task_name}" ]; then
      task="${task_name}"

      printf "  ${task_name}\n\n"
    fi

    bb.tty.print_columnized_list "  ${task_optkey}" "${task_optdesc}"
  done

  printf "\n"
}
