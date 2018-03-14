# (String): Boolean
function env.has_function() {
  declare -f -F "${1}" 1>/dev/null
}

# (String): Boolean
function env.has_command() {
  which "$1" &>/dev/null
}

# (): Boolean
function env.source_profile() {
  local files=(~/.bash_profile ~/.profile /etc/profile)

  for file in "${files[@]}"; do
    if [ -e "${file}" ]; then
      source "${file}"
      return $?
    fi
  done

  return 1
}