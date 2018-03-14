# (String): String
#
# Print a multi-line message with sane formatting; automatic trimming and word-
# wrapping. The "n" stands for nice.
#
# Use \ to conjunct lines in a paragraph. You can also use printf(1) formatting
# to insert padding or perform any substitution.
#
# Usage:
#
#     nprintf """
#       Lorem ipsum dolor sit amet, consectetur adipiscing elit. \
#       Donec gravida turpis at tellus rutrum, vel luctus tellus rutrum.
#
#       Phasellus ut elit ac lorem commodo congue nec sed lorem. \
#       Sed mauris velit, volutpat ut blandit in, blandit finibus nisl.
#     """
#     => | Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec gravida
#        | turpis at tellus rutrum, vel luctus tellus rutrum.
#        |
#        | Phasellus ut elit ac lorem commodo congue nec sed lorem. Sed mauris
#        | velit, volutpat ut blandit in, blandit finibus nisl.
#
#
#     nprintf """
#       Some message:
#
#       %-4s some code %d
#     """ "" 3
#     => |
#        | Some message:
#        |
#        |     some code 3
#
function nprintf() {
  local buffer

  printf -v buffer \
    "$(echo -n "${1}" | tr -s '[ ]' | sed -e 's|^ ||' | fold -s -w 72)" \
    "${@:2:$#}"

  echo "${buffer}"
}
