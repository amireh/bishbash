declare -a __bb_import_paths=(".")
declare -a __bb_import_imported=()
declare -a __bb_import_package_names=()
declare -a __bb_import_package_sources=()

# source a shell script at most once
function bb.import() {
  local script="${1}"

  # already sourced: quit
  if [[ " ${__bb_import_imported[@]} " =~ " ${script} " ]]; then
    return 0
  fi

  local resolved=$( bb.import.__resolve_module "${script}" )

  if test -z "${resolved}"; then
    (1>&2 echo "Unable to import \"${script}\": file not found.")
    return 1
  fi

  source "${resolved}" || return 1

  __bb_import_imported+=( "$script" )
}

# (): void
function bb.import.add_path() {
  __bb_import_paths+=("${1}")
}

# (name: String, location: String): void
function bb.import.add_package() {
  __bb_import_package_names+=("${1}")
  __bb_import_package_sources+=("${2}")
}

# (String:) String
function bb.import.resolve() {
  local over_there="$( cd "$( dirname "${BASH_SOURCE[1]}" )" && pwd )"

  bb.import.__normalize_path "${over_there}/${1}"
}

# @private
function bb.import.__resolve_module() {
  local script="${1}"

  if bb.import.__resolve_module_on_disk "${script}"; then
    return 0
  elif bb.import.__resolve_module_in_package "${script}"; then
    return 0
  else
    return 1
  fi
}

# @private
function bb.import.__resolve_module_on_disk() {
  local script="${1}"
  local resolved

  # absolute path
  if [[ "${script}" =~ ^/ ]]; then
    echo "${script}"
    return 0
  fi

  # look through the modules on disk:
  for path in "${__bb_import_paths[@]}"; do
    resolved="${path}/${script}"

    if test -f "${resolved}"; then
      echo "${resolved}"
      return 0
    fi
  done

  return 1
}

# @private
function bb.import.__resolve_module_in_package() {
  local script="${1}"
  local resolved
  local fragments
  local pkg_id
  local i

  # potentially a package module:
  IFS='/' fragments=( $(echo "${script}") )

  pkg_id="${fragments[0]}"

  if [[ "${#fragments[@]}" -gt 1 && " ${__bb_import_package_names[@]} " =~ " ${pkg_id} " ]]; then
    for i in "${!__bb_import_package_names[@]}"; do
      if [[ "${__bb_import_package_names[i]}" != "${pkg_id}" ]]; then
        continue
      fi

      resolved="${__bb_import_package_sources[i]}/${script}"

      if [[ -f "${resolved}" ]]; then
        echo "${resolved}"
        return 0
      fi
    done
  fi

  return 1
}

# @private
#
# credit: http://www.linuxjournal.com/content/normalizing-path-names-bash
function bb.import.__normalize_path() {
  # Remove all /./ sequences.
  local path="${1//\/.\//\/}"

  # Remove dir/.. sequences.
  while [[ "${path}" =~ ([^/][^/]*/\.\./) ]]; do
    path="${path/${BASH_REMATCH[0]}/}"
  done

  echo $path
}