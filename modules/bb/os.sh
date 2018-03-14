# (): Boolean
function os.macOS() {
  test $(uname) == "Darwin"
}

# (): Boolean
function os.arch_linux() {
  [[ $(uname -a) =~ "-ARCH" ]]
}

# (): Boolean
function os.ubuntu() {
  [[ $(uname -a) =~ "-Ubuntu" ]]
}
