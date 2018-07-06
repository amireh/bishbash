#!/usr/bin/env bash

# download the import function:
if [[ ! -s ~/'.bishbash/import.sh' ]]; then
  mkdir -p ~/'.bishbash'
  curl -sS -f \
    'https://raw.githubusercontent.com/amireh/bishbash/master/modules/bb/import.sh' > ~/'.bishbash/import.sh'
fi

# load it and say good bye to good source:
source ~/'.bishbash/import.sh'

# that's it, you can now start importing scripts:

# A) relative imports, free of current-working directory:
import "./foo.sh"

# B) disk imports (similar to PATH but for scripts):
import.path "~/my-bash-scripts"
import "foo.sh" # => ~/my-bash-scripts/foo.sh

# C) import scripts from a "package" living on the internet, like a github repository:
import.package 'bb' 'github:amireh/bishbash#master/modules'
import "bb/tasks.sh" # => modules/bb/tasks.sh from github
