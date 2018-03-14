#!/usr/bin/env bash

# download bishbash:
if [[ ! -s ~/'.bishbash/import.sh' ]]; then
  mkdir -p ~/'.bishbash'
  curl -sS -f 'https://raw.githubusercontent.com/amireh/bishbash/master/modules/bb/import.sh' > ~/'.bishbash/import.sh'
fi

# load the "import" routine:
source ~/'.bishbash/import.sh'

# tell it where to load modules from:
import.add_package 'bb' 'github:amireh/bishbash#master'

# load modules:
import "bb/tasks.sh"
