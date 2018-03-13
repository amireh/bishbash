declare -a __bb_import_paths=(".")
declare -a __bb_import_imports=()
declare -a __bb_import_package_names=()
declare -a __bb_import_package_sources=()

# source a shell script at most once
function bb.import() {
  local script="${1}"

  # don't re-source
  if [[ " ${__bb_import_imports[@]} " =~ " ${script} " ]]; then
    return 0
  fi

  IFS='/' local fragments=( "${script}" )

  if [[
    "${#fragments[@]}" -gt 1 &&
    " ${__bb_import_package_names} " =~ " ${fragments[0]} "
  ]]; then
    (1>&2 echo "found a package module: ${fragments[0]} ${fragments:1:${#fragments[@]}}")
  fi

  local resolved=$( bb.import.__resolve_path "${script}" )

  if test -z "${resolved}"; then
    (1>&2 echo "Unable to import \"${script}\": file not found.")
    return 1
  fi

  source "${resolved}" || return 1

  __bb_import_imports+=( "$script" )
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
function bb.import.__resolve_path() {
  local script="${1}"
  local resolved

  if [[ "${script}" =~ ^/ ]]; then
    echo "${script}"
    return 0
  fi

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