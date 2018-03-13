# (Array): Boolean
function bb.array.is_empty() {
  test $# -eq 0
}

# (Array): String
function bb.array.last() {
  if ! bb.array.is_empty $@; then
    echo "${@:$#:1}"
  fi
}

# (Array): Array
function bb.array.tail() {
  if ! bb.array.is_empty $@; then
    echo "${@:1:$(($#-1))}"
  fi
}

# (Array, String): Boolean
function bb.array.contains() {
  local item="${@:$#:1}"
  local array=( $(bb.array.tail "${@}") )

  [[ " ${array[@]} " =~ " ${item} " ]]
}
