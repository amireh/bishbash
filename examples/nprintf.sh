import "bb/nprintf"

nprintf """
  Lorem ipsum dolor sit amet, consectetur adipiscing elit. \
  Donec gravida turpis at tellus rutrum, vel luctus tellus rutrum.

  Phasellus ut elit ac lorem commodo congue nec sed lorem. \
  Sed mauris velit, volutpat ut blandit in, blandit finibus nisl.
"""
# Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec gravida
# turpis at tellus rutrum, vel luctus tellus rutrum.
#
# Phasellus ut elit ac lorem commodo congue nec sed lorem. Sed mauris
# velit, volutpat ut blandit in, blandit finibus nisl.

nprintf """
  Some message:

  %-4s some code %d
""" "" 3
# Some message:
#
#     some code 3