__import_checksum_routine=""
__import_home="${BISHBASH_HOME}"
__import_imported=()
__import_package_names=()
__import_package_sources=()
__import_pedantic=false
__import_paths=()

if [[ -z "${__import_home}" ]]; then
  __import_home=~/'.bishbash'
fi

# source a shell script at most once
function import() {
  local script="${1}"

  # source only once
  if [[ " ${__import_imported[@]} " =~ " ${script} " ]]; then
    return 0
  fi

  local module=$( import.__resolve_module "${script}" )

  if [[ -z "${module}" || ! -s "${module}" ]]; then
    printf "import: cannot find module \"${script}\"\n" 1>&2

    if [[ $__import_pedantic ]]; then
      exit 1
    fi

    return 1
  fi

  source "${module}" || return $?

  __import_imported+=( "${script}" )
}

function import.pedantic() {
  __import_pedantic=$1
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

# (command: String): void
function import.checksum() {
  __import_checksum_routine="$1"
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

  # remove all /./ sequences.
  path="${path//\/\.\///}"

  # remove dir/.. sequences.
  while [[ "${path}" =~ ([^/][^/]*/\.\./) ]]; do
    path="${path/${BASH_REMATCH[0]}/}"
  done

  # remove trailing slash for directories
  path="${path%/}"

  echo $path
}

# @private
#
# (path: String): String?
function import.__resolve_module() {
  local script="${1}"

  # if it's absolute path we'll do nothing, even if the file doesn't exist
  if [[ "${script}" =~ ^/ ]]; then
    echo "${script}"
    return 0
  fi

  import.__resolve_module_in_path "${script}" ||
  import.__resolve_module_in_package "${script}"
}

# @private
#
# Look through the modules on disk registered using `import.path()`.
function import.__resolve_module_in_path() {
  for path in "${__import_paths[@]}"; do
    if test -f "${path}/${1}"; then
      echo "${path}/${1}"
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
  local package
  local i

  # potentially a package module:
  IFS='/' fragments=( $(echo "${script}") )

  package="${fragments[0]}"

  if [[ ${#fragments[@]} -lt 2 ]]; then
    return 1
  elif [[ ! " ${__import_package_names[@]} " =~ " ${package} " ]]; then
    return 1
  fi

  for i in "${!__import_package_names[@]}"; do
    if [[ ${__import_package_names[i]} != ${package} ]]; then
      continue
    fi

    local package_source="${__import_package_sources[i]}"

    # file exists on disk?
    if [[ -f "${package_source}/${script}" ]]; then
      echo "${package_source}/${script}"
      return 0
    fi

    # github mebbe?
    import.__resolve_module_from_github "${script}" "${package_source}"
  done
}

function import.__resolve_module_from_github() {
  local script="${1}"
  local pkg_source="${2}"
  local pkg_refurl_re="github:(.+)/(.+)#(.+)(/.+)?"
  #                           ---- ---- ---- ----
  #                           user repo tree path

  if [[ ! $pkg_source =~ $pkg_refurl_re ]]; then
    return 1
  fi

  local gh_user="${BASH_REMATCH[1]}"
  local gh_repo="${BASH_REMATCH[2]}"
  local gh_tree="${BASH_REMATCH[3]}"
  local gh_path="${BASH_REMATCH[4]}"
  local gh_url="https://raw.githubusercontent.com/${gh_user}/${gh_repo}/${gh_tree}${gh_path}/${script}"
  local gh_url_digest=$(import.__calculate_digest "${gh_url}")

  if [[ -z $gh_url_digest ]]; then
    printf "import: unable to calculate digest, please ensure you have\n" 1>&2
    printf "        one of the following programs installed:\n" 1>&2
    printf "        sha256sum, sha1sum, shasum, md5sum\n" 1>&2

    return 1
  fi

  local disk_path="${__import_home}/modules/${gh_url_digest}.sh"

  if [ ! -d "${__import_home}/modules" ]; then
    mkdir -p "${__import_home}/modules"
  fi

  if [ ! -s "${disk_path}" ]; then
    printf "import: downloading script \"${script}\" from github:\n" 1>&2
    printf "import:     ${gh_url}\n" 1>&2

    curl -sS -f "${gh_url}" 1> "${disk_path}" || {
      printf "import: could not retrieve module from github\n" 1>&2

      return 1
    }
  fi

  echo "${disk_path}"
}

# @private
#
# (String): String
function import.__calculate_digest() {
  if [[ -n $__import_checksum_routine ]]; then
    echo "${1}" | $__import_checksum_routine | cut -d' ' -f1
  elif which sha256sum >/dev/null; then
    echo "${1}" | sha256sum | cut -d' ' -f1
  elif which sha1sum >/dev/null; then
    echo "${1}" | sha1sum | cut -d' ' -f1
  elif which shasum >/dev/null; then
    echo "${1}" | shasum | cut -d' ' -f1
  elif which md5sum >/dev/null; then
    echo "${1}" | md5sum | cut -d' ' -f1
  else
    return 1
  fi
}