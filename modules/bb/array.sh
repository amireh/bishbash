# (Array): Boolean
function array.is_empty() {
  test $# -eq 0
}

# (Array): String
function array.last() {
  if ! array.is_empty $@; then
    echo "${@:$#:1}"
  fi
}

# (Array): Array
function array.tail() {
  if ! array.is_empty $@; then
    echo "${@:1:$(($#-1))}"
  fi
}

# (Array, String): Boolean
function array.contains() {
  local item="${@:$#:1}"
  local array=( $(array.tail "${@}") )

  [[ " ${array[@]} " =~ " ${item} " ]]
}
