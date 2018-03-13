function dry() {
  if test "$DRY_RUN" == "1"; then
    echo "${@}" 1>&2
    return 0
  else
    $@
  fi
}
