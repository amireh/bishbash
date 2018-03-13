declare -a __import_paths=(".")
declare -a __import_imported=()
declare -a __import_package_names=()
declare -a __import_package_sources=()

# source a shell script at most once
function import() {
  local script symbols

  if [[ " ${@} " =~ " : " ]]; then
    symbols="${1}"
    script="${3}"
  else
    script="${1}"
  fi

  # source only once
  if [[ ! " ${__import_imported[@]} " =~ " ${script} " ]]; then
    local module=$( import.__resolve_module "${script}" )

    if [[ -z "${module}" || ! -s "${module}" ]]; then
      (1>&2 echo "import: cannot find module \"${script}\"")
      return 1
    fi

    source "${module}" || return $?

    __import_imported+=( "${script}" )
  fi

  if [[ -n "${symbols}" ]]; then
    import.__import_symbols "${symbols}"
  fi
}

# (): void
function import.add_path() {
  __import_paths+=("${1}")
}

# (name: String, location: String): void
function import.add_package() {
  __import_package_names+=("${1}")
  __import_package_sources+=("${2}")
}

# (String:) String
#
# Resolve a path to a file or a directory relative to the current script path.
#
# Credit: http://www.linuxjournal.com/content/normalizing-path-names-bash
function import.resolve() {
  if [[ "${1}" =~ ^/ ]]; then
    echo "${1}"
    return 0
  fi

  local over_there="$( cd "$( dirname "${BASH_SOURCE[1]}" )" && pwd )"
  local path="${over_there}/${1}"

  # Remove all /./ sequences.
  path="${path//\/.\//\/}"

  # Remove dir/.. sequences.
  while [[ "${path}" =~ ([^/][^/]*/\.\./) ]]; do
    path="${path/${BASH_REMATCH[0]}/}"
  done

  path="${path%/}"

  echo $path
}

# @private
function import.__resolve_module() {
  local script="${1}"

  if import.__resolve_module_on_disk "${script}"; then
    return 0
  elif import.__resolve_module_in_package "${script}"; then
    return 0
  else
    return 1
  fi
}

# @private
function import.__resolve_module_on_disk() {
  local script="${1}"
  local resolved

  # absolute path
  if [[ "${script}" =~ ^/ ]]; then
    echo "${script}"
    return 0
  fi

  # look through the modules on disk:
  for path in "${__import_paths[@]}"; do
    resolved="${path}/${script}"

    if test -f "${resolved}"; then
      echo "${resolved}"
      return 0
    fi
  done

  return 1
}

# @private
function import.__resolve_module_in_package() {
  local script="${1}"
  local resolved
  local fragments
  local pkg_id
  local i

  # potentially a package module:
  IFS='/' fragments=( $(echo "${script}") )

  pkg_id="${fragments[0]}"

  if [[ "${#fragments[@]}" -gt 1 && " ${__import_package_names[@]} " =~ " ${pkg_id} " ]]; then
    for i in "${!__import_package_names[@]}"; do
      if [[ "${__import_package_names[i]}" != "${pkg_id}" ]]; then
        continue
      fi

      resolved="${__import_package_sources[i]}/${script}"

      if [[ -f "${resolved}" ]]; then
        echo "${resolved}"
        return 0
      fi
    done
  fi

  return 1
}

function import.__import_symbols() {
  local symbol="${1}"

  IFS=$'\n' local defined=( $(declare -f -F | grep "${symbol}" | cut -d' ' -f3) )

  for export in "${defined[@]}"; do
    local name=$( echo "${export}" | cut -d'.' -f2- )

    if declare -f -F "${name}" 1>/dev/null; then
      continue
    # don't export private symbols marked with __
    elif [[ " ${name} " =~ ".__" ]]; then
      continue
    fi

    eval """
      function $name() {
        $export \"\${@}\"
      }
    """
  done

  return 0
}