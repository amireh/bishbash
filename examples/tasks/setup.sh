#!/usr/bin/env bash

# download bishbash:
if [[ ! -s ~/'.bishbash/import.sh' ]]; then
  mkdir -p ~/'.bishbash'
  curl -sS -f 'https://raw.githubusercontent.com/amireh/bishbash/master/modules/bb/import.sh' > ~/'.bishbash/import.sh'
fi

# load bishbash:
source ~/'.bishbash/import.sh'

# tell it where to load modules from:
import.add_package 'bb' 'github:amireh/bishbash#master'

# load modules:
import "bb/tasks.sh"

tasks.define 'a'
tasks.define 'b'
tasks.define 'c'

tasks.read_wants $@

shift $?

if tasks.wants_help; then
  tasks.print_help "$(import.resolve ".")"
  exit 1
fi

tasks.run_all "$(import.resolve ".")" "${1:-up}"
