# (): Boolean
function platform.macOS() {
  test $(uname) == "Darwin"
}

# (): Boolean
function platform.arch_linux() {
  [[ $(uname -a) =~ "-ARCH" ]]
}

# (): Boolean
function platform.ubuntu() {
  [[ $(uname -a) =~ "-Ubuntu" ]]
}

# (String): Boolean
function platform.is_function_available() {
  declare -f -F "${1}" 1>/dev/null
}

# (String): Boolean
function platform.is_command_available() {
  which "$1" >/dev/null
}

# (): Boolean
function platform.source_profile() {
  local files=(~/.bash_profile ~/.profile /etc/profile)

  for file in "${files[@]}"; do
    if [ -e "${file}" ]; then
      source "${file}"
      return $?
    fi
  done

  return 1
}