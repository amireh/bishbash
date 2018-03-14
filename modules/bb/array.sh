# (Array): Boolean
function array.is_empty() {
  [[ $# -eq 0 ]]
}

# (Array): String
function array.last() {
  if [[ $# -gt 0 ]]; then
    echo "${@:(-1)}"
  fi
}

# (Array): Array
function array.tail() {
  if [[ $# -gt 0 ]]; then
    echo "${@:1:$#-1}"
  fi
}

# (Array, String): Boolean
function array.contains() {
  if [[ $# -eq 0 ]]; then
    return 1
  fi

  local array="${@:1:($#-1)}"
  local item="${@:(-1)}"

  [[ " ${array[@]} " =~ " ${item} " ]]
}
